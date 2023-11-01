local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local CurrencyLabel = require(ReplicatedStorage.Shared.React.Components.HUD.CurrencyDisplay.CurrencyLabel)
local React = require(ReplicatedStorage.Packages.React)
local useCurrency = require(ReplicatedStorage.Shared.React.Hooks.useCurrency)

export type CurrencyDisplayProps = {
	currencyType: CurrencyDefinitions.CurrencyType,
	position: UDim2,
	size: UDim2,
	anchorPoint: Vector2,
}

local CurrencyDisplay: React.FC<CurrencyDisplayProps> = function(props)
	local currencyAmount = useCurrency(props.currencyType)
	return React.createElement(CurrencyLabel, {
		amount = currencyAmount,
		currency = props.currencyType,
		position = props.position,
		size = props.size,
		anchorPoint = props.anchorPoint,
	})
end

return CurrencyDisplay
