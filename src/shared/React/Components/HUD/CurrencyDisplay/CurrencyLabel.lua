local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local CurrencyIcon = require(ReplicatedStorage.Shared.React.Components.Common.CurrencyIcon)
local React = require(ReplicatedStorage.Packages.React)

-- consts
local CURRENCY_BORDER_COLORS: { [CurrencyDefinitions.CurrencyType]: Color3 } = {
	power = Color3.fromRGB(90, 27, 27),
	premium = Color3.fromRGB(0, 136, 170),
	kills = Color3.fromRGB(116, 8, 8),
}

export type CurrencyLabelProps = {
	amount: number,
	currency: CurrencyDefinitions.CurrencyType,
	position: UDim2,
	size: UDim2,
	anchorPoint: Vector2,
}

local CurrencyLabel: React.FC<CurrencyLabelProps> = function(props)
	local currency = props.currency
	local position = props.position
	local size = props.size
	local anchorPoint = props.anchorPoint

	return React.createElement("Frame", {
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundTransparency = 1,
	}, {
		React.createElement("TextLabel", {
			Size = UDim2.fromScale(0.8, 1),
			BackgroundTransparency = 1,
			Text = tostring(props.amount),
			Font = Enum.Font.GothamBold,
			TextScaled = true,
			TextColor3 = CurrencyDefinitions[currency].textColor,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
		}, {
			Stroke = React.createElement("UIStroke", {
				Thickness = 3,
				LineJoinMode = Enum.LineJoinMode.Miter,
				Color = CURRENCY_BORDER_COLORS[currency],
			}),
		}),
		React.createElement(CurrencyIcon, {
			size = UDim2.fromScale(1, 1),
			layoutOrder = 0,
			currency = currency,
		}),
		React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 4),
		}),
	})
end

return CurrencyLabel
