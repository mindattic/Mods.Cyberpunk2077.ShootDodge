-- Prone: the rules of lying on the ground after a dive (C2SD-T11 / C2SD-US-D8).
--
-- Pure Lua, no CET or game API (the CET glue is modules/ProneDriver.lua), so the rules can be
-- exercised outside the game.
--
-- As in Max Payne 2, V lands and stays down: free to aim and fire in any direction, for as long as
-- the player likes. Nothing here ends PRONE on a timer. Only a stand input does: a *fresh* press
-- of a movement direction (never jump, C2SD-T26), i.e. one that starts while V is already lying down. An input
-- still held from the dive (through the landing) does not count until it has been released once,
-- so V always hits the ground first; the get-up right after impact with movement held is C2SD-T12's
-- call (it reads DiveDriver.lastLanding.moveHeld).
--
-- The first-person eye is lowered toward the floor over `lowerSec` while prone, and comes back up
-- when PRONE ends. Height() reports how far down it should be this frame.

local Prone = {}
Prone.__index = Prone

Prone.defaults = {
  -- How far the first-person camera drops below standing eye height while prone (m). Standing
  -- eye height is ~1.7 m; this puts the eye ~0.4 m off the floor, roughly a prone shooter's.
  eyeDrop = 1.3,
  -- Time (s, real time) for the eye to settle to the floor after impact, and to come back up.
  lowerSec = 0.12,
  raiseSec = 0.2,
  -- Ignore stand inputs for this long after impact (s), so the landing itself can't be undone by
  -- an input that bounced on the same frame.
  minProneSec = 0.25,
  -- V knocked off a ledge while prone: after this long ungrounded the pose is dropped (s).
  maxUngroundedSec = 0.4,
  -- C2SD-T53: the landing is a slide, like the game's own crouch-slide, instead of lying prone:
  -- V keeps the dive's momentum along the dive line at crouch height, the speed drains to zero
  -- over `slideSec` (real time), then V stands. A fresh direction press ends it early.
  slide = true,
  -- C2SD-T62: the fake slide (camera dropped to crouch height, pushes along the dive line) fought
  -- the game's own landing and wrecked it. V now lands on their feet and keeps the dive's
  -- momentum through the game's own physics: no camera drop, no pushes, control back at once.
  slideSec = 0.15,
  slideEyeDrop = 0.0,
  slideDrive = false,
  -- Slide start speed (m/s): the landing speed, kept inside these bounds.
  slideMinSpeed = 4.0,
  slideMaxSpeed = 8.0,
}

-- Why PRONE asked to end, reported to the state machine and the overlay.
Prone.End = {
  move = "movement pressed",
  jump = "jump pressed",
  fell = "fell while prone",
  slideOver = "slide over", -- C2SD-T53
}

function Prone.new(config)
  local self = setmetatable({}, Prone)
  self.config = {}
  for k, v in pairs(Prone.defaults) do self.config[k] = v end
  for k, v in pairs(config or {}) do self.config[k] = v end
  self:Clear()
  return self
end

function Prone:Clear()
  self.active = false
  self.elapsed = 0
  self.ungrounded = 0
  -- An input counts only once it has been seen released while prone (no carry-over from the dive).
  self.moveArmed = false
  self.jumpArmed = false
  self.standRequest = nil
  -- Eye drop, 0 (standing) .. 1 (on the floor); keeps easing back to 0 after PRONE ends.
  self.lowered = self.lowered or 0
end

-- V has just landed prone. moveHeld/jumpHeld: what is held at that instant.
function Prone:Enter(moveHeld, jumpHeld)
  self:Clear()
  self.active = true
  self.moveArmed = not moveHeld
  self.jumpArmed = not jumpHeld
end

function Prone:Exit()
  self.active = false
  self.standRequest = nil
end

-- Advance one frame. deltaTime is real time (bullet-time is off once prone). Returns a stand
-- reason (Prone.End.*) the frame the player asks to get up, else nil. Keeps returning the same
-- reason until Exit() so the request can't be lost if the state machine refuses it once.
function Prone:Update(deltaTime, moveHeld, jumpHeld, grounded)
  local cfg = self.config
  deltaTime = deltaTime or 0
  self:_ease(deltaTime)
  if not self.active then return nil end
  self.elapsed = self.elapsed + deltaTime

  if grounded == false then
    self.ungrounded = self.ungrounded + deltaTime
    if self.ungrounded >= cfg.maxUngroundedSec then self.standRequest = Prone.End.fell end
  else
    self.ungrounded = 0
  end

  -- C2SD-T53: the slide stands V up by itself once it has run out.
  if self.standRequest == nil and cfg.slide and self.elapsed >= cfg.slideSec then
    self.standRequest = Prone.End.slideOver
  end
  if self.standRequest == nil and self.elapsed >= cfg.minProneSec then
    if moveHeld and self.moveArmed then
      self.standRequest = Prone.End.move
    end
    -- Jump never stands V up: the press is observed, not consumed, so the game would also run
    -- its real jump (C2SD-T26). Only movement counts.
  end
  if not moveHeld then self.moveArmed = true end
  if not jumpHeld then self.jumpArmed = true end
  return self.standRequest
end

function Prone:_ease(deltaTime)
  local cfg = self.config
  if self.active then
    local step = cfg.lowerSec > 0 and deltaTime / cfg.lowerSec or 1
    self.lowered = math.min(1, self.lowered + step)
  else
    local step = cfg.raiseSec > 0 and deltaTime / cfg.raiseSec or 1
    self.lowered = math.max(0, self.lowered - step)
  end
end

-- The camera's vertical offset this frame (m, negative = down), smoothed in and out.
function Prone:Height()
  local t = self.lowered or 0
  local eased = t * t * (3 - 2 * t)
  local drop = self.config.slide and self.config.slideEyeDrop or self.config.eyeDrop
  return -drop * eased
end

-- C2SD-T53: the slide's target speed this frame (m/s) for a slide that started at `startSpeed`:
-- the start speed (kept within slideMin/MaxSpeed) draining linearly to 0 over slideSec. 0 when
-- not sliding.
function Prone:SlideSpeed(startSpeed)
  local cfg = self.config
  if not (self.active and cfg.slide) or cfg.slideSec <= 0 then return 0 end
  local v0 = math.max(cfg.slideMinSpeed, math.min(cfg.slideMaxSpeed, startSpeed or 0))
  return v0 * math.max(0, 1 - self.elapsed / cfg.slideSec)
end

-- True while the camera still needs an offset applied (prone, or still coming back up).
function Prone:NeedsCamera()
  return self.active or (self.lowered or 0) > 0
end

return Prone
