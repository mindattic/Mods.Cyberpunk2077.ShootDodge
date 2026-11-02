-- ComboDetector: recognizes the Shootdodge input and debounces it against normal play.
--
-- C2SD-T51: the Shootdodge is Shift + Space (either Shift; C2SD-T46 had Ctrl): no aim needed, it dives the way you're
-- moving, or straight forward with no direction held. In Bullet Time mode Space alone does the
-- same. Plain Space is always a normal jump. This replaces the original aim + jump + move combo
-- (C2SD-T5); the aim/move tracking below is kept for the landing and get-up, which read it.
--
-- Pure Lua, no CET or game API: the CET glue (modules/Input.lua) feeds it input events stamped
-- with the mod's own clock, so the rules here can be exercised outside the game.
--
-- The combo fires on the *fresh press* of jump, only when every guard below holds at that
-- instant. Each guard exists to keep an ordinary aimed jump, strafe-hop or mantle from
-- turning into a dive:
--   * aim has been held continuously for at least `minAimHoldSec` (a deliberate aim, not a
--     panic tap pressed together with jump);
--   * a movement direction is held with magnitude >= `moveThreshold` (stick dead zone /
--     partial key travel never counts), and has been held for at least `minMoveHoldSec`;
--   * jump was released before this press (holding jump never re-fires);
--   * at least `cooldownSec` has passed since the last trigger (no double dives);
--   * the context allows it: `blocked` is false (menus, vehicles, scenes, an active dive) and
--     the player is grounded;
--   * the equipped weapon is on the allow-list (pistol, revolver, SMG -- C2SD-T13, see
--     modules/WeaponGate.lua). The weapon is read at the jump press itself, so a swap takes
--     effect on the very next combo.
--
-- C2SD-T38: while Bullet Time mode is on (context.bulletTime), jump alone is the Shootdodge: the aim
-- guards and the movement hold time are skipped, the held direction is used when one is held, and
-- with none held the trigger dives straight forward (moveX 0, moveY 1). The disabled/blocked,
-- grounded, weapon and cooldown guards still apply, so a disallowed weapon keeps Space a jump.
--
-- Nothing here starts a dive: a trigger only records the combo and notifies listeners. The state
-- machine (C2SD-T6) and the dive itself (C2SD-T7) decide what a trigger does.

local ComboDetector = {}
ComboDetector.__index = ComboDetector

ComboDetector.defaults = {
  minAimHoldSec = 0.15,
  minMoveHoldSec = 0.05,
  moveThreshold = 0.5,
  cooldownSec = 1.0,
}

-- Reasons a jump press did not trigger, reported to the debug overlay so a miss can be
-- explained in-game.
ComboDetector.Reject = {
  disabled = "disabled",
  blocked = "blocked",
  airborne = "airborne",
  weapon = "weapon not allowed",
  noAim = "aim not held",
  aimTooShort = "aim held too briefly",
  noMove = "no movement direction",
  moveTooShort = "movement held too briefly",
  cooldown = "cooldown",
  noCtrl = "Shift not held", -- C2SD-T46 / C2SD-T51: the modifier is Shift
}

local function clamp(v, lo, hi)
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

function ComboDetector.new(config)
  local self = setmetatable({}, ComboDetector)
  self.config = {}
  for k, v in pairs(ComboDetector.defaults) do self.config[k] = v end
  for k, v in pairs(config or {}) do self.config[k] = v end
  self.listeners = {}
  self:Reset()
  return self
end

-- Clears all held-input tracking and the trigger history (on load, on mod disable).
function ComboDetector:Reset()
  self.enabled = true
  self.aimHeld = false
  self.aimSince = nil
  self.jumpHeld = false
  self.moveX = 0
  self.moveY = 0
  self.moveSince = nil
  self.lastTriggerTime = nil
  self.lastTrigger = nil
  self.lastReject = nil
  self.triggerCount = 0
  self.modifierHeld = false -- C2SD-T51: Shift
end

