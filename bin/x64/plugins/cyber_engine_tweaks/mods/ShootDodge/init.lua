-- ShootDodge: Max Payne 2 style Shootdodge (dive, bullet-time, prone/get-up) for Cyberpunk 2077.
-- Implemented so far: combo detection, the state machine, the dive trigger and bullet-time
-- (C2SD-T5..T8). See docs/DESIGN.md in the repo root for the planned states and build order
-- (follow the ticket log's requires chain, docs/USER_STORIES.md).

local Input = require("modules/Input")
local StateMachine = require("modules/StateMachine")
local DiveDriver = require("modules/DiveDriver")
local BulletTimeDriver = require("modules/BulletTimeDriver")

local ShootDodge = {
  enabled = false,
  -- C2SD-T6: the one centralized state (NONE | DIVING | AIRBORNE | PRONE | GETUP). Every
  -- transition is defined in modules/StateMachine.lua; read it with ShootDodge.machine.state.
  machine = StateMachine.new(),
}

registerForEvent("onInit", function()
  -- C2SD-T8: a CET reload mid-dive must not leave the old session's slow-mo behind.
  BulletTimeDriver.Clear()
  ShootDodge.machine:Reset("load")
  ShootDodge.machine:AddListener(function(from, to, event, reason)
    print(string.format("[ShootDodge] state %s -> %s (%s%s)", from, to, event,
      reason and (": " .. reason) or ""))
  end)
  -- C2SD-T8: bullet-time follows the state the instant it changes (on as DIVING starts, off the
  -- same frame it leaves DIVING/AIRBORNE), not a frame later.
  ShootDodge.machine:AddListener(function()
    BulletTimeDriver.Sync(ShootDodge.machine, ShootDodge.enabled)
  end)
  -- A new combo can't start while a Shootdodge is already in progress.
  Input.isBlocked = function() return ShootDodge.machine:IsActive() end

  -- C2SD-T5: detect the Shootdodge combo (aim held + jump + move).
  -- C2SD-T7: a detected combo launches the dive (NONE -> DIVING) in the held movement direction.
  DiveDriver.isGrounded = Input.IsGrounded
  ShootDodge.combo = Input.Install()
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
  print("[ShootDodge] loaded (dive trigger and bullet-time active; landing not yet)")
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
    -- The landing branch hooks in here next (C2SD-T10 onward), per docs/DESIGN.md.
    DiveDriver.Update(machine, (deltaTime or 0) * BulletTimeDriver.TimeScale())
  end)
  if not ok then
    print("[ShootDodge] update error: " .. tostring(err))
    DiveDriver.Cancel()
    machine:Reset("update error")
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
  if not ImGui.Begin("ShootDodge") then
    ImGui.End()
    return
  end

  local changed
  changed, ShootDodge.enabled = ImGui.Checkbox("Enabled", ShootDodge.enabled)
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

  -- C2SD-T8: bullet-time controls and live status.
  local bt = BulletTimeDriver.rules
  local btChanged
  btChanged, bt.config.enabled = ImGui.Checkbox("Bullet-time", bt.config.enabled)
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
  ImGui.TextWrapped("Dive and bullet-time only -- landing not implemented yet.")

  ImGui.End()
end)

return ShootDodge
