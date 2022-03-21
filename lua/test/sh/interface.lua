--
-- Tests related to switching from client to server or reversed
--

-- TODO
-- PROBLEMS:
-- OK 1. server side seek must go forward even if muted. BUT client shouldnt
  -- SEEMS FIXED

-- OKish 2. Pausing client and switching to a playing server will not change
-- the top ui. And the TSS remains stuck on server side
  -- SEEMS TO WORK

-- 3. if server reaches end while muted and then you switch to the server, it should already be stopped and not stuck at the end (probably isnt stuck but the seek handle remains visible)
  -- MIGHT BE HARD TO TEST

-- OKish 4. When server autoplay stops while window is hidden, if you show it then the slider is visible for some secs and then disappears. Make it so it disappears in background
  -- SEEMS TO WORK

-- 5. Context menu button doesnt change TSS color



insulate("sh - Switch Highlight CL to SV", function()
  local dermaBase, _ = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  play_cl_switch_sv(dermaBase)
end)

insulate("sh - Switch Highlight SV to CL", function()
  local dermaBase, _ = create_with_dark_mode()
  assert.set_derma(dermaBase)
  init_sv_shared_settings()
  play_sv_switch_cl(dermaBase)
end)