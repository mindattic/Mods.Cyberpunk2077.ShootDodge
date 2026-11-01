-- IntroMessageDriver: CET glue for the once-per-save text thread from Max Payne (C2SD-T27).
-- modules/IntroMessage.lua holds the words and the rules; this file reads/writes the save's fact
-- and hands the thread to the phone side, r6/scripts/ShootDodge/ShootDodgePhone.reds (a redscript
-- ScriptableSystem that adds the "Max Payne" contact through the Phone Extension framework).
--
--   * Once per session (save loaded, new game, or CET reloaded in game), a settle delay after V
--     exists, while the game isn't paused and once the HUD phone is up, it reads the save's fact and
--     fills the phone thread (every session, so the texts stay in the phone like any other SMS).
--   * Fact unset: it writes the fact (1 = sent, unread) and pops the phone's "new message"
--     notification. Fact set: no notification, ever again, on that save. Opening the thread in the
--     phone sets the fact to 2 (read).
--   * No on-screen fallback: if redscript or Phone Extension is missing, the overlay says so.
--   * The CET overlay keeps the whole thread for re-reading and a button to re-notify (testing).

local IntroMessage = require("modules/IntroMessage")

local IntroMessageDriver = {
  installed = false,
  delaySec = 8.0,      -- after V appears: past the load fade and the loadout grant
  waited = 0,
  done = false,        -- this session has been handled
  hadPlayer = false,
  sentThisRun = false, -- delivered during this CET session (overlay)
  lastResult = "waiting for a session",
  lastError = nil,
}

local PHONE_SYSTEM = "ShootDodgePhoneSystem"

-- The redscript side, or nil when it isn't compiled in (redscript / Phone Extension missing).
function IntroMessageDriver.PhoneSystem()
  local container = Game.GetScriptableSystemsContainer()
  if container == nil then return nil end
  return container:Get(PHONE_SYSTEM)
end

-- Fill the phone thread with every text; unread decides the badge.
local function fillThread(phone, unread)
  phone:ClearThread(IntroMessage.sender)
  for _, text in ipairs(IntroMessage.messages) do
    phone:AddMessage(text)
  end
  phone:SetUnread(unread == true)
end

-- Handle this session: restore the thread, and send (notify + write the fact) if the save has
-- never had it. Returns true when the session is handled, false to try again next frame.
function IntroMessageDriver.Check()
  local phone = IntroMessageDriver.PhoneSystem()
  if phone == nil then
    IntroMessageDriver.lastError = "phone route missing: install redscript and Phone Extension (optional, only for the text) "
      .. "(r6/scripts/ShootDodge/ShootDodgePhone.reds did not load)"
    IntroMessageDriver.lastResult = "not sent (no phone route)"
    IntroMessageDriver.done = true
    return true
  end
  if not phone:IsPhoneReady() then
    IntroMessageDriver.lastResult = "waiting for the phone"
    return false
  end
  local qs = Game.GetQuestsSystem()
  local plan = IntroMessage.Plan(qs:GetFactStr(IntroMessage.FACT))
  fillThread(phone, plan.unread)
  if plan.send then
    if not phone:Notify(IntroMessage.sender, IntroMessage.preview) then
      IntroMessageDriver.lastResult = "waiting for the phone"
      return false
    end
    qs:SetFactStr(IntroMessage.FACT, IntroMessage.SENT)
    IntroMessageDriver.sentThisRun = true
    print("[ShootDodge] text from " .. IntroMessage.sender .. " sent to V's phone")
  end
  IntroMessageDriver.lastResult = plan.why
  IntroMessageDriver.done = true
  return true
end

-- Overlay button: put the thread back and pop the notification again. Does not touch the fact.
function IntroMessageDriver.Resend()
  local phone = IntroMessageDriver.PhoneSystem()
  if phone == nil then error("phone route missing (redscript / Phone Extension)") end
  fillThread(phone, true)
  if not phone:Notify(IntroMessage.sender, IntroMessage.preview) then
    error("phone not ready")
  end
  IntroMessageDriver.lastResult = "re-sent from the overlay"
end

local function sessionEnded()
  IntroMessageDriver.done = false
  IntroMessageDriver.waited = 0
  IntroMessageDriver.lastResult = "waiting for a session"
end

-- Call once from onInit.
function IntroMessageDriver.Install()
  if IntroMessageDriver.installed then return end
  Observe("QuestTrackerGameController", "OnUninitialize", sessionEnded)
  IntroMessageDriver.installed = true
end

-- Call every onUpdate with the real frame time and the game's pause flag.
function IntroMessageDriver.Update(deltaTime, paused)
  local hasPlayer = Game.GetPlayer() ~= nil
  if not hasPlayer then
    if IntroMessageDriver.hadPlayer then sessionEnded() end
    IntroMessageDriver.hadPlayer = false
    return
  end
  IntroMessageDriver.hadPlayer = true
  if paused or IntroMessageDriver.done then return end
  IntroMessageDriver.waited = IntroMessageDriver.waited + (deltaTime or 0)
  if IntroMessageDriver.waited < IntroMessageDriver.delaySec then return end
  local ok, err = pcall(IntroMessageDriver.Check)
  if not ok then
    IntroMessageDriver.lastError = "send: " .. tostring(err)
    IntroMessageDriver.lastResult = "failed (see problem line)"
    IntroMessageDriver.done = true  -- don't retry every frame; the overlay button re-sends
  end
end

return IntroMessageDriver
