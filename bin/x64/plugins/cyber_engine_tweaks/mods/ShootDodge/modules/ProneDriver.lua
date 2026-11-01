-- ProneDriver: CET glue that holds V on the ground after a dive (C2SD-T11).
--
-- The dive driver fires AIRBORNE -> PRONE on the landing (C2SD-T10). From then on this driver owns
-- PRONE: it drives the state machine every frame (so the driver timeout never pulls V up on its
-- own: PRONE has no timer), lowers V's first-person camera toward the floor, and leaves aiming and
-- firing entirely to the game, so V free-aims and shoots in any direction, 360 degrees, from the
-- ground. The camera never leaves first person.
--
-- PRONE ends only on a stand input (modules/Prone.lua: a fresh movement press), which is
-- handed to `ProneDriver.onStandRequest`. By default that fires PRONE -> GETUP; the get-up itself
-- (C2SD-T12) owns GETUP from there. V knocked off a ledge while prone aborts to NONE. Leaving PRONE
-- any way at all (abort, reset, mod disable) eases the camera back to standing height.
--
-- Pose: CP77 has no prone stance, so the "lying down" here is the camera height alone; V's body
-- and collision stay the stock standing ones. A real prone pose is the animation follow-up in
-- docs/DESIGN.md ("Open question: animation fidelity").

local Prone = require("modules/Prone")

local ProneDriver = {
  prone = Prone.new(),
  lastEnd = nil, -- { reason, time } of the most recent stand request, for the overlay
  lastError = nil,
  cameraOk = nil, -- whether the last camera offset was applied
  baseCamera = nil, -- the FPP camera's own local position before the first offset
  -- Injected from init.lua (the combo detector tracks MoveX/MoveY and jump at all times) and
  -- modules/Input.lua (one definition of "grounded" for the whole mod).
  isMoveHeld = function() return false end,
  isJumpHeld = function() return false end,
  isGrounded = function() return true end,
}

-- What a stand request does. C2SD-T12 may replace this; the default hands PRONE to GETUP.
function ProneDriver.onStandRequest(machine, reason)
  return machine:Fire("getUp", reason)
end

local function fppCamera(player)
  local ok, cam = pcall(function() return player:GetFPPCameraComponent() end)
  if ok then return cam end
  return nil
end

local function applyCamera(height)
  local player = Game.GetPlayer()
  if player == nil then return false end
  local cam = fppCamera(player)
  if cam == nil then
    ProneDriver.cameraOk = false
    ProneDriver.lastError = "no first-person camera"
    return false
  end
  local ok, err = pcall(function()
    if ProneDriver.baseCamera == nil then
      local base = { x = 0, y = 0, z = 0 }
      local got, pos = pcall(function() return cam:GetLocalPosition() end)
      if got and pos ~= nil then base = { x = pos.x or 0, y = pos.y or 0, z = pos.z or 0 } end
      ProneDriver.baseCamera = base
    end
    local b = ProneDriver.baseCamera
    cam:SetLocalPosition(Vector4.new(b.x, b.y, b.z + height, 1.0))
  end)
  ProneDriver.cameraOk = ok
  if not ok then ProneDriver.lastError = "camera: " .. tostring(err) end
  return ok
end

-- State listener: called on every state change (init.lua wires it).
function ProneDriver.OnStateChange(from, to)
  if to == "PRONE" then
    ProneDriver.prone:Enter(ProneDriver.isMoveHeld(), ProneDriver.isJumpHeld())
    ProneDriver.lastEnd = nil
    ProneDriver.lastError = nil
  elseif from == "PRONE" then
    ProneDriver.prone:Exit()
  end
end

-- Call every onUpdate while the mod is enabled (after machine:Update). deltaTime is real time:
-- the world is back at normal speed once V is down.
function ProneDriver.Update(machine, deltaTime)
  local prone = ProneDriver.prone
  if prone.active and not machine:Is("PRONE") then prone:Exit() end

  local player = Game.GetPlayer()
  if prone.active and player == nil then
    prone:Exit()
    machine:Fire("abort", "player gone")
  end

  local reason
  if prone.active then
    machine:Drive()
    reason = prone:Update(deltaTime, ProneDriver.isMoveHeld(), ProneDriver.isJumpHeld(),
      ProneDriver.isGrounded(player))
  else
    prone:Update(deltaTime) -- keeps easing the camera back up
  end

  if prone:NeedsCamera() or ProneDriver.baseCamera ~= nil then
    applyCamera(prone:Height())
    if not prone:NeedsCamera() then ProneDriver.baseCamera = nil end
  end

  if reason == nil then return end
  ProneDriver.lastEnd = { reason = reason, time = machine.clock }
  if reason == Prone.End.fell then
    machine:Fire("abort", reason)
    return
  end
  local ok, err = pcall(ProneDriver.onStandRequest, machine, reason)
  if not ok then
    ProneDriver.lastError = "stand: " .. tostring(err)
    machine:Fire("abort", "get-up error")
  end
end

-- Drop the pose immediately and put the camera back (mod disabled, reload, shutdown, error).
function ProneDriver.Cancel()
  local prone = ProneDriver.prone
  prone:Exit()
  prone.lowered = 0
  if ProneDriver.baseCamera ~= nil then
    applyCamera(0)
    ProneDriver.baseCamera = nil
  end
end

return ProneDriver
