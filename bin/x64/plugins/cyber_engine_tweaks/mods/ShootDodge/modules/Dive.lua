-- Dive: the rules of the Shootdodge leap (C2SD-T7 / C2SD-US-D4).
--
-- Pure Lua, no CET or game API (the CET glue is modules/DiveDriver.lua), so the math and the
-- lifecycle can be exercised outside the game.
--
-- The leap goes the way V is *moving*, not the way V is aiming: the held movement axes
-- (x = strafe right, y = forward) are turned into a world direction using the camera's yaw at the
-- instant of launch. That direction is then locked for the whole dive: later movement input
-- never steers it (Correction() works out the push that cancels any sideways or backward drift),
-- while the camera and aim stay entirely free.
--
-- World axes follow the game: X and Y horizontal, Z up.

local Dive = {}
Dive.__index = Dive

Dive.defaults = {
  -- Horizontal speed added at launch (m/s), along the locked direction.
  launchSpeed = 7.5,
  -- Upward speed added at launch (m/s), on top of the stock jump it rides on.
  launchLift = 2.5,
  -- Below this movement-input magnitude there is no direction to lock, so no dive.
  minMoveMagnitude = 0.2,
  -- Grounded frames before this much air time don't count as the dive having landed (the stock
  -- jump needs a moment to actually leave the ground).
  minAirSec = 0.15,
  -- If V never visibly leaves the ground (blocked by a wall, low ceiling) give up after this long.
  leaveGroundTimeoutSec = 0.6,
  -- Hard cap on a single dive, whatever the ground check says.
  maxDurationSec = 4.0,
  -- Fraction of the off-direction horizontal velocity cancelled per frame, and the most one frame
  -- may push (m/s), so the lock can't fight the physics into a jitter.
  lockGain = 0.6,
  maxCorrection = 3.0,
  -- Off-direction speed (m/s) below which no correction is sent at all.
  lockDeadZone = 0.25,
}

-- Why a dive ended, reported to the state machine and the overlay.
Dive.End = {
  landed = "landed",
  noLiftOff = "never left the ground",
  timeout = "dive time limit",
}

local function length2(x, y)
  return math.sqrt(x * x + y * y)
end

function Dive.new(config)
  local self = setmetatable({}, Dive)
  self.config = {}
  for k, v in pairs(Dive.defaults) do self.config[k] = v end
  for k, v in pairs(config or {}) do self.config[k] = v end
  self:Clear()
  return self
end

function Dive:Clear()
  self.active = false
  self.dirX, self.dirY = 0, 0
  self.elapsed = 0
  self.airTime = 0
  self.leftGround = false
end

-- World-space unit direction for movement input (moveX right, moveY forward) relative to a camera
-- looking along (forwardX, forwardY). The camera's pitch is ignored: only its yaw matters.
-- Returns x, y, or nil when there is no usable movement or camera heading.
function Dive.Direction(moveX, moveY, forwardX, forwardY, minMoveMagnitude)
  moveX, moveY = moveX or 0, moveY or 0
  if length2(moveX, moveY) < (minMoveMagnitude or Dive.defaults.minMoveMagnitude) then
    return nil
  end
  local fLen = length2(forwardX or 0, forwardY or 0)
  if fLen < 1e-4 then return nil end -- camera looking straight up/down: no yaw to build from
  local fx, fy = forwardX / fLen, forwardY / fLen
  -- Right of forward in a Z-up world: forward (0, 1) -> right (1, 0).
  local rx, ry = fy, -fx
  local x = moveX * rx + moveY * fx
  local y = moveX * ry + moveY * fy
  local len = length2(x, y)
  if len < 1e-4 then return nil end
  return x / len, y / len
end

-- Start a dive. Locks the direction and returns the launch impulse { x, y, z }, or nil (and the
-- reason) when there's no direction to dive in.
function Dive:Launch(moveX, moveY, forwardX, forwardY)
  local cfg = self.config
  local x, y = Dive.Direction(moveX, moveY, forwardX, forwardY, cfg.minMoveMagnitude)
  if x == nil then return nil, "no movement direction" end
  self:Clear()
  self.active = true
  self.dirX, self.dirY = x, y
  return { x = x * cfg.launchSpeed, y = y * cfg.launchSpeed, z = cfg.launchLift }
end

-- The horizontal push that keeps V on the locked line, given V's current horizontal velocity:
-- it removes the sideways part and any backward part (so pressing the opposite direction can't
-- brake or reverse the dive). Returns x, y, or nil when no correction is needed.
function Dive:Correction(vx, vy)
  if not self.active then return nil end
  local cfg = self.config
  local along = vx * self.dirX + vy * self.dirY
  local offX = vx - along * self.dirX
  local offY = vy - along * self.dirY
  if along < 0 then
    offX = offX + along * self.dirX
    offY = offY + along * self.dirY
  end
  local off = length2(offX, offY)
  if off < cfg.lockDeadZone then return nil end
  local scale = cfg.lockGain
  if off * scale > cfg.maxCorrection then scale = cfg.maxCorrection / off end
  return -offX * scale, -offY * scale
end

-- Advance the dive one frame. Returns an end reason (Dive.End.*) once the dive is over, else nil.
function Dive:Update(deltaTime, grounded)
  if not self.active then return nil end
  local cfg = self.config
  deltaTime = deltaTime or 0
  self.elapsed = self.elapsed + deltaTime
  if not grounded then
    self.leftGround = true
    self.airTime = self.airTime + deltaTime
  end

  local reason
  if self.elapsed >= cfg.maxDurationSec then
    reason = Dive.End.timeout
  elseif self.leftGround and grounded and self.airTime >= cfg.minAirSec then
    reason = Dive.End.landed
  elseif not self.leftGround and self.elapsed >= cfg.leaveGroundTimeoutSec then
    reason = Dive.End.noLiftOff
  end
  if reason then self.active = false end
  return reason
end

return Dive
