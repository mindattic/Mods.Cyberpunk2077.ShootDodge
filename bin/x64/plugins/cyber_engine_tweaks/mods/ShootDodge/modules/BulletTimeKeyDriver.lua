-- BulletTimeKeyDriver: CET glue for Bullet Time mode's key routes (C2SD-T37).
--
-- Route 1, the default key: r6/input/ShootDodge.xml (Input Loader) maps the game action
-- ShootDodgeBulletTime to IK_Enter (Numpad Enter, and main Enter too: the game has one key code for
-- both). r6/scripts/ShootDodge/ShootDodgeBulletTimeKey.reds counts the presses; Update() takes them
-- each frame. Route 2, the fallback/rebind: the CET binding calls Press("cet"). Both go through the
-- BulletTimeKey debounce, then `toggle` (init.lua sets it to MeterDriver.ToggleMode). Missing
-- redscript or Input Loader only means route 1 never reports a press.

local BulletTimeKey = require("modules/BulletTimeKey")

local KEY_SYSTEM = "ShootDodgeBulletTimeKeySystem"

local BulletTimeKeyDriver = {
  clock = 0,
  rules = BulletTimeKey.new(),
  -- Set by init.lua: toggles the mode (returns whether it changed).
  toggle = function() return false end,
  lastResult = "no press yet",
  lastError = nil,
}

-- The redscript side, or nil when it isn't compiled in (redscript missing).
function BulletTimeKeyDriver.KeySystem()
  local container = Game.GetScriptableSystemsContainer()
  if container == nil then return nil end
  return container:Get(KEY_SYSTEM)
end

-- One key press from `source` ("game" or "cet").
function BulletTimeKeyDriver.Press(source)
  local d = BulletTimeKeyDriver
  if not d.rules:Accept(source, d.clock) then
    d.lastResult = string.format("%s press at %.2fs ignored (same press as %s)", source, d.clock,
      d.rules.lastSource or "-")
    return false
  end
  local ok, changed = pcall(d.toggle)
  if not ok then
    d.lastError = "toggle: " .. tostring(changed)
    return false
  end
  d.lastResult = string.format("%s press at %.2fs: %s", source, d.clock,
    changed and "toggled" or "refused")
  return changed
end

-- Call every onUpdate with the real frame time.
function BulletTimeKeyDriver.Update(deltaTime)
  local d = BulletTimeKeyDriver
  d.clock = d.clock + (deltaTime or 0)
  local okSys, system = pcall(d.KeySystem)
  if not okSys or system == nil then return end
  local okTake, presses = pcall(function() return system:TakePresses() end)
  if not okTake then
    d.lastError = "read key: " .. tostring(presses)
    return
  end
  for _ = 1, math.min(tonumber(presses) or 0, 4) do d.Press("game") end
end

-- Overlay status: whether the game route is listening and how many presses it has seen.
function BulletTimeKeyDriver.Status()
  local okSys, system = pcall(BulletTimeKeyDriver.KeySystem)
  if not okSys or system == nil then return "game key route: not loaded (redscript missing)" end
  local ok, listening, total = pcall(function()
    return system:IsListening(), system:TotalPresses()
  end)
  if not ok then return "game key route: unreadable" end
  return string.format("game key route: %s, %d presses (none = Input Loader missing?)",
    listening and "listening" or "no player yet", total or 0)
end

return BulletTimeKeyDriver
