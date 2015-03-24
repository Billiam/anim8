require 'spec.love-mocks'

local anim8        = require 'anim8'
local newFrameset = anim8.newFrameset

describe("anim8", function()
  describe("newFrameset", function()
    it("sets the basic stuff", function()
      local img = {}
      local a = newFrameset(img, {1,2,3}, 4)
      assert.same({1,2,3}, a.frames)
      assert.same({1, 1, 1}, a.durations)
      assert.equal(img, a.image)
    end)

    it("makes a clone of the frame table", function()
      local frames = {1,2,3}
      local a = newFrameset({}, frames, 4)
      assert.same(frames, a.frames)
      assert.not_equal (frames, a.frames)
    end)

    describe("when parsing the durations", function()
      it("reads a simple array", function()
        local a = newFrameset({}, {1,2,3,4}, {4,6,8,10})
        assert.same({1, 1.5, 2, 2.5}, a.durations)
      end)
      it("reads a hash with strings or numbers", function()
        local a = newFrameset({}, {1,2,3,4}, {['1-3']=1, [4]=4})
        assert.same({1,1,1,4}, a.durations)
      end)
      it("reads mixed-up durations", function()
        local a = newFrameset({}, {1,2,3,4}, {5, ['2-4']=2})
        assert.same({2.5, 1, 1, 1}, a.durations)
      end)
      describe("when given erroneous input", function()
        it("throws errors for keys that are not integers or strings", function()
          assert.error(function() newFrameset({}, {1}, {[{}]=1}) end)
          assert.error(function() newFrameset({}, {1}, {[print]=1}) end)
          assert.error(function() newFrameset({}, {1}, {print}) end)
        end)
        it("throws errors when frames are missing durations", function()
          assert.error(function() newFrameset({}, {1,2,3,4,5}, {["1-3"]=1}) end)
          assert.error(function() newFrameset({}, {1,2,3,4,5}, {1,2,3,4}) end)
        end)
      end)
    end)
  end)

  describe("Frameset", function()
    describe(":clone", function()
      it("returns a new frameset with the same properties", function()
        local frames = {1,2,3,4 }
        local img = {}
        local a = newFrameset(img, frames, 1)

        local b = a:clone()
        assert.not_equal(frames, b.frames)
        assert.same(frames, b.frames)
        assert.equal(img, b.image)
        assert.same(a.durations, b.durations)
      end)
    end)
  end)
end)
