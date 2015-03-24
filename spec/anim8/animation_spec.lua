require 'spec.love-mocks'

local anim8 = require 'anim8'
local newAnimation = anim8.newAnimation

describe("anim8", function()
  describe("newAnimation", function()
    it("sets basic properties", function()
      local frameset = {
        durations = {1, 1, 1}
      }
      local loop = {}

      local a = newAnimation(frameset, 1/4, loop)
      assert.equal(0,         a.timer)
      assert.equal(1,         a.position)
      assert.equal("playing", a.status)
      assert.equal(loop,      a.onLoop)

      assert.same({0,4,8,12}, a.intervals)
      assert.equal(12, a.totalDuration)

      assert.False(a.flippedH)
      assert.False(a.flippedV)
    end)
  end)

  describe("Player", function()
    describe(":update", function()
      it("moves to the next frame #focus", function()
        local frameset = {
          durations = {1, 1, 1, 1}
        }

        local a = newAnimation(frameset, 1)
        a:update(1)
        assert.equal(1, a.position)
        a:update(0.1)
        assert.equal(2, a.position)
      end)

      it("moves several frames if needed", function()
        local frameset = {
          durations = {1, 1, 1, 1}
        }

        local a = newAnimation(frameset, 1)
        a:update(2.1)
        assert.equal(3, a.position)
      end)

      describe("When the last frame is spent", function()
        it("goes back to the first frame in framesets", function()
          local frameset = {
            durations = {1, 1, 1, 1}
          }

          local a = newAnimation(frameset, 1)
          a:update(4.1)
          assert.equal(1, a.position)
        end)
      end)

      describe("When there are different durations per frame", function()
        it("moves the frame correctly", function()
          local frameset = {
            durations = {1, 2, 1, 1}
          }
          local a = newAnimation(frameset, 1)
          a:update(1.1)
          assert.equal(2, a.position)
          a:update(1.1)
          assert.equal(2, a.position)
          a:update(1.1)
          assert.equal(3, a.position)
        end)
      end)

      describe("When the animation loops", function()
        it("invokes the onloop callback", function()
          local looped = false;
          local frameset = {
            durations = {1, 1, 1}
          }
          local a = newAnimation(frameset, 1, function() looped = true end)
          assert.False(looped)
          a:update(4)
          assert.True(looped)
        end)

        it("accepts the callback as a string", function()
          local frameset = {
            durations = {1, 1, 1}
          }
          local a = newAnimation(frameset, 1, 'foo')
          a.foo = function(self) self.looped = true end
          assert.Nil(a.looped)
          a:update(4)
          assert.True(a.looped)
        end)

        it("counts the loops", function()
          local count = 0;
          local frameset = {
            durations = {1, 1, 1}
          }
          local a = newAnimation(frameset, 1, function(a, x) count = count + x end)
          a:update(4)
          assert.equals(count, 1)
          a:update(7)
          assert.equals(count, 3)
        end)

        it("counts negative loops", function()
          local count = 0;
          local frameset = {
            durations = {1, 1, 1}
          }
          local a = newAnimation(frameset, 1, function(a, x) count = count + x end)
          a:update(-2)
          assert.equals(count, -1)
          a:update(-6)
          assert.equals(count, -3)
        end)
      end)
    end)

    describe(":pause", function()
      it("stops animations from happening", function()
        local frameset = {
          durations = {1, 1, 1, 1}
        }
        local a = newAnimation(frameset, 1)
        a:update(1.1)
        a:pause()
        a:update(1)
        assert.equal(2, a.position)
      end)
    end)

    describe(":resume", function()
      it("reanudates paused animations", function()
        local frameset = {
          durations = {1, 1, 1, 1}
        }
        local a = newAnimation(frameset, 1)
        a:update(1.1)
        a:pause()
        a:resume()
        a:update(1)
        assert.equal(3, a.position)
      end)
    end)

    describe(":gotoFrame", function()
      it("moves the position and time to the frame specified", function()
        local frameset = {
          durations = {1, 1, 1, 1}
        }
        local a = newAnimation(frameset, 1)
        a:update(1.1)
        a:gotoFrame(1)
        assert.equal(1, a.position)
        assert.equal(0, a.timer)
      end)
    end)

    describe(":pauseAtEnd", function()
      it("goes to the last frame, and pauses", function()
        local frameset = {
          durations = {1, 1, 1, 1},
          frames = {1, 2, 3, 4}
        }
        local a = newAnimation(frameset, 1)
        a:pauseAtEnd()
        assert.equal(4, a.position)
        assert.equal(4, a.timer)
        assert.equal('paused', a.status)
      end)
    end)

    describe(":pauseAtStart", function()
      it("goes to the first frame, and pauses", function()
        local frameset = {
          durations = {1, 1, 1, 1},
          frames = {1, 2, 3, 4}
        }
        local a = newAnimation(frameset, 1)
        a:pauseAtStart()
        assert.equal(1, a.position)
        assert.equal(0, a.timer)
        assert.equal('paused', a.status)
      end)
    end)

    describe(":draw", function()
      it("invokes love.graphics.draw with the expected parameters", function()
        spy.on(love.graphics, 'draw')
        local img, frame1, frame2, frame3 = {},{},{},{}
        local frameset = {
          durations = {1, 1, 1},
          frames = {frame1, frame2, frame3},
          image = img,
        }
        local a = newAnimation(frameset, 1)
        a:draw(10, 20, 0, 1,2,3,4)
        assert.spy(love.graphics.draw).was.called_with(img, frame1, 10, 20, 0, 1,2,3,4)
      end)
    end)

    describe(":flipH and :flipV", function()
      local img, frame, frameset, a
      before_each(function()
        spy.on(love.graphics, 'draw')
        img = {}
        frame = love.graphics.newQuad(1,2,3,4) -- x,y,width, height
        frameset = {
          durations = {1},
          frames = {frame},
          image = img,
        }
        a = newAnimation(frameset, 1)
      end)

      it("defaults to non-flipped", function()
        assert.False(a.flippedH)
        assert.False(a.flippedV)
      end)

      it("Flips the animation horizontally (does not create a clone)", function()
        a:flipH()
        a:draw(10, 20, 0, 5,6,7,8)
        assert.spy(love.graphics.draw).was.called_with(img, frame, 10, 20, 0, -5,6,3-7,8)

        assert.equal(a, a:flipH())
        a:draw(10, 20, 0, 5,6,7,8)
        assert.spy(love.graphics.draw).was.called_with(img, frame, 10, 20, 0, 5,6,7,8)
      end)

      it("Flips the animation vertically (does not create a clone)", function()
        a:flipV()
        a:draw(10, 20, 0, 5,6,7,8)
        assert.spy(love.graphics.draw).was.called_with(img, frame, 10, 20, 0, 5,-6,7,4-8)

        assert.equal(a, a:flipV())
        a:draw(10, 20, 0, 5,6,7,8)
        assert.spy(love.graphics.draw).was.called_with(img, frame, 10, 20, 0, 5,6,7,8)
      end)
    end)
  end)
end)