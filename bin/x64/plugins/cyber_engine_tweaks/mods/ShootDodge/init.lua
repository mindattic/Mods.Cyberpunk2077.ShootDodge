-- ShootDodge: Max Payne 2 style Shootdodge (dive, bullet-time, prone/get-up) for Cyberpunk 2077.
-- Implemented so far: combo detection, the state machine, the dive trigger and bullet-time
-- (C2SD-T5..T8), aim/fire kept at normal speed during slow-mo (C2SD-T9), landing detection
-- (C2SD-T10), plus the Max Payne 2 bullet-time hourglass (C2SD-T15). See docs/DESIGN.md in the repo root for the planned states and build order
-- (follow the ticket log's requires chain, docs/USER_STORIES.md).

local Input = require("modules/Input")
local StateMachine = require("modules/StateMachine")
local DiveDriver = require("modules/DiveDriver")
local BulletTimeDriver = require("modules/BulletTimeDriver")
local MeterDriver = require("modules/BulletTimeMeterDriver")

local ShootDodge = {
  enabled = false,
  -- C2SD-T6: the one centralized state (NONE | DIVING | AIRBORNE | PRONE | GETUP). Every
  -- transition is defined in modules/StateMachine.lua; read it with ShootDodge.machine.state.
  machine = StateMachine.new(),
}

-- C2SD-T15: Max Payne 2's Bullet Time mode, toggled by a CET binding (Bindings tab; unbound by
-- default). It drains the hourglass; the shootdodge does not. CET only accepts this at load time.
registerInput("ShootDodgeBulletTimeMode", "Bullet-time mode (Max Payne 2, toggle)", function(down)
  if not down then return end
  local ok, err = pcall(MeterDriver.ToggleMode, ShootDodge.enabled, ShootDodge.machine)
  if not ok then print("[ShootDodge] bullet-time mode error: " .. tostring(err)) end
end)

registerForEvent("onInit", function()
  -- C2SD-T8: a CET reload mid-dive must not leave the old session's slow-mo behind.
  BulletTimeDriver.Clear()
  -- C2SD-T15: the hourglass (kills refill it, saved with the game) gates Bullet Time mode.
  BulletTimeDriver.meter = MeterDriver.meter
  MeterDriver.Install()
  ShootDodge.machine:Reset("load")
  ShootDodge.machine:AddListener(function(from, to, event, reason)
    print(string.format("[ShootDodge] state %s -> %s (%s%s)", from, to, event,
      reason and (": " .. reason) or ""))
  end)
  -- C2SD-T8: bullet-time follows the state the instant it changes (on as DIVING starts, off the
  -- same frame it leaves DIVING/AIRBORNE), not a frame later.
  -- C2SD-T15: a shootdodge ends Bullet Time mode and costs no meter (MP2), before the sync below.
  ShootDodge.machine:AddListener(function(_, to)
    if to == "DIVING" then MeterDriver.meter:OnDiveStart() end
  end)
  ShootDodge.machine:AddListener(function()
    BulletTimeDriver.Sync(ShootDodge.machine, ShootDodge.enabled)
  end)
  -- A new combo can't start while a Shootdodge is already in progress.
  Input.isBlocked = function() return ShootDodge.machine:IsActive() end

  -- C2SD-T5: detect the Shootdodge combo (aim held + jump + move).
  -- C2SD-T7: a detected combo launches the dive (NONE -> DIVING) in the held movement direction.
  DiveDriver.isGrounded = Input.IsGrounded
  ShootDodge.combo = Input.Install()
  -- C2SD-T10: the landing records whether movement is held at impact (for the get-up, C2SD-T12),
  -- read from the same movement tracking the combo uses.
  DiveDriver.isMoveHeld = function()
    local combo = ShootDodge.combo
    if combo == nil then return false, 0 end
    return combo:IsMoving(), combo:MoveMagnitude()
  end
  DiveDriver.AddLandingListener(function(landing)
    print(string.format("[ShootDodge] landing #%d at %.2fs: movement %s (%.2f), air %.2fs, grazes %d",
      landing.index, landing.time, landing.moveHeld and "held" or "not held", landing.moveMagnitude,
      landing.airTime, landing.grazes))
  end)
  ShootDodge.combo:SetEnabled(ShootDodge.enabled)
  ShootDodge.combo:AddListener(function(trigger)
    print(string.format("[ShootDodge] combo detected at %.2fs (move %.2f, %.2f)",
      trigger.time, trigger.moveX, trigger.moveY))
    local ok, err = pcall(DiveDriver.Start, ShootDodge.machine, trigger)
    if not ok then
      print("[ShootDodge] dive start error: " .. tostring(err))
      DiveDriver.Cancel()
      ShootDodge.machine:Reset("dive start error")
    end
  end)
  print("[ShootDodge] loaded (dive trigger, bullet-time and landing detection active)")
end)

registerForEvent("onShutdown", function()
  Input.Reset()
  DiveDriver.Cancel()
  ShootDodge.machine:Reset("shutdown")
  BulletTimeDriver.Clear()
end)

registerForEvent("onUpdate", function(deltaTime)
  Input.Update(deltaTime)
  local machine = ShootDodge.machine
  local ok, err = pcall(function()
    machine:Update(deltaTime)
    if not ShootDodge.enabled then
      DiveDriver.Cancel()
      if machine:IsActive() then machine:Reset("mod disabled") end
      return
    end
    -- C2SD-T7: the dive drives DIVING (direction lock, lift-off/landing check). Its timers and
    -- velocity estimate run on game time, so they keep working while bullet-time slows V too.
    -- C2SD-T10: it also drives AIRBORNE and fires the landing (-> PRONE) on ground contact.
    DiveDriver.Update(machine, (deltaTime or 0) * BulletTimeDriver.TimeScale())
  end)
  if not ok then
    print("[ShootDodge] update error: " .. tostring(err))
    DiveDriver.Cancel()
    machine:Reset("update error")
  end
  -- C2SD-T15: drain (Bullet Time mode) or refill (passive) the hourglass on real time, before the
  -- sync below, so a meter that just ran dry drops the dilation this same frame.
  local meterOk, meterErr = pcall(MeterDriver.Update, deltaTime, {
    enabled = ShootDodge.enabled,
    paused = BulletTimeDriver.paused,
    diving = machine.state == "DIVING" or machine.state == "AIRBORNE",
  })
  if not meterOk then
    print("[ShootDodge] bullet-time meter error: " .. tostring(meterErr))
    pcall(function() MeterDriver.meter:EndMode("error") end)
  end
  -- C2SD-T8: every frame, enabled or not and even after an error, bring the world's time
  -- dilation in line with the state (and pause/death), so slow-mo can never get stuck on.
  local syncOk, syncErr = pcall(BulletTimeDriver.Sync, machine, ShootDodge.enabled)
  if not syncOk then
    print("[ShootDodge] bullet-time error: " .. tostring(syncErr))
    pcall(BulletTimeDriver.Clear)
  end
end)

