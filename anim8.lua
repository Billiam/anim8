-- anim8 v0.5 - 2012-02
-- Copyright (c) 2011 Enrique García Cota
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local Grid = {}

local function assertPositiveInteger(value, name)
  if type(value) ~= 'number' then error(("%s should be a number, was %q"):format(name, tostring(value))) end
  if value < 1 then error(("%s should be a positive number, was %d"):format(name, value)) end
  if value ~= math.floor(value) then error(("%s should be an integer, was %d"):format(name, value)) end
end

local function createFrame(self, x, y)
  return love.graphics.newQuad(
    (x-1) * self.frameWidth,
    (y-1) * self.frameHeight,
    self.frameWidth,
    self.frameHeight,
    self.imageWidth,
    self.imageHeight
  )
end

local function getOrCreateFrame(self, x, y)
  if x < 1 or x > self.width or y < 1 or y > self.height then
    error(("There is no frame for x=%d, y=%d"):format(x, y))
  end
  self._frames[x] = self._frames[x] or {}
  self._frames[x][y] = self._frames[x][y] or createFrame(self, x, y)
  return self._frames[x][y]
end

local function parseInterval(str)
  str = str:gsub(' ', '')
  local min, max = str:match("^(%d+)-(%d+)$")
  if not min then
    min = str:match("^%d+$")
    max = min
  end
  assert(min and max, ("Could not parse interval from %q"):format(str))
  return tonumber(min), tonumber(max)
end

local function parseIntervals(str)
  local left, right = str:match("(.+),(.+)")
  assert(left and right, ("Could not parse intervals from %q"):format(str))
  local minx, maxx = parseInterval(left)
  local miny, maxy = parseInterval(right)
  return minx, miny, maxx, maxy
end

local function parseFrames(self, args, result, position)
  local current = args[position]
  local kind = type(current)

  if kind == 'number' then

    result[#result + 1] = getOrCreateFrame(self, current, args[position + 1])
    return position + 2

  elseif kind == 'string' then

    local minx, miny, maxx, maxy = parseIntervals(current)
    for x = minx, maxx do
      for y = miny, maxy do
        result[#result+1] = getOrCreateFrame(self,x,y)
      end
    end

    return position + 1

  else

    error(("Invalid type: %q (%s)"):format(kind, tostring(args[position])))

  end
end

function Grid:getFrames(...)
  local args = {...}
  local length = #args
  local result = {}
  local position = 1

  while position <= length do
    position = parseFrames(self, args, result, position)
  end

  return result
end

local Gridmt = {
  __index = Grid,
  __call  = Grid.getFrames
}

local function newGrid(frameWidth, frameHeight, imageWidth, imageHeight)
  assertPositiveInteger(frameWidth,  "frameWidth")
  assertPositiveInteger(frameHeight, "frameHeight")
  assertPositiveInteger(imageWidth,  "imageWidth")
  assertPositiveInteger(imageHeight, "imageHeight")

  local grid = setmetatable(
    { frameWidth  = frameWidth,
      frameHeight = frameHeight,
      imageWidth  = imageWidth,
      imageHeight = imageHeight,
      width       = math.floor(imageWidth/frameWidth),
      height      = math.floor(imageHeight/frameHeight),
      _frames = {}
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

local animationModes = {
  loop   = function(self) self.position = 1 end,
  once   = function(self) self.position = #self.frames end,
  bounce = function(self)
    self.direction = self.direction * -1
    self.position = self.position + self.direction + self.direction
  end
}

local Animationmt = { __index = Animation }

local function parseDelays(delays)
  local parsedDelays = {}
  local tk,min,max
  for k,v in pairs(delays) do
    tk = type(k)
    if     tk == "number"
      then parsedDelays[k] = v
    elseif tk == "string" then
      min, max = parseInterval(k)
      for i = min,max do parsedDelays[i] = v end
    else
      error(("Unexpected delay key: [%s]. Expected a number or a string"):format(tostring(k)))
    end
  end
  return parsedDelays
end

local function repeatValue(value, times)
  local result = {}
  for i=1,times do result[i] = value end
  return result
end

local function createDelays(frames, defaultDelay, delays)
  local maxFrames = #frames
  local result = repeatValue(defaultDelay, maxFrames)
  for i,v in pairs(parseDelays(delays)) do
    if i > maxFrames then
      error(("The delay value %d is too high; there are only %d frames"):format(i, maxFrames))
    end
    result[i] = v
  end
  return result
end

local function newAnimation(mode, frames, defaultDelay, delays)
  delays = delays or {}
  assert(animationModes[mode], ("%q is not a valid mode"):format(tostring(mode)))
  assert(type(defaultDelay) == 'number' and defaultDelay > 0, "defaultDelay must be a positive number" )
  assert(type(delays) == 'table', "delays must be a table or nil")
  return setmetatable({
      mode        = mode,
      frames      = cloneArray(frames),
      padPosition = animationModes[mode],
      delays      = createDelays(frames, defaultDelay, delays),
      timer       = 0,
      position    = 1,
      direction   = 1,
      status      = "playing"
    },
    Animationmt
  )
end


-----------------------------------------------------------

local anim8 = {
  newGrid      = newGrid,
  newAnimation = newAnimation
}
return anim8