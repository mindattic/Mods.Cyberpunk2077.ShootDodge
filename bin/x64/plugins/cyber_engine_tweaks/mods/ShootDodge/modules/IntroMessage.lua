-- IntroMessage: the once-per-save text thread from Max Payne that explains ShootDodge (C2SD-T27).
--
-- Pure Lua, no CET or game API (modules/IntroMessageDriver.lua is the glue). It holds the sender,
-- the thread of texts, the verbatim quotes woven into them, and the rule for what to do with the
-- save's quest fact (FACT), which is what makes the message arrive once per save: a reload, a CET
-- restart or a second session on the same save never sends it again.
--
-- Delivery is a real phone text: r6/scripts/ShootDodge/ShootDodgePhone.reds adds a "Max Payne"
-- contact to the phone's Messages app through the Phone Extension framework (Nexus mod 24949).
-- There is no on-screen fallback; if the phone route is missing the overlay says so.
--
-- Every quote below is word for word from Wikiquote's page source for Max Payne (2001) and
-- Max Payne 2: The Fall of Max Payne (2003); each one's source is in docs/DESIGN.md
-- ("In-game text message"). Everything else in the texts is original writing in Max's voice and
-- is never presented as a quote.

local IntroMessage = {}

-- Quest fact in the save: 0 = not sent yet, 1 = sent and unread, 2 = read (set by the phone side
-- when the thread is opened).
IntroMessage.FACT = "shootdodge_intro_message"
IntroMessage.SENT = 1
IntroMessage.READ = 2

-- Who it's from (the phone contact's name).
IntroMessage.sender = "Max Payne"

-- The HUD notification's line when the thread arrives.
IntroMessage.preview = "The sun went down with practiced bravado."

-- The verbatim quotes woven into the texts, each with its source (also listed in docs/DESIGN.md).
-- IntroMessage.MissingQuotes() checks that every one appears word for word in the thread.
IntroMessage.quotes = {
  { text = "The sun went down with practiced bravado.",
    source = "Max Payne (2001), Part I, Prologue" },
  { text = "But dreams have a nasty habit of going bad when you're not looking.",
    source = "Max Payne (2001), Part I, Prologue" },
  { text = "The nightmare was always the same.",
    source = "Max Payne (2001), Part II, Prologue" },
  { text = "Somewhere the baby was crying.",
    source = "Max Payne (2001), Part II, Prologue" },
  { text = "The devil was in the drug. I knew. I had met him.",
    source = "Max Payne (2001), Part III, Chapter 8 \"Pain and Suffering\"" },
  { text = "I hadn't slept in a million years.",
    source = "Max Payne (2001), Part III, Chapter 4 \"Backstabbing Bastard\"" },
  { text = "I lied to myself that it was over. I was still alive, my loved ones were still dead. "
      .. "It wasn't over.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "Throw the rules out the window, odds are you'll go that way too.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "Logic was such a liar.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "When you're looking down the barrel of a gun, time slows down. Your whole life "
      .. "flashes by, heartbreak and scars.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "This hadn't been my first fall in the night, still just a prelude to the real deal, "
      .. "still a long way to the bottom.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "The genius of the hole: no matter how long you spend climbing out, you can still "
      .. "fall back down in an instant.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "I don't know about angels, but it's fear that gives men wings.",
    source = "Max Payne (2001), Part I, Chapter 6 \"Fear That Gives Men Wings\"" },
  { text = "I felt the rise of that old familiar feeling. I hated it. I welcomed it.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "Death is inevitable. Our fear of it makes us play safe, blocks out emotion. It's a "
      .. "losing game. Without passion you are already dead.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "Firing a gun is a binary choice. Either you pull the trigger or you don't.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "In a nightmare, every choice you make is a wrong one.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "Bad things happened in the night, on the streets of that other city.",
    source = "Max Payne (2001), Part III, Chapter 4 \"Backstabbing Bastard\"" },
  { text = "None of us was a saint.",
    source = "Max Payne (2001), Part II, Chapter 2 \"An Offer You Can't Refuse\"" },
  { text = "There were only personal apocalypses. Nothing is a cliché when it's happening to "
      .. "you.",
    source = "Max Payne (2001), Part I, Chapter 9 \"An Empire of Evil\"" },
  { text = "Closing your eyes forces you to look at the darkness inside.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "Your past is like pieces of a broken mirror. You try to pick them up, but you only "
      .. "end up cutting yourself.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "Like always, the dead had all the answers I was missing.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "I didn't deserve to walk away. There are no happy endings.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne" },
  { text = "I had a dream of my wife. She was dead. But it was all right.",
    source = "Max Payne 2: The Fall of Max Payne (2003), Max Payne (final narration)" },
}

