local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local PlatformContext = require(ReplicatedStorage.Shared.React.Contexts.PlatformContext)
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local useCooldownBinding = require(ReplicatedStorage.Shared.React.Hooks.useCooldownBinding)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)

local FILL_COLOR = Color3.fromRGB(146, 213, 216)
local EMPTY_COLOR = Color3.fromRGB(237, 90, 90)

export type ActionButtonProps = {
	iconId: string,
	iconScale: number?,
	hotkey: string,
	activationCallback: (inputObject: InputObject) -> (),
	cooldown: { getPercentage: ({}) -> number },
	size: UDim2?,
	position: UDim2,
	anchorPoint: Vector2,
}

local function isValidInputType(inputObject: InputObject)
	return inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch
end

local ActionButton: React.FC<ActionButtonProps> = function(props)
	local platform = React.useContext(PlatformContext)
	local isMobile = platform == "Mobile"

	local iconId = props.iconId
	local activationCallback = props.activationCallback
	local cooldown = props.cooldown

	local popBinding, popMotor = useMotor(0)
	local cooldownBinding, chargesBinding, chargesVisibleBinding = useCooldownBinding(
		cooldown,
		React.useCallback(function()
			popMotor:setGoal(Flipper.Instant.new(1))
			popMotor:step()
			popMotor:setGoal(Flipper.Spring.new(0, {
				frequency = 3,
				dampingRatio = 0.5,
			}))
		end, {
			popMotor,
		})
	)

	local size = props.size or UDim2.fromScale(0.4, 0.4)
	local position = props.position
	local anchorPoint = props.anchorPoint

	return React.createElement(
		"Frame",
		{
			Size = size,
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Position = position,
			AnchorPoint = anchorPoint,
			BackgroundTransparency = 1,
		},
		Sift.Dictionary.merge(props.children, {
			ColorBackground = React.createElement("ImageLabel", {
				ZIndex = 0,
				Image = "rbxassetid://13746973076",
				ImageColor3 = cooldownBinding:map(function(value)
					return EMPTY_COLOR:Lerp(FILL_COLOR, value)
				end),
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
			}),
			Edge = React.createElement("ImageLabel", {
				ZIndex = 1,
				Image = "rbxassetid://13746813973",
				Size = cooldownBinding:map(function(value)
					local x = math.sin(math.pow(value, 2) * math.pi)
					return UDim2.fromScale(1 + x * 0.15, 1 + x * 0.15)
				end),
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
			}),
			Button = React.createElement("TextButton", {
				ZIndex = 2,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				[React.Event.InputBegan] = function(_rbx, inputObject: InputObject)
					if not isValidInputType(inputObject) then return end
					activationCallback(inputObject)
				end,
				[React.Event.InputEnded] = function(_rbx, inputObject: InputObject)
					if not isValidInputType(inputObject) then return end
					activationCallback(inputObject)
				end,
			}),
			FlashEffect = React.createElement("ImageLabel", {
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 3,
				Image = "rbxassetid://6673021984",
				ImageColor3 = FILL_COLOR,
				ImageTransparency = popBinding:map(function(value)
					return 1 - value
				end),
				Size = popBinding:map(function(value)
					return UDim2.fromScale(value * 2, value * 2)
				end),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
			}),
			Icon = React.createElement("ImageLabel", {
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 4,
				Image = iconId,
				Size = UDim2.fromScale(props.iconScale or 1, props.iconScale or 1),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ScaleType = Enum.ScaleType.Fit,
				BackgroundTransparency = 1,
			}),
			ChargesLabel = React.createElement("TextLabel", {
				Size = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				ZIndex = 5,
				Position = UDim2.fromScale(0.5, 0.35),
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				Text = chargesBinding:map(function(value)
					return `{value}`
				end),
				Visible = chargesVisibleBinding:map(function(value)
					return value
				end),
				TextStrokeTransparency = 0,
				TextColor3 = Color3.new(1, 1, 1),
			}),
			HotkeyLabel = (not isMobile) and React.createElement("TextLabel", {
				Size = UDim2.fromOffset(0, 0),
				BackgroundTransparency = 1,
				ZIndex = 5,
				Position = UDim2.fromScale(0.5, 0.65),
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				Text = props.hotkey,
				TextStrokeTransparency = 0,
				TextColor3 = Color3.new(1, 1, 1),
			}),
		})
	)
end

return ActionButton
