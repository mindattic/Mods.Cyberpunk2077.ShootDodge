-- DivePolishDriver: CET glue for the dive's camera + audio polish (C2SD-T14).
--
-- modules/DivePolish.lua decides what should be on; this file applies it to the game:
--   * FOV pull-back: V's first-person camera component (GetFOV/SetFOV). The FOV the camera had when
--     the pull-back began is recorded and put back exactly once the ease-out finishes, so nothing
--     is left widened. The camera stays first person throughout.
--   * Whoosh: a game sound event played on V once, from a state listener on NONE -> DIVING.
--   * Music/ambience muffle: the music volume setting (/audio/volume MusicVolume) is ducked to a
--     fraction of the player's own value, plus an optional pair of audio events (`lowPassOn` /
--     `lowPassOff`, editable in the overlay) for a low-pass mix on music and ambience. Restored on
--     landing, pause, death, abort, mod disable, reload and shutdown.
--
-- The music volume is a user setting, not part of the save, so a crash or a CET reload mid-dive
-- must not leave it ducked: while ducked, the original and ducked values are written to a small
-- file in the mod folder, and Install() (onInit) puts the original back if the setting still holds
-- the ducked value (i.e. the player hasn't changed it since).

local DivePolish = require("modules/DivePolish")

local RESTORE_FILE = "polish_restore.txt"
local MUSIC_GROUP, MUSIC_VAR = "/audio/volume", "MusicVolume"

local DivePolishDriver = {
  rules = DivePolish.new(),
  -- C2SD-T67: set by init.lua; Bullet Time mode muffles the world's sound like a dive does.
  isBulletTimeMode = function() return false end,
  baseFov = nil,        -- the camera's FOV before the pull-back, while held
  appliedFov = nil,     -- the FOV last written, for the overlay
  musicOriginal = nil,  -- the player's music volume while it is ducked
  musicDucked = nil,    -- the value it was ducked to
  -- Sound events. The whoosh plays once per dive; the low-pass pair (empty = none) brackets the dive.
  sounds = {
    whoosh = "lcm_player_double_jump",
    lowPassOn = "",
    lowPassOff = "",
  },
  lastWhoosh = nil,     -- { time, event } of the most recent whoosh, for the overlay
  lastError = nil,
}

local function note(prefix, err)
  DivePolishDriver.lastError = prefix .. ": " .. tostring(err)
end

-- FOV ------------------------------------------------------------------------------------------

local function fppCamera()
  local player = Game.GetPlayer()
  if player == nil then return nil end
  local ok, cam = pcall(function() return player:GetFPPCameraComponent() end)
  if ok then return cam end
  return nil
end

local function applyFov(offset)
  local cam = fppCamera()
  if cam == nil then
    note("fov", "no first-person camera")
    return false
  end
  local ok, err = pcall(function()
    if DivePolishDriver.baseFov == nil then
      DivePolishDriver.baseFov = cam:GetFOV()
    end
    local fov = DivePolishDriver.baseFov + offset
    cam:SetFOV(fov)
    DivePolishDriver.appliedFov = fov
  end)
  if not ok then note("fov", err) end
  return ok
end

local function releaseFov()
  local base = DivePolishDriver.baseFov
  DivePolishDriver.baseFov = nil
  DivePolishDriver.appliedFov = nil
  if base == nil then return true end
  local cam = fppCamera()
  if cam == nil then return false end
  local ok, err = pcall(function() cam:SetFOV(base) end)
  if not ok then note("fov restore", err) end
  return ok
end

-- Sound events ---------------------------------------------------------------------------------

local function playEvent(name)
  if name == nil or name == "" then return true end
  local player = Game.GetPlayer()
  if player == nil then return false end
  local ok, err = pcall(function() GameObject.PlaySoundEvent(player, name) end)
  if not ok then note("sound " .. name, err) end
  return ok
end

-- Music volume ---------------------------------------------------------------------------------

local function musicVar()
  local ok, var = pcall(function() return Game.GetSettingsSystem():GetVar(MUSIC_GROUP, MUSIC_VAR) end)
  if ok then return var end
  return nil
end

local function writeRestoreFile(original, ducked)
  pcall(function()
    local f = io.open(RESTORE_FILE, "w")
    if f == nil then return end
    if original ~= nil then f:write(string.format("%d %d", original, ducked)) end
    f:close()
  end)
end

local function readRestoreFile()
  local ok, original, ducked = pcall(function()
    local f = io.open(RESTORE_FILE, "r")
    if f == nil then return nil, nil end
    local text = f:read("*a") or ""
    f:close()
    local a, b = text:match("^%s*(%-?%d+)%s+(%-?%d+)")
    return tonumber(a), tonumber(b)
  end)
  if ok then return original, ducked end
  return nil, nil
end

local function duckMusic()
  local var = musicVar()
  if var == nil then
    note("music", "no MusicVolume setting")
    return false
  end
  local ok, err = pcall(function()
    local original = math.floor(tonumber(var:GetValue()) or 0)
    local ducked = DivePolishDriver.rules:DuckedVolume(original)
    DivePolishDriver.musicOriginal = original
    DivePolishDriver.musicDucked = ducked
    writeRestoreFile(original, ducked)
    var:SetValue(ducked)
  end)
  if not ok then note("music", err) end
  return ok
end

local function restoreMusic()
  local original = DivePolishDriver.musicOriginal
  DivePolishDriver.musicOriginal = nil
  DivePolishDriver.musicDucked = nil
  if original == nil then return true end
  local var = musicVar()
  local ok, err = pcall(function() var:SetValue(original) end)
  if ok then
    writeRestoreFile(nil)
  else
    note("music restore", err)
  end
  return ok
end

local function muffle()
  local ok = duckMusic()
  playEvent(DivePolishDriver.sounds.lowPassOn)
  return ok
end

local function unmuffle()
  playEvent(DivePolishDriver.sounds.lowPassOff)
  return restoreMusic()
end

local function isDead()
  local ok, dead = pcall(function()
    local player = Game.GetPlayer()
    if player == nil then return true end
    return player:IsDead()
  end)
  return ok and dead == true
end

-- Public ---------------------------------------------------------------------------------------

-- onInit: undo a music duck a crash or CET reload left behind, then start clean.
function DivePolishDriver.Install()
  local original, ducked = readRestoreFile()
  if original ~= nil then
    local var = musicVar()
    pcall(function()
      if var ~= nil and math.floor(tonumber(var:GetValue()) or -1) == ducked then
        var:SetValue(original)
      end
    end)
    writeRestoreFile(nil)
  end
  DivePolishDriver.rules:Clear()
  DivePolishDriver.baseFov = nil
end

-- Play the whoosh now (also the overlay's test button).
function DivePolishDriver.PlayWhoosh(time)
  local name = DivePolishDriver.sounds.whoosh
  if playEvent(name) then
    DivePolishDriver.lastWhoosh = { time = time or 0, event = name }
  end
end

-- State listener (init.lua wires it, passing the machine's clock): the whoosh, once, as the dive
-- starts. NONE -> DIVING is the only way into DIVING, so this is once per dive.
function DivePolishDriver.OnStateChange(from, to, time)
  if to ~= "DIVING" or from ~= "NONE" then return end
  if DivePolishDriver.rules:OnDiveStart() then
    DivePolishDriver.PlayWhoosh(time)
  end
end

-- Call every onUpdate, mod enabled or not, so turning the mod off mid-dive reverts everything.
-- deltaTime is real time; paused comes from the bullet-time driver's check (same frame).
function DivePolishDriver.Update(machine, enabled, deltaTime, paused)
  local rules = DivePolishDriver.rules
  local plan = rules:Update(deltaTime, {
    state = machine.state,
    enabled = enabled,
    paused = paused,
    dead = DivePolish.diveStates[machine.state] == true and isDead(),
    mode = DivePolishDriver.isBulletTimeMode() == true, -- C2SD-T67
  })
  if plan.fov ~= nil then
    applyFov(plan.fov)
  elseif plan.fovRelease then
    releaseFov()
  end
  if plan.audio == "muffle" then
    rules:AudioApplied("muffle", muffle())
  elseif plan.audio == "restore" then
    rules:AudioApplied("restore", unmuffle())
  end
end

-- Revert everything at once (reload, shutdown, error).
function DivePolishDriver.Cancel()
  local rules = DivePolishDriver.rules
  local wasMuffled = rules.muffled
  rules:Clear()
  releaseFov()
  if wasMuffled or DivePolishDriver.musicOriginal ~= nil then unmuffle() end
end

return DivePolishDriver