-- The thread, one text per entry, in the order they arrive. Max's first person throughout; the
-- how-to-play is woven between the quotes.
IntroMessage.messages = {
  "V. Max Payne. The sun went down with practiced bravado. Night City lit up like a slot machine "
    .. "that never pays, and you woke up with a long coat and two pistols you don't remember "
    .. "buying. They're from me. But dreams have a nasty habit of going bad when you're not "
    .. "looking. This one already has.",
  "The nightmare was always the same. Somewhere the baby was crying. The devil was in the drug. "
    .. "I knew. I had met him. I hadn't slept in a million years. Now your city hums in the "
    .. "static between the stations like a ghost that wants a drink.",
  "I lied to myself that it was over. I was still alive, my loved ones were still dead. It "
    .. "wasn't over. It never is. So listen, kid, because I'm only going to teach you this once.",
  "Open the Cyber Engine Tweaks overlay, find the ShootDodge window, tick Enabled. Put a pistol, "
    .. "a revolver or an SMG in your hand. Nothing else. A rifle is an anchor, and anchors don't "
    .. "fly.",
  "Here's the part nobody tells you, so I will. The overlay is Cyber Engine Tweaks. Its key is "
    .. "whatever you picked the first night CET started, and if you never picked, it's the "
    .. "tilde, the squiggle under Escape. Press it and a pane of cold glass drops over the city. "
    .. "That's where the machinery lives.",
  "Find the window marked ShootDodge. Tick Enabled. I mean it. Until that box is checked "
    .. "nothing happens, you jump like a civilian and eat the floor like one too. It starts off "
    .. "every session, a bad habit of this town. And the debug window only shows while the "
    .. "overlay is open. Close the glass and it's gone. The mod keeps working in the dark.",
  "Bullet Time has its own switch. Open the Bindings tab in that same overlay and find "
    .. "ShootDodge. It ships unbound, because CET won't let a mod pick your keys. I'd give it "
    .. "Numpad Enter. No numpad, or want another key? Click the binding, press the key you "
    .. "want, done. Never V. V "
    .. "already summons your ride and the city has enough cars trying to kill you.",
  "Aim. Hold a direction. Jump. Throw the rules out the window, odds are you'll go that way too. "
    .. "You leave the ground sideways, like a bad decision with a head start. Gravity swears it "
    .. "will take you at the usual speed. Logic was such a liar.",
  "The world goes thick as cold syrup. When you're looking down the barrel of a gun, time slows "
    .. "down. Your whole life flashes by, heartbreak and scars. Your hands don't slow. Keep "
    .. "aiming. Keep firing all the way down.",
  "This hadn't been my first fall in the night, still just a prelude to the real deal, still a "
    .. "long way to the bottom. You hit the concrete like a confession and you stay there, prone, "
    .. "still shooting, until you move or jump and scramble back up. Hold the "
    .. "direction through the landing and you're up before the brass stops bouncing.",
  "Get up fast. The genius of the hole: no matter how long you spend climbing out, you can "
    .. "still fall back down in an instant.",
  "I don't know about angels, but it's fear that gives men wings. Mine come with an hourglass. "
    .. "Bullet Time, once you bind it (Numpad Enter, say), is the answer. Press it and the city crawls while the "
    .. "sand runs out. It trickles back on its own, every kill pours some back, and a shootdodge "
    .. "costs you nothing.",
  "And in Bullet Time you don't need the whole ritual. Space alone sends you flying. No aim, "
    .. "just the way you're leaning, or straight ahead if you're leaning nowhere. The dive takes "
    .. "over the slow-mo and the hourglass stops running. Land, switch it back on, do it again.",
  "I felt the rise of that old familiar feeling. I hated it. I welcomed it. Death is "
    .. "inevitable. Our fear of it makes us play safe, blocks out emotion. It's a losing game. "
    .. "Without passion you are already dead.",
  "Firing a gun is a binary choice. Either you pull the trigger or you don't. In a nightmare, "
    .. "every choice you make is a wrong one. So make yours loud.",
  "Bad things happened in the night, on the streets of that other city. Yours is no different, "
    .. "just brighter, like a wound under neon. None of us was a saint. There were only personal "
    .. "apocalypses. Nothing is a cliché when it's happening to you.",
  "Closing your eyes forces you to look at the darkness inside. Your past is like pieces of a "
    .. "broken mirror. You try to pick them up, but you only end up cutting yourself. Like "
    .. "always, the dead had all the answers I was missing.",
  "I didn't deserve to walk away. There are no happy endings. I had a dream of my wife. She was "
    .. "dead. But it was all right. Don't write back. The dead never check their messages.",
}

-- The whole thread as one block of text (the overlay's re-read view and the log).
function IntroMessage.FullText()
  return table.concat(IntroMessage.messages, "\n\n")
end

-- Quotes that are not word for word somewhere in the thread (should be none).
function IntroMessage.MissingQuotes()
  local full = IntroMessage.FullText()
  local missing = {}
  for _, quote in ipairs(IntroMessage.quotes) do
    if not string.find(full, quote.text, 1, true) then missing[#missing + 1] = quote.text end
  end
  return missing
end

-- What to do this session, from the save's fact value (nil/0 = never sent).
-- Returns { send = deliver now and notify, unread = show the thread as unread, why = label }.
-- A save that already has it only gets its thread back in the phone (never a second notification).
function IntroMessage.Plan(factValue)
  local value = tonumber(factValue) or 0
  if value <= 0 then
    return { send = true, unread = true, why = "sent" }
  end
  if value == IntroMessage.SENT then
    return { send = false, unread = true, why = "already sent for this save (unread)" }
  end
  return { send = false, unread = false, why = "already sent for this save (read)" }
end

return IntroMessage
