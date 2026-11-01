-- BulletTimeDriver: CET glue that applies the dive's world time dilation (C2SD-T8).
--
-- Uses the game's own TimeSystem (the lever Sandevistan-style effects pull) under one reason name
-- owned by this mod, so it never touches dilation another effect set. modules/BulletTime.lua
-- decides whether the world should be slowed; this file only reads the game's pause/death state
-- and sets or unsets the dilation to match.
--
-- No stuck slow-mo, ever:
--   * Sync() runs every onUpdate (mod enabled or not) and from a state-machine listener, so a
--     transition out of DIVING/AIRBORNE (landing, abort, driver timeout, reset) clears the
--     dilation in the same frame, the instant the state changes.
--   * The pause menu (or any menu that pauses the game) and V's death count as "not diving":
--     dilation is unset while paused and only re-applied on resume if the dive is still going.
--   * Clear() runs on init (a CET mod reload mid-dive), shutdown and mod disable, and unsets the
--     reason unconditionally even if this session never set it.
--   * If the unset call itself fails, the reason is forced back to 1.0 instead.
--
-- C2SD-T9: while the world is slowed, V's weapon (and, opt-in, all of V) is exempted from the
-- dilation so aim and fire stay responsive (rules in modules/AimFireExemption.lua). The exemption
-- is synced right after the world dilation every time, so it comes and goes the same frame, and
-- Clear() drops it unconditionally too.

local BulletTime = require("modules/BulletTime")
local AimFireExemption = require("modules/AimFireExemption")

local REASON = "ShootDodgeBulletTime"

local BulletTimeDriver = {
  rules = BulletTime.new(),
  exemption = AimFireExemption.new(), -- C2SD-T9
  exemptWeapon = nil, -- C2SD-T9: the weapon entity currently exempted (to unset it after a swap)
  paused = false,
  lastError = nil,
  meter = nil, -- C2SD-T15: the BulletTimeMeter, set by init.lua
}

local function timeSystem()
  return Game.GetTimeSystem()
end

local function isPaused()
  local ok, paused = pcall(function() return Game.GetSystemRequestsHandler():IsGamePaused() end)
  return ok and paused == true
end

local function isDead()
  local ok, dead = pcall(function()
    local player = Game.GetPlayer()
    if player == nil then return true end
    return player:IsDead()
  end)
  return ok and dead == true
end

local function setDilation(factor)
  local ok, err = pcall(function() timeSystem():SetTimeDilation(REASON, factor) end)
  if not ok then BulletTimeDriver.lastError = "set: " .. tostring(err) end
  return ok
end

local function unsetDilation()
  local ok, err = pcall(function() timeSystem():UnsetTimeDilation(REASON) end)
  if ok then return true end
  BulletTimeDriver.lastError = "unset: " .. tostring(err)
  -- Fallback: at least put our reason back to normal speed.
  return setDilation(1.0)
end

-- C2SD-T9: the weapon in V's hands and a stable key for it, or nil when unarmed/unknown.
local function equippedWeapon()
  local ok, weapon, key = pcall(function()
    local player = Game.GetPlayer()
    if player == nil then return nil end
    local w = ScriptedPuppet.GetWeaponRight(player)
    if w == nil then w = GameObject.GetActiveWeapon(player) end
    if w == nil then return nil end
    return w, tostring(w:GetEntityID().hash)
  end)
  if ok then return weapon, key end
  return nil, nil
end

-- C2SD-T9: give one entity its own time scale that ignores the world's dilation.
local function exemptEntity(entity, factor)
  local ok, err = pcall(function()
    entity:SetIndividualTimeDilation(REASON, factor, 0.0, "", "", true)
  end)
  if not ok then BulletTimeDriver.lastError = "exempt weapon: " .. tostring(err) end
  return ok
end

local function unexemptEntity(entity)
  if entity == nil then return true end
  local ok = pcall(function() entity:UnsetIndividualTimeDilation() end)
  -- A weapon that was holstered/despawned meanwhile has nothing left to unset.
  return ok
end

local function exemptPlayer(factor)
  local ok, err = pcall(function()
    timeSystem():SetTimeDilationOnLocalPlayerZero(REASON, factor, 0.0, "", "", true)
  end)
  if not ok then BulletTimeDriver.lastError = "exempt player: " .. tostring(err) end
  return ok
