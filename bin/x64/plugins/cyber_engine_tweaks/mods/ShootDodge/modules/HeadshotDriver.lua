-- HeadshotDriver: every headshot is lethal while V is mid-Shootdodge (C2SD-T56).
--
-- Enemies have RPG health, so a single headshot rarely kills. While the dive is in the air
-- (DIVING / AIRBORNE, the slowed part), V gets a large additive bonus on the player's own
-- HeadshotDamageMultiplier stat, so any head hit does enough damage to kill an ordinary enemy.
-- The modifier is removed the moment the dive ends (landing, abort, reset, mod disable, session
-- end). Enemies with scripted invulnerability (some bosses) can still survive.

local Session = require("modules/Session")

local HeadshotDriver = {
  -- Added to HeadshotDamageMultiplier while airborne. Vanilla is around 1.5-2.5x.
  bonus = 1000.0,
  enabled = true,
  modifier = nil, -- the applied stat modifier, or nil
  ownerID = nil,  -- the entity it was applied to
  lastError = nil,
}

local AIR_STATES = { DIVING = true, AIRBORNE = true }

local function note(msg)
  if HeadshotDriver.lastError ~= msg then print("[ShootDodge] lethal headshots: " .. msg) end
  HeadshotDriver.lastError = msg
end

local function apply()
  if HeadshotDriver.modifier ~= nil or not HeadshotDriver.enabled or not Session.Ready() then return end
  local ok, err = pcall(function()
    local player = Game.GetPlayer()
    local id = player:GetEntityID()
    local mod = RPGManager.CreateStatModifier(gamedataStatType.HeadshotDamageMultiplier,
      gameStatModifierType.Additive, HeadshotDriver.bonus)
    Game.GetStatsSystem():AddModifier(id, mod)
    HeadshotDriver.modifier = mod
    HeadshotDriver.ownerID = id
  end)
  if ok then print("[ShootDodge] lethal headshots on") else note("apply: " .. tostring(err)) end
end

local function remove()
  local mod, id = HeadshotDriver.modifier, HeadshotDriver.ownerID
  HeadshotDriver.modifier, HeadshotDriver.ownerID = nil, nil
  if mod == nil then return end
  local ok, err = pcall(function() Game.GetStatsSystem():RemoveModifier(id, mod) end)
  if ok then print("[ShootDodge] lethal headshots off") else note("remove: " .. tostring(err)) end
end

-- State listener (init.lua wires it): on while the dive is in the air, off the frame it ends.
function HeadshotDriver.OnStateChange(_, to)
  if AIR_STATES[to] then apply() else remove() end
end

-- Call every onUpdate: drops the modifier if the state moved on without a listener call
-- (session end, mod disabled) so it can never stick.
function HeadshotDriver.Update(machine, enabled)
  if HeadshotDriver.modifier ~= nil
      and (not enabled or not Session.Ready() or not AIR_STATES[machine.state]) then
    remove()
  end
end

function HeadshotDriver.Cancel()
  remove()
end

function HeadshotDriver.Active()
  return HeadshotDriver.modifier ~= nil
end

return HeadshotDriver
