
local anim8 = {
  _VERSION     = 'anim8 v2.1.0',
  _DESCRIPTION = 'An animation library for LÖVE',
  _URL         = 'https://github.com/kikito/anim8',
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2011 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

local Grid = {}

local _frames = {}

local function assertPositiveInteger(value, name)
  if type(value) ~= 'number' then error(("%s should be a number, was %q"):format(name, tostring(value))) end
  if value < 1 then error(("%s should be a positive number, was %d"):format(name, value)) end
  if value ~= math.floor(value) then error(("%s should be an integer, was %d"):format(name, value)) end
end

local function createFrame(self, x, y)
  local fw, fh = self.frameWidth, self.frameHeight
  return love.graphics.newQuad(
    self.left + (x-1) * fw + x * self.border,
    self.top  + (y-1) * fh + y * self.border,
    fw,
    fh,
    self.imageWidth,
    self.imageHeight
  )
end

local function getGridKey(...)
  return table.concat( {...} ,'-' )
end

local function getOrCreateFrame(self, x, y)
  if x < 1 or x > self.width or y < 1 or y > self.height then
    error(("There is no frame for x=%d, y=%d"):format(x, y))
  end
  local key = self._key
  _frames[key]       = _frames[key]       or {}
  _frames[key][x]    = _frames[key][x]    or {}
  _frames[key][x][y] = _frames[key][x][y] or createFrame(self, x, y)
  return _frames[key][x][y]
end

local function parseInterval(str)
  if type(str) == "number" then return str,str,1 end
  str = str:gsub('%s', '') -- remove spaces
  local min, max = str:match("^(%d+)-(%d+)$")
  assert(min and max, ("Could not parse interval from %q"):format(str))
  min, max = tonumber(min), tonumber(max)
  local step = min <= max and 1 or -1
  return min, max, step
end

function Grid:getFrames(...)
  local result, args = {}, {...}
  local minx, maxx, stepx, miny, maxy, stepy

  for i=1, #args, 2 do
    minx, maxx, stepx = parseInterval(args[i])
    miny, maxy, stepy = parseInterval(args[i+1])
    for y = miny, maxy, stepy do
      for x = minx, maxx, stepx do
        result[#result+1] = getOrCreateFrame(self,x,y)
      end
    end
  end

  return result
end

local Gridmt = {
  __index = Grid,
  __call  = Grid.getFrames
}

local function newGrid(frameWidth, frameHeight, imageWidth, imageHeight, left, top, border)
  assertPositiveInteger(frameWidth,  "frameWidth")
  assertPositiveInteger(frameHeight, "frameHeight")
  assertPositiveInteger(imageWidth,  "imageWidth")
  assertPositiveInteger(imageHeight, "imageHeight")

  left   = left   or 0
  top    = top    or 0
  border = border or 0

  local key  = getGridKey(frameWidth, frameHeight, imageWidth, imageHeight, left, top, border)

  local grid = setmetatable(
    { frameWidth  = frameWidth,
      frameHeight = frameHeight,
      imageWidth  = imageWidth,
      imageHeight = imageHeight,
      left        = left,
      top         = top,
      border      = border,
      width       = math.floor(imageWidth/frameWidth),
      height      = math.floor(imageHeight/frameHeight),
      _key        = key
    },
    Gridmt
  )
  return grid
end

-----------------------------------------------------------

local Animation = {}

local function cloneArray(arr)
  local result = {}
  for i=1,#arr do result[i] = arr[i] end
  return result
end

local function parseDurations(durations, frameCount)
  local result = {}

  if type(durations) ~= 'table' then
    for i=1,frameCount do result[i] = 1 end
  else
    -- normalize durations to a minumum value of 1
    local lowestDuration

    for key,duration in pairs(durations) do
      assert(type(duration) == 'number', "The value [" .. tostring(duration) .. "] should be a number")

      if not lowestDuration or lowestDuration > duration then
        lowestDuration = duration
      end
    end

    assert(frameCount == 0 or lowestDuration > 0, "A frame durations should all be above zero, but the value [" .. tostring(lowestDuration) .. "] was detected")

    local min, max, step
    for key,duration in pairs(durations) do
      min, max, step = parseInterval(key)
      for i = min,max,step do
        result[i] = duration / lowestDuration
      end
    end

    if #result < frameCount then
      error("The durations table has length of " .. tostring(#result) .. ", but it should be >= " .. tostring(frameCount))
    end
  end

  return result
end

local Animationmt = { __index = Animation }

local function newAnimation(image, frames, durations)
  return setmetatable({
    image          = image,
    frames         = cloneArray(frames),
    durations      = parseDurations(durations, #frames),
  },
    Animationmt
  )
end

function Animation:clone()
  return newAnimation(self.image, self.frames, self.durations)
end

-----------------------------------------------------------

local Status = {
  PLAYING = 'playing',
  PAUSED = 'paused'
}

local Player = {}
local Playermt = { __index = Player }

local nop = function() end

local function parseIntervals(durations, speed)
  local result, time = {0},0
  for i=1,#durations do
    time = time + durations[i] * speed
    result[i+1] = time
  end
  return result, time
end

local function newPlayer(animation, framerate, onLoop)
  onLoop = onLoop or nop
  local intervals, totalDuration = parseIntervals(animation.durations, 1/framerate)

  return setmetatable({
    animation = animation,
    timer          = 0,
    position       = 1,
    status         = Status.PLAYING,
    flippedH       = false,
    flippedV       = false,
    onLoop         = onLoop,
    intervals      = intervals,
    totalDuration  = totalDuration
  },
    Playermt
  )
end

local function seekFrameIndex(intervals, timer)
  local high, low, i = #intervals-1, 1, 1

  while(low <= high) do
    i = math.floor((low + high) / 2)
    if     timer >  intervals[i+1] then low  = i + 1
    elseif timer <= intervals[i]   then high = i - 1
    else
      return i
    end
  end

  return i
end

-- TODO: Memoize delegated properties
function Player:frames()
  return self.animation.frames
end

function Player:image()
  return self.animation.image
end

function Player:flipH()
  self.flippedH = not self.flippedH
  return self
end

function Player:flipV()
  self.flippedV = not self.flippedV
  return self
end

function Player:frameAt(index)
  return self:frames()[index]
end

function Player:frameCount()
  return #self:frames()
end

function Player:update(dt)
  if self.status ~= Status.PLAYING then return end

  self.timer = self.timer + dt
  local loops = math.floor(self.timer / self.totalDuration)
  if loops ~= 0 then
    self.timer = self.timer - self.totalDuration * loops
    local f = type(self.onLoop) == 'function' and self.onLoop or self[self.onLoop]
    f(self, loops)
  end

  self.position = seekFrameIndex(self.intervals, self.timer)
end

function Player:pause()
  self.status = Status.PAUSED
end

function Player:gotoFrame(position)
  self.position = position
  self.timer = self.intervals[self.position]
end

function Player:pauseAtEnd()
  self.position = self:frameCount()
  self.timer = self.totalDuration
  self:pause()
end

function Player:pauseAtStart()
  self.position = 1
  self.timer = 0
  self:pause()
end

function Player:resume()
  self.status = Status.PLAYING
end

function Player:draw(x, y, r, sx, sy, ox, oy, ...)
  local frame = self:frameAt(self.position)

  if self.flippedH or self.flippedV then
    r,sx,sy,ox,oy = r or 0, sx or 1, sy or 1, ox or 0, oy or 0
    local _,_,w,h = frame:getViewport()

    if self.flippedH then
      sx = sx * -1
      ox = w - ox
    end
    if self.flippedV then
      sy = sy * -1
      oy = h - oy
    end
  end

  love.graphics.draw(self:image(), frame, x, y, r, sx, sy, ox, oy, ...)
end

-----------------------------------------------------------

anim8.newGrid       = newGrid
anim8.newAnimation  = newAnimation
anim8.newPlayer     = newPlayer

return anim8
