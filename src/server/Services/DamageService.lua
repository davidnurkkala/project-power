local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)
local DamageTracker = require(ServerScriptService.Server.Classes.DamageTracker)
local ProductService = require(ServerScriptService.Server.Services.ProductService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)
local WeaponService = require(ServerScriptService.Server.Services.WeaponService)

local Damage = require(ReplicatedStorage.Shared.Classes.Damage)
local EventStream = require(ReplicatedStorage.Shared.Singletons.EventStream)
local InBattleHelper = require(ReplicatedStorage.Shared.Util.InBattleHelper)
local Loader = require(ReplicatedStorage.Shared.Loader)
local ProductDefinitions = require(ReplicatedStorage.Shared.Data.ProductDefinitions)
local Signal = require(ReplicatedStorage.Packages.Signal)
local WeaponLeaderboards = require(ReplicatedStorage.Shared.Singletons.WeaponLeaderboards)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)
local pickRandom = require(ReplicatedStorage.Shared.Util.pickRandom)

local DamageService = {}
DamageService.className = "DamageService"
DamageService.priority = 0

DamageService.willDealDamage = Signal.new()
DamageService.damageDealt = Signal.new()

function DamageService:init()
	self._damageTrackersByTarget = {}

	self._comm = Comm.ServerComm.new(ReplicatedStorage, "DamageService")
	self._damageDealtRemote = self._comm:CreateSignal("DamageDealt")
	self._playerKilled = self._comm:CreateSignal("PlayerKilled")
	self._killImageRequested = self._comm:CreateSignal("KillImageRequested")
end

function DamageService:start()
	DamageService.damageDealt:Connect(function(damage)
		CurrencyService:processDamage(damage)

		if not damage.didKill then return end

		local sourcePlayer = damage:getSourcePlayer()
		local targetPlayer = damage:getTargetPlayer()

		self:_tryKillImage(sourcePlayer, targetPlayer)

		if not sourcePlayer then
			if targetPlayer then self._playerKilled:FireAll({ Name = damage.source.Parent.Name }, targetPlayer) end
			return
		end

		self:_tryKillSound(sourcePlayer, damage.target)

		local tracker = self:getDamageTracker(damage.target)
		local mostRecent = tracker:getMostRecent()
		local mostDamage = tracker:getMostDamage()
		if not (mostRecent or mostDamage) then return end

		local sources = if mostRecent == mostDamage then { mostRecent } else { mostRecent, mostDamage }
		for _, source in sources do
			if targetPlayer then
				self:_tryAddScore(source)
				EventStream:event("PlayerKilled", { killer = source, target = targetPlayer })
				self._playerKilled:FireAll(source, targetPlayer)
			else
				self._playerKilled:FireAll(source, { Name = damage.target.Parent.Name })
			end
		end
	end)
end

function DamageService:_tryAddScore(player: Player)
	local weapon = WeaponService:getEquippedWeapon(player)
	if not weapon then return end
	local id = weapon.definition.id

	WeaponLeaderboards:getLeaderboard(id):addScore(player, 1)
end

function DamageService:_tryKillSound(killer: Player, target: Damage.DamageTarget)
	local part = WeaponUtil.getTargetRoot(target)
	if not part then return end

	local killSoundSet = ProductService:getEquipped(killer, "killSound")
	if not killSoundSet then return end

	local killSounds = Sift.Set.toArray(killSoundSet)
	local killSound = pickRandom(killSounds)

	local sound = Instance.new("Sound")
	sound.Name = "KillSound"
	sound.SoundId = ProductDefinitions.killSound.products[killSound].soundId
	sound.Parent = part
	sound.Volume = 0.8
	sound:Play()
	task.delay(10, sound.Destroy, sound)
end

function DamageService:_tryKillImage(killer: Player, target: Player)
	if not target then return end
	if not killer then
		self._killImageRequested:Fire(target, "DEFAULT")
		return
	end

	local killImageSet = ProductService:getEquipped(killer, "killImage")
	if not killImageSet then
		self._killImageRequested:Fire(target, "DEFAULT")
		return
	end

	local killImages = Sift.Set.toArray(killImageSet)
	local killImage = pickRandom(killImages)

	self._killImageRequested:Fire(target, killImage)
end

function DamageService:getDamageTracker(target: Humanoid)
	if not self._damageTrackersByTarget[target] then
		local tracker = DamageTracker.new(target)
		tracker.destroyed:Connect(function()
			self._damageTrackersByTarget[target] = nil
		end)
		self._damageTrackersByTarget[target] = tracker
	end

	return self._damageTrackersByTarget[target]
end

function DamageService:damage(args: Damage.DamageArgs)
	local damage = Damage.new(args)

	self.willDealDamage:Fire(damage)

	-- deal damage
	local sourcePlayer = damage:getSourcePlayer()
	local target = damage.target
	if target:IsA("Humanoid") then
		local targetPlayer = damage:getTargetPlayer()
		if (targetPlayer ~= nil) and (not InBattleHelper.isPlayerInBattle(targetPlayer)) then return end

		local initialHealth = target.Health
		if initialHealth <= 0 then return end

		target:TakeDamage(damage.amount)

		local realDamageDealt = initialHealth - math.max(target.Health, 0)
		if realDamageDealt <= 0 then return end

		damage.amount = realDamageDealt
		damage.didKill = target.Health <= 0

		-- ensure the target is dead, sometimes regen can
		-- pseudo revive someone in the same frame leading to
		-- double kill events that are undesirable
		if damage.didKill then target.Health = -999 end

		local tracker = self:getDamageTracker(target)
		if sourcePlayer then
			tracker:trackDamage(sourcePlayer, damage.amount)
		elseif (damage.source == nil) or (typeof(damage.source) == "table") then
			-- damage was dealt by the environment
			local mostRecent = tracker:getMostRecent()
			if mostRecent then
				-- set the damage source to the most recent damager
				damage.source = Promise.try(function()
					return mostRecent.Character.Humanoid
				end)
					:catch(function()
						-- failsafe: set damage source to target itself
						return target
					end)
					:now()
					:expect()
			else
				-- set the damage source to the target itself (they jumped off a cliff)
				damage.source = target
			end
		end
	elseif target:IsA("Model") and CollectionService:HasTag(target, "Breakable") then
		local breakable = ComponentService:getComponent(target, "Breakable")

		if not breakable then return end
		breakable:takeDamage(sourcePlayer, damage.breakPower or damage.amount)
	end

	self.damageDealt:Fire(damage)

	if not sourcePlayer then return end
	self._damageDealtRemote:Fire(sourcePlayer, target, damage.amount, damage.didKill)
end

return Loader:registerSingleton(DamageService)
