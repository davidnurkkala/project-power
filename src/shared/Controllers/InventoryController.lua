local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Loader)

local InventoryController = {}
InventoryController.className = "InventoryController"
InventoryController.priority = 0

function InventoryController:init() end

function InventoryController:start() end

return Loader:registerSingleton(InventoryController)