function ComboDetector:SetEnabled(enabled)
  self.enabled = enabled and true or false
end

-- fn(trigger) is called once per detected combo; trigger = { time, moveX, moveY }.
function ComboDetector:AddListener(fn)
  table.insert(self.listeners, fn)
end

function ComboDetector:MoveMagnitude()
  return math.sqrt(self.moveX * self.moveX + self.moveY * self.moveY)
end

function ComboDetector:IsMoving()
  return self:MoveMagnitude() >= self.config.moveThreshold
end

function ComboDetector:OnAim(pressed, now)
  if pressed then
    if not self.aimHeld then
      self.aimHeld = true
      self.aimSince = now
    end
  else
    self.aimHeld = false
    self.aimSince = nil
  end
end

-- Movement axes in [-1, 1]: x = strafe (right positive), y = forward (forward positive).
-- Either axis may be updated alone; pass nil to keep the other as it was.
function ComboDetector:OnMove(x, y, now)
  local wasMoving = self:IsMoving()
  if x ~= nil then self.moveX = clamp(x, -1, 1) end
  if y ~= nil then self.moveY = clamp(y, -1, 1) end
  local moving = self:IsMoving()
  if moving and not wasMoving then
    self.moveSince = now
  elseif not moving then
    self.moveSince = nil
  end
end

-- Returns the trigger table when the combo fires, else nil (with the reason in lastReject).
-- context: { blocked = bool, grounded = bool, weaponAllowed = bool, weapon = label,
-- bulletTime = bool }; a missing field means "not blocked" / "grounded" / "weapon allowed" /
-- "not in Bullet Time mode".
function ComboDetector:OnJump(pressed, now, context)
  if not pressed then
    self.jumpHeld = false
    return nil
  end
  if self.jumpHeld then return nil end -- held / auto-repeat: only a fresh press counts
  self.jumpHeld = true
  return self:Evaluate(now, context)
end

-- C2SD-T46 / C2SD-T51: Shift (either one) held or released. While it is held, Space is the Shootdodge.
function ComboDetector:OnModifier(pressed)
  self.modifierHeld = pressed and true or false
end

function ComboDetector:Evaluate(now, context)
  local cfg = self.config
  local R = ComboDetector.Reject
  context = context or {}

  local reason
  -- C2SD-T51: Shift + Space dives exactly like Space in Bullet Time mode (no aim needed; the held
  -- direction, or forward with none). context.modifier lets the glue add its own read of Shift.
  local ctrl = self.modifierHeld == true or context.modifier == true
  local bulletTime = context.bulletTime == true or ctrl
  if not self.enabled then
    reason = R.disabled
  elseif context.blocked then
    reason = R.blocked
  elseif context.grounded == false then
    reason = R.airborne
  elseif context.weaponAllowed == false then
    reason = R.weapon
    if context.weapon then reason = reason .. " (" .. context.weapon .. ")" end
  elseif bulletTime then
    -- C2SD-T38: Space alone dives in Bullet Time mode; only the cooldown is left to check.
    if self.lastTriggerTime and now - self.lastTriggerTime < cfg.cooldownSec then
      reason = R.cooldown
    end
  else
    -- C2SD-T51: outside Bullet Time mode the Shootdodge is Shift + Space; plain Space is a jump.
    reason = R.noCtrl
  end

  if reason then
    self.lastReject = { time = now, reason = reason }
    return nil
  end

  local moveX, moveY = self.moveX, self.moveY
  if bulletTime and not self:IsMoving() then
    -- C2SD-T38: no direction held in Bullet Time mode: dive forward (see docs/DESIGN.md).
    moveX, moveY = 0, 1
  end
  local trigger = { time = now, moveX = moveX, moveY = moveY, bulletTime = bulletTime }
  self.lastTriggerTime = now
  self.lastTrigger = trigger
  self.lastReject = nil
  self.triggerCount = self.triggerCount + 1
  for _, fn in ipairs(self.listeners) do fn(trigger) end
  return trigger
end

return ComboDetector
