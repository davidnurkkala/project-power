local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Loader = require(ReplicatedStorage.Shared.Loader)
local ProductDefinitions = require(ReplicatedStorage.Shared.Data.ProductDefinitions)
local ProductHelper = require(ReplicatedStorage.Shared.Util.ProductHelper)
local Signal = require(ReplicatedStorage.Packages.Signal)

local ProductController = {}
ProductController.className = "ProductController"
ProductController.priority = 0

ProductController.shopOpened = Signal.new()

function ProductController:init() end

function ProductController:start()
	self._comm = Comm.ClientComm.new(ReplicatedStorage, true, "ProductService")

	self.purchaseProduct = self._comm:GetFunction("purchaseProduct")
	self.equipProduct = self._comm:GetFunction("equipProduct")
	self.unequipProduct = self._comm:GetFunction("unequipProduct")
	self.productData = self._comm:GetProperty("productData")
end

function ProductController:isKindEquipped(kind)
	return self.productData:OnReady():andThen(function(data)
		return data.equipped[kind] ~= nil
	end)
end

function ProductController:isEquipped(productable)
	return self.productData:OnReady():andThen(function(data)
		if ProductDefinitions[productable.kind].isMultiEquip then
			if not data.equipped[productable.kind] then return false end
			return data.equipped[productable.kind][productable.id] == true
		else
			return data.equipped[productable.kind] == productable.id
		end
	end)
end

function ProductController:isPurchased(productable)
	local key = ProductHelper.getProductKey(productable)

	return self.productData:OnReady():andThen(function(data)
		return data.owned[key] == true
	end)
end

return Loader:registerSingleton(ProductController)
