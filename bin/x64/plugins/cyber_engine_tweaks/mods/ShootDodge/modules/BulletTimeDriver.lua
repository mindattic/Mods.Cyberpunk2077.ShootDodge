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
--     reason even if this session never set it, but only while a world with V exists (C2SD-T43:
--     at game boot/exit the native call crashes the game).
--   * If the unset call itself fails, the reason is forced back to 1.0 instead.
--
-- C2SD-T9: while the world is slowed, V's weapon (and, opt-in, all of V) is exempted from the
-- dilation so aim and fire stay responsive (rules in modules/AimFireExemption.lua). The exemption
-- is synced right after the world dilation every time, so it comes and goes the same frame, and
-- Clear() drops it unconditionally too. C2SD-T30: while dual wielding (2.5 Double Trouble) both
-- held guns are exempted, and both are dropped on landing, a swap of either hand, and Clear().

local BulletTime = require("modules/BulletTime")
local Session = require("modules/Session") -- C2SD-T45
local AimFireExemption = require("modules/AimFireExemption")

local REASON = "ShootDodgeBulletTime"

local BulletTimeDriver = {
  rules = BulletTime.new(),
  exemption = AimFireExemption.new(), -- C2SD-T9
  -- C2SD-T9 / C2SD-T30: key -> weapon entity currently exempted (to unset it after a swap); two
  -- entries while dual wielding.
  exemptWeapons = {},
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

-- C2SD-T9 / C2SD-T30: the weapons in V's hands as a list of { entity, key }, empty when
-- unarmed/unknown. The right hand first, then the left: with Double Trouble (2.5) the off-hand gun
-- sits in AttachmentSlots.WeaponLeft, which ScriptedPuppet.GetWeaponLeft reads (cast to
-- WeaponObject, so a quick-throw grenade held there is not a weapon and is skipped).
local function heldWeapons()
  local list = {}
  local ok = pcall(function()
    local player = Game.GetPlayer()
    if player == nil then return end
    local right = ScriptedPuppet.GetWeaponRight(player)
    if right == nil then right = GameObject.GetActiveWeapon(player) end
    local leftOk, left = pcall(function() return ScriptedPuppet.GetWeaponLeft(player) end)
    for _, w in ipairs({ right, leftOk and left or false }) do
      if w then
        local key = tostring(w:GetEntityID().hash)
        local seen = false
        for _, e in ipairs(list) do
          if e.key == key then seen = true end
        end
        if not seen then list[#list + 1] = { entity = w, key = key } end
      end
    end
  end)
  if ok then return list end
  return {}
end

-- C2SD-T9: give one entity its own time scale that ignores the world's dilation.
-- C2SD-T55: exemption failures go to the CET log too (once per distinct message), so a silent
-- failure (V left at 5% speed) shows up in scripting.log.
local loggedErrors = {}
local function logError(msg)
  BulletTimeDriver.lastError = msg
  if not loggedErrors[msg] then
    loggedErrors[msg] = true
    print("[ShootDodge] " .. msg)
  end
end

local function exemptEntity(entity, factor)
  local ok, err = pcall(function()
    entity:SetIndividualTimeDilation(REASON, factor, 0.0, "", "", true)
  end)
  if not ok then logError("exempt weapon: " .. tostring(err)) end
  return ok
end

local function unexemptEntity(entity)
  if entity == nil then return true end
  local ok = pcall(function() entity:UnsetIndividualTimeDilation() end)
  -- A weapon that was holstered/despawned meanwhile has nothing left to unset.
  return ok
end

-- C2SD-T55 / C2SD-T60: V gets the per-entity exemption the weapon uses (confirmed in game: V's
-- dive runs at full speed while the world is at 5%). The TimeSystem's
-- SetTimeDilationOnLocalPlayerZero lever is not used: in this game version it takes 2-5
-- parameters and has no ignore-global flag, so it can't exempt V from the world dilation.
local function exemptPlayer(factor)
  local ok, err = pcall(function()
    Game.GetPlayer():SetIndividualTimeDilation(REASON, factor, 0.0, "", "", true)
  end)
  if not ok then logError("exempt player: " .. tostring(err)) end
  return ok
end

local function unexemptPlayer()
  local ok, err = pcall(function() Game.GetPlayer():UnsetIndividualTimeDilation() end)
  if not ok then logError("unexempt player: " .. tostring(err)) end
  return ok
end

-- C2SD-T9: carry out what the exemption rules want for this frame.
local function syncExemption()
  local exemption = BulletTimeDriver.exemption
  local tracked = BulletTimeDriver.exemptWeapons
  local keys, byKey = {}, {}
  if BulletTimeDriver.rules.applied ~= nil and exemption.config.exemptWeapon then
    for _, held in ipairs(heldWeapons()) do
      keys[#keys + 1] = held.key
      byKey[held.key] = held.entity
    end
  end
  local actions = exemption:Step({ slowed = BulletTimeDriver.rules.applied, weaponKeys = keys })
  for _, action in ipairs(actions) do
    local ok
    if action.op == "unsetWeapon" then
      ok = unexemptEntity(tracked[action.key])
      tracked[action.key] = nil
    elseif action.op == "setWeapon" then
      local weapon = byKey[action.key]
      ok = weapon ~= nil and exemptEntity(weapon, action.factor)
      tracked[action.key] = ok and weapon or nil
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
-- A weapon's is not (it would ignore later game slow-mo), hence the held-weapon unset below.
local function clearExemption()
  local exemption = BulletTimeDriver.exemption
  local tracked = BulletTimeDriver.exemptWeapons
  for _, entity in pairs(tracked) do unexemptEntity(entity) end
  -- C2SD-T24: a CET reload mid-slow-mo leaves the old module's weapon exemption on (a fresh module
  -- tracks nothing), so also unset whatever weapons V holds now (C2SD-T30: both hands).
  for _, held in ipairs(heldWeapons()) do
    if tracked[held.key] == nil then unexemptEntity(held.entity) end
  end
  BulletTimeDriver.exemptWeapons = {}
  if exemption.player then unexemptPlayer() end
  exemption:Forget()
end

-- C2SD-T43: true only while a game world with V is running. The TimeSystem's native calls are
-- not safe before that (onInit fires during game boot, onShutdown during exit): calling
-- UnsetTimeDilation there is an access violation that pcall cannot catch, and it crashed the game
-- at start-up. With no world, there is no dilation of ours to remove anyway.
-- C2SD-T45: the main menu has a player too, so ask the shared session gate.
local function worldReady()
  return Session.Ready()
end

-- Remove this mod's dilation (only the Lua bookkeeping when no game world is running).
function BulletTimeDriver.Clear()
  if worldReady() then
    unsetDilation()
    clearExemption()
  else
    BulletTimeDriver.exemptWeapons = {}
    BulletTimeDriver.exemption:Forget()
  end
  BulletTimeDriver.rules.applied = nil
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
