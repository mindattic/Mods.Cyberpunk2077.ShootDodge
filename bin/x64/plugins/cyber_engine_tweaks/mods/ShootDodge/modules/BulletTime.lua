-- BulletTime: the rules for world time dilation during the dive (C2SD-T8 / C2SD-US-D5).
--
-- Pure Lua, no CET or game API (the CET glue is modules/BulletTimeDriver.lua), so the rules can be
-- exercised outside the game.
--
-- C2SD-T15: Max Payne 2's Bullet Time mode (the meter's manual toggle) slows the world the same
-- way, and the meter can veto the dive's slow-mo (it doesn't by default, matching MP2).
--
-- The world is slowed only while the state machine is in DIVING or AIRBORNE, the game is not
-- paused (pause menu, other menus) and V is alive. The moment any of those stops being true the
-- wanted factor is nil, which means "no dilation": the driver unsets it that same frame. Leaving
-- the pause menu mid-dive simply makes the factor wanted again, so it is re-applied, never left on
-- across the menu.

local BulletTime = {}
BulletTime.__index = BulletTime

BulletTime.defaults = {
  -- World time scale while diving (1.0 = normal speed). Configurable from the overlay.
  factor = 0.05, -- C2SD-T52: 5% (was 20%): enemies take several hits, so the world crawls
  -- Master switch for the effect (the dive itself still works with it off).
  enabled = true,
  -- Clamp for the configurable factor: never freeze time, never speed it up.
  minFactor = 0.01,
  maxFactor = 1.0,
}

-- States during which the world is slowed.
BulletTime.slowStates = { DIVING = true, AIRBORNE = true }

function BulletTime.new(config)
  local self = setmetatable({}, BulletTime)
  self.config = {}
  for k, v in pairs(BulletTime.defaults) do self.config[k] = v end
  for k, v in pairs(config or {}) do self.config[k] = v end
  self.config.factor = self:ClampFactor(self.config.factor)
  self.applied = nil -- factor currently set on the game's time system, or nil when none
  return self
end

function BulletTime:ClampFactor(factor)
  local cfg = self.config
  factor = tonumber(factor) or BulletTime.defaults.factor
  if factor < cfg.minFactor then factor = cfg.minFactor end
  if factor > cfg.maxFactor then factor = cfg.maxFactor end
  return factor
end

function BulletTime:SetFactor(factor)
  self.config.factor = self:ClampFactor(factor)
end

-- C2SD-T22: can slow-mo apply at all? False when bullet-time is off or the factor is 1.0, so Bullet
-- Time mode must not run (it would drain the hourglass with the world at normal speed).
function BulletTime:CanSlow()
  return self.config.enabled and self.config.factor < 1.0
end

-- The factor that should be active right now, or nil for normal time.
-- ctx = { state = <machine state>, paused = bool, dead = bool,
--         diveSlow = bool (C2SD-T15: the meter grants the dive's slow-mo; nil = granted),
--         mode = bool (C2SD-T15: Max Payne 2's Bullet Time mode is on) }
function BulletTime:Wanted(ctx)
  local cfg = self.config
  if not cfg.enabled then return nil end
  if ctx == nil then return nil end
  local diving = BulletTime.slowStates[ctx.state] and ctx.diveSlow ~= false
  if not diving and not ctx.mode then return nil end
  if ctx.paused or ctx.dead then return nil end
  if cfg.factor >= 1.0 then return nil end
  return cfg.factor
end

-- Work out what the driver must do this frame. Returns "set", factor | "unset" | nil (no change).
function BulletTime:Step(ctx)
  local want = self:Wanted(ctx)
  if want == nil then
    if self.applied ~= nil then return "unset" end
    return nil
  end
  if self.applied ~= want then return "set", want end
  return nil
end

-- Time scale the dive's own timers should run at this frame (game time per real second), so the
-- leap's lift-off/landing windows stay measured in game time while the world is slowed.
function BulletTime:TimeScale()
  return self.applied or 1.0
end

return BulletTime
