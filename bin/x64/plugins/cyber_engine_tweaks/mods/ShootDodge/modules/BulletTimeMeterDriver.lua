-- BulletTimeMeterDriver: CET glue for the Max Payne 2 bullet-time hourglass (C2SD-T15).
--
-- modules/BulletTimeMeter.lua holds the economy; this file wires it to the game:
--   * Kills: observes NPCPuppet:OnDeath (the game's own death event) and refills the meter when
--     the death's instigator is the player. Each NPC is counted once.
--   * Save/load: the level is written to a quest fact, which the game stores inside the save file,
--     and read back at every session start (load, new game). A save without the fact starts full.
--   * HUD: an hourglass drawn with ImGui in the lower left, visible in game whether or not the CET
--     overlay is open. Sand drains from the top bulb to the bottom as the meter empties and turns
--     yellow after kills, as MP2's does.

local Meter = require("modules/BulletTimeMeter")
local Session = require("modules/Session") -- C2SD-T45
local BulletTimeDriver = require("modules/BulletTimeDriver")

local FACT = "shootdodge_bt_meter"

local MeterDriver = {
  meter = Meter.new(),
  installed = false,
  counted = {},        -- entity hashes of NPCs already counted as kills this session
  lastError = nil,
  lastSaved = nil,     -- last encoded value written to the save
  saveTimer = 0,
  restoredFrom = nil,  -- "save" | "default" for the overlay
  hadPlayer = false,
  -- False between a session's end and the next one's restore, so the old session's level is
  -- never written into the save that is loading.
  sessionOpen = false,
  hud = {
    visible = true,
    x = 0.035,         -- position as a fraction of the screen (lower left, like MP2)
    y = 0.62,
    height = 64,       -- hourglass height in pixels
  },
}

local function questSystem()
  return Game.GetQuestsSystem()
end

local function note(prefix, err)
  MeterDriver.lastError = prefix .. ": " .. tostring(err)
end

-- Write the level to the save (throttled; force = write now).
function MeterDriver.Persist(force)
  local value = MeterDriver.meter:Encode()
  if not MeterDriver.sessionOpen or value == MeterDriver.lastSaved then return end
  if not force and MeterDriver.saveTimer > 0 then return end
  local ok, err = pcall(function() questSystem():SetFactStr(FACT, value) end)
  if ok then
    MeterDriver.lastSaved = value
    MeterDriver.saveTimer = 0.25
  else
    note("save", err)
  end
end

-- Read the level back from the loaded save; a save without it starts full.
-- Returns true once the save was actually read (the session then opens and Persist may write);
-- false leaves the session closed so nothing overwrites the saved level, and the caller retries.
function MeterDriver.Restore()
  local meter = MeterDriver.meter
  local ok, value = pcall(function() return questSystem():GetFactStr(FACT) end)
  if not ok then
    note("load", value)
    MeterDriver.restoredFrom = "default (save unreadable)"
    return false
  end
  meter:EndMode("load")
  meter.yellow = 0
  MeterDriver.counted = {}
  local level = meter:Decode(value)
  if level ~= nil then
    meter:SetLevel(level)
    MeterDriver.restoredFrom = "save"
  else
    meter:SetLevel(meter.config.startLevel)
    MeterDriver.restoredFrom = "default"
  end
  MeterDriver.lastSaved = meter:Encode()
  MeterDriver.sessionOpen = true
  return true
end

local function entityKey(npc)
  local ok, key = pcall(function() return tostring(npc:GetEntityID().hash) end)
  if ok then return key end
  return nil
end

local function killedByPlayer(evt)
  local ok, yes = pcall(function()
    local instigator = evt.instigator
    if instigator == nil then return false end
    return instigator:IsPlayer() == true
  end)
  return ok and yes == true
end

local function onDeath(npc, evt)
  if not Session.Ready() then return end -- C2SD-T45
  if not killedByPlayer(evt) then return end
  local key = entityKey(npc)
  if key ~= nil then
    if MeterDriver.counted[key] then return end
    MeterDriver.counted[key] = true
  end
  MeterDriver.meter:OnKill()
  MeterDriver.Persist(true)
end

-- Call once from onInit.
function MeterDriver.Install()
  if MeterDriver.installed then return end
  Observe("NPCPuppet", "OnDeath", function(npc, evt)
    local ok, err = pcall(onDeath, npc, evt)
    if not ok then note("kill", err) end
  end)
  -- The session follows the player appearing (see Update), not a HUD widget's lifetime: a HUD
  -- rebuild mid-session must neither end Bullet Time mode nor stop saving.
  MeterDriver.installed = true
end

-- Bullet Time mode toggle (the hotkey / overlay button). Refused mid-dive and when disabled.
function MeterDriver.ToggleMode(enabled, machine)
  if not enabled then return false end
  if machine ~= nil and machine:IsActive() then return false end
  -- C2SD-T22: no slow-mo to grant (bullet-time off / factor 1.0) -> don't start (ending is fine).
  if not MeterDriver.meter.mode and not BulletTimeDriver.rules:CanSlow() then return false end
  local changed = MeterDriver.meter:ToggleMode()
  MeterDriver.Persist(true)
  return changed
end

-- Call every onUpdate with the real frame time.
function MeterDriver.Update(deltaTime, ctx)
  local meter = MeterDriver.meter
  local hasPlayer = Session.Ready() -- C2SD-T45: not the main menu's player
  -- Fallback session detection: the player reappearing after none (main menu -> load).
  if not hasPlayer then
    MeterDriver.hadPlayer = false
    MeterDriver.sessionOpen = false
    meter:EndMode("no player")
    return
  end
  if not MeterDriver.hadPlayer then
    -- Retried every frame until the save was readable.
    local ok, restored = pcall(MeterDriver.Restore)
    if not ok then note("load", restored) end
    MeterDriver.hadPlayer = ok and restored == true
  end
  if not ctx.enabled then meter:EndMode("mod disabled") end
  if meter.mode and not BulletTimeDriver.rules:CanSlow() then meter:EndMode("no slow-mo") end
  local okDead, dead = pcall(function() return Game.GetPlayer():IsDead() end)
  ctx.dead = okDead and dead == true
  meter:Update(deltaTime, ctx)
  MeterDriver.saveTimer = math.max(0, MeterDriver.saveTimer - (deltaTime or 0))
  MeterDriver.Persist(false)
end

-- HUD -------------------------------------------------------------------------------------------

local WINDOW_FLAGS = nil

local function windowFlags()
  if WINDOW_FLAGS ~= nil then return WINDOW_FLAGS end
  local f = ImGuiWindowFlags
  local flags = 0
  for _, name in ipairs({ "NoTitleBar", "NoResize", "NoMove", "NoScrollbar", "NoCollapse",
      "NoBackground", "NoInputs", "NoSavedSettings", "NoFocusOnAppearing", "NoNav",
      "AlwaysAutoResize" }) do
    local ok, v = pcall(function() return f[name] end)
    if ok and type(v) == "number" then flags = flags + v end
  end
  WINDOW_FLAGS = flags
  return flags
end

local function color(r, g, b, a)
  return ImGui.GetColorU32(r, g, b, a)
end

-- Draw the hourglass at (x, y) top-left, w x h.
local function drawHourglass(dl, x, y, w, h, fraction, yellow, active)
  local cx = x + w / 2
  local cy = y + h / 2
  local half = h / 2
  local hw = w / 2
  -- Sand: white blending to MP2's yellow after kills.
  local sand = color(1.0, 1.0 - 0.15 * yellow, 1.0 - 0.85 * yellow, 0.95)
  local glass = color(1.0, 1.0, 1.0, active and 0.95 or 0.6)
  local shade = color(0.0, 0.0, 0.0, 0.35)

  -- Glass backing.
  ImGui.ImDrawListAddTriangleFilled(dl, x, y, x + w, y, cx, cy, shade)
  ImGui.ImDrawListAddTriangleFilled(dl, cx, cy, x + w, y + h, x, y + h, shade)

  -- Top bulb (apex at the neck): the sand left, sitting at the neck. Area scales with the square
  -- of height, so a fraction f fills a similar triangle sqrt(f) tall.
  local s = math.sqrt(math.max(0, math.min(1, fraction)))
  if s > 0 then
    ImGui.ImDrawListAddTriangleFilled(dl, cx - hw * s, cy - half * s, cx + hw * s, cy - half * s,
      cx, cy, sand)
  end
  -- Bottom bulb: the sand that has run through (1 - f), piled from the base; its empty part is
  -- a triangle at the neck sqrt(f) tall.
  if s < 1 then
    local ty = cy + half * s
    local tw = hw * s
    ImGui.ImDrawListAddQuadFilled(dl, cx - tw, ty, cx + tw, ty, x + w, y + h, x, y + h, sand)
  end
  -- Falling stream while the mode drains it.
  if active and fraction > 0 then
    ImGui.ImDrawListAddLine(dl, cx, cy - 1, cx, y + h, sand, 1.5)
  end

  -- Frame: two triangles meeting at the neck, with caps.
  local t = 1.5
  ImGui.ImDrawListAddLine(dl, x - 2, y, x + w + 2, y, glass, 2.5)
  ImGui.ImDrawListAddLine(dl, x - 2, y + h, x + w + 2, y + h, glass, 2.5)
  ImGui.ImDrawListAddLine(dl, x, y, cx, cy, glass, t)
  ImGui.ImDrawListAddLine(dl, x + w, y, cx, cy, glass, t)
  ImGui.ImDrawListAddLine(dl, cx, cy, x, y + h, glass, t)
  ImGui.ImDrawListAddLine(dl, cx, cy, x + w, y + h, glass, t)
end

-- Call from onDraw. paused = the game is paused (menus), when the HUD hides like the game's own.
function MeterDriver.DrawHud(paused)
  local hud = MeterDriver.hud
  if not hud.visible or paused or not Session.Ready() then return end
  local meter = MeterDriver.meter
  local sw, sh = GetDisplayResolution()
  local h = hud.height
  local w = math.floor(h * 0.62)
  ImGui.SetNextWindowPos(sw * hud.x, sh * hud.y)
  if ImGui.Begin("##ShootDodgeHourglass", windowFlags()) then
    local ok, err = pcall(function()
      local x, y = ImGui.GetCursorScreenPos()
      local dl = ImGui.GetWindowDrawList()
      drawHourglass(dl, x + 2, y, w, h, meter:Fraction(), meter.yellow, meter.mode)
      ImGui.Dummy(w + 4, h)
    end)
    if not ok then
      -- Draw-list API unavailable: fall back to a plain bar so the meter is never invisible.
      MeterDriver.lastError = "hud: " .. tostring(err)
      ImGui.ProgressBar(meter:Fraction(), w + 4, 8, "")
    end
  end
  ImGui.End()
end

return MeterDriver
