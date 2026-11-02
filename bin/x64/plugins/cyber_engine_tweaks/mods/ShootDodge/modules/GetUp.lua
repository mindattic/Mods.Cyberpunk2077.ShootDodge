-- GetUp: the rules of the get-up recovery from prone (C2SD-T12 / C2SD-US-D9).
--
-- Pure Lua, no CET or game API (the CET glue is modules/GetUpDriver.lua), so the rules can be
-- exercised outside the game.
--
-- As in Max Payne 2, a dive always ends lying on the ground, and V stays there (shooting, C2SD-T11)
-- until the player chooses to stand: there is no timer. Two ways up:
--   * a fresh movement (or jump) press while prone: detected by the prone mechanic (C2SD-T11,
--     modules/Prone.lua) and handed over through ProneDriver.onStandRequest, so there is one
--     stand-press watcher, not two;
--   * movement already held at the moment of impact (C2SD-T10's `landing.moveHeld`), which Prone
--     deliberately ignores until released: here V still hits the ground first, then scrambles
--     straight up once the impact beat (`impactBeatSec`) has played, with no fresh press needed.
-- Either way the get-up itself (Start/UpdateScramble) is the same.
--
-- The get-up itself (GETUP) is a short scramble, not a snap to idle: a small push in the held
-- movement direction (camera relative, like the dive), V's horizontal speed held under
-- `maxScrambleSpeed` until it completes, and an eased 0..1 `Progress()` that a stance/pose layer
-- can follow to raise V smoothly. Full normal movement returns only once it completes.

local Dive = require("modules/Dive")

local GetUp = {}
GetUp.__index = GetUp

GetUp.defaults = {
  -- Time V lies on the ground after impact before the held-at-impact get-up begins (s); matches
  -- Prone's minProneSec, the earliest a fresh press can stand V up.
  impactBeatSec = 0.25,
  -- C2SD-T49: whether movement held through the landing stands V up by itself. False: V stays
  -- pinned until a fresh direction press (release, then press), as in MP2.
  standIfHeldAtImpact = false,
  -- How long the scramble back to the feet takes (s). Normal movement returns when it ends.
  durationSec = 0.7,
  -- Horizontal push (m/s) given at the start of the scramble, along the held movement direction.
  scrambleSpeed = 2.0,
  -- Horizontal speed cap (m/s) during the scramble, so V can't sprint off before standing.
  maxScrambleSpeed = 2.5,
  -- Fraction of the excess speed removed per frame, and the most one frame may push (m/s).
  limitGain = 0.6,
  maxCorrection = 3.0,
  -- Movement-input magnitude below which there is no direction to scramble in (just stand).
  minMoveMagnitude = 0.2,
}

-- Why the get-up started, for the state machine and the overlay.
GetUp.Cause = {
  heldAtImpact = "movement held at impact",
  moveInput = "movement input",
}

local function length2(x, y)
  return math.sqrt(x * x + y * y)
end

function GetUp.new(config)
  local self = setmetatable({}, GetUp)
  self.config = {}
  for k, v in pairs(GetUp.defaults) do self.config[k] = v end
  for k, v in pairs(config or {}) do self.config[k] = v end
  self:Clear()
  return self
end

function GetUp:Clear()
  -- Prone phase.
  self.watching = false
  self.proneTime = 0
  self.heldAtImpact = false
  -- Scramble phase.
  self.active = false
  self.elapsed = 0
  self.dirX, self.dirY = nil, nil
end

-- V has just gone prone. `landing` is C2SD-T10's landing record (or nil when unknown).
function GetUp:OnProne(landing)
  self:Clear()
  self.watching = true
  -- C2SD-T49: off by default. The direction is held through every dive, so this stood V straight
  -- back up; MP2 pins you on the floor until you press a direction again.
  self.heldAtImpact = self.config.standIfHeldAtImpact == true
    and landing ~= nil and landing.moveHeld == true
end

-- Advance one prone frame. Returns GetUp.Cause.heldAtImpact on the frame the automatic get-up
-- should start (movement was held through the landing and the impact beat has played), else nil.
-- Without that, nothing here ends PRONE: V stays down until a fresh press (C2SD-T11) or forever.
function GetUp:UpdateProne(deltaTime)
  if not self.watching then return nil end
  self.proneTime = self.proneTime + (deltaTime or 0)
  if self.heldAtImpact and self.proneTime >= self.config.impactBeatSec then
    self.watching = false
    return GetUp.Cause.heldAtImpact
  end
  return nil
end

-- Begin the scramble. Movement axes (moveX right, moveY forward) and the camera's heading give the
-- push direction. Returns the push impulse { x, y, z } or nil when there's no direction (V then
-- just stands where they lie).
function GetUp:Start(moveX, moveY, forwardX, forwardY)
  self.watching = false
  self.active = true
  self.elapsed = 0
  local x, y = Dive.Direction(moveX, moveY, forwardX, forwardY, self.config.minMoveMagnitude)
  self.dirX, self.dirY = x, y
  if x == nil then return nil end
  local s = self.config.scrambleSpeed
  return { x = x * s, y = y * s, z = 0 }
end

-- Advance the scramble one frame. Returns true on the frame it completes.
function GetUp:UpdateScramble(deltaTime)
  if not self.active then return false end
  self.elapsed = self.elapsed + (deltaTime or 0)
  if self.elapsed >= self.config.durationSec then
    self.active = false
    return true
  end
  return false
end

-- 0..1 progress of the scramble, eased (smoothstep): 0 lying, 1 standing.
function GetUp:Progress()
  if not self.active then return self.elapsed > 0 and 1 or 0 end
  local d = self.config.durationSec
  local t = d > 0 and math.min(1, math.max(0, self.elapsed / d)) or 1
  return t * t * (3 - 2 * t)
end

-- The horizontal push that keeps V's speed under maxScrambleSpeed during the scramble, given V's
-- current horizontal velocity. Returns x, y, or nil when V is within the cap.
function GetUp:SpeedLimit(vx, vy)
  if not self.active then return nil end
  local cfg = self.config
  local speed = length2(vx, vy)
  if speed <= cfg.maxScrambleSpeed or speed < 1e-4 then return nil end
  local excess = (speed - cfg.maxScrambleSpeed) * cfg.limitGain
  if excess > cfg.maxCorrection then excess = cfg.maxCorrection end
  return -vx / speed * excess, -vy / speed * excess
end

return GetUp