registerForEvent("onDraw", function()
  -- C2SD-T15: the in-game hourglass HUD, drawn whether or not the CET overlay is open.
  local hudOk, hudErr = pcall(MeterDriver.DrawHud, BulletTimeDriver.paused)
  if not hudOk then MeterDriver.lastError = "hud: " .. tostring(hudErr) end

  if not ImGui.Begin("ShootDodge") then
    ImGui.End()
    return
  end

  local changed
  ShootDodge.enabled, changed = ImGui.Checkbox("Enabled", ShootDodge.enabled)
  if changed and ShootDodge.combo then ShootDodge.combo:SetEnabled(ShootDodge.enabled) end

  local machine = ShootDodge.machine
  ImGui.Text(string.format("State: %s (%.2fs)", machine.state, machine:TimeInState()))
  local last = machine.lastTransition
  if last then
    ImGui.Text(string.format("Last change: %s -> %s (%s%s)", last.from, last.to, last.event,
      last.reason and (": " .. last.reason) or ""))
  end
  if machine.lastRejected then
    ImGui.Text(string.format("Refused: %s from %s", machine.lastRejected.event,
      machine.lastRejected.from))
  end

  local combo = ShootDodge.combo
  if combo then
    ImGui.Text(string.format("Combo: aim %s | move %.2f | detected %d",
      combo.aimHeld and "held" or "-", combo:MoveMagnitude(), combo.triggerCount))
    if combo.lastReject then
      ImGui.Text(string.format("Last jump not a combo: %s", combo.lastReject.reason))
    end
  end
  local dive = DiveDriver.dive
  if dive.active then
    ImGui.Text(string.format("Dive: locked dir %.2f, %.2f | air %.2fs", dive.dirX, dive.dirY,
      dive.airTime))
  elseif DiveDriver.lastEnd then
    ImGui.Text(string.format("Last dive ended: %s", DiveDriver.lastEnd.reason))
  end
  if DiveDriver.lastError then
    ImGui.Text(string.format("Dive problem: %s", DiveDriver.lastError))
  end
  -- C2SD-T10: one landing event per dive, with the held-movement flag at impact.
  local landing = DiveDriver.lastLanding
  ImGui.Text(string.format("Landings: %d%s", DiveDriver.landingCount,
    landing and string.format(" | last #%d at %.2fs: movement %s (%.2f), air %.2fs, grazes %d",
      landing.index, landing.time, landing.moveHeld and "held" or "not held",
      landing.moveMagnitude, landing.airTime, landing.grazes) or ""))

  -- C2SD-T8: bullet-time controls and live status.
  local bt = BulletTimeDriver.rules
  local btChanged
  bt.config.enabled, btChanged = ImGui.Checkbox("Bullet-time", bt.config.enabled)
  local factor
  factor, btChanged = ImGui.SliderFloat("Time scale", bt.config.factor, bt.config.minFactor,
    bt.config.maxFactor, "%.2f")
  if btChanged then bt:SetFactor(factor) end
  ImGui.Text(string.format("World time: %s%s",
    bt.applied and string.format("%.2fx (slowed)", bt.applied) or "1.00x",
    BulletTimeDriver.paused and " | game paused" or ""))
  if BulletTimeDriver.lastError then
    ImGui.Text(string.format("Bullet-time problem: %s", BulletTimeDriver.lastError))
  end

  -- C2SD-T9: aim/fire stay at normal speed while the world is slowed.
  local ex = BulletTimeDriver.exemption
  ex.config.exemptWeapon = ImGui.Checkbox("Weapon at normal speed (fire rate)",
    ex.config.exemptWeapon)
  ex.config.exemptPlayer = ImGui.Checkbox("All of V at normal speed (pad look; fall not slowed)",
    ex.config.exemptPlayer)
  ImGui.Text(string.format("Exempt now: weapon %s | V %s",
    ex.weaponKey and "yes" or "no", ex.player and "yes" or "no"))

  -- C2SD-T15: the hourglass, exact values.
  local meter = MeterDriver.meter
  ImGui.Text(string.format("Meter: %.3f / %.3f (%.1f%%) | mode %s | yellow %.2f",
    meter.level, meter.config.max, meter:Fraction() * 100, meter.mode and "ON" or "off",
    meter.yellow))
  ImGui.Text(string.format("Kills counted: %d%s | loaded from: %s", meter.kills,
    meter.lastRefill and string.format(" (last +%.3f)", meter.lastRefill.amount) or "",
    MeterDriver.restoredFrom or "-"))
  if meter.lastModeEnd then
    ImGui.Text(string.format("Bullet-time mode last ended: %s", meter.lastModeEnd))
  end
  if ImGui.Button(meter.mode and "Stop bullet-time mode" or "Start bullet-time mode") then
    MeterDriver.ToggleMode(ShootDodge.enabled, machine)
  end
  ImGui.SameLine()
  if ImGui.Button("Refill meter") then
    meter:SetLevel(meter.config.max)
    MeterDriver.Persist(true)
  end
  ImGui.SameLine()
  if ImGui.Button("Empty meter") then
    meter:SetLevel(0)
    MeterDriver.Persist(true)
  end
  MeterDriver.hud.visible = ImGui.Checkbox("Hourglass HUD", MeterDriver.hud.visible)
  if MeterDriver.lastError then
    ImGui.Text(string.format("Meter problem: %s", MeterDriver.lastError))
  end
  ImGui.TextWrapped("Dive, bullet-time and landing detection -- prone pose and get-up not implemented yet.")

  ImGui.End()
end)

return ShootDodge
