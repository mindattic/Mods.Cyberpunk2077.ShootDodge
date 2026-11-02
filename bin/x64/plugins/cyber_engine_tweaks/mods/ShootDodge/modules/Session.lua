-- Session: the one gate for "a real save is loaded and V is in the world" (C2SD-T45).
--
-- The main menu is itself a game world that spawns a local player, so Game.GetPlayer() ~= nil is
-- true there too. Touching the time system, inventory, quest facts or blackboards from the main
-- menu (or while a save is still spawning) crashed the game with only this mod installed. Every
-- driver asks Session.Ready() instead: true only when a player exists, the game is not pre-game
-- (main menu / character creation), and that has held for `delaySec` of real time.

local Session = {
  ready = false,
  settle = 0,
  delaySec = 1.5,
}

local function live()
  local ok, result = pcall(function()
    if Game.GetPlayer() == nil then return false end
    local handler = Game.GetSystemRequestsHandler()
    if handler == nil then return false end
    return not handler:IsPreGame()
  end)
  return ok and result == true
end

-- Call first thing in every onUpdate with the real frame time.
function Session.Update(deltaTime)
  if not live() then
    Session.ready = false
    Session.settle = 0
    return
  end
  if Session.ready then return end
  Session.settle = Session.settle + (deltaTime or 0)
  if Session.settle >= Session.delaySec then Session.ready = true end
end

function Session.Ready()
  return Session.ready == true
end

return Session
