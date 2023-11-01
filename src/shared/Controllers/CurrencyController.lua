local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Comm = require(ReplicatedStorage.Packages.Comm)
local Loader = require(ReplicatedStorage.Shared.Loader)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)

local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)

local CurrencyController = {}
CurrencyController.className = "CurrencyController"
CurrencyController.priority = 0

CurrencyController.currencyUpdated = Signal.new() :: Signal.Signal<string, number>

function CurrencyController:init()
	self._currencies = {}
	self._currencyProperties = {} :: { [CurrencyDefinitions.CurrencyType]: any }
	self._currencyUpdaters = {}
	self._currencyInitialized = Signal.new()
end

function CurrencyController:start()
	self._comm = Comm.ClientComm.new(ReplicatedStorage, true, "CurrencyService")

	-- get remote properties using currency definitions
	for currencyName, _currencyDefinition in CurrencyDefinitions do
		local remoteProperty = self._comm:GetProperty(currencyName)
		self._currencyProperties[currencyName] = remoteProperty
		self._currencyUpdaters[currencyName] = remoteProperty:Observe(function(value)
			self._currencies[currencyName] = value
			CurrencyController.currencyUpdated:Fire(currencyName, value)
		end)
		self._currencyInitialized:Fire(currencyName)
	end
end

function CurrencyController:getCurrency(currencyName: CurrencyDefinitions.CurrencyType): number
	return self._currencies[currencyName]
end

function CurrencyController:observeCurrency(currencyName: CurrencyDefinitions.CurrencyType, callback: (number) -> ())
	return Promise.new(function(resolve)
		local prop = self._currencyProperties[currencyName]
		if prop then
			resolve()
		else
			resolve(Promise.fromEvent(self._currencyInitialized, function(initializedName)
				return initializedName == currencyName
			end))
		end
	end):andThen(function()
		return self._currencyProperties[currencyName]:Observe(callback)
	end)
end

return Loader:registerSingleton(CurrencyController)
