-- GetUpDriver: CET glue for the get-up recovery from prone (C2SD-T12).
--
-- Two ways into the get-up (modules/GetUp.lua has the rules): a fresh stand press, detected by the
-- prone mechanic (C2SD-T11) and handed over through ProneDriver.onStandRequest (init.lua points it
-- at GetUpDriver.OnStandRequest); or movement held through the landing (C2SD-T10's landing record),
-- watched here, which starts the get-up right after the impact beat. Either way it fires
-- PRONE -> GETUP, gives V a small scramble push in the held movement direction (the game's own
-- PSMImpulse, camera relative like the dive), and drives GETUP:
-- V's horizontal speed is held under the scramble cap so normal movement control only returns
-- when the scramble completes, then it fires GETUP -> NONE (recover).
--
-- PRONE itself is owned and driven by the prone-and-shoot mechanic (C2SD-T11, ProneDriver): V stays
-- down with no timer, and ProneDriver fires PRONE -> GETUP on a fresh move press. This driver
-- adds the case ProneDriver leaves to it (movement held at impact: up right after the impact beat,
-- no fresh press) and, however GETUP was entered, runs the scramble and the recovery, so the two
-- never race. The eye rises back to standing height over the scramble (init.lua matches
-- ProneDriver's raise time to `durationSec`); the camera stays first person throughout.
--
-- Listeners (AddListener) get ("start", cause) as the scramble begins and ("done") when it ends,
-- and `rules:Progress()` is the eased 0..1 rise, for a stance/pose layer to follow.

local GetUp = require("modules/GetUp")

local GetUpDriver = {
  rules = GetUp.new(),
  proneSince = nil, -- machine.enteredAt of the prone episode being watched
  getUpSince = nil, -- machine.enteredAt of the GETUP the current scramble belongs to
  lastPos = nil,
  lastStart = nil, -- { cause, time } of the most recent get-up, for the overlay
  lastError = nil,
  getUpCount = 0,
  listeners = {},
  -- Injected from init.lua: the held movement axes (x, y) and the most recent landing record
  -- (C2SD-T10).
  moveAxes = function() return 0, 0 end,
  lastLanding = function() return nil end,
}

-- fn(phase, cause): phase is "start" (cause = GetUp.Cause.*) or "done".
function GetUpDriver.AddListener(fn)
  table.insert(GetUpDriver.listeners, fn)
end

local function notify(phase, cause)
  for _, fn in ipairs(GetUpDriver.listeners) do
    local ok, err = pcall(fn, phase, cause)
    if not ok then print("[ShootDodge] get-up listener error: " .. tostring(err)) end
  end
end

local function cameraForward(player)
  local ok, fwd = pcall(function() return Game.GetCameraSystem():GetActiveCameraForward() end)
  if ok and fwd ~= nil then return fwd.x, fwd.y end
  ok, fwd = pcall(function() return player:GetWorldForward() end)
  if ok and fwd ~= nil then return fwd.x, fwd.y end
  return nil, nil
end

local function queueImpulse(player, x, y, z)
  local ok, err = pcall(function()
    local evt = PSMImpulse.new()
    evt.id = "impulse"
    evt.impulse = Vector4.new(x, y, z, 0)
    player:QueueEvent(evt)
  end)
  if not ok then GetUpDriver.lastError = "impulse: " .. tostring(err) end
  return ok
end

local function worldPosition(player)
  local ok, pos = pcall(function() return player:GetWorldPosition() end)
  if ok and pos ~= nil then return { x = pos.x, y = pos.y } end
  return nil
end

-- Begin the scramble. From PRONE it fires getUp itself; when another mechanic already moved the
-- state to GETUP it just takes the scramble over. Returns whether the get-up started.
local function startGetUp(machine, cause)
  local rules = GetUpDriver.rules
  if machine:Is("PRONE") and not machine:Fire("getUp", cause) then return false end
  local player = Game.GetPlayer()
  local mx, my = GetUpDriver.moveAxes()
  local fx, fy = nil, nil
  if player ~= nil then fx, fy = cameraForward(player) end
  local push = rules:Start(mx, my, fx, fy)
  if push and player ~= nil then queueImpulse(player, push.x, push.y, push.z) end
  GetUpDriver.lastPos = player ~= nil and worldPosition(player) or nil
  GetUpDriver.getUpSince = machine.enteredAt
  GetUpDriver.getUpCount = GetUpDriver.getUpCount + 1
  GetUpDriver.lastStart = { cause = cause, time = machine.clock }
  notify("start", cause)
  return true
end

-- ProneDriver.onStandRequest (C2SD-T11 hands PRONE over on a fresh move press). Returns what
-- machine:Fire would, so ProneDriver keeps re-asking if the state machine refused.
function GetUpDriver.OnStandRequest(machine, reason)
  if not machine:Is("PRONE") then return false, nil end
  if startGetUp(machine, reason) then return true, machine.state end
  return false, nil
end

local function updateScramble(machine, deltaTime)
  local rules = GetUpDriver.rules
  machine:Drive()
  local player = Game.GetPlayer()
  if player ~= nil then
    local pos = worldPosition(player)
    if pos and GetUpDriver.lastPos and deltaTime and deltaTime > 0 then
      local vx = (pos.x - GetUpDriver.lastPos.x) / deltaTime
      local vy = (pos.y - GetUpDriver.lastPos.y) / deltaTime
      local cx, cy = rules:SpeedLimit(vx, vy)
      if cx then queueImpulse(player, cx, cy, 0) end
    end
    GetUpDriver.lastPos = pos
  end
  if rules:UpdateScramble(deltaTime) then
    GetUpDriver.lastPos = nil
    machine:Fire("recover", "on their feet")
    notify("done")
  end
end

-- Call every onUpdate while the mod is enabled (after DiveDriver.Update, so a landing this frame is
-- seen at once).
function GetUpDriver.Update(machine, deltaTime)
  local rules = GetUpDriver.rules
  if machine:Is("PRONE") then
    if GetUpDriver.proneSince ~= machine.enteredAt then
      GetUpDriver.proneSince = machine.enteredAt
      rules:OnProne(GetUpDriver.lastLanding())
    end
    local cause = rules:UpdateProne(deltaTime)
    if cause then startGetUp(machine, cause) end
    return
  end
  GetUpDriver.proneSince = nil
  if machine:Is("GETUP") then
    if not rules.active and GetUpDriver.getUpSince ~= machine.enteredAt then
      -- GETUP entered some other way (e.g. ProneDriver's default hook): run the scramble anyway.
      local last = machine.lastTransition
      startGetUp(machine, last and last.reason or GetUp.Cause.moveInput)
    end
    if rules.active then
      updateScramble(machine, deltaTime)
      return
    end
  end
  -- Anything else (reset, abort, driver timeout) took the state away: let go.
  if rules.active or rules.watching then GetUpDriver.Cancel() end
end

function GetUpDriver.Cancel()
  local wasActive = GetUpDriver.rules.active
  GetUpDriver.rules:Clear()
  GetUpDriver.proneSince = nil
  GetUpDriver.lastPos = nil
  if wasActive then notify("done") end
end

return GetUpDriver
