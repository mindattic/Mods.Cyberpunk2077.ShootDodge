-- Loadout: the Max Payne 2 look and twin pistols granted once per save (C2SD-T4 / C2SD-US-D1).
--
-- Pure Lua, no CET or game API (modules/LoadoutDriver.lua is the glue). Every item is an existing
-- vanilla TweakDB record, so nothing new is shipped: no meshes, textures, .archive art or TweakXL
-- records. Clothing records resolve their body-gender mesh on their own (each one below has both a
-- "&Female" and a "&Male" appearance in the TweakDB), so male and female V share one list; a
-- per-body override is supported for the day a piece needs a different item on one body type.
-- The research and the slot-by-slot choices with runners-up are in docs/DESIGN.md ("Loadout").

local Loadout = {}

-- Quest fact written into the save once the grant has gone through.
Loadout.FACT = "shootdodge_mp2_loadout"

-- slot -> { record, count, label }. Order is the grant order.
Loadout.items = {
  { slot = "weapon",      record = "Items.Preset_Lexington_Default",  count = 2,
    label = "Twin M-10AF Lexington (Beretta 92FS stand-in)" },
  { slot = "outer torso", record = "Items.Coat_01_basic_01",          count = 1,
    label = "Long leather coat (Max's trench)" },
  { slot = "inner torso", record = "Items.FormalShirt_01_basic_01",   count = 1,
    label = "Collared dress shirt" },
  { slot = "legs",        record = "Items.FormalPants_01_basic_01",   count = 1,
    label = "Suit trousers" },
  { slot = "feet",        record = "Items.FormalShoes_01_basic_01",   count = 1,
    label = "Dress shoes" },
}

-- body ("Male" | "Female") -> { [slot] = record }. Empty: every piece above fits both bodies.
Loadout.bodyOverrides = {
  Male = {},
  Female = {},
}

-- The item list for one body type, with any override applied.
function Loadout.ItemsFor(body)
  local overrides = Loadout.bodyOverrides[body] or {}
  local list = {}
  for _, item in ipairs(Loadout.items) do
    list[#list + 1] = {
      slot = item.slot,
      record = overrides[item.slot] or item.record,
      count = item.count,
      label = item.label,
    }
  end
  return list
end

-- What to give. granted = the save's fact says the grant already happened; held(record) = how many
-- of that record V holds now. Returns a list of { record, count } (empty = nothing to do) and why.
-- Once granted, nothing is ever given again (selling or dropping a piece is the player's call).
-- Before that, only the shortfall is given, so a save made between the items arriving and the fact
-- being written, or a second call in the same frame, never duplicates anything.
function Loadout.Plan(body, granted, held)
  if granted then return {}, "already granted for this save" end
  local plan = {}
  for _, item in ipairs(Loadout.ItemsFor(body)) do
    local have = held and held(item.record) or 0
    local missing = item.count - (have or 0)
    if missing > 0 then
      plan[#plan + 1] = { record = item.record, count = missing, label = item.label }
    end
  end
  if #plan == 0 then return plan, "already held" end
  return plan, "grant"
end

-- "Male" | "Female" from the game's gender name; anything else counts as Male (the default list).
function Loadout.NormalizeBody(name)
  if type(name) == "string" and name:lower():find("female", 1, true) then return "Female" end
  return "Male"
end

return Loadout
