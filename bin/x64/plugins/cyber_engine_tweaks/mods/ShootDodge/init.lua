-- ShootDodge: Max Payne 2 style Shootdodge (dive, bullet-time, prone/get-up) for Cyberpunk 2077.
-- Skeleton only -- no mechanics are implemented yet. See docs/DESIGN.md in the repo root for the
-- planned states and build order (follow the ticket log's requires chain, docs/USER_STORIES.md).

local Input = require("modules/Input")
local StateMachine = require("modules/StateMachine")

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

  -- C2SD-T5: detect the Shootdodge combo (aim held + jump + move). Detection only: a trigger is
  -- recorded and shown in the overlay, but nothing is wired to a state transition yet (C2SD-T6).
  ShootDodge.combo = Input.Install()
  ShootDodge.combo:SetEnabled(ShootDodge.enabled)
  ShootDodge.combo:AddListener(function(trigger)
    print(string.format("[ShootDodge] combo detected at %.2fs (move %.2f, %.2f)",
      trigger.time, trigger.moveX, trigger.moveY))
  end)
  print("[ShootDodge] loaded (skeleton, no mechanics active)")
end)

registerForEvent("onShutdown", function()
  Input.Reset()
  ShootDodge.machine:Reset("shutdown")
end)

registerForEvent("onUpdate", function(deltaTime)
  Input.Update(deltaTime)
  local machine = ShootDodge.machine
  local ok, err = pcall(function()
    machine:Update(deltaTime)
    if not ShootDodge.enabled then
      if machine:IsActive() then machine:Reset("mod disabled") end
      return
    end
    -- TODO: dive / bullet-time / landing branch drive the machine here (C2SD-T7 onward), in the
    -- order laid out in docs/DESIGN.md and the ticket log. Until then nothing fires a transition,
    -- so the state stays NONE.
  end)
  if not ok then
    print("[ShootDodge] update error: " .. tostring(err))
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
  ImGui.TextWrapped("No mechanics implemented yet -- scaffold only.")

  ImGui.End()
end)

return ShootDodge
