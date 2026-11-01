-- WeaponGate: which equipped weapons may arm the Shootdodge combo (C2SD-T13 / C2SD-US-D10).
--
-- Pure Lua, no CET or game API: it classifies a gamedataItemType name (the string the CET glue in
-- modules/Input.lua reads off the weapon in V's hands). It is an explicit allow-list: only
-- pistols, revolvers and SMGs arm the combo; every other type (rifles, shotguns, LMGs/HMGs,
-- sniper and precision rifles, melee, fists, cyberware arms, no weapon at all, or a type this
-- list doesn't know) blocks it.
--
-- The check runs at the instant jump is pressed, against whatever is equipped right then, so a
-- weapon swap mid-session changes the outcome on the very next combo with no restart.

local WeaponGate = {}

-- gamedataItemType names that permit the dive.
WeaponGate.allowed = {
  Wea_Handgun = "pistol",
  Wea_Revolver = "revolver",
  Wea_SubmachineGun = "SMG",
}

-- Returns allowed (bool) and a short label for the debug overlay.
function WeaponGate.Classify(typeName)
  if typeName == nil or typeName == "" then
    return false, "no weapon"
  end
  local label = WeaponGate.allowed[typeName]
  if label then return true, label end
  return false, typeName
end

return WeaponGate
