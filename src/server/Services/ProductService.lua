local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BoosterService = require(ServerScriptService.Server.Services.BoosterService)
local Comm = require(ReplicatedStorage.Packages.Comm)
local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local CurrencyService = require(ServerScriptService.Server.Services.CurrencyService)
local DataCrunchService = require(ServerScriptService.Server.Services.DataCrunchService)
local DataStore2 = require(ServerScriptService.ServerPackages.DataStore2)
local Loader = require(ReplicatedStorage.Shared.Loader)
local ProductDefinitions = require(ReplicatedStorage.Shared.Data.ProductDefinitions)
local ProductHelper = require(ReplicatedStorage.Shared.Util.ProductHelper)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)

type Productable = { id: string, kind: string }

local DATA_KEY = "ProductData"
DataStore2.Combine(Configuration.DataStoreKey, DATA_KEY)

local DEFAULT_PRODUCT_DATA = {
	owned = {},
	equipped = {},
}

local ProductService = {}
ProductService.className = "ProductService"
ProductService.priority = 0

ProductService._assetPurchased = Signal.new()
ProductService._assetRejected = Signal.new()

function ProductService:init() end

function ProductService:start()
	MarketplaceService.ProcessReceipt = function(info)
		local player = Players:GetPlayerByUserId(info.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

		local assetId = info.ProductId
		if not assetId then
			self._assetRejected:Fire(player)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local product = self:findProductByAssetId(assetId)
		if not product then
			self._assetRejected:Fire(player, assetId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local store = DataStore2(DATA_KEY, player)
		if not store then
			self._assetRejected:Fire(player, assetId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local data = store:Get(DEFAULT_PRODUCT_DATA)
		if not data then
			self._assetRejected:Fire(player, assetId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		DataCrunchService:processReceipt(info)

		if product.kind == "currency" then
			CurrencyService:addCurrency(player, "premium", product.amount)

			DataCrunchService:resourceSourced(player, {
				currency = "premium",
				amount = product.amount,
				itemType = "robux",
				itemId = `premium{product.amount}`,
			})
		else
			local key = ProductHelper.getProductKey(product)
			data.owned[key] = true
			store:Set(data)
		end

		self._assetPurchased:Fire(player, assetId)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	self._comm = Comm.ServerComm.new(ReplicatedStorage, "ProductService")

	self._comm:BindFunction("purchaseProduct", function(player, productable)
		return self:purchaseProduct(player, productable)
			:catch(function()
				warn(`Something went wrong with {player} buying {ProductHelper.getProductKey(productable)}!`)
			end)
			:await()
	end)

	self._comm:BindFunction("equipProduct", function(player, productable)
		return self:equipProduct(player, productable):await()
	end)

	self._comm:BindFunction("unequipProduct", function(player, productable)
		return self:unequipProduct(player, productable):await()
	end)

	self._productData = self._comm:CreateProperty("productData", DEFAULT_PRODUCT_DATA)

	local function onPlayerAdded(player)
		local store = DataStore2(DATA_KEY, player)
		local function update()
			self._productData:SetFor(player, store:Get(DEFAULT_PRODUCT_DATA))
		end
		store:OnUpdate(update)
		update()
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Sift.Array.map(Players:GetPlayers(), onPlayerAdded)
end

function ProductService:findProductByAssetId(assetId: number)
	for _, category in ProductDefinitions do
		for _, product in category.products do
			if product.assetId == assetId then return product end
		end
	end
	return nil
end

function ProductService:getEquipped(player: Player, kind: string)
	local store = DataStore2(DATA_KEY, player)
	local data = store:Get(DEFAULT_PRODUCT_DATA)

	return data.equipped[kind]
end

function ProductService:equipProduct(player: Player, productable: Productable)
	local key = ProductHelper.getProductKey(productable)

	local store = DataStore2(DATA_KEY, player)
	local data = store:Get(DEFAULT_PRODUCT_DATA)

	if not data.owned[key] then return Promise.reject() end

	if ProductDefinitions[productable.kind].isMultiEquip then
		if not data.equipped[productable.kind] then data.equipped[productable.kind] = {} end
		data.equipped[productable.kind][productable.id] = true
	else
		data.equipped[productable.kind] = productable.id
	end
	store:Set(data)

	return Promise.resolve()
end

function ProductService:isOwned(player: Player, productable: Productable)
	local key = ProductHelper.getProductKey(productable)

	local store = DataStore2(DATA_KEY, player)
	local data = store:Get(DEFAULT_PRODUCT_DATA)

	return data.owned[key]
end

function ProductService:unequipProduct(player: Player, productable: Productable)
	local store = DataStore2(DATA_KEY, player)
	local data = store:Get(DEFAULT_PRODUCT_DATA)

	if ProductDefinitions[productable.kind].isMultiEquip then
		if not data.equipped[productable.kind] then return end
		data.equipped[productable.kind][productable.id] = nil
		if not next(data.equipped[productable.kind]) then data.equipped[productable.kind] = nil end
	else
		data.equipped[productable.kind] = nil
	end
	store:Set(data)

	return Promise.resolve()
end

function ProductService:awaitPurchase(buyer: Player, boughtAssetId: number)
	MarketplaceService:PromptProductPurchase(buyer, boughtAssetId)

	return Promise.race({
		Promise.fromEvent(self._assetRejected, function(player, assetId)
			if assetId == nil then
				return player == buyer
			else
				return (player == buyer) and (assetId == boughtAssetId)
			end
		end):andThen(function()
			return Promise.reject()
		end),
		Promise.fromEvent(self._assetPurchased, function(player, assetId)
			return (player == buyer) and (assetId == boughtAssetId)
		end),
		Promise.fromEvent(MarketplaceService.PromptProductPurchaseFinished, function(userId, assetId)
			return (buyer.UserId == userId) and (assetId == boughtAssetId)
		end):andThen(function()
			return Promise.resolve()
		end),
	})
end

function ProductService:purchaseCurrency(player, product)
	return self:awaitPurchase(player, product.assetId)
end

function ProductService:purchaseProduct(player: Player, productable: Productable)
	local product = ProductDefinitions[productable.kind].products[productable.id]

	if product.kind == "currency" then return self:purchaseCurrency(player, product) end

	local key = ProductHelper.getProductKey(product)

	local store = DataStore2(DATA_KEY, player)
	local data = store:Get(DEFAULT_PRODUCT_DATA)

	if data.owned and data.owned[key] then
		warn(`Player {player} already owns product {key}`)
		return Promise.resolve()
	end

	return Promise.new(function(resolve)
		if product.assetId then
			resolve(self:awaitPurchase(player, product.assetId))
		else
			resolve(product.getPrice():andThen(function(price, currencyType)
				if currencyType == "premium" then
					local success = CurrencyService:spendCurrency(player, "premium", price)
					if not success then return Promise.resolve(false, "insufficientCurrency") end
				else
					error(`Attempted to purchase product {key} with unsupported currency type {currencyType}`)
				end

				DataCrunchService:resourceSunk(player, {
					currency = "premium",
					amount = price,
					itemType = "shop",
					itemId = key,
				})

				if product.kind == "booster" then
					BoosterService:boostPlayer(player, product.amount)
					return Promise.resolve(true)
				end

				data.owned[key] = true
				store:Set(data)

				return Promise.resolve(true)
			end))
		end
	end)
end

function ProductService:giveProduct(player: Player, productable: Productable)
	if self:isOwned(player, productable) then return Promise.reject() end

	local key = ProductHelper.getProductKey(productable)

	local store = DataStore2(DATA_KEY, player)
	local data = store:Get(DEFAULT_PRODUCT_DATA)

	data.owned[key] = true
	store:Set(data)

	return Promise.resolve()
end

return Loader:registerSingleton(ProductService)
