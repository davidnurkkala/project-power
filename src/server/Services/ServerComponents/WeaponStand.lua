local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local WeaponLeaderboards = require(ReplicatedStorage.Shared.Singletons.WeaponLeaderboards)
local WeaponService = require(ServerScriptService.Server.Services.WeaponService)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local function getWeaponDefinitionByOrder(order)
	for _, def in WeaponDefinitions do
		if def.order == order then return def end
	end
	return nil
end

local WeaponStand = {}
WeaponStand.__index = WeaponStand

function WeaponStand.new(object)
	local order = object:GetAttribute("Order")
	if order then
		local def = getWeaponDefinitionByOrder(order)
		if def then
			object.Name = def.id
		else
			object:Destroy()
			return
		end
	end

	local self = setmetatable({
		_object = object,
		_trove = Trove.new(),
		_weaponDefinition = WeaponUtil.getWeaponDefinition(object.Name),
	}, WeaponStand)

	self._serverComm = self._trove:Construct(Comm.ServerComm, object, "WeaponStand")

	self._ownedProperty = self._serverComm:CreateProperty("Owned", false)
	self._newProperty = self._serverComm:CreateProperty("New", false)
	self._selectedProperty = self._serverComm:CreateProperty("Selected", false)
	self._leaderboardProperty = self._serverComm:CreateProperty("Leaderboard", nil)

	self._selectRequested = self._serverComm:CreateSignal("SelectRequested")

	local function setPropertiesForPlayer(player: Player)
		self._ownedProperty:SetFor(player, WeaponService:getOwnsWeapon(player, self._weaponDefinition.id))
		self._selectedProperty:SetFor(player, WeaponService:getSelectedWeapon(player) == self._weaponDefinition.id)
		self:_updateNew(player)
	end
	for _, player in Players:GetPlayers() do
		setPropertiesForPlayer(player)
	end
	self._trove:Connect(Players.PlayerAdded, setPropertiesForPlayer)

	self._trove:Add(task.spawn(function()
		local leaderboard = WeaponLeaderboards:getLeaderboard(self._weaponDefinition.id)
		while true do
			local data = leaderboard:get():expect()
			if not Sift.Array.equalsDeep(data, self._leaderboardProperty:Get()) then self._leaderboardProperty:Set(data) end
			task.wait(10)
		end
	end))

	self._trove:Connect(WeaponService.playerUnlockedWeapon, function(player: Player, weaponId: string)
		if weaponId ~= self._weaponDefinition.id then return end

		self._ownedProperty:SetFor(player, true)

		self:_updateNew(player)
	end)

	self._trove:Connect(WeaponService.playerSelectedWeapon, function(player: Player, _previousWeaponId, newWeaponId: string)
		self._selectedProperty:SetFor(player, newWeaponId == self._weaponDefinition.id)
		self:_updateNew(player)
	end)

	self._trove:Connect(self._selectRequested, function(player: Player)
		WeaponService:selectWeapon(player, self._weaponDefinition.id)
	end)

	return self
end

function WeaponStand:_updateNew(player)
	self._newProperty:SetFor(player, WeaponService:getIsNew(player, self._weaponDefinition.id))
end

function WeaponStand:OnRemoved()
	self._trove:Destroy()
end

return ComponentService:registerComponentClass(script.Name, WeaponStand)
