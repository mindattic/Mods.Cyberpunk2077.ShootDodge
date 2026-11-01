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

local BulletTime = require("modules/BulletTime")

local REASON = "ShootDodgeBulletTime"

local BulletTimeDriver = {
  rules = BulletTime.new(),
  paused = false,
  lastError = nil,
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

-- Unconditionally remove this mod's dilation.
function BulletTimeDriver.Clear()
  unsetDilation()
  BulletTimeDriver.rules.applied = nil
end

-- Bring the game's dilation in line with the rules for the current state. Cheap when nothing
-- changes, so it is safe to call every frame and on every state change.
function BulletTimeDriver.Sync(machine, enabled)
  local rules = BulletTimeDriver.rules
  local paused = isPaused()
  BulletTimeDriver.paused = paused
  local ctx = {
    state = enabled and machine.state or "NONE",
    paused = paused,
    dead = BulletTime.slowStates[machine.state] and isDead() or false,
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
end

-- Game time per real second for this frame (1.0 when the world isn't slowed).
function BulletTimeDriver.TimeScale()
  return BulletTimeDriver.rules:TimeScale()
end

return BulletTimeDriver
