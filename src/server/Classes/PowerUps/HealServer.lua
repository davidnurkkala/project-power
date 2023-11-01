local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local EffectService = require(ServerScriptService.Server.Services.EffectService)
local PowerUpDefinitions = require(ReplicatedStorage.Shared.Data.PowerUpDefinitions)
local PowerUpModel = require(ServerScriptService.Server.Classes.PowerUps.PowerUpModel)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Heal = {}
Heal.__index = Heal

function Heal.heal(player)
	local amount = PowerUpDefinitions.Heal.recoveryAmount
	local duration = PowerUpDefinitions.Heal.duration
	local rate = amount / duration

	local char = player.Character
	if not char then return end
	local human = char:FindFirstChildWhichIsA("Humanoid")
	if not human then return end

	task.spawn(function()
		local emitter = ReplicatedStorage.Assets.Emitters.HealEmitter:Clone()
		emitter.Parent = char:FindFirstChild("UpperTorso")

		Promise.race({
			Promise.fromEvent(RunService.Heartbeat, function(dt)
				local healed = rate * dt
				amount -= healed
				human.Health = math.min(human.Health + healed, human.MaxHealth)
				return (human.Health >= human.MaxHealth) or (not human:IsDescendantOf(workspace)) or (amount <= 0)
			end),
			Promise.fromEvent(human.Died),
		})
			:timeout(5)
			:catch(function() end)
			:finally(function()
				emitter.Enabled = false
				task.delay(emitter.Lifetime.Max, emitter.Destroy, emitter)
			end)
	end)
end

function Heal.new(definition, rootPart, position)
	local self = setmetatable({
		_definition = definition,
		_trove = Trove.new(),
		destroyed = Signal.new(),
	}, Heal)

	self._trove:Connect(self._trove:Add(PowerUpModel.new(definition.id, rootPart, position), "destroy").activated, function(player)
		self:activate(player)
	end)

	return self
end

function Heal:activate(player)
	Heal.heal(player)

	EffectService:effect("sound", {
		parent = player.Character and player.Character.PrimaryPart,
		name = "PowerUp1",
	})

	self:destroy()
end

function Heal:destroy()
	self._trove:Clean()
	self.destroyed:Fire()
end

return Heal
