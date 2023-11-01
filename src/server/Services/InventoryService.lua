local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DataStore2 = require(ServerScriptService.ServerPackages.DataStore2)

local Comm = require(ReplicatedStorage.Packages.Comm)
local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local Loader = require(ReplicatedStorage.Shared.Loader)

-- constants
local DS2_KEY = "Inventory"
local DEFAULT_INVENTORY = {}

DataStore2.Combine(Configuration.DataStoreKey, DS2_KEY)

local InventoryService = {}
InventoryService.className = "InventoryService"
InventoryService.priority = 0

function InventoryService:init() end

function InventoryService:start()
	local serverComm = Comm.ServerComm.new(ReplicatedStorage, "InventoryService")

	local playerInventoryUpdatedSignal = serverComm:CreateSignal("PlayerInventoryUpdated")

	local function onPlayerJoin(player: Player)
		local itemStore = DataStore2(DS2_KEY, player)
		local items = itemStore:Get({})
		playerInventoryUpdatedSignal:Fire(player, items)

		DataStore2(DS2_KEY, player):OnUpdate(function(newItems)
			playerInventoryUpdatedSignal:Fire(player, newItems)
		end)
	end

	Players.PlayerAdded:Connect(onPlayerJoin)
	for _, player in Players:GetPlayers() do
		onPlayerJoin(player)
	end
end

function InventoryService:hasItem(itemId: string, player: Player): (boolean, number)
	assert(typeof(itemId) == "string", "itemId must be a string")

	local inventory = DataStore2(DS2_KEY, player)
	local items = inventory:Get(DEFAULT_INVENTORY)
	local amount = items[itemId]

	return amount ~= nil, amount or 0
end

function InventoryService:addItem(itemId: string, amount: number, player: Player)
	assert(typeof(itemId) == "string", "itemId must be a string")
	assert(typeof(amount) == "number", "amount must be a number")
	assert(math.modf(amount) == amount, "amount must be an integer")

	local inventory = DataStore2(DS2_KEY, player)
	local items = inventory:Get(DEFAULT_INVENTORY)
	if items[itemId] then
		items[itemId] = items[itemId] + amount
	else
		items[itemId] = amount
	end

	inventory:Set(items)
end

function InventoryService:removeItem(itemId: string, amount: number, player: Player)
	assert(typeof(itemId) == "string", "itemId must be a string")
	assert(typeof(amount) == "number", "amount must be a number")
	assert(math.modf(amount) == amount, "amount must be an integer")

	local inventory = DataStore2(DS2_KEY, player)
	local items = inventory:Get(DEFAULT_INVENTORY)
	if not items[itemId] then return end

	items[itemId] = items[itemId] - amount
	if items[itemId] <= 0 then items[itemId] = nil end

	inventory:Set(items)
end

return Loader:registerSingleton(InventoryService)