end

local function unexemptPlayer()
  -- The signature changed across game versions (with and without the reason).
  if pcall(function() timeSystem():UnsetTimeDilationOnLocalPlayerZero(REASON) end) then
    return true
  end
  if pcall(function() timeSystem():UnsetTimeDilationOnLocalPlayerZero() end) then return true end
  -- Fallback: at least stop ignoring the world dilation (V follows it again).
  local ok, err = pcall(function()
    timeSystem():SetTimeDilationOnLocalPlayerZero(REASON, 1.0, 0.0, "", "", false)
  end)
  if not ok then BulletTimeDriver.lastError = "unexempt player: " .. tostring(err) end
  return ok
end

-- C2SD-T9: carry out what the exemption rules want for this frame.
local function syncExemption()
  local exemption = BulletTimeDriver.exemption
  local weapon, key = nil, nil
  if BulletTimeDriver.rules.applied ~= nil and exemption.config.exemptWeapon then
    weapon, key = equippedWeapon()
  end
  local actions = exemption:Step({ slowed = BulletTimeDriver.rules.applied, weaponKey = key })
  for _, action in ipairs(actions) do
    local ok
    if action.op == "unsetWeapon" then
      ok = unexemptEntity(BulletTimeDriver.exemptWeapon)
      BulletTimeDriver.exemptWeapon = nil
    elseif action.op == "setWeapon" then
      ok = weapon ~= nil and exemptEntity(weapon, action.factor)
      BulletTimeDriver.exemptWeapon = ok and weapon or nil
    elseif action.op == "setPlayer" then
      ok = exemptPlayer(action.factor)
    elseif action.op == "unsetPlayer" then
      ok = unexemptPlayer()
    end
    exemption:Applied(action, ok)
  end
end

-- C2SD-T9: drop every exemption this session set. The player one is only unset when we set it,
-- so this never touches another effect's (Sandevistan's) player dilation. One left behind by a CET
-- reload is harmless: it is "normal speed, ignore the world", and the world is back to normal too.
local function clearExemption()
  local exemption = BulletTimeDriver.exemption
  unexemptEntity(BulletTimeDriver.exemptWeapon)
  BulletTimeDriver.exemptWeapon = nil
  if exemption.player then unexemptPlayer() end
  exemption.weaponKey = nil
  exemption.player = false
end

-- Unconditionally remove this mod's dilation.
function BulletTimeDriver.Clear()
  unsetDilation()
  BulletTimeDriver.rules.applied = nil
  clearExemption()
end

-- Bring the game's dilation in line with the rules for the current state. Cheap when nothing
-- changes, so it is safe to call every frame and on every state change.
function BulletTimeDriver.Sync(machine, enabled)
  local rules = BulletTimeDriver.rules
  local paused = isPaused()
  BulletTimeDriver.paused = paused
  -- C2SD-T15: the bullet-time meter grants (or, if so configured, refuses) the dive's slow-mo and
  -- owns Max Payne 2's Bullet Time mode. An empty meter ends the mode, which unsets the dilation
  -- here the same frame.
  local meter = BulletTimeDriver.meter
  local mode = enabled and meter ~= nil and meter.mode or false
  local ctx = {
    state = enabled and machine.state or "NONE",
    paused = paused,
    dead = (BulletTime.slowStates[machine.state] or mode) and isDead() or false,
    diveSlow = meter == nil or meter:DiveSlowAllowed(),
    mode = mode,
  }
  local action, factor = rules:Step(ctx)
  if action == "set" then
    if setDilation(factor) then
      rules.applied = factor
    else
      -- Couldn't set it: make sure nothing half-applied lingers.
      BulletTimeDriver.Clear()
    end
  elseif action == "unset" then
    BulletTimeDriver.Clear()
  end
  -- C2SD-T9: aim/fire exemption follows the dilation just applied (or removed), same frame. Also
  -- picks up a weapon swap mid-slow-mo.
  syncExemption()
end

-- Game time per real second for this frame (1.0 when the world isn't slowed).
-- C2SD-T9: with all of V exempted (opt-in), V's own dive runs at normal speed again.
function BulletTimeDriver.TimeScale()
  if BulletTimeDriver.exemption.player then return 1.0 end
  return BulletTimeDriver.rules:TimeScale()
end

return BulletTimeDriver
