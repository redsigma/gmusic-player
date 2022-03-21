_G.asd = function()
  local nothing = 0;
end

describe("Level1", function()
    it("test", function()
      asd();
    end)
    describe("Level2", function()
      asd();
      it("test", function()
        asd();
      end)
      describe("Level3", function()
        asd();
        it("test", function()
          asd();
        end)
      end)
    end)
end)
