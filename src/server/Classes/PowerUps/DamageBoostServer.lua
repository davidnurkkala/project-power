local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local EffectService = require(ServerScriptService.Server.Services.EffectService)
local PowerUpModel = require(ServerScriptService.Server.Classes.PowerUps.PowerUpModel)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local DamageBoost = {}
DamageBoost.__index = DamageBoost

function DamageBoost.new(definition, rootPart, position)
	local self = setmetatable({
		_definition = definition,
		_trove = Trove.new(),
		destroyed = Signal.new(),
	}, DamageBoost)

	self._trove:Connect(self._trove:Add(PowerUpModel.new(definition.id, rootPart, position), "destroy").activated, function(player)
		self:activate(player)
	end)

	return self
end

function DamageBoost:activate(player)
	local char = WeaponUtil.getChar(player)
	if not char then return end
	local root = WeaponUtil.getRoot(player)
	if not root then return end

	local trove = Trove.new()

	trove:Connect(DamageService.willDealDamage, function(damage)
		if damage:getSourcePlayer() ~= player then return end
		damage.amount *= (1 + self._definition.amount)
	end)

	local attachment = Instance.new("Attachment")
	attachment.Parent = root

	local emitter = ReplicatedStorage.Assets.Emitters.DamageBoost:Clone()
	emitter.Parent = attachment

	trove:Add(function()
		emitter.Enabled = false
		task.delay(emitter.Lifetime.Max, attachment.Destroy, attachment)
	end)

	task.delay(self._definition.duration, trove.Clean, trove)

	EffectService:effect("sound", {
		parent = char.PrimaryPart,
		name = "PowerUp1",
	})

	self:destroy()
end

function DamageBoost:destroy()
	self._trove:Clean()
	self.destroyed:Fire()
end

return DamageBoost
