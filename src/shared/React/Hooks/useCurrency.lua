local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CurrencyController = require(ReplicatedStorage.Shared.Controllers.CurrencyController)
local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local React = require(ReplicatedStorage.Packages.React)
local Trove = require(ReplicatedStorage.Packages.Trove)

return function(currencyName: CurrencyDefinitions.CurrencyType)
	if not RunService:IsRunning() then return 123456789 end

	local currency, setCurrency = React.useState(CurrencyController:getCurrency(currencyName))

	React.useEffect(function()
		local trove = Trove.new()

		trove:AddPromise(CurrencyController:observeCurrency(currencyName, setCurrency)):andThen(function(connection)
			trove:Add(connection)
		end)

		return function()
			trove:Clean()
		end
	end, {
		currencyName,
	})

	return currency
end
