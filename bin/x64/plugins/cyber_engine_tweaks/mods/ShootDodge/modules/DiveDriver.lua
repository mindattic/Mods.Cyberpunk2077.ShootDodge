-- DiveDriver: CET glue that turns a detected combo into the Shootdodge leap (C2SD-T7).
--
-- On a combo trigger, while the state machine is in NONE:
--   1. read the camera's heading and lock the dive direction from the held movement input
--      (modules/Dive.lua does the math);
--   2. fire NONE -> DIVING on the state machine (the only legal way in, so a combo mid-dive is
--      refused there even if the input layer let one through);
--   3. queue a PSMImpulse on V: the game's own locomotion impulse, layered on the stock jump the
--      same button press already starts (no custom animation; see docs/DESIGN.md).
-- Every frame of the dive it drives the state machine, keeps V on the locked line by cancelling
-- any sideways/backward drift with small corrective impulses, and ends the dive once V is back on
-- the ground. It never touches the camera or aim: V stays first person and free to look and shoot
-- anywhere while flying.
--
-- Until the landing branch exists (C2SD-T10) the end of a dive simply returns the machine to NONE.

local Dive = require("modules/Dive")

local DiveDriver = {
  dive = Dive.new(),
  lastPos = nil,
  lastEnd = nil, -- { reason, time } of the most recent dive, for the overlay
  lastError = nil,
  impulseOk = nil, -- whether the last impulse was queued successfully
  -- Ground check, injected from modules/Input.lua so both use one definition of "grounded".
  isGrounded = function() return true end,
}

local function cameraForward(player)
  local ok, fwd = pcall(function() return Game.GetCameraSystem():GetActiveCameraForward() end)
  if ok and fwd ~= nil then return fwd.x, fwd.y end
  ok, fwd = pcall(function() return player:GetWorldForward() end)
  if ok and fwd ~= nil then return fwd.x, fwd.y end
  return nil, nil
end

local function queueImpulse(player, x, y, z)
  local ok, err = pcall(function()
    local evt = PSMImpulse.new()
    evt.id = "impulse"
    evt.impulse = Vector4.new(x, y, z, 0)
    player:QueueEvent(evt)
  end)
  DiveDriver.impulseOk = ok
  if not ok then DiveDriver.lastError = "impulse: " .. tostring(err) end
  return ok
end

local function worldPosition(player)
  local ok, pos = pcall(function() return player:GetWorldPosition() end)
  if ok and pos ~= nil then return { x = pos.x, y = pos.y } end
  return nil
end

-- Called from the combo listener. Returns true when a dive started.
function DiveDriver.Start(machine, trigger)
  if not machine:Can("dive") then
    -- Mid-dive (or any non-NONE state): record the refusal, don't re-launch.
    machine:Fire("dive", "combo while " .. machine.state)
    return false
  end
  local player = Game.GetPlayer()
  if player == nil then return false end

  local fx, fy = cameraForward(player)
  if fx == nil then
    DiveDriver.lastError = "no camera heading"
    return false
  end
  local impulse, why = DiveDriver.dive:Launch(trigger.moveX, trigger.moveY, fx, fy)
  if impulse == nil then
    DiveDriver.lastError = why
    return false
  end

  machine:Fire("dive", string.format("move %.2f, %.2f", trigger.moveX, trigger.moveY))
  if not queueImpulse(player, impulse.x, impulse.y, impulse.z) then
    DiveDriver.dive:Clear()
    machine:Fire("abort", "impulse failed")
    return false
  end
  DiveDriver.lastPos = worldPosition(player)
  DiveDriver.lastError = nil
  return true
end

-- Call every onUpdate while the mod is enabled (after machine:Update).
function DiveDriver.Update(machine, deltaTime)
  local dive = DiveDriver.dive
  if not dive.active then return end
  if not machine:Is("DIVING") then
    -- Something else (reset, abort, the driver timeout) took the state away: let go.
    DiveDriver.Cancel()
    return
  end
  machine:Drive()

  local player = Game.GetPlayer()
  if player == nil then
    DiveDriver.Cancel()
    machine:Fire("abort", "player gone")
    return
  end

  -- Direction lock: estimate V's horizontal velocity from the frame's movement and push back
  -- onto the locked line.
  local pos = worldPosition(player)
  if pos and DiveDriver.lastPos and deltaTime and deltaTime > 0 then
    local vx = (pos.x - DiveDriver.lastPos.x) / deltaTime
    local vy = (pos.y - DiveDriver.lastPos.y) / deltaTime
    local cx, cy = dive:Correction(vx, vy)
    if cx then queueImpulse(player, cx, cy, 0) end
  end
  DiveDriver.lastPos = pos

  local reason = dive:Update(deltaTime, DiveDriver.isGrounded(player))
  if reason then
    DiveDriver.lastEnd = { reason = reason, time = machine.clock }
    DiveDriver.lastPos = nil
    -- C2SD-T10 replaces this with the landing branch (DIVING/AIRBORNE -> PRONE).
    machine:Fire("abort", "dive over: " .. reason)
  end
end

function DiveDriver.Cancel()
  DiveDriver.dive:Clear()
  DiveDriver.lastPos = nil
end

return DiveDriver
