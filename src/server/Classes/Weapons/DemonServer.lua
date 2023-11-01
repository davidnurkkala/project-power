local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local DemonServer = {}
DemonServer.__index = DemonServer

function DemonServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,
		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown),
	}, DemonServer)

	return self
end

function DemonServer:equip()
	local character = self.player.Character
	if not character then return end

	local root = character.PrimaryPart
	if not root then return end

	local rootAttachment = root:FindFirstChild("RootRigAttachment")
	if not rootAttachment then return end

	self._cleanup = Trove.new()

	local demonSymbol = self._cleanup:Clone(ReplicatedStorage.Assets.Emitters["DemonSymbol"])
	demonSymbol.Parent = root
end

function DemonServer:destroy()
	self._cleanup:Clean()
end

function DemonServer:attack(target)
	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = 15,
	})
end

function DemonServer:special(victims)
	for _, victim in victims do
		local target = victim.target
		local direction = victim.direction :: Vector3
		if direction:FuzzyEq(Vector3.new()) then direction = Vector3.new(0, 1, 0) end

		if not WeaponUtil.isTargetInRange(self.player, target, self.definition.specialRange) then return end
		if self._specialLimiter:limitTarget(target) then return end

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = 25,
		})

		StunService:stunTarget(target, 1, direction.Unit * 150)
	end
end

function DemonServer:dash(dashEnabled: boolean)
	self._isDashing = dashEnabled
	-- TODO: (increased) i-frames on dash
end
return DemonServer
