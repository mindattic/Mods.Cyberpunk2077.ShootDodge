-- ShootDodge: Max Payne 2 style Shootdodge (dive, bullet-time, prone/get-up) for Cyberpunk 2077.
-- Skeleton only -- no mechanics are implemented yet. See docs/DESIGN.md in the repo root for the
-- planned states and build order (follow the ticket log's requires chain, docs/USER_STORIES.md).

local ShootDodge = {
  enabled = false,
  state = "NONE", -- "NONE" | "DIVING" | "AIRBORNE" | "PRONE" | "GETUP"
}

local Input = require("modules/Input")

registerForEvent("onInit", function()
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
end)

registerForEvent("onUpdate", function(deltaTime)
  Input.Update(deltaTime)
  if not ShootDodge.enabled then return end
  -- TODO: input detection / state machine / dive / bullet-time / landing branch go here,
  -- in the order laid out in docs/DESIGN.md and the ticket log.
end)

registerForEvent("onDraw", function()
  if not ImGui.Begin("ShootDodge") then
    ImGui.End()
    return
  end

  local changed
  changed, ShootDodge.enabled = ImGui.Checkbox("Enabled", ShootDodge.enabled)
  if changed and ShootDodge.combo then ShootDodge.combo:SetEnabled(ShootDodge.enabled) end
  ImGui.Text("State: " .. ShootDodge.state)
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
