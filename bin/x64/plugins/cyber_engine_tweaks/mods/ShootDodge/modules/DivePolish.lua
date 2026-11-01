-- DivePolish: the rules of the dive's camera + audio polish (C2SD-T14 / C2SD-US-D11).
--
-- Pure Lua, no CET or game API (the CET glue is modules/DivePolishDriver.lua), so the rules can be
-- exercised outside the game.
--
-- Three effects, each with its own switch so it can be verified in isolation:
--   * FOV pull-back: the first-person field of view widens by `fovPullBack` degrees while the state
--     machine is in DIVING/AIRBORNE, eased in on launch and back out on landing (or on any other
--     way out of the dive). It eases on real time, so slow-mo doesn't drag the camera.
--   * Whoosh: one sound cue on dive entry (NONE -> DIVING), never repeated within the same dive.
--   * Music/ambience muffle: a volume duck on the music (and the configured low-pass audio events)
--     for the duration of DIVING/AIRBORNE, restored on landing.
-- The pause menu (or any pausing menu) and V's death count as "not diving" for the audio, so the
-- player's real music volume is what the settings menu shows; it is re-applied on resume if the
-- dive is still going, just like the bullet-time dilation.

local DivePolish = {}
DivePolish.__index = DivePolish

DivePolish.defaults = {
  -- FOV pull-back.
  fovEnabled = true,
  fovPullBack = 12.0,  -- degrees added to the FOV while diving
  maxPullBack = 30.0,  -- clamp for the overlay slider
  fovInSec = 0.15,     -- ease from 0 to the full pull-back (real time)
  fovOutSec = 0.25,    -- ease back to normal after landing (real time)
  -- Whoosh on dive entry.
  whooshEnabled = true,
  -- Music/ambience muffle.
  audioEnabled = true,
  musicKeep = 0.35,    -- fraction of the player's music volume kept while diving (0..1)
}

-- States during which the dive's polish is on.
DivePolish.diveStates = { DIVING = true, AIRBORNE = true }

function DivePolish.new(config)
  local self = setmetatable({}, DivePolish)
  self.config = {}
  for k, v in pairs(DivePolish.defaults) do self.config[k] = v end
  for k, v in pairs(config or {}) do self.config[k] = v end
  self.config.fovPullBack = self:ClampPullBack(self.config.fovPullBack)
  self.config.musicKeep = DivePolish.ClampKeep(self.config.musicKeep)
  self.whooshCount = 0
  self:Clear()
  return self
end

-- Forget everything applied (the driver has restored the game, or is about to).
function DivePolish:Clear()
  self.fov = 0          -- current pull-back (degrees), eased toward the target
  self.fovHeld = false  -- the driver owns the camera FOV (base recorded, offset applied)
  self.muffled = false  -- the audio muffle is applied
end

function DivePolish:ClampPullBack(deg)
  deg = tonumber(deg) or DivePolish.defaults.fovPullBack
  if deg < 0 then deg = 0 end
  if deg > self.config.maxPullBack then deg = self.config.maxPullBack end
  return deg
end

function DivePolish.ClampKeep(keep)
  keep = tonumber(keep) or DivePolish.defaults.musicKeep
  if keep < 0 then keep = 0 end
  if keep > 1 then keep = 1 end
  return keep
end

-- The music volume to set while diving, given the player's own (integer settings scale).
function DivePolish:DuckedVolume(volume)
  volume = tonumber(volume) or 0
  return math.floor(volume * self.config.musicKeep + 0.5)
end

-- A dive has just started (NONE -> DIVING). Returns true when the whoosh should play (once).
function DivePolish:OnDiveStart()
  if not self.config.whooshEnabled then return false end
  self.whooshCount = self.whooshCount + 1
  return true
end

local function approach(value, target, step)
  if value < target then return math.min(target, value + step) end
  if value > target then return math.max(target, value - step) end
  return value
end

-- Advance one frame. ctx = { state = <machine state>, enabled = bool, paused = bool, dead = bool }.
-- deltaTime is real time. Returns a plan for the driver:
--   { fov = <pull-back degrees to apply, or nil to leave the camera alone>,
--     fovRelease = true on the frame the pull-back is fully undone (put the base FOV back exactly),
--     audio = "muffle" | "restore" | nil (no change) }
function DivePolish:Update(deltaTime, ctx)
  ctx = ctx or {}
  local cfg = self.config
  local diving = ctx.enabled == true and DivePolish.diveStates[ctx.state] == true
  local plan = {}

  -- FOV: freeze while paused (nothing to see), otherwise ease toward the target.
  local target = (diving and cfg.fovEnabled) and cfg.fovPullBack or 0
  if not ctx.paused then
    local dt = deltaTime or 0
    if dt < 0 then dt = 0 end
    local secs = target > self.fov and cfg.fovInSec or cfg.fovOutSec
    local rate = secs > 0 and (math.max(cfg.fovPullBack, self.fov) / secs) or math.huge
    self.fov = approach(self.fov, target, rate * dt)
  end
  if self.fov > 0 then
    self.fovHeld = true
    plan.fov = self.fov
  elseif self.fovHeld then
    self.fovHeld = false
    plan.fovRelease = true
  end

  -- Audio: on only while diving, not paused, V alive.
  local wantMuffle = diving and cfg.audioEnabled and not ctx.paused and not ctx.dead
  if wantMuffle and not self.muffled then
    plan.audio = "muffle"
  elseif not wantMuffle and self.muffled then
    plan.audio = "restore"
  end
  return plan
end

-- The driver reports whether the audio action it was given took effect.
function DivePolish:AudioApplied(action, ok)
  if action == "muffle" then
    self.muffled = ok == true
  elseif action == "restore" then
    -- Even a failed restore must not be retried forever; the driver logs it.
    self.muffled = false
  end
end

return DivePolish
