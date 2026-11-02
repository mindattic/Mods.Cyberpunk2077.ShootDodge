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
--     C2SD-T30: with the 2.5 Double Trouble perk V holds two guns, one per hand slot
--     (AttachmentSlots.WeaponRight and AttachmentSlots.WeaponLeft), each its own entity. Both are
--     exempted: the rules track a set of weapon keys, so a swap of either hand moves only that
--     hand's exemption, and single-weapon play is the one-key case of the same rules.
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
  -- C2SD-T53: on by default: V's weapon raise, aim-down-sights and draw are V's own animations,
  -- which at 5% world speed took forever. V now runs at full speed (hands ready at once) while the
  -- world stays slowed; the dive arc runs at full speed too.
  exemptPlayer = true,
  -- Time scale the exempted entities run at (1.0 = normal speed).
  factor = 1.0,
}

function AimFireExemption.new(config)
  local self = setmetatable({}, AimFireExemption)
  self.config = {}
  for k, v in pairs(AimFireExemption.defaults) do self.config[k] = v end
  for k, v in pairs(config or {}) do self.config[k] = v end
  -- C2SD-T30: keys of the weapons currently exempted (a set; two while dual wielding), in the
  -- order they were exempted so the driver's actions are deterministic.
  self.weaponKeys = {}
  self.player = false  -- whether the player exemption is currently applied
  return self
end

local function indexOf(list, key)
  for i, k in ipairs(list) do
    if k == key then return i end
  end
  return nil
end

-- The weapon keys a context names: ctx.weaponKeys (a list, C2SD-T30) and/or the single
-- ctx.weaponKey, with nils and duplicates dropped.
local function contextKeys(ctx)
  local keys = {}
  local function add(k)
    if k ~= nil and not indexOf(keys, k) then keys[#keys + 1] = k end
  end
  add(ctx.weaponKey)
  for _, k in ipairs(ctx.weaponKeys or {}) do add(k) end
  return keys
end

-- What should be exempt right now.
-- ctx = { slowed = <world factor this mod applied, or nil>,
--         weaponKey = <equipped weapon key or nil>,
--         weaponKeys = <list of held weapon keys, both hands while dual wielding> }
-- Returns { weaponKeys = list, weaponKey = first key or nil, player = bool }.
function AimFireExemption:Wanted(ctx)
  local cfg = self.config
  local want = { weaponKeys = {}, weaponKey = nil, player = false }
  if not cfg.enabled or ctx == nil then return want end
  local slowed = tonumber(ctx.slowed)
  if slowed == nil or slowed >= 1.0 then return want end
  if cfg.exemptWeapon then
    want.weaponKeys = contextKeys(ctx)
    want.weaponKey = want.weaponKeys[1]
  end
  want.player = cfg.exemptPlayer == true
  return want
end

-- Work out what the driver must do this frame. Returns a list of actions, in order:
--   { op = "unsetWeapon", key = k } | { op = "setWeapon", key = k, factor = f }
--   { op = "unsetPlayer" }          | { op = "setPlayer", factor = f }
-- Every unset comes before any set. Empty when nothing changes. The driver reports success back
-- with Applied.
function AimFireExemption:Step(ctx)
  local want = self:Wanted(ctx)
  local actions = {}
  for _, key in ipairs(self.weaponKeys) do
    if not indexOf(want.weaponKeys, key) then
      actions[#actions + 1] = { op = "unsetWeapon", key = key }
    end
  end
  for _, key in ipairs(want.weaponKeys) do
    if not indexOf(self.weaponKeys, key) then
      actions[#actions + 1] = { op = "setWeapon", key = key, factor = self.config.factor }
    end
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
  local i = action.key ~= nil and indexOf(self.weaponKeys, action.key) or nil
  if action.op == "setWeapon" then
    if ok and not i then
      self.weaponKeys[#self.weaponKeys + 1] = action.key
    elseif not ok and i then
      table.remove(self.weaponKeys, i)
    end
  elseif action.op == "unsetWeapon" then
    if i then table.remove(self.weaponKeys, i) end
  elseif action.op == "setPlayer" then
    self.player = ok == true
  elseif action.op == "unsetPlayer" then
    self.player = false
  end
end

-- C2SD-T30: how many weapons are exempted right now (2 while dual wielding in slow-mo).
function AimFireExemption:WeaponCount()
  return #self.weaponKeys
end

-- Forget every exemption (the driver has already unset them in the game).
function AimFireExemption:Forget()
  self.weaponKeys = {}
  self.player = false
end

function AimFireExemption:IsActive()
  return #self.weaponKeys > 0 or self.player
end

return AimFireExemption
