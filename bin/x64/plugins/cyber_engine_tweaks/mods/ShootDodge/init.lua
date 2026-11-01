-- ShootDodge: Max Payne 2 style Shootdodge (dive, bullet-time, prone/get-up) for Cyberpunk 2077.
-- Implemented so far: combo detection, the state machine and the dive trigger (C2SD-T5..T7). See
-- docs/DESIGN.md in the repo root for the planned states and build order (follow the ticket log's requires chain, docs/USER_STORIES.md).

local Input = require("modules/Input")
local StateMachine = require("modules/StateMachine")
local DiveDriver = require("modules/DiveDriver")

local ShootDodge = {
  enabled = false,
  -- C2SD-T6: the one centralized state (NONE | DIVING | AIRBORNE | PRONE | GETUP). Every
  -- transition is defined in modules/StateMachine.lua; read it with ShootDodge.machine.state.
  machine = StateMachine.new(),
}

registerForEvent("onInit", function()
  ShootDodge.machine:Reset("load")
  ShootDodge.machine:AddListener(function(from, to, event, reason)
    print(string.format("[ShootDodge] state %s -> %s (%s%s)", from, to, event,
      reason and (": " .. reason) or ""))
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
  print("[ShootDodge] loaded (dive trigger active; bullet-time and landing not yet)")
end)

registerForEvent("onShutdown", function()
  Input.Reset()
  DiveDriver.Cancel()
  ShootDodge.machine:Reset("shutdown")
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
    -- C2SD-T7: the dive drives DIVING (direction lock, lift-off/landing check). Bullet-time and
    -- the landing branch hook in here next (C2SD-T8 onward), per docs/DESIGN.md.
    DiveDriver.Update(machine, deltaTime)
  end)
  if not ok then
    print("[ShootDodge] update error: " .. tostring(err))
    DiveDriver.Cancel()
    machine:Reset("update error")
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
  ImGui.TextWrapped("Dive trigger only -- bullet-time and landing not implemented yet.")

  ImGui.End()
end)

return ShootDodge
