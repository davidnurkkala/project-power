local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local EffectService = require(ServerScriptService.Server.Services.EffectService)
local PowerUpModel = require(ServerScriptService.Server.Classes.PowerUps.PowerUpModel)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)
local destroyEmitter = require(ReplicatedStorage.Shared.Util.destroyEmitter)

local Invincibility = {}
Invincibility.__index = Invincibility

function Invincibility.new(definition, rootPart, position)
	local self = setmetatable({
		_definition = definition,
		_trove = Trove.new(),
		destroyed = Signal.new(),
	}, Invincibility)

	self._trove:Connect(self._trove:Add(PowerUpModel.new(definition.id, rootPart, position), "destroy").activated, function(player)
		self:activate(player)
	end)

	return self
end

function Invincibility:activate(player: Player)
	local root = WeaponUtil.getRoot(player)
	if not root then return end

	local human = WeaponUtil.getHuman(player)
	if not human then return end

	local trove = Trove.new()

	trove:Connect(DamageService.willDealDamage, function(damage)
		if damage.target ~= human then return end
		damage.amount = math.ceil(damage.amount * 0.25)
	end)

	local attachment = Instance.new("Attachment")
	attachment.Parent = root

	local emitter1 = ReplicatedStorage.RojoAssets.Emitters.ShieldEmitter1:Clone()
	emitter1.Parent = attachment
	emitter1:Emit(1)

	local emitter2 = ReplicatedStorage.RojoAssets.Emitters.ShieldEmitter2:Clone()
	emitter2.Parent = attachment
	emitter2:Emit(1)

	trove:Add(function()
		Promise.all({ destroyEmitter(emitter1), destroyEmitter(emitter2) }):andThenCall(attachment.Destroy, attachment)
	end)

	Promise.delay(self._definition.duration):andThenCall(trove.Clean, trove)

	EffectService:effect("sound", {
		parent = root,
		name = "PowerUp1",
	})

	self:destroy()
end

function Invincibility:destroy()
	self._trove:Clean()
	self.destroyed:Fire()
end

return Invincibility
