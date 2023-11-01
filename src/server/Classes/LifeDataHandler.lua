local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)
local DataCrunchService = require(ServerScriptService.Server.Services.DataCrunchService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponService = require(ServerScriptService.Server.Services.WeaponService)

local LifeDataHandler = {}
LifeDataHandler.__index = LifeDataHandler

function LifeDataHandler.new(player)
	local self = setmetatable({
		_player = player,
		_didDie = false,
		_power = CurrencyService:getCurrency(player, "power"),
		_kills = CurrencyService:getCurrency(player, "kills"),
		_time = os.time(),
		_weaponId = nil,
		_trove = Trove.new(),
		_destroyed = false,
	}, LifeDataHandler)

	Promise.new(function(resolve)
		repeat
			local weapon = WeaponService:getEquippedWeapon(player)
			if weapon then
				resolve(weapon)
			else
				task.wait()
			end
		until weapon
	end)
		:timeout(5)
		:andThen(function(weapon)
			self._weaponId = weapon.definition.id
		end)
		:catch(function() end)

	-- clean up on player leave
	self._trove:AddPromise(Promise.fromEvent(Players.PlayerRemoving, function(leavingPlayer)
		return leavingPlayer == player
	end):andThen(function()
		self:destroy()
	end))

	-- clean up on respawn after the current character dies
	-- don't clean up on death since the player may have meaningful
	-- actions while they're a ragdoll (earning power, killing, etc.)
	self._trove:AddPromise(Promise.new(function(resolve)
		if player.Character then
			resolve(player.Character)
		else
			resolve(Promise.fromEvent(player.CharacterAdded))
		end
	end)
		:timeout(5)
		:andThen(function()
			return Promise.fromEvent(player.CharacterAdded)
		end)
		:andThen(function()
			self._didDie = true
			self:destroy()
		end)
		:catch(function() end))

	return self
end

function LifeDataHandler:destroy()
	if self._destroyed then return end
	self._destroyed = true

	self._trove:Clean()

	local powerEarned = CurrencyService:getCurrency(self._player, "power") - self._power
	if powerEarned > 0 then
		DataCrunchService:resourceSourced(self._player, {
			currency = "power",
			amount = powerEarned,
			itemType = "battle",
			itemId = "power",
		})

		if self._weaponId then DataCrunchService:custom(self._player, `weapon:earnedPower:{self._weaponId}`, powerEarned) end
	end

	local killsEarned = CurrencyService:getCurrency(self._player, "kills") - self._kills
	if killsEarned > 0 then
		DataCrunchService:resourceSourced(self._player, {
			currency = "kills",
			amount = killsEarned,
			itemType = "battle",
			itemId = "kills",
		})

		if self._weaponId then DataCrunchService:custom(self._player, `weapon:killed:{self._weaponId}`, killsEarned) end
	end

	local duration = os.time() - self._time
	if duration > 0 then
		if self._weaponId then DataCrunchService:custom(self._player, `weapon:usedForTime:{self._weaponId}`, duration) end
	end

	if self._didDie then
		if self._weaponId then DataCrunchService:custom(self._player, `weapon:diedWith:{self._weaponId}`) end
	end
end

return LifeDataHandler
