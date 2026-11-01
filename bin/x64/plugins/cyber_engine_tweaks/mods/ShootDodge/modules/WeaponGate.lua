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
--
-- C2SD-T30: with the 2.5 Double Trouble perk V can hold a second gun in the off hand;
-- ClassifyPair below requires both to be allowed. (Double Trouble itself only pairs power pistols
-- and power revolvers, both on the list.)

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

-- C2SD-T30: the check for both hands. leftTypeName is the gamedataItemType name of the weapon in
-- the off-hand slot (AttachmentSlots.WeaponLeft), or nil when V holds a single weapon, which is
-- then exactly Classify(rightTypeName). With two guns (2.5 Double Trouble) both must be on the
-- allow-list; an off-hand gun that isn't refuses the combo and the label says it was the off hand.
function WeaponGate.ClassifyPair(rightTypeName, leftTypeName)
  if leftTypeName == nil or leftTypeName == "" then
    return WeaponGate.Classify(rightTypeName)
  end
  if rightTypeName == nil or rightTypeName == "" then
    -- Only the off-hand slot holds a weapon: judge it as the one weapon.
    return WeaponGate.Classify(leftTypeName)
  end
  local rightOk, rightLabel = WeaponGate.Classify(rightTypeName)
  if not rightOk then return false, rightLabel end
  local leftOk, leftLabel = WeaponGate.Classify(leftTypeName)
  if not leftOk then return false, "off-hand " .. leftLabel end
  if leftLabel == rightLabel then return true, "dual " .. rightLabel end
  return true, "dual " .. rightLabel .. " + " .. leftLabel
end

return WeaponGate
