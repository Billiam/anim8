anim8
=====

Animation library for [LÖVE](http://love2d.org).

[![Build Status](https://travis-ci.org/Billiam/anim8.svg?branch=master)](https://travis-ci.org/Billiam/anim8)
[![Coverage Status](https://coveralls.io/repos/Billiam/anim8/badge.svg)](https://coveralls.io/r/Billiam/anim8)

It divides animations into three parts: grids, framesets and animations.

`anim8.newGrid(frameWidth, frameHeight, imageWidth, imageHeight, left, top, border)`:

Creates a *Grid*. Grids are useful for quickly defining frames (in LÖVE terminology, they are called *Quads*. The last 3 parameters are optional.

`anim8.newFrameset(image, frames, durations)`:

Creates a new *Frameset*. Framesets represent an image, a collection of frames, and their relative durations.
`image` is a LÖVE image which will be drawn.
`frames` an array of frames.
`durations` an (optional) array of relative frame durations. If not provided, all frames will have same length.

`anim8.newAnimation(frameset, framerate, onLoop)`:

Creates a new *Animation*. Animations can be updated and drawn.
`framerate` is an integer, given as number of frames per second.
`onLoop` is an optional function or method name.

LÖVE compatibility
==================

Since anim8 uses LÖVE's graphical functions, and they change from version to version, you must choose
the version of anim8 which is compatible with your LÖVE.

* The current version of anim8 is v2.1. It is compatible with LÖVE 0.9.x
* The last version of anim8 compatible with LÖVE 0.8.x was [anim8 v2.0](https://github.com/kikito/anim8/tree/v2.0.0).

Example
=======

```lua
local anim8 = require 'anim8'

local animation

function love.load()
  local image = love.graphics.newImage('path/to/image.png')
  local g = anim8.newGrid(32, 32, image:getWidth(), image:getHeight())
  local frameset = anim8.newFrameset(image, g('1-8',1))

  animation = anim8.newAnimation(frameset, 10)
end

function love.update(dt)
  animation:update(dt)
end

function love.draw()
  animation:draw(100, 200)
end
```

You can see a more ellaborated example in the [demo branch](https://github.com/kikito/anim8/tree/demo).

Explanation
===========

Grids
-----

Grids have only one purpose: To build groups of quads of the same size as easily as possible. In order to do this, they need to know only 2 things:
the size of each quad and the size of the image they will be applied two.
Each size is a width and a height, and those are the first 4 parameters of `anim8.newGrid`.

Grids are just a convenient way of getting frames from a sprite. Frames are assumed to be distributed in rows and columns. Frame 1,1 is the one in the first row, first column.

The last 3 parameters of newGrid default to 0. They are called `left`, `right` & `border`. They allow you to handle those cases in which the frames start slightly up or left, or have "borders" that must be ignored.

Grids only have one important method: `Grid:getFrames(...)`.

`Grid:getFrames` accepts an arbitrary number of parameters. They can be either numbers or strings.

* Each two numbers are interpreted as quad coordinates. This way, `grid:getFrames(3,4)` will return the frame in column 3, row 4 of the grid. There can be more than just two: `grid:getFrames(1,1, 1,2, 1,3)` will return the frames in {1,1}, {1,2} and {1,3} respectively.
* Using numbers for long rows is tedious - so grids also accept strings. The previous row of 3 elements, for example, can be also expressed like this: `grid:getFrames(1,'1-3')` . Again, there can be more than one string (`grid:getFrames(1,'1-3', '2-4',3)`) and it's also possible to combine them with numbers (`grid:getFrames(1,4, 1,'1-3')`)

But you will probably never use getFrames directly. You can use a grid as if it was a function, and getFrames will be called. In other words, given a grid called `g`, this:

    g:getFrames('2-8',1, 1,2)

Is equivalent to this:

    g('2-8',1, 1,2)

This is very convenient to use in animations.

Framesets
---------
Framesets are groups of frames, an image, and an optional set of frame durations.

`anim8.newFrameset(image, frames, durations)`:

`image` is a [Löve Drawable](https://love2d.org/wiki/Drawable) object.

`frames` is an array of frames (Quads in LÖVE argot). You could provide your own quad array if you wanted to, but using a grid to get them is very convenient.

`durations` is an optional table. It can represent different durations for different frames. You can specify durations for all frames individually, like this: `{1, 5, 1}` or you can specify durations for ranges of frames: `{['3-5']=1}`.
A duration of `3` will be displayed for three times longer than a duration of `1`. The actual display time will be based on the animation framerate.

Framesets have the following methods:

`Frameset:clone()`

Creates a new frameset identical to the current one.

Animations
----------

Animations have a collection of frames which can be cycled through. Animations have a state (`playing` or `paused`),
a current position, may be rewound, updated and displayed.

`anim8.newAnimation(frames, framerate, onLoop)`:

`frames` is a reference to an anim8 `Frameset` which this animation will iterate over.

`framerate` is a number indicating the number number of frames to play per second.

`onLoop` is an optional parameter which can be a function or a string representing one of the animation methods. It does nothing by default. If specified, it will be called every time an animation "loops". It will have two parameters: the animation instance, and how many loops have been elapsed. The most usual value (apart from none) is the
string 'pauseAtEnd'. It will make the animation loop once and then pause and stop on the last frame.

Animations have the following methods:

`Animation:update(dt)`

Use this inside `love.update(dt)` so that your animation changes frames according to the time that has passed.

`Animation:draw(x, y, angle, sx, sy, ox, oy)`

Draws the current frame in the specified coordinates with the right angle, scale and offset. These parameters work exacly the same way as in [love.graphics.drawq](https://love2d.org/wiki/love.graphics.drawq).

`Animation:gotoFrame(frame)`

Moves the animation to a given frame (frames start counting in 1).

`Animation:pause()`

Stops the animation from updating (`animation:update(dt)` will have no effect)

`Animation:resume()`

Unpauses an animation

`Animation:flipH()`

Flips an animation horizontally (left goes to right and viceversa). This means that the frames are simply drawn differently, nothing more.

Note that this method does not create a new animation. If you want to create a new one, use the `clone` method.

This method returns the animation, so you can do things like `local a = anim8.newAnimation(frameset):flipV()`

`Animation:flipV()`

Flips an animation vertically. The same rules that apply to `flipH` also apply here.

`Animation:pauseAtEnd()`

Moves the animation to its last frame and then pauses it.

`Animation:pauseAtStart()`

Moves the animation to its first frame and then pauses it.

Installation
============

Just copy the anim8.lua file wherever you want it. Then require it wherever you need it:

    local anim8 = require 'anim8'

Please make sure that you read the license, too (for your convenience it's included at the beginning of the anim8.lua file).

Specs
=====

This project uses [busted](http://olivinelabs.com/busted/) for its specs. If you want to run the specs, you will have to install it first. Then just execute the following from the root folder:

    busted

