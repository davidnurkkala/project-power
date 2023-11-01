local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)

export type CurrencyIconProps = {
	anchorPoint: Vector2?,
	size: UDim2?,
	position: UDim2?,
	layoutOrder: number?,

	currency: CurrencyDefinitions.CurrencyType,
}

local CurrencyIcon: React.FC<CurrencyIconProps> = function(props)
	local currencyDef = CurrencyDefinitions[props.currency]

	return React.createElement("ImageLabel", {
		AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,

		Image = currencyDef.iconId,
		Size = props.size or UDim2.new(1, 0, 1, 0),
		Position = props.position or UDim2.new(0.25, 0, 0.5, 0),

		SizeConstraint = Enum.SizeConstraint.RelativeYY,

		LayoutOrder = props.layoutOrder or 0,
	})
end

return CurrencyIcon
