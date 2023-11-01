local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local DataCrunchService = require(ServerScriptService.Server.Services.DataCrunchService)
local DataStore2 = require(ServerScriptService.ServerPackages.DataStore2)
local Sift = require(ReplicatedStorage.Packages.Sift)

local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local EventStream = require(ReplicatedStorage.Shared.Singletons.EventStream)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Signal = require(ReplicatedStorage.Packages.Signal)
local SilenceHelper = require(ReplicatedStorage.Shared.Util.SilenceHelper)
local StunHelper = require(ReplicatedStorage.Shared.Util.StunHelper)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

-- typedefs
type WeaponData = {
	new: { [string]: boolean },
	owned: { [string]: boolean },
	selected: boolean,
}

local DS2_KEY = "WeaponData"
DataStore2.Combine(Configuration.DataStoreKey, DS2_KEY)

local DEFAULT_WEAPON_DATA: WeaponData = {
	owned = {
		["Fist"] = true,
	},
	new = {},
	selected = "Fist",
}

local SELECTED_WEAPON_ATTRIBUTE = "SelectedWeapon"

local WeaponService = {}
WeaponService.className = "WeaponService"
WeaponService.priority = 0

WeaponService.playerUnlockedWeapon = Signal.new() :: Signal.Signal<Player, string>
WeaponService.playerSelectedWeapon = Signal.new() :: Signal.Signal<Player, string, string>

WeaponService._equippedWeaponsByPlayer = {} :: { [Player]: WeaponDefinitions.WeaponServer }

function WeaponService:init() end

function WeaponService:start()
	local function onPlayerJoin(player: Player)
		local weaponStore = DataStore2(DS2_KEY, player)
		local weaponData = weaponStore:Get(DEFAULT_WEAPON_DATA) :: WeaponData
		player:SetAttribute(SELECTED_WEAPON_ATTRIBUTE, weaponData.selected)

		DataStore2(DS2_KEY, player):OnUpdate(function(newWeaponData)
			local selectedWeapon = player:GetAttribute(SELECTED_WEAPON_ATTRIBUTE)
			if selectedWeapon ~= newWeaponData.selected then
				WeaponService.playerSelectedWeapon:Fire(player, selectedWeapon, newWeaponData.selected)
				player:SetAttribute(SELECTED_WEAPON_ATTRIBUTE, newWeaponData.selected)
			end
		end)
	end

	for _, player in Players:GetPlayers() do
		onPlayerJoin(player)
	end
	Players.PlayerAdded:Connect(onPlayerJoin)

	self._comm = Comm.ServerComm.new(ReplicatedStorage, "WeaponService")
	self._weaponEquipped = self._comm:CreateSignal("WeaponEquipped")
	self._attackRequested = self._comm:CreateSignal("AttackRequested")
	self._specialRequested = self._comm:CreateSignal("SpecialRequested")
	self._dashRequested = self._comm:CreateSignal("DashRequested")
	self._customRequested = self._comm:CreateSignal("CustomRequested")

	self._attackRequested:Connect(function(player: Player, ...)
		if StunHelper.isStunned(player) then return end

		local weapon = self:getEquippedWeapon(player)
		if not weapon then return end

		weapon:attack(...)
	end)

	self._specialRequested:Connect(function(player: Player, ...)
		if StunHelper.isStunned(player) then return end
		if SilenceHelper.isSilenced(player) then return end

		local weapon = self:getEquippedWeapon(player)
		if not weapon then return end

		weapon:special(...)
	end)

	self._dashRequested:Connect(function(player: Player, ...)
		if StunHelper.isStunned(player) then return end

		local weapon = self:getEquippedWeapon(player)
		if not weapon then return end

		weapon:dash(...)
	end)

	self._customRequested:Connect(function(player, ...)
		local weapon = self:getEquippedWeapon(player)
		if not weapon then return end
		if not weapon.custom then return end

		weapon:custom(...)
	end)
end

function WeaponService:getOwnsWeapon(player: Player, weaponId: string): boolean
	local weaponStore = DataStore2(DS2_KEY, player)
	local weaponData = weaponStore:Get(DEFAULT_WEAPON_DATA) :: WeaponData

	return weaponData.owned[weaponId] or false
end

function WeaponService:getOwnedWeapons(player: Player)
	local weaponStore = DataStore2(DS2_KEY, player)
	local weaponData = weaponStore:Get(DEFAULT_WEAPON_DATA) :: WeaponData

	return Sift.Set.toArray(weaponData.owned)
end

function WeaponService:getSelectedWeapon(player: Player): string
	local weaponStore = DataStore2(DS2_KEY, player)
	local weaponData = weaponStore:Get(DEFAULT_WEAPON_DATA) :: WeaponData

	return weaponData.selected
end

function WeaponService:unlockWeapon(player: Player, weaponId: string)
	local weaponStore = DataStore2(DS2_KEY, player)
	local weaponData = weaponStore:Get(DEFAULT_WEAPON_DATA) :: WeaponData

	weaponData.owned[weaponId] = true
	weaponData.new[weaponId] = true
	weaponStore:Set(weaponData)

	self.playerUnlockedWeapon:Fire(player, weaponId)

	DataCrunchService:custom(player, `weapon:unlocked:{weaponId}`)
end

function WeaponService:selectWeapon(player: Player, weaponId: string)
	local weaponStore = DataStore2(DS2_KEY, player)
	local weaponData = weaponStore:Get(DEFAULT_WEAPON_DATA) :: WeaponData

	weaponData.selected = weaponId
	weaponData.new[weaponId] = nil
	weaponStore:Set(weaponData)

	EventStream:event("PlayerEquippedWeapon", { player = player, weaponId = weaponId })

	DataCrunchService:custom(player, `weapon:selected:{weaponId}`)
end

function WeaponService:getIsNew(player: Player, weaponId: string)
	local weaponStore = DataStore2(DS2_KEY, player)
	local weaponData = weaponStore:Get(DEFAULT_WEAPON_DATA) :: WeaponData
	return weaponData.new[weaponId] == true
end

function WeaponService:getEquippedWeapon(player: Player): WeaponDefinitions.WeaponServer?
	return self._equippedWeaponsByPlayer[player]
end

function WeaponService:unequipWeapon(player: Player)
	local weapon = self._equippedWeaponsByPlayer[player]
	if weapon then
		weapon:destroy()
		self._equippedWeaponsByPlayer[player] = nil
	end
end

function WeaponService:equipWeapon(player: Player)
	local char = player.Character
	if not char then return end
	local human = char:FindFirstChild("Humanoid")
	if not human then return end

	local id = self:getSelectedWeapon(player)
	local definition = WeaponDefinitions[id]

	local className = definition.className or id
	local source = ServerScriptService.Server.Classes.Weapons:FindFirstChild(className .. "Server")
	local class = require(source)
	local instance = class.new(player, definition) :: WeaponDefinitions.WeaponServer

	self:unequipWeapon(player)

	self._equippedWeaponsByPlayer[player] = instance

	local function onDied()
		self:unequipWeapon(player)
	end
	human.Died:Connect(onDied)
	char.AncestryChanged:Connect(function()
		if char:IsDescendantOf(workspace) then return end
		onDied()
	end)

	instance:equip()

	self._weaponEquipped:Fire(player, id)

	DataCrunchService:custom(player, `weapon:spawnedWith:{id}`)
end

return Loader:registerSingleton(WeaponService)
