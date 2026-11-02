-- LoadoutDriver: CET glue for the Max Payne 2 loadout (C2SD-T4). modules/Loadout.lua decides
-- what to give; this file reads the save and the inventory and gives it.
--
--   * Once per session (save loaded, new game, or CET reloaded in game), a short beat after V
--     exists so the inventory has loaded, it checks the save's quest fact. Unset: it counts what V
--     already holds of each record, gives only the shortfall (Game.AddToInventory, which mints a
--     separate weapon per pistol), then writes the fact into the save. Set: it does nothing.
--   * So reloading the save or restarting CET never re-grants duplicates.
--   * V's body type is read from the player (GetResolvedGenderName) for the per-body list.

local Loadout = require("modules/Loadout")
local Session = require("modules/Session") -- C2SD-T45

local LoadoutDriver = {
  installed = false,
  delaySec = 1.5,      -- wait after V appears before touching the inventory
  waited = 0,
  done = false,        -- this session has been checked
  hadPlayer = false,
  body = nil,          -- "Male" | "Female" once read
  lastResult = "waiting for a session",
  lastError = nil,
  grants = 0,          -- grants made this CET session (overlay)
}

local function note(prefix, err)
  LoadoutDriver.lastError = prefix .. ": " .. tostring(err)
end

local function readBody(player)
  local ok, name = pcall(function()
    local cname = player:GetResolvedGenderName()
    local okStr, str = pcall(function() return Game.NameToString(cname) end)
    if okStr and type(str) == "string" then return str end
    return tostring(cname.value or cname)
  end)
  return Loadout.NormalizeBody(ok and name or nil)
end

-- record name -> how many V holds, read once from the inventory.
local function heldCounts(player)
  local counts = {}
  local wanted = {}
  for _, item in ipairs(Loadout.items) do wanted[item.record] = TweakDBID.new(item.record) end
  for _, overrides in pairs(Loadout.bodyOverrides) do
    for _, record in pairs(overrides) do wanted[record] = TweakDBID.new(record) end
  end
  local ok, list = Game.GetTransactionSystem():GetItemList(player)
  if not ok or list == nil then return counts, false end
  for _, data in ipairs(list) do
    local okId, tdbid = pcall(function() return data:GetID().id end)
    if okId and tdbid ~= nil then
      for record, want in pairs(wanted) do
        if tdbid.hash == want.hash and tdbid.length == want.length then
          local okQty, qty = pcall(function() return data:GetQuantity() end)
          counts[record] = (counts[record] or 0) + ((okQty and qty and qty > 0) and qty or 1)
        end
      end
    end
  end
  return counts, true
end

-- Check the save and grant what's missing. Safe to call any number of times.
function LoadoutDriver.Check()
  local player = Game.GetPlayer()
  if player == nil then return false end
  local qs = Game.GetQuestsSystem()
  local granted = qs:GetFactStr(Loadout.FACT) > 0
  LoadoutDriver.body = readBody(player)
  local counts = granted and {} or heldCounts(player)
  local plan, why = Loadout.Plan(LoadoutDriver.body, granted,
    function(record) return counts[record] or 0 end)
  for _, entry in ipairs(plan) do
    if TweakDB:GetRecord(entry.record) == nil then
      error("no TweakDB record " .. entry.record)
    end
  end
  local failed = {}
  for _, entry in ipairs(plan) do
    local before, canCount = heldCounts(player)
    local okAdd, added = pcall(Game.AddToInventory, entry.record, entry.count)
    local success = okAdd and added ~= false
    if success and canCount then
      -- CET's helper may return nothing, so judge by what V actually holds now.
      local after, okAfter = heldCounts(player)
      if okAfter and (after[entry.record] or 0) <= (before[entry.record] or 0) then success = false end
    end
    if success then
      print(string.format("[ShootDodge] loadout: +%d %s (%s)", entry.count, entry.record,
        entry.label))
    else
      failed[#failed + 1] = entry.label .. " (" .. entry.record .. ")"
      print(string.format("[ShootDodge] loadout: FAILED +%d %s (%s)", entry.count,
        entry.record, entry.label))
    end
  end
  if #plan > 0 then LoadoutDriver.grants = LoadoutDriver.grants + 1 end
  if #failed > 0 then
    -- Leave the save fact unset so "Check loadout now" retries (shortfall-only, no duplicates).
    LoadoutDriver.lastResult = string.format("INCOMPLETE, not marked granted; failed to add: %s (%s V)",
      table.concat(failed, ", "), LoadoutDriver.body)
    LoadoutDriver.done = true
    return true
  end
  if not granted then qs:SetFactStr(Loadout.FACT, 1) end
  LoadoutDriver.lastResult = string.format("%s (%s V)", why, LoadoutDriver.body)
  LoadoutDriver.done = true
  return true
end

local function sessionEnded()
  LoadoutDriver.done = false
  LoadoutDriver.waited = 0
  LoadoutDriver.lastResult = "waiting for a session"
end

-- Call once from onInit.
function LoadoutDriver.Install()
  if LoadoutDriver.installed then return end
  -- Loading another save from inside the game: start over for the new session.
  Observe("QuestTrackerGameController", "OnUninitialize", sessionEnded)
  LoadoutDriver.installed = true
end

-- Call every onUpdate with the real frame time.
function LoadoutDriver.Update(deltaTime)
  local hasPlayer = Session.Ready() -- C2SD-T45: not the main menu's player
  if not hasPlayer then
    if LoadoutDriver.hadPlayer then sessionEnded() end
    LoadoutDriver.hadPlayer = false
    return
  end
  LoadoutDriver.hadPlayer = true
  if LoadoutDriver.done then return end
  LoadoutDriver.waited = LoadoutDriver.waited + (deltaTime or 0)
  if LoadoutDriver.waited < LoadoutDriver.delaySec then return end
  local ok, err = pcall(LoadoutDriver.Check)
  if not ok then
    note("grant", err)
    LoadoutDriver.lastResult = "failed (see problem line)"
    LoadoutDriver.done = true  -- don't retry every frame; the overlay button retries
  end
end

return LoadoutDriver
