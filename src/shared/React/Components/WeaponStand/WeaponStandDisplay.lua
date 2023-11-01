local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyIcon = require(ReplicatedStorage.Shared.React.Components.Common.CurrencyIcon)
local React = require(ReplicatedStorage.Packages.React)
local Signal = require(ReplicatedStorage.Packages.Signal)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

export type WeaponStandDisplayProps = {
	weaponDefinition: WeaponDefinitions.WeaponDefinition,
	owned: boolean,
	ownershipChanged: Signal.Signal<boolean>?,
}

local WeaponStandDisplay: React.FC<WeaponStandDisplayProps> = function(props)
	local weaponDefinition = props.weaponDefinition
	local weaponName = weaponDefinition.name
	local currency = weaponDefinition.currency
	local price = weaponDefinition.price

	local owned, setOwned = React.useState(props.owned)

	React.useEffect(function()
		if not props.ownershipChanged then return end

		local connection = props.ownershipChanged:Connect(function(newOwned)
			setOwned(newOwned)
		end)

		return function()
			connection:Disconnect()
		end
	end, { props.ownershipChanged })

	React.useEffect(function()
		if props.owned then setOwned(true) end
	end, { props.owned })

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
	}, {
		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),
		Name = React.createElement("TextLabel", {
			BackgroundTransparency = 1,

			Font = Enum.Font.FredokaOne,
			Text = weaponName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextScaled = true,

			Size = UDim2.new(1, 0, 0.25, 0),

			LayoutOrder = 0,
		}, {
			Stroke = React.createElement("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				Color = Color3.fromRGB(0, 0, 0),
				Thickness = 4,
			}),
		}),
		Price = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0.25, 0),
			LayoutOrder = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),

			CurrencyIcon = (not owned) and React.createElement(CurrencyIcon, {
				layoutOrder = 1,

				anchorPoint = Vector2.new(0.5, 0.5),
				size = UDim2.new(1, 0, 1, 0),

				currency = currency,
			}),
			Price = (not owned) and React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,

				Font = Enum.Font.FredokaOne,
				Text = tostring(price),
				TextColor3 = Color3.fromRGB(255, 219, 14),
				TextScaled = true,

				Size = UDim2.new(0, 0, 1, 0),
				AutomaticSize = Enum.AutomaticSize.X,
				LayoutOrder = 2,
			}, {
				Stroke = React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
					Color = Color3.fromRGB(204, 169, 12),
					Thickness = 4,
				}),
				Padding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0.1, 0),
					PaddingRight = UDim.new(0.1, 0),
				}),
			}),
			OwnedLabel = owned and React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,

				Font = Enum.Font.FredokaOne,
				Text = "OWNED",
				TextColor3 = Color3.fromRGB(255, 219, 14),
				TextScaled = true,

				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				TextXAlignment = Enum.TextXAlignment.Center,
				LayoutOrder = 1,
			}, {
				Stroke = React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
					Color = Color3.fromRGB(204, 169, 12),
					Thickness = 4,
				}),
			}),
		}),
	})
end

return WeaponStandDisplay
