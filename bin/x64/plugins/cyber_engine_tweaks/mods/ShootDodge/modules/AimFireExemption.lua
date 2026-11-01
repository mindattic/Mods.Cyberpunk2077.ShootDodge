-- AimFireExemption: the rules for keeping V's aim and fire responsive while the world is slowed
-- (C2SD-T9 / C2SD-US-D6).
--
-- Pure Lua, no CET or game API (the CET glue lives in modules/BulletTimeDriver.lua), so the rules
-- can be exercised outside the game.
--
-- Cyberpunk's time system has no "camera only" or "trigger only" exemption: dilation is set per
-- entity. The levers, and what each one buys:
--
--   * weapon (default on): the weapon in V's hands is its own entity. It gets an individual time
--     dilation of 1.0 that ignores the global one, so its fire cycle, trigger polling, recoil and
--     reload run at normal cadence while enemies, projectiles, the environment and V's own body
--     (the dive's fall arc) stay slowed. A weapon swap mid-slow-mo moves the exemption to the new
--     weapon and takes it off the old one.
--   * player (default off): Sandevistan's lever, the "local player zero" dilation set to 1.0 with
--     the global dilation ignored. It restores everything V does to full speed, gamepad look rate
--     included, but that also means V's fall arc is no longer slowed, so it is opt-in from the
--     overlay. Mouse look is a per-frame displacement, not a rate, so it is not slowed by the
--     world dilation in the first place.
--
-- The exemption follows the dilation this mod actually applied (BulletTime.applied): it is wanted
-- exactly while the world is slowed by us (the dive, or Bullet Time mode) and dropped the same
-- frame the dilation is unset.

local AimFireExemption = {}
AimFireExemption.__index = AimFireExemption

AimFireExemption.defaults = {
  -- Master switch for the whole exemption.
  enabled = true,
  -- Exempt the equipped weapon (fire rate and shoot-input cadence).
  exemptWeapon = true,
  -- Exempt all of V (turn rate on every input device, but V's fall arc speeds up too).
  exemptPlayer = false,
  -- Time scale the exempted entities run at (1.0 = normal speed).
  factor = 1.0,
}

function AimFireExemption.new(config)
  local self = setmetatable({}, AimFireExemption)
  self.config = {}
  for k, v in pairs(AimFireExemption.defaults) do self.config[k] = v end
  for k, v in pairs(config or {}) do self.config[k] = v end
  self.weaponKey = nil -- key of the weapon currently exempted, or nil
  self.player = false  -- whether the player exemption is currently applied
  return self
end

-- What should be exempt right now.
-- ctx = { slowed = <world factor this mod applied, or nil>, weaponKey = <equipped weapon key or nil> }
-- Returns { weaponKey = key or nil, player = bool }.
function AimFireExemption:Wanted(ctx)
  local cfg = self.config
  local want = { weaponKey = nil, player = false }
  if not cfg.enabled or ctx == nil then return want end
  local slowed = tonumber(ctx.slowed)
  if slowed == nil or slowed >= 1.0 then return want end
  if cfg.exemptWeapon then want.weaponKey = ctx.weaponKey end
  want.player = cfg.exemptPlayer == true
  return want
end

-- Work out what the driver must do this frame. Returns a list of actions, in order:
--   { op = "unsetWeapon", key = k } | { op = "setWeapon", key = k, factor = f }
--   { op = "unsetPlayer" }          | { op = "setPlayer", factor = f }
-- Empty when nothing changes. The driver reports success back with Applied*.
function AimFireExemption:Step(ctx)
  local want = self:Wanted(ctx)
  local actions = {}
  if self.weaponKey ~= nil and self.weaponKey ~= want.weaponKey then
    actions[#actions + 1] = { op = "unsetWeapon", key = self.weaponKey }
  end
  if want.weaponKey ~= nil and self.weaponKey ~= want.weaponKey then
    actions[#actions + 1] = { op = "setWeapon", key = want.weaponKey, factor = self.config.factor }
  end
  if self.player and not want.player then
    actions[#actions + 1] = { op = "unsetPlayer" }
  elseif want.player and not self.player then
    actions[#actions + 1] = { op = "setPlayer", factor = self.config.factor }
  end
  return actions
end

-- Record the outcome of an action the driver carried out. A failed set is recorded as "not
-- applied" (and retried next frame); an unset always counts as done, so a vanished weapon entity
-- can never pin the bookkeeping.
function AimFireExemption:Applied(action, ok)
  if action.op == "setWeapon" then
    self.weaponKey = ok and action.key or nil
  elseif action.op == "unsetWeapon" then
    if self.weaponKey == action.key then self.weaponKey = nil end
  elseif action.op == "setPlayer" then
    self.player = ok == true
  elseif action.op == "unsetPlayer" then
    self.player = false
  end
end

function AimFireExemption:IsActive()
  return self.weaponKey ~= nil or self.player
end

return AimFireExemption
