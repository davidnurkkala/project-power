local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local DamageService = require(ServerScriptService.Server.Services.DamageService)
local EffectService = require(ServerScriptService.Server.Services.EffectService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local StunService = require(ServerScriptService.Server.Services.StunService)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local AbyssServer = {}
AbyssServer.__index = AbyssServer

function AbyssServer.new(player, definition)
	local self = setmetatable({
		player = player,
		definition = definition,

		_attackLimiter = HitLimiter.new(definition.attackCooldown),
		_specialLimiter = HitLimiter.new(definition.specialCooldown),

		_cursed = {},
	}, AbyssServer)
	self._model = self.definition.model:Clone()

	self._trove = Trove.new()
	self._trove:Connect(RunService.Heartbeat, function()
		local currentTime = tick()
		for character, data in self._cursed do
			local startTime = data.startTime

			if currentTime - startTime > self.definition.curseDuration then self:_removeCurse(character) end
		end
	end)
	self._trove:Add(function()
		for character, _ in self._cursed do
			self:_removeCurse(character)
		end
		self._cursed = {}
	end)

	return self
end

function AbyssServer:equip()
	local char = WeaponUtil.getChar(self.player)
	if not char then return end

	self._model.Parent = char
	WeaponUtil.attachWeapon(self.player, self._model.Handle.RightGripAttachment, "RightGripAttachment", true)
end

function AbyssServer:destroy()
	self._trove:Destroy()
end

function AbyssServer:_addCurse(character)
	if not self._cursed[character] then
		local targetPlayer = Players:GetPlayerFromCharacter(character)

		--// effect
		local upperTorso = character:FindFirstChild("UpperTorso")
		if not upperTorso then return end

		local attachment = upperTorso:FindFirstChild("BodyFrontAttachment")
		if not attachment then return end

		local guid = HttpService:GenerateGUID(false)

		--// Only visible for attacker and target to prevent confusion
		EffectService:effectPlayer(self.player, "emitter", {
			parent = attachment,
			name = "VoidCurse",
			guid = guid,
		})
		if targetPlayer then EffectService:effectPlayer(targetPlayer, "emitter", {
			parent = attachment,
			name = "VoidCurse",
			guid = guid,
		}) end

		--// data
		self._cursed[character] = {
			startTime = tick(),
			guid = guid,
			player = targetPlayer,
		}
	else
		self._cursed[character].startTime = tick()
	end
end

function AbyssServer:_removeCurse(character)
	local entry = self._cursed[character]
	if not entry then return end
	if character and character.Parent then EffectService:effectPlayer(self.player, "cancel", { guid = entry.guid }) end
	if entry.player and entry.player.Parent then EffectService:effectPlayer(entry.player, "cancel", { guid = entry.guid }) end
	self._cursed[character] = nil
end

function AbyssServer:attack(victim)
	local target = victim.target
	local direction = victim.direction :: Vector3

	if not WeaponUtil.isTargetInRange(self.player, target, self.definition.attackRange) then return end
	if self._attackLimiter:limitTarget(target) then return end

	local damage = self.definition.attackDamage
	if target:IsA("Humanoid") and self._cursed[target.Parent] then
		local targetRoot = target.Parent.PrimaryPart
		if targetRoot then
			damage = self.definition.attackDamageCursed

			EffectService:effect("hitEffect", {
				part = targetRoot,
				emitterName = "VoidSlash",
				particleCount = 2,
				soundName = "AbyssCurseHit",
				Color = Color3.fromRGB(0, 0, 42),
				pitchRange = NumberRange.new(0.95, 1.05),
			})
			EffectService:effect("sound", {
				parent = targetRoot,
				name = "AbyssDemonic",
			})
		end
	end

	DamageService:damage({
		source = WeaponUtil.getHuman(self.player),
		target = target,
		amount = damage,
	})

	local horizontalNormalized = (direction * Vector3.new(1, 0, 1)).Unit
	StunService:pushbackTarget(target, 0.1, horizontalNormalized * self.definition.attackLaunchSpeed)
end

function AbyssServer:special(victims)
	for _, victim in victims do
		local target = victim.target
		local direction = victim.direction :: Vector3
		if direction:FuzzyEq(Vector3.new()) then direction = Vector3.new(0, 1, 0) end

		if not WeaponUtil.isTargetInRange(self.player, target, self.definition.specialRadius * 2) then continue end
		if self._specialLimiter:limitTarget(target) then continue end

		local damage = self._cursed[target.Parent] and self.definition.specialCurseDamage or self.definition.specialBaseDamage

		DamageService:damage({
			source = WeaponUtil.getHuman(self.player),
			target = target,
			amount = damage,
		})

		StunService:stunTarget(target, 0.5, direction.Unit * self.definition.specialLaunchSpeed)
		if target:IsA("Humanoid") then self:_addCurse(target.Parent) end
	end
end

return AbyssServer
