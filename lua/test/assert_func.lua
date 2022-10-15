
-- https://lua-users.org/wiki/ObserverPattern


_G.asd = function()
  local nothing = 0;
end

-- describe("Level1", function()
--     it("test", function()
--       asd();
--     end)
--     describe("Level2", function()
--       asd();
--       it("test", function()
--         asd();
--       end)
--       describe("Level3", function()
--         asd();
--         it("test", function()
--           asd();
--         end)
--       end)
--     end)
-- end)

-- require("includes/modules/observer")

insulate("sv - Autoplay while seek end", function()
  local dermaBase, media = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  dermaBase.main:SwitchModeServer()

  describe("admin access off", function()
    -- _set_checkbox_as_admin(dermaBase.cbadminaccess, false)
    print("asd")
    player_with_admin:do_action(function(self)
      dermaBase.buttonplay:DoClick(nil, 0)
    end)
  end)

end)