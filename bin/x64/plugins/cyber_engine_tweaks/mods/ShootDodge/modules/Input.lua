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
local Session = require("modules/Session") -- C2SD-T45
local WeaponGate = require("modules/WeaponGate")

local Input = {
  clock = 0,
  detector = nil,
  installed = false,
  -- Extra veto the state machine (C2SD-T6) can set, e.g. to block a new combo mid-dive.
  isBlocked = function() return false end,
  -- C2SD-T38: whether Bullet Time mode is on (set by init.lua from the meter); while it is, jump
  -- alone is the Shootdodge (see modules/ComboDetector.lua).
  isBulletTimeMode = function() return false end,
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

-- Shared with the dive (C2SD-T7) so lift-off and landing use the same ground check as the combo.
Input.IsGrounded = isGrounded

local function isInVehicle(player)
  local ok, vehicle = pcall(function() return Game.GetMountedVehicle(player) end)
  return ok and vehicle ~= nil
end

local function enumName(enumType, value)
  if value == nil then return nil end
  local ok, name = pcall(function() return value.value end)
  if ok and type(name) == "string" and name ~= "" then return name end
  ok, name = pcall(function() return EnumValueToString(enumType, EnumInt(value)) end)
  if ok and type(name) == "string" and name ~= "" then return name end
  return nil
end

-- gamedataItemType name of one weapon object, or nil when unknown.
local function weaponType(weapon)
  if weapon == nil then return nil end
  local ok, name = pcall(function()
    local itemID = weapon:GetItemID()
    local t = enumName("gamedataItemType", RPGManager.GetItemType(itemID))
    if t then return t end
    local record = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID))
    return enumName("gamedataItemType", record:ItemType():Type())
  end)
  if ok then return name end
  return nil
end

local function entityKey(entity)
  local ok, key = pcall(function() return tostring(entity:GetEntityID().hash) end)
  if ok then return key end
  return nil
end

-- gamedataItemType names of the weapons in V's hands right now: the main (right-hand) weapon and,
-- C2SD-T30, the off-hand gun the 2.5 Double Trouble perk puts in AttachmentSlots.WeaponLeft
-- (ScriptedPuppet.GetWeaponLeft, nil when V holds one weapon). Either is nil when absent/unknown.
local function equippedWeaponTypes(player)
  local ok, right, left = pcall(function()
    local main = ScriptedPuppet.GetWeaponRight(player)
    if main == nil then main = GameObject.GetActiveWeapon(player) end
    local leftOk, off = pcall(function() return ScriptedPuppet.GetWeaponLeft(player) end)
    if not leftOk then off = nil end
    -- GetActiveWeapon falls back to the left slot: the same gun is not a pair.
    if main ~= nil and off ~= nil and entityKey(main) == entityKey(off) then off = nil end
    return main, off
  end)
  if not ok then return nil, nil end
  return weaponType(right), weaponType(left)
end

-- C2SD-T13: result of the last weapon check ({ allowed = bool, label = string }).
Input.weapon = nil

-- Reads the equipped weapon(s) live (no caching), so a weapon swap applies to the next combo.
-- C2SD-T30: while dual wielding both guns must pass the gate (WeaponGate.ClassifyPair).
function Input.WeaponStatus(player)
  local right, left = nil, nil
  if player ~= nil then right, left = equippedWeaponTypes(player) end
  local allowed, label = WeaponGate.ClassifyPair(right, left)
  Input.weapon = { allowed = allowed, label = label }
  return allowed, label
end

-- C2SD-T46: the redscript side's own read of Shift (r6/scripts/ShootDodge/ShootDodgeBulletTimeKey.reds),
-- false when redscript or Input Loader is missing. C2SD-T48: must be defined above Input.Context,
-- which calls it (a local declared later is an undefined global there).
local function ctrlHeldByScript()
  local ok, held = pcall(function()
    local system = Game.GetScriptableSystemsContainer():Get("ShootDodgeBulletTimeKeySystem")
    if system == nil then return false end
    return system:IsModifierHeld()
  end)
  return ok and held == true
end

-- The combo context at the instant jump is pressed.
function Input.Context(player)
  local blocked = player == nil or isInVehicle(player) or Input.isBlocked()
  local weaponAllowed, weapon = Input.WeaponStatus(player)
  return {
    blocked = blocked,
    grounded = player ~= nil and isGrounded(player) or false,
    weaponAllowed = weaponAllowed,
    weapon = weapon,
    bulletTime = Input.isBulletTimeMode() == true,
    modifier = ctrlHeldByScript(), -- C2SD-T46
  }
end

-- C2SD-T51: the actions that mean "Shift (sprint) is down" (C2SD-T46 had Ctrl). Vanilla binds Left
-- Shift to ToggleSprint and Right Shift to Sprint (hold); ShootDodgeModifier is this mod's own
-- Input Loader action on both Shift keys, so Shift still counts whatever those are bound to.
-- Sprint + jump = the Shootdodge.
local MODIFIER_ACTIONS = { Sprint = true, ToggleSprint = true, ShootDodgeModifier = true }

local function actionName(action)
  return Game.NameToString(action:GetName(action))
end

local function actionType(action)
  return action:GetType(action).value
end

local function onAction(player, action)
  local d = Input.detector
  if d == nil then return end
  if not Session.Ready() then return end -- C2SD-T45: ignore the main menu's player

  local name = actionName(action)
  local isCtrl = MODIFIER_ACTIONS[name] == true
  if not isCtrl and name ~= "CameraAim" and name ~= "Jump" and name ~= "MoveX" and name ~= "MoveY" then
    return
  end

  local kind = actionType(action)
  local now = Input.clock

  if isCtrl then
    -- C2SD-T51: Shift held / released (Shift + Space is the Shootdodge).
    if kind == "BUTTON_PRESSED" then
      d:OnModifier(true)
    elseif kind == "BUTTON_RELEASED" then
      d:OnModifier(false)
    end
  elseif name == "CameraAim" then
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
  -- C2SD-T21: session start (the player reappearing after none: main menu -> load, same signal
  -- MeterDriver/LoadoutDriver use) drops held aim / stale move axes from the previous session.
  local hasPlayer = Session.Ready() -- C2SD-T45: not the main menu's player
  if hasPlayer and not Input.hadPlayer then Input.Reset() end
  Input.hadPlayer = hasPlayer
end

-- Forget held inputs (on game load / session end), so a stale "aim held" can't carry over.
function Input.Reset()
  local d = Input.detector
  if not d then return end
  local enabled = d.enabled
  d:Reset()
  if enabled ~= nil then d.enabled = enabled end -- Reset() re-enables; keep the user's toggle
end

return Input
