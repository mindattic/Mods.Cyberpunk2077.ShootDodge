-- StateMachine: the one centralized Shootdodge state (C2SD-T6 / C2SD-US-D3).
--
-- Pure Lua, no CET or game API, so the rules can be exercised outside the game. Every mechanic
-- (dive, bullet-time, landing, get-up) reads and changes the state only through this module:
-- no other file keeps its own "am I diving" flag.
--
--   NONE --dive--> DIVING --launch--> AIRBORNE --land--> PRONE --getUp--> GETUP --recover--> NONE
--                    \------------------land------------/
--   any state --abort--> NONE
--
-- Every legal transition is listed in `StateMachine.transitions`; anything else is refused (and
-- reported to the debug overlay), never applied.
--
-- Safety net: a non-NONE state must be actively driven. The mechanic that owns the current state
-- calls Drive() every frame it is still in control; if no Drive() arrives for `driverTimeoutSec`
-- the machine falls back to NONE on its own. So a mechanic that errors out, is unloaded, or
-- forgets to finish can never leave V stuck mid-dive. Reset() (load, shutdown, mod disable)
-- also forces NONE.

local StateMachine = {}
StateMachine.__index = StateMachine

StateMachine.State = {
  NONE = "NONE",
  DIVING = "DIVING",
  AIRBORNE = "AIRBORNE",
  PRONE = "PRONE",
  GETUP = "GETUP",
}

local S = StateMachine.State

-- Display / iteration order for the overlay.
StateMachine.order = { S.NONE, S.DIVING, S.AIRBORNE, S.PRONE, S.GETUP }

-- The single transition table: transitions[from][event] = to.
-- "abort" is accepted from every state and always leads to NONE.
StateMachine.transitions = {
  [S.NONE] = { dive = S.DIVING },
  [S.DIVING] = { launch = S.AIRBORNE, land = S.PRONE },
  [S.AIRBORNE] = { land = S.PRONE },
  [S.PRONE] = { getUp = S.GETUP },
  [S.GETUP] = { recover = S.NONE },
}
for _, state in ipairs(StateMachine.order) do
  StateMachine.transitions[state].abort = S.NONE
end

StateMachine.defaults = {
  driverTimeoutSec = 0.5,
}

function StateMachine.new(config)
  local self = setmetatable({}, StateMachine)
  self.config = {}
  for k, v in pairs(StateMachine.defaults) do self.config[k] = v end
  for k, v in pairs(config or {}) do self.config[k] = v end
  self.listeners = {}
  self.clock = 0
  self:Reset("init")
  return self
end

-- fn(from, to, event, reason) is called after every applied state change.
function StateMachine:AddListener(fn)
  table.insert(self.listeners, fn)
end

function StateMachine:Is(state)
  return self.state == state
end

function StateMachine:IsActive()
  return self.state ~= S.NONE
end

function StateMachine:TimeInState()
  return self.clock - self.enteredAt
end

-- The state `event` would lead to from the current state, or nil if it isn't allowed.
function StateMachine:Target(event)
  local row = StateMachine.transitions[self.state]
  return row and row[event] or nil
end

function StateMachine:Can(event)
  return self:Target(event) ~= nil
end

function StateMachine:_enter(to, event, reason)
  local from = self.state
  self.state = to
  self.enteredAt = self.clock
  self.lastDriven = self.clock
  self.lastTransition = { from = from, to = to, event = event, reason = reason, time = self.clock }
  if from ~= to then
    for _, fn in ipairs(self.listeners) do
      local ok, err = pcall(fn, from, to, event, reason)
      if not ok then print("[ShootDodge] state listener error: " .. tostring(err)) end
    end
  end
end

-- Apply `event`. Returns true and the new state on success, or false and nil when the event is
-- not allowed from the current state (recorded in lastRejected for the overlay).
function StateMachine:Fire(event, reason)
  local to = self:Target(event)
  if to == nil then
    self.lastRejected = { from = self.state, event = event, time = self.clock }
    return false, nil
  end
  self:_enter(to, event, reason)
  return true, to
end

-- Called every frame by the mechanic that owns the current state, to say it is still driving it.
function StateMachine:Drive()
  self.lastDriven = self.clock
end

-- Advance the machine's clock (call once per onUpdate) and apply the driver-timeout safety net.
function StateMachine:Update(deltaTime)
  self.clock = self.clock + (deltaTime or 0)
  if self.state ~= S.NONE and self.clock - self.lastDriven > self.config.driverTimeoutSec then
    self:_enter(S.NONE, "abort", "no mechanic driving " .. self.state)
  end
end

-- Force NONE (on load, shutdown, mod disable, or an unexpected error).
function StateMachine:Reset(reason)
  if self.state ~= nil and self.state ~= S.NONE then
    self:_enter(S.NONE, "abort", reason or "reset")
  else
    self.state = S.NONE
    self.enteredAt = self.clock
    self.lastDriven = self.clock
  end
  self.lastRejected = nil
end

return StateMachine
