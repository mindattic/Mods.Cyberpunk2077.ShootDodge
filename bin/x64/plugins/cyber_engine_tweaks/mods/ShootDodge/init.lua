-- ShootDodge: Max Payne 2 style Shootdodge (dive, bullet-time, prone/get-up) for Cyberpunk 2077.
-- Skeleton only -- no mechanics are implemented yet. See docs/DESIGN.md in the repo root for the
-- planned states and build order (follow the ticket log's requires chain, docs/USER_STORIES.md).

local ShootDodge = {
  enabled = false,
  state = "NONE", -- "NONE" | "DIVING" | "AIRBORNE" | "PRONE" | "GETUP"
}

registerForEvent("onInit", function()
  print("[ShootDodge] loaded (skeleton, no mechanics active)")
end)

registerForEvent("onUpdate", function(deltaTime)
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
  ImGui.Text("State: " .. ShootDodge.state)
  ImGui.TextWrapped("No mechanics implemented yet -- scaffold only.")

  ImGui.End()
end)

return ShootDodge
