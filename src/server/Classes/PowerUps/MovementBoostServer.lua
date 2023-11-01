local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local EffectService = require(ServerScriptService.Server.Services.EffectService)
local PowerUpModel = require(ServerScriptService.Server.Classes.PowerUps.PowerUpModel)
local PowerUpService = require(ServerScriptService.Server.Services.PowerUpService)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local MovementBoost = {}
MovementBoost.__index = MovementBoost

function MovementBoost.new(definition, rootPart, position)
	local self = setmetatable({
		_definition = definition,
		_trove = Trove.new(),
		destroyed = Signal.new(),
	}, MovementBoost)

	self._trove:Connect(self._trove:Add(PowerUpModel.new(definition.id, rootPart, position), "destroy").activated, function(player)
		self:activate(player)
	end)

	return self
end

function MovementBoost:activate(player)
	local char = WeaponUtil.getChar(player)
	if not char then return end

	PowerUpService.powerUpActivated:Fire(player, self._definition.id)

	local emitter = ReplicatedStorage.Assets.Emitters.MovementBoostEmitter:Clone()
	emitter.Parent = char:FindFirstChild("UpperTorso")

	local trail = ReplicatedStorage.Assets.Trails.MovementBoostTrail:Clone()
	trail.Parent = char.PrimaryPart
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = char.PrimaryPart
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = char.PrimaryPart
	trail.Attachment0 = a0
	trail.Attachment1 = a1

	task.delay(self._definition.duration, function()
		emitter.Enabled = false
		task.delay(emitter.Lifetime.Max, emitter.Destroy, emitter)

		trail.Enabled = false
		task.delay(trail.Lifetime, function()
			trail:Destroy()
			a0:Destroy()
			a1:Destroy()
		end)
	end)

	EffectService:effect("sound", {
		parent = char.PrimaryPart,
		name = "PowerUp1",
	})

	self:destroy()
end

function MovementBoost:destroy()
	self._trove:Clean()
	self.destroyed:Fire()
end

return MovementBoost
