local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local WeaponService = require(ServerScriptService.Server.Services.WeaponService)

local EventStream = require(ReplicatedStorage.Shared.Singletons.EventStream)
local Loader = require(ReplicatedStorage.Shared.Loader)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

-- constants
local ProgressionService = {}
ProgressionService.className = "ProgressionService"
ProgressionService.priority = 0

ProgressionService._playerInitialized = Signal.new()

function ProgressionService:_updateUnlockLevel(player)
	return self:getPlayerLevel(player)
		:andThen(function(currentLevel)
			local unlockedWeapons = {}
			local nextLevel = currentLevel + 1
			local nextWeapon = self._progressionTree[nextLevel]

			local currentPower = CurrencyService:getCurrency(player, "power")

			while nextWeapon do
				if currentPower < nextWeapon.price then break end

				table.insert(unlockedWeapons, nextWeapon.weaponId)

				self._playerProgression[player] = nextLevel
				nextLevel = nextLevel + 1
				nextWeapon = self._progressionTree[nextLevel]
			end
			return unlockedWeapons
		end)
		:catch(function()
			warn("Player's progression level was never set.")
			return {}
		end)
end

function ProgressionService:getPlayerLevel(player)
	return Promise.new(function(resolve)
		if self._playerProgression[player] then
			resolve(self._playerProgression[player])
		else
			resolve(Promise.fromEvent(self._playerInitialized, function(initializedPlayer)
				return initializedPlayer == player
			end):andThen(function()
				return self._playerProgression[player]
			end))
		end
	end):timeout(10)
end

function ProgressionService:getProgressToNextWeapon(player)
	return self:getPlayerLevel(player):andThen(function(level)
		local floor = 0
		local currentWeapon = self._progressionTree[level]
		if currentWeapon then floor = currentWeapon.price end

		local nextWeapon = self._progressionTree[level + 1]
		if not nextWeapon then return nil end

		local currency = CurrencyService:getCurrency(player, "power")

		local goal = nextWeapon.price - floor
		local current = currency - floor

		return {
			weaponId = nextWeapon.weaponId,
			goal = goal,
			current = current,
			percent = current / goal,
		}
	end)
end

function ProgressionService:_initializePlayer(player: Player)
	local power = CurrencyService:getCurrency(player, "power")
	local playerLevel = 1

	for level, weapon in self._progressionTree do
		local isRetroactiveUnlock = (weapon.price < power) and (not WeaponService:getOwnsWeapon(player, weapon.weaponId))
		if isRetroactiveUnlock then WeaponService:unlockWeapon(player, weapon.weaponId) end

		if power < weapon.price then break end
		playerLevel = level
	end
	self._playerProgression[player] = playerLevel

	self._playerInitialized:Fire(player)
end

function ProgressionService:init()
	self._comm = Comm.ServerComm.new(ReplicatedStorage, "ProgressionService")
	self._clientWeaponUnlocked = self._comm:CreateSignal("WeaponUnlocked")
	self._weaponProgressRemote = self._comm:CreateProperty("WeaponProgress")

	self._progressionTree = {}
	self._playerProgression = {}

	for id, definition in WeaponDefinitions do
		if definition.currency ~= "power" then continue end
		table.insert(self._progressionTree, {
			weaponId = id,
			price = definition.price,
		})
	end

	table.sort(self._progressionTree, function(a, b)
		return a.price < b.price
	end)
end

function ProgressionService:start()
	-- on player join create currencies
	Players.PlayerAdded:Connect(function(player: Player)
		self:_initializePlayer(player)

		task.spawn(function()
			while player:IsDescendantOf(game) do
				self._weaponProgressRemote:SetFor(
					player,
					self:getProgressToNextWeapon(player)
						:catch(function()
							return nil
						end)
						:expect()
				)
				task.wait(1)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		self._playerProgression[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		self:_initializePlayer(player)
	end

	CurrencyService.currencyAdded:Connect(function(player, currency)
		if currency ~= "power" then return end
		self:_updateUnlockLevel(player):andThen(function(unlockedWeapons)
			for _, weaponId in unlockedWeapons do
				WeaponService:unlockWeapon(player, weaponId)
				EventStream:event("PlayerUnlockedWeapon", { player = player, weaponId = weaponId })
				self._clientWeaponUnlocked:Fire(player, weaponId)
			end
		end)
	end)
end

return Loader:registerSingleton(ProgressionService)
