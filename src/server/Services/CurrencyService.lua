-- create currencies and keep track of them

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BoosterService = require(ServerScriptService.Server.Services.BoosterService)
local Comm = require(ReplicatedStorage.Packages.Comm)
local InventoryService = require(ServerScriptService.Server.Services.InventoryService)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Signal = require(ReplicatedStorage.Packages.Signal)
local StarterPackHelper = require(ServerScriptService.Server.Util.StarterPackHelper)

local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local EventStream = require(ReplicatedStorage.Shared.Singletons.EventStream)

-- typedefs
type CurrencyType = CurrencyDefinitions.CurrencyType

-- consts
local DAMAGE_CURRENCY: CurrencyType = "power"
local KILL_CURRENCY: CurrencyType = "kills"

local DAMAGE_CONVERSION = 1

local CurrencyService = {}
CurrencyService.className = "CurrencyService"
CurrencyService.priority = 0

CurrencyService.currencyAdded = Signal.new() :: Signal.Signal<(player: Player, currency: CurrencyType, amount: number) -> ()>
CurrencyService.currencyChanged = Signal.new() :: Signal.Signal<(player: Player, currency: CurrencyType) -> ()>

function CurrencyService:_initializePlayer(player: Player)
	for currencyName, currencyDefinition in CurrencyDefinitions do
		local hasCurrency, amount = InventoryService:hasItem(currencyName, player)
		if not hasCurrency then
			amount = currencyDefinition.initialValue
			InventoryService:addItem(currencyName, amount, player)
		end
		self._remoteProperties[currencyName]:SetFor(player, amount)
	end

	self._playerFractionalPower[player] = 0
end

function CurrencyService:_updateClientCurrency(player: Player, currency: CurrencyType)
	local amount = self:getCurrency(player, currency)
	self._remoteProperties[currency]:SetFor(player, amount)
end

function CurrencyService:processDamage(damage)
	if damage.target == damage.source then return end

	local baseMultiplier = damage:getCurrencyMultiplier()
	if baseMultiplier == 0 then return end

	local sourcePlayer = damage:getSourcePlayer()
	if not sourcePlayer then return end

	local powerAdded = damage.amount * DAMAGE_CONVERSION * baseMultiplier

	local multiplier = 1

	-- +25% for having the starter pack
	if StarterPackHelper.isOwned(sourcePlayer) then
		multiplier += 0.25
	end

	-- boost active?
	if BoosterService:isActive(sourcePlayer) then
		multiplier += 1
	end

	powerAdded *= multiplier

	local fractionalPower = self._playerFractionalPower[sourcePlayer]
	local currencyGenerated, remainder = math.modf(fractionalPower + powerAdded)
	self._playerFractionalPower[sourcePlayer] = remainder

	if currencyGenerated == 0 then return end
	self:addCurrency(sourcePlayer, DAMAGE_CURRENCY, currencyGenerated)

	if damage.didKill then self:addCurrency(sourcePlayer, KILL_CURRENCY, 1) end
end

function CurrencyService:init()
	self._comm = Comm.ServerComm.new(ReplicatedStorage, "CurrencyService")
	self._comm:CreateSignal("CurrencyUpdated")

	self._playerFractionalPower = {}

	self._remoteProperties = {}
	for currencyName, _currencyDefinition in CurrencyDefinitions do
		self._remoteProperties[currencyName] = self._comm:CreateProperty(currencyName, 0)
	end
end

function CurrencyService:start()
	-- on player join create currencies
	Players.PlayerAdded:Connect(function(player: Player)
		self:_initializePlayer(player)
	end)
	for _, player in Players:GetPlayers() do
		self:_initializePlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		self._playerFractionalPower[player] = nil
	end)
end

function CurrencyService:getCurrency(player: Player, currency: CurrencyType): number
	assert(CurrencyDefinitions[currency], `CurrencyService.getCurrency() | Invalid currency "{currency}."`)
	local _hasCurrency, currencyAmount = InventoryService:hasItem(currency, player)
	return currencyAmount
end

function CurrencyService:addCurrency(player: Player, currency: CurrencyType, amount: number)
	assert(CurrencyDefinitions[currency], `CurrencyService.addCurrency() | Invalid currency "{currency}."`)
	assert(amount > 0, `CurrencyService.addCurrency() | amount must be positive.`)
	if math.modf(amount) ~= amount then
		warn(`CurrencyService.spendCurrency() | currency amount should be an integer, rounding down.`)
		amount = math.floor(amount)
	end

	InventoryService:addItem(currency, amount, player)
	self:_updateClientCurrency(player, currency)

	self.currencyAdded:Fire(player, currency, amount)
	self.currencyChanged:Fire(player, currency)

	if currency == "power" then EventStream:event("PowerEarned", {
		player = player,
		amount = amount,
	}) end
end

-- returns true if transaction was successful
function CurrencyService:spendCurrency(player: Player, currency: CurrencyType, amount: number): boolean
	assert(CurrencyDefinitions[currency], `CurrencyService.spendCurrency() | Invalid currency "{currency}."`)
	assert(amount > 0, `CurrencyService.spendCurrency() | amount must be positive.`)
	if math.modf(amount) ~= amount then
		warn(`CurrencyService.spendCurrency() | currency amount should be an integer, rounding down.`)
		amount = math.floor(amount)
	end

	local _hasCurrency, currencyAmount = InventoryService:hasItem(currency, player)
	if currencyAmount < amount then return false end
	if CurrencyDefinitions[currency].canSpend then
		InventoryService:removeItem(currency, amount, player)
		self:_updateClientCurrency(player, currency)
		self.currencyChanged:Fire(player, currency)
	end
	return true
end

return Loader:registerSingleton(CurrencyService)
