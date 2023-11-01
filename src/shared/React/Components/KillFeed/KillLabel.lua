local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local FlipperUtil = require(ReplicatedStorage.Shared.Util.FlipperUtil)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)

export type KillLabelProps = {
	killer: Player,
	victim: Player,
	destructor: () -> (),
	layoutOrder: number?,
}

local KillLabel: React.FC<KillLabelProps> = function(props)
	local positionBinding, positionMotor = useMotor(1)
	local sizeBinding, sizeMotor = useMotor(1)

	React.useEffect(function()
		positionMotor:setGoal(Flipper.Spring.new(0, {
			frequency = 3,
			dampingRatio = 1,
		}))

		local promise = Promise.delay(3)
			:andThen(function()
				return FlipperUtil.waitForGoal(
					positionMotor,
					Flipper.Spring.new(1, {
						frequency = 4,
						dampingRatio = 1,
					}),
					0.98
				)
			end)
			:andThen(function()
				return FlipperUtil.waitForGoal(
					sizeMotor,
					Flipper.Spring.new(0, {
						frequency = 2,
						dampingRatio = 1,
					}),
					0.02
				)
			end)
			:andThenCall(props.destructor)

		return function()
			promise:cancel()
		end
	end, {})

	return React.createElement("Frame", {
		Size = sizeBinding:map(function(value)
			return UDim2.fromScale(1, 0.1 * value)
		end),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder,
	}, {
		React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			AnchorPoint = positionBinding:map(function(value)
				return Vector2.new(value, 0)
			end),
			Position = positionBinding:map(function(value)
				return UDim2.new(1, 10 * (1 - value * 2), 0, 0)
			end),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
		}, {
			Killer = React.createElement("TextLabel", {
				Size = UDim2.fromScale(0, 1),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Text = props.killer.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Left,
				AutomaticSize = Enum.AutomaticSize.X,
				Font = Enum.Font.GothamBold,
				LayoutOrder = 1,
			}, {
				Outline = React.createElement("UIStroke", {
					Thickness = 2,
					Color = Color3.fromRGB(0, 0, 0),
				}),
			}),
			Icon = React.createElement("ImageLabel", {
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundTransparency = 1,
				Image = "rbxassetid://13746973451",
				LayoutOrder = 2,
			}),
			Victim = React.createElement("TextLabel", {
				Size = UDim2.fromScale(0, 1),
				BackgroundTransparency = 1,
				Text = props.victim.Name,
				TextColor3 = Color3.fromRGB(255, 128, 128),
				TextSize = 20,
				AutomaticSize = Enum.AutomaticSize.X,
				TextXAlignment = Enum.TextXAlignment.Right,
				Font = Enum.Font.GothamBold,
				LayoutOrder = 3,
			}, {
				Outline = React.createElement("UIStroke", {
					Thickness = 2,
					Color = Color3.fromRGB(0, 0, 0),
				}),
			}),
			UIListLayout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				Padding = UDim.new(0, 5),
			}),
		}),
	})
end

return KillLabel
