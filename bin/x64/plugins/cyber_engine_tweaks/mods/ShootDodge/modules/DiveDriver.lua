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
-- C2SD-T10 ground contact: the driver owns both DIVING and AIRBORNE. The frame V actually leaves
-- the ground it fires DIVING -> AIRBORNE (launch); the frame the landing is confirmed (see
-- Dive:Update, which rejects grazes) it fires land -> PRONE, always, whatever input is held, and
-- records one landing event with whether a movement input was held at impact (`lastLanding`, for
-- the get-up in C2SD-T12, modules/GetUpDriver.lua). PRONE itself is driven by ProneDriver
-- (C2SD-T11), with no timer, until the get-up takes over. A dive that never lifts off or hits the
-- time cap is not a landing and still aborts to NONE.

local Dive = require("modules/Dive")

local DiveDriver = {
  dive = Dive.new(),
  lastPos = nil,
  lastEnd = nil, -- { reason, time } of the most recent dive, for the overlay
  lastError = nil,
  impulseOk = nil, -- whether the last impulse was queued successfully
  -- Ground check, injected from modules/Input.lua so both use one definition of "grounded".
  isGrounded = function() return true end,
  -- C2SD-T10: whether a movement input is held right now (held, magnitude), injected from the
  -- combo detector, which tracks MoveX/MoveY at all times.
  isMoveHeld = function() return false, 0 end,
  -- C2SD-T10: the most recent landing { index, time, moveHeld, moveMagnitude, airTime, grazes }
  -- and the number of landings this session.
  lastLanding = nil,
  landingCount = 0,
  landingListeners = {},
}

-- C2SD-T10: fn(landing) is called once per landing, right after AIRBORNE -> PRONE.
function DiveDriver.AddLandingListener(fn)
  table.insert(DiveDriver.landingListeners, fn)
end

local function cameraForward(player)
  local ok, fwd = pcall(function() return Game.GetCameraSystem():GetActiveCameraForward() end)
  if ok and fwd ~= nil then return fwd.x, fwd.y end
  ok, fwd = pcall(function() return player:GetWorldForward() end)
  if ok and fwd ~= nil then return fwd.x, fwd.y end
  return nil, nil
end

-- C2SD-T50: V counts as airborne this far above the launch point (m), or falling faster than
-- this (m/s, game time).
local AIR_HEIGHT = 0.08
local AIR_FALL_SPEED = 0.5

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
  if ok and pos ~= nil then return { x = pos.x, y = pos.y, z = pos.z } end
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
  -- C2SD-T50: the launch height, for the physical airborne check in Update.
  DiveDriver.launchZ = DiveDriver.lastPos and DiveDriver.lastPos.z or nil
  DiveDriver.lastError = nil
  return true
end

-- Call every onUpdate while the mod is enabled (after machine:Update).
function DiveDriver.Update(machine, deltaTime)
  local dive = DiveDriver.dive
  if not dive.active then return end
  if not (machine:Is("DIVING") or machine:Is("AIRBORNE")) then
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
  local vz = nil
  if pos and DiveDriver.lastPos and deltaTime and deltaTime > 0 then
    local vx = (pos.x - DiveDriver.lastPos.x) / deltaTime
    local vy = (pos.y - DiveDriver.lastPos.y) / deltaTime
    if pos.z and DiveDriver.lastPos.z then vz = (pos.z - DiveDriver.lastPos.z) / deltaTime end
    local cx, cy = dive:Correction(vx, vy)
    if cx then queueImpulse(player, cx, cy, 0) end
    DiveDriver.lastVel = { x = vx, y = vy }
  end
  DiveDriver.lastPos = pos

  -- C2SD-T10: sample the held movement input the same frame as the ground check, so the landing
  -- records what was held at impact.
  local moveHeld, moveMagnitude = DiveDriver.isMoveHeld()
  -- C2SD-T50: in game the locomotion-state check never reported V airborne (every dive aborted
  -- with "never left the ground"), so V's own motion decides too: off the ground while clearly
  -- above the launch point or falling. Either check saying airborne counts.
  local grounded = DiveDriver.isGrounded(player)
  if pos and pos.z and DiveDriver.launchZ then
    local above = pos.z - DiveDriver.launchZ
    if above > AIR_HEIGHT or (vz ~= nil and vz < -AIR_FALL_SPEED) then grounded = false end
  end
  DiveDriver.lastGrounded = grounded
  local reason = dive:Update(deltaTime, grounded, vz)
  if reason == nil then
    -- C2SD-T10: V has really left the ground -> AIRBORNE (once; refused harmlessly otherwise).
    if dive.leftGround and machine:Is("DIVING") then machine:Fire("launch", "left the ground") end
    -- C2SD-T49: keep the leap low, then slam V down once the arc tops out.
    local z = dive:AirImpulse(vz)
    if z then queueImpulse(player, 0, 0, z) end
    return
  end

  DiveDriver.lastEnd = { reason = reason, time = machine.clock }
  DiveDriver.lastPos = nil
  local vel = DiveDriver.lastVel
  DiveDriver.lastVel = nil
  if reason ~= Dive.End.landed then
    machine:Fire("abort", "dive over: " .. reason)
    return
  end
  -- C2SD-T49: hit the ground and stay there: cancel the leap's horizontal speed on impact.
  local stop = dive.config.landingStop or 0
  if vel and stop > 0 then queueImpulse(player, -vel.x * stop, -vel.y * stop, 0) end

  -- C2SD-T10: the landing. Every dive that lands goes prone, held input or not.
  DiveDriver.landingCount = DiveDriver.landingCount + 1
  local landing = {
    index = DiveDriver.landingCount,
    time = machine.clock,
    moveHeld = moveHeld and true or false,
    moveMagnitude = moveMagnitude or 0,
    airTime = dive.airTime,
    grazes = dive.grazes,
  }
  DiveDriver.lastLanding = landing
  machine:Fire("land", landing.moveHeld and "landed, movement held" or "landed, no movement held")
  for _, fn in ipairs(DiveDriver.landingListeners) do
    local ok, err = pcall(fn, landing)
    if not ok then print("[ShootDodge] landing listener error: " .. tostring(err)) end
  end
end

function DiveDriver.Cancel()
  DiveDriver.dive:Clear()
  DiveDriver.lastPos = nil
  DiveDriver.lastVel = nil
  DiveDriver.launchZ = nil
end

return DiveDriver
