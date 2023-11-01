local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PPHudButton = require(ReplicatedStorage.Shared.React.Components.Common.PPUI.PPHudButton.PPHudButton)
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)
local useViewportSize = require(ReplicatedStorage.Shared.React.Hooks.useViewportSize)

export type HudButtonsProps = {
	buttonSelected: (buttonName: string?) -> (),
	notificationAdded: Signal.Signal<string>,
}

local MIN_SCALE = 0.5
local BASE_SCALE = 1080

local BUTTONS = {
	Shop = {
		order = 0,
		icon = "rbxassetid://14066771613",
	},
	Extras = {
		order = 1,
		icon = "rbxassetid://14977893179",
	},
}

local function notification(props)
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.75, 1),
		BackgroundColor3 = Color3.fromRGB(200, 100, 50),
		Size = UDim2.new(0, 48, 0, 48),
		Position = UDim2.new(1, 0, 1, 0),
	}, {
		UICorner = React.createElement("UICorner", {
			CornerRadius = UDim.new(1, 0),
		}),
		UIStroke = React.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 0, 0),
			Thickness = 4,
		}),
		Exclamation = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Font = Enum.Font.Bangers,
			Text = "!",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 42,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.65, 0, 0.65, 0),
		}, {
			UIStroke = React.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 0, 0),
				Thickness = 3,
			}),
		}),
	})
end

local HudButtons: React.FC<HudButtonsProps> = function(props)
	local notifications, setNotifications = React.useState({})
	local viewportSize = useViewportSize()

	React.useEffect(function()
		local connection = props.notificationAdded:Connect(function(buttonName)
			setNotifications(function(oldNotifications)
				return Sift.Dictionary.merge(oldNotifications, { [buttonName] = true })
			end)
		end)

		return function()
			connection:Disconnect()
		end
	end, { props.notificationAdded })

	local children = {
		UIScale = React.createElement("UIScale", {
			Scale = math.clamp((viewportSize.Y / BASE_SCALE) ^ 2, MIN_SCALE, 1),
		}),
		ListLayout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 16),
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	}

	for name, button in pairs(BUTTONS) do
		children[name] = React.createElement(PPHudButton, {
			size = UDim2.new(0, 128, 0, 128),
			layoutOrder = button.order,
			onActivated = function()
				props.buttonSelected(name)

				if not notifications[name] then return end
				setNotifications(function(oldNotifications)
					return Sift.Dictionary.merge(oldNotifications, { [name] = false })
				end)
			end,
		}, {
			Icon = React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = button.icon,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0.65, 0, 0.65, 0),
			}),
			Notification = notifications[name] and React.createElement(notification),
		})
	end

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 512, 0, 128),
		Position = UDim2.new(0.5, 0, 0, 36),
	}, children)
end

return HudButtons
