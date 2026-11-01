-- Input: CET glue that feeds the game's input actions into the ComboDetector (C2SD-T5).
--
-- Observes PlayerPuppet:OnAction (it does not consume or block any action, so normal aiming,
-- jumping and moving are untouched) and translates the three actions the combo needs:
--   CameraAim  -> aim held / released
--   Jump       -> fresh jump press / release
--   MoveX/MoveY -> movement axes (keyboard WASD and the left stick both report through these)
-- The mod's own clock (advanced in onUpdate) timestamps every event so the detector's hold
-- times and cooldown use one time base.

local ComboDetector = require("modules/ComboDetector")

local Input = {
  clock = 0,
  detector = nil,
  installed = false,
  -- Extra veto the state machine (C2SD-T6) can set, e.g. to block a new combo mid-dive.
  isBlocked = function() return false end,
}

-- Detailed locomotion states in which V is not standing on the ground. Looked up by name and
-- skipped when a game version lacks one, so a renamed state can never break detection.
local AIRBORNE_STATE_NAMES = {
  "Jump", "DoubleJump", "ChargeJump", "HoverJump", "Fall", "AirThrusters", "AirHover", "DodgeAir",
}
local airborneStates = nil

local function buildAirborneStates()
  local set = {}
  for _, name in ipairs(AIRBORNE_STATE_NAMES) do
    local ok, value = pcall(function() return EnumInt(gamePSMDetailedLocomotionStates[name]) end)
    if ok and value ~= nil then set[value] = true end
  end
  return set
end

local function isGrounded(player)
  local ok, grounded = pcall(function()
    if airborneStates == nil then airborneStates = buildAirborneStates() end
    local defs = GetAllBlackboardDefs().PlayerStateMachine
    local bb = Game.GetBlackboardSystem():GetLocalInstanced(player:GetEntityID(), defs)
    local state = bb:GetInt(defs.LocomotionDetailed)
    return not airborneStates[state]
  end)
  -- If the lookup fails, don't silently disable the mod: assume grounded.
  if not ok then return true end
  return grounded
end

local function isInVehicle(player)
  local ok, vehicle = pcall(function() return Game.GetMountedVehicle(player) end)
  return ok and vehicle ~= nil
end

-- The combo context at the instant jump is pressed.
function Input.Context(player)
  local blocked = player == nil or isInVehicle(player) or Input.isBlocked()
  return {
    blocked = blocked,
    grounded = player ~= nil and isGrounded(player) or false,
  }
end

local function actionName(action)
  return Game.NameToString(action:GetName(action))
end

local function actionType(action)
  return action:GetType(action).value
end

local function onAction(player, action)
  local d = Input.detector
  if d == nil then return end

  local name = actionName(action)
  if name ~= "CameraAim" and name ~= "Jump" and name ~= "MoveX" and name ~= "MoveY" then
    return
  end

  local kind = actionType(action)
  local now = Input.clock

  if name == "CameraAim" then
    if kind == "BUTTON_PRESSED" then
      d:OnAim(true, now)
    elseif kind == "BUTTON_RELEASED" then
      d:OnAim(false, now)
    end
  elseif name == "Jump" then
    if kind == "BUTTON_PRESSED" then
      d:OnJump(true, now, Input.Context(player))
    elseif kind == "BUTTON_RELEASED" then
      d:OnJump(false, now)
    end
  elseif kind == "AXIS_CHANGE" then
    local value = action:GetValue(action)
    if name == "MoveX" then
      d:OnMove(value, nil, now)
    else
      d:OnMove(nil, value, now)
    end
  end
end

-- Call once from onInit. Returns the detector so init.lua can add listeners.
function Input.Install(config)
  if Input.installed then return Input.detector end
  Input.detector = ComboDetector.new(config)
  Observe("PlayerPuppet", "OnAction", function(player, action)
    local ok, err = pcall(onAction, player, action)
    if not ok then print("[ShootDodge] input error: " .. tostring(err)) end
  end)
  Input.installed = true
  return Input.detector
end

-- Call from onUpdate with its deltaTime.
function Input.Update(deltaTime)
  Input.clock = Input.clock + (deltaTime or 0)
end

-- Forget held inputs (on game load / session end), so a stale "aim held" can't carry over.
function Input.Reset()
  if Input.detector then Input.detector:Reset() end
end

return Input
