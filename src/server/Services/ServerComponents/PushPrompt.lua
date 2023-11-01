-- Server implementation of PushPrompts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)

-- consts
local PUSH_POWER = 20
local PUSH_MAX_DISTANCE = 6
local PUSH_COOLDOWN = 5

-- local DEVELOPERS = {
-- 	["324616"] = true,
-- 	["15379184"] = true,
-- 	["22741940"] = true,
-- 	["85750749"] = true,
-- 	["4021304"] = true,
-- 	["2526045425"] = true,
-- 	["5840316"] = true,
-- }

local PushPrompt = {}
PushPrompt.__index = PushPrompt

function PushPrompt:_onDeath()
	if not self._player then return end
	if not self._lastPusher then return end
end

function PushPrompt:_onPush(pusher)
	self._lastPush = tick()
	self._lastPusher = pusher

	local pusherPart = pusher.Character and pusher.Character.PrimaryPart
	local pusherPos = pusherPart and pusherPart.Position
	if not pusherPos then return end

	local pusheePos = self._object.WorldPosition
	local pushVector = (pusheePos - pusherPos).Unit

	local velocity = PUSH_POWER * pushVector + Vector3.new(0, 10, 0)

	local hum = self._object.Parent.Parent:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local deathConnection = hum.Died:Connect(function()
		self:_onDeath()
	end)

	hum.PlatformStand = true

	self._linearVelocity.VectorVelocity = velocity
	self._linearVelocity.Enabled = true
	wait(0.25)
	self._linearVelocity.Enabled = false

	wait(2)
	hum.PlatformStand = false

	wait(2)
	self._lastPusher = nil
	deathConnection:Disconnect()
end

function PushPrompt:_canPush(pusher)
	local char = pusher.Character
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not (hum and hum.Health > 0) then return false end

	local part = char.PrimaryPart
	local pos = part and part.Position

	local dist = (self._object.WorldPosition - pos).Magnitude
	if dist > PUSH_MAX_DISTANCE * 1.25 then return false end

	return true
end

function PushPrompt.new(obj)
	print("initializing prompt")
	local self = setmetatable({
		_object = obj,
		_lastPush = 0,
		_player = nil,
		_lastPusher = nil,
	}, PushPrompt)

	local character = obj.Parent.Parent
	local targetPlayer = Players:GetPlayerFromCharacter(character)
	if not targetPlayer then return self end

	self._player = targetPlayer

	-- create proximity prompt
	local newPrompt = Instance.new("ProximityPrompt")
	newPrompt.Enabled = false
	newPrompt.ActionText = "Push"
	newPrompt.ObjectText = ""
	newPrompt.MaxActivationDistance = PUSH_MAX_DISTANCE
	newPrompt.RequiresLineOfSight = false
	newPrompt.Parent = obj
	self._prompt = newPrompt

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Enabled = false
	linearVelocity.Attachment0 = obj
	linearVelocity.MaxForce = 5000
	linearVelocity.Parent = obj
	self._linearVelocity = linearVelocity

	self._promptTrigerredConnection = newPrompt.Triggered:Connect(function(player)
		if targetPlayer == player then return end
		if tick() - self._lastPush < PUSH_COOLDOWN then return end
		if not self:_canPush(player) then return end

		self:_onPush(player)
	end)

	return self
end

-- when object is untagged/deleted
function PushPrompt:OnRemoved()
	self._object = nil
	self._player = nil

	if self._promptTriggeredConnection then
		self._promptTriggeredConnection:Disconnect()
		self._promptTriggeredConnection = nil
	end
	if self._linearVelocity then self._linearVelocity:Destroy() end
	if self._prompt then self._prompt:Destroy() end
end

return ComponentService:registerComponentClass(script.Name, PushPrompt)
