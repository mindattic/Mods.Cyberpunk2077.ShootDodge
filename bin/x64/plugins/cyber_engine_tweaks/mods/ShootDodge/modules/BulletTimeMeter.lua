-- BulletTimeMeter: Max Payne 2's bullet-time hourglass (C2SD-T15 / C2SD-US-D12).
--
-- Pure Lua, no CET or game API (the CET glue is modules/BulletTimeMeterDriver.lua), so the
-- economy can be exercised outside the game. The rules follow Max Payne 2 as researched in
-- docs/DESIGN.md ("Bullet-time meter"):
--   * Only Bullet Time *mode* (the manual toggle) drains the hourglass, continuously, until it is
--     empty or the player turns the mode off. Empty ends the mode and the world returns to normal.
--   * The meter refills on its own whenever Bullet Time mode is not in use, and every enemy kill
--     bumps it up by a fixed amount (capped at the maximum).
--   * A shootdodge costs no meter and still gets its slow motion with an empty hourglass; starting
--     one ends Bullet Time mode. diveCost / diveDrainPerSec / diveNeedsMeter exist only so the
--     economy can be tuned away from MP2 from this one table; their defaults are MP2's (none).
--   * Kills tint the sand yellow; the tint fades back toward white over time.

local Meter = {}
Meter.__index = Meter

-- Every rate and amount of the economy, in one table. Levels are in "hourglasses" (max = 1.0).
-- Max Payne 2's exact internal numbers are not published; the values marked "estimate" are tuned
-- to match how MP2 plays (see docs/DESIGN.md) and are the ones to adjust.
Meter.defaults = {
  max = 1.0,               -- a full hourglass
  startLevel = 1.0,        -- level on a fresh load with nothing saved (MP2: starts full)
  modeDrainPerSec = 0.1,   -- Bullet Time mode drain: a full hourglass lasts ~10 s (estimate)
  modeMinToStart = 0.02,   -- need at least this much sand to switch the mode on
  regenPerSec = 0.0125,    -- passive refill while the mode is off: empty -> full ~80 s (estimate)
  killRefill = 0.15,       -- added per enemy kill, capped at max (estimate)
  diveCost = 0.0,          -- MP2: a shootdodge costs nothing
  diveDrainPerSec = 0.0,   -- MP2: the dive's slow-mo does not drain the meter
  diveNeedsMeter = false,  -- MP2: a dive is slowed even with an empty hourglass
  yellowPerKill = 0.34,    -- sand tint added per kill (0 = white, 1 = full yellow)
  yellowDecayPerSec = 0.08,-- tint fades back toward white
}

function Meter.new(config)
  local self = setmetatable({}, Meter)
  self.config = {}
  for k, v in pairs(Meter.defaults) do self.config[k] = v end
  for k, v in pairs(config or {}) do self.config[k] = v end
  self.level = self.config.startLevel
  self.mode = false        -- Bullet Time mode (the manual toggle) active
  self.yellow = 0
  self.kills = 0
  self.lastRefill = nil    -- { amount = n, from = level before }
  self.lastModeEnd = nil   -- reason the mode last ended
  self:Clamp()
  return self
end

function Meter:Clamp()
  local max = self.config.max
  if self.level ~= self.level or self.level < 0 then self.level = 0 end
  if self.level > max then self.level = max end
end

function Meter:SetLevel(level)
  self.level = tonumber(level) or self.config.startLevel
  self:Clamp()
end

function Meter:Fraction()
  if self.config.max <= 0 then return 0 end
  return self.level / self.config.max
end

function Meter:IsEmpty()
  return self.level <= 0
end

function Meter:CanStartMode()
  return self.level >= self.config.modeMinToStart
end

function Meter:StartMode()
  if self.mode or not self:CanStartMode() then return false end
  self.mode = true
  return true
end

function Meter:EndMode(reason)
  if not self.mode then return false end
  self.mode = false
  self.lastModeEnd = reason or "off"
  return true
end

function Meter:ToggleMode()
  if self.mode then return self:EndMode("toggled off") end
  return self:StartMode()
end

-- An enemy kill: MP2 bumps the hourglass by a fixed amount and tints the sand yellow.
function Meter:OnKill()
  local before = self.level
  self.level = self.level + self.config.killRefill
  self:Clamp()
  self.kills = self.kills + 1
  self.yellow = math.min(1, self.yellow + self.config.yellowPerKill)
  self.lastRefill = { amount = self.level - before, from = before }
end

-- A shootdodge starts: MP2 takes V out of Bullet Time mode and charges nothing (diveCost = 0).
function Meter:OnDiveStart()
  self:EndMode("shootdodge")
  if self.config.diveCost > 0 then
    self.level = self.level - self.config.diveCost
    self:Clamp()
  end
end

-- Whether the dive's slow motion is granted right now. MP2: always (diveNeedsMeter = false).
-- With diveNeedsMeter on, an empty hourglass gives a normal-speed dive, and one emptied mid-dive
-- drops the world back to normal speed that same frame.
function Meter:DiveSlowAllowed()
  if not self.config.diveNeedsMeter then return true end
  return self.level > 0
end

-- Advance the meter. dt is real seconds. ctx = { paused = bool, dead = bool, diving = bool }.
function Meter:Update(dt, ctx)
  ctx = ctx or {}
  dt = tonumber(dt) or 0
  if ctx.dead then self:EndMode("dead") end
  if dt <= 0 or ctx.paused or ctx.dead then return end
  local cfg = self.config

  local drain = 0
  if self.mode then
    drain = cfg.modeDrainPerSec
  elseif ctx.diving then
    drain = cfg.diveDrainPerSec
  end
  if drain > 0 then
    self.level = self.level - drain * dt
    if self.level <= 0 then
      self.level = 0
      self:EndMode("empty")
    end
  elseif not self.mode then
    self.level = self.level + cfg.regenPerSec * dt
  end
  self:Clamp()

  if self.yellow > 0 then
    self.yellow = math.max(0, self.yellow - cfg.yellowDecayPerSec * dt)
  end
end

-- Save encoding: an integer the game can store in a save (a quest fact). 0 means "nothing saved"
-- (a fact that was never set reads 0), so a stored level is permille + 1.
function Meter:Encode()
  return math.floor(self:Fraction() * 1000 + 0.5) + 1
end

-- Returns the level a stored value stands for, or nil when nothing was saved.
function Meter:Decode(value)
  value = tonumber(value)
  if value == nil or value <= 0 then return nil end
  local fraction = (value - 1) / 1000
  if fraction < 0 then fraction = 0 end
  if fraction > 1 then fraction = 1 end
  return fraction * self.config.max
end

return Meter
