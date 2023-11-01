local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local WeaponPreview = require(ReplicatedStorage.Shared.React.Components.Common.WeaponPreview)

local function fancyStroke(props: {
	color: Color3,
	thickness: number,
})
	local alpha, setAlpha = React.useState(0)
	local width = 0.1

	React.useEffect(function()
		local connection = RunService.Heartbeat:Connect(function()
			local clock = (tick() % 2) / 2
			setAlpha(math.sin(clock * math.pi * 2) / 2 + 0.5)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	local transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(math.max(0.001, alpha - width), 1),
		NumberSequenceKeypoint.new(math.clamp(alpha, 0.002, 0.998), 0),
		NumberSequenceKeypoint.new(math.min(0.999, alpha + width), 1),
		NumberSequenceKeypoint.new(1, 1),
	})

	return React.createElement("UIStroke", {
		Color = props.color,
		Thickness = props.thickness,
	}, {
		Gradient = React.createElement("UIGradient", {
			Transparency = transparency,
			Rotation = -45,
		}),
	})
end

local function label(props)
	props = Sift.Dictionary.merge({
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextStrokeTransparency = 0,
		TextSize = 12,
		BackgroundTransparency = 1,
	}, props)

	return React.createElement("TextLabel", props)
end

return function(props: {
	weaponDefinition: WeaponDefinitions.WeaponDefinition,
	percent: number,
})
	return React.createElement("Frame", {
		LayoutOrder = 2,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0.25),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
	}, {
		Left = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.8, -4, 1, 0),
		}, {
			Layout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			Title = React.createElement(label, {
				LayoutOrder = 1,
				Size = UDim2.fromScale(1, 1 / 3),
				Text = "Next unlock:",
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.Bangers,
				TextScaled = true,
			}),

			WeaponName = React.createElement(label, {
				LayoutOrder = 2,
				Size = UDim2.fromScale(1, 1 / 3),
				Text = props.weaponDefinition.name,
				TextXAlignment = Enum.TextXAlignment.Left,
				Font = Enum.Font.GothamBold,
				TextScaled = true,
			}),

			Bar = React.createElement("CanvasGroup", {
				LayoutOrder = 3,
				Size = UDim2.fromScale(1, 1 / 3),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BorderSizePixel = 0,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0.5, 0),
				}),

				Bar = React.createElement("ImageLabel", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://14497999756",
					Size = UDim2.fromScale(props.percent, 1),
					ScaleType = Enum.ScaleType.Tile,
					TileSize = UDim2.fromScale(4, 1),
				}),

				Text = React.createElement(label, {
					Size = UDim2.fromScale(1, 1),
					Text = `{math.floor(props.percent * 100)}%`,
					TextScaled = true,
					Font = Enum.Font.GothamBold,
					ZIndex = 4,
				}),
			}),
		}),

		Preview = React.createElement("Frame", {
			Size = UDim2.fromScale(0.2, 0.2),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			Position = UDim2.fromScale(0.8, 1),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
		}, {
			Stroke = React.createElement(fancyStroke, {
				color = Color3.new(1, 1, 1),
				thickness = 2,
			}),

			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),

			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),

			Preview = React.createElement(WeaponPreview, {
				def = props.weaponDefinition,
				burstDisabled = true,
			}),
		}),
	})
end
