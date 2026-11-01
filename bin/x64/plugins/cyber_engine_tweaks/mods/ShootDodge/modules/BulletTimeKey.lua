-- BulletTimeKey: pure rules for Bullet Time mode's two key routes (C2SD-T37).
--
-- The mode can be toggled from two places: the game input action from r6/input/ShootDodge.xml
-- (Mouse 4 by default, needs Input Loader) and the CET binding (Bindings tab, user-set). A
-- player who binds the same key in CET gets both on one press, a frame or so apart. This debounce
-- drops a press from the OTHER route that comes within `windowSec` of the last accepted one, so one
-- physical press toggles once. Presses from the same route are never dropped (a quick double tap
-- on one key still toggles twice; the game action and CET each report one press per key-down).

local BulletTimeKey = {}
BulletTimeKey.__index = BulletTimeKey

BulletTimeKey.DEFAULTS = {
  windowSec = 0.25,
}

function BulletTimeKey.new(config)
  local self = setmetatable({}, BulletTimeKey)
  self.config = {}
  for k, v in pairs(BulletTimeKey.DEFAULTS) do self.config[k] = v end
  for k, v in pairs(config or {}) do self.config[k] = v end
  self:Reset()
  return self
end

function BulletTimeKey:Reset()
  self.lastSource = nil
  self.lastTime = nil
  self.accepted = 0
  self.dropped = 0
end

-- source: "game" (input action) or "cet" (CET binding); now: seconds on one real-time clock.
-- Returns true when this press should toggle the mode.
function BulletTimeKey:Accept(source, now)
  local last = self.lastTime
  if last ~= nil and self.lastSource ~= nil and source ~= self.lastSource
      and now >= last and now - last < self.config.windowSec then
    self.dropped = self.dropped + 1
    return false
  end
  self.lastSource = source
  self.lastTime = now
  self.accepted = self.accepted + 1
  return true
end

return BulletTimeKey
