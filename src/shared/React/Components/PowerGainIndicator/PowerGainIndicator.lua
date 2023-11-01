local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local Flipper = require(ReplicatedStorage.Packages.Flipper)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local setMotorGoalPromise = require(ReplicatedStorage.Shared.React.Hooks.setMotorGoalPromise)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)

local SCALE_PER_AMOUNT = 1 / 50
local SPRING_SLOW = { frequency = 1 }
local HANG_TIME = 2.5

local PowerGainIndicator: React.FC<any> = function(props)
	local powerAdded = props.PowerAdded

	local visible, setVisible = React.useState(false)
	local powerGoal = React.useRef(0)
	local promise = React.useRef(nil)
	local powerBinding, powerMotor = useMotor(0)
	local scaleBinding, scaleMotor = useMotor(1)
	local fadeBinding, fadeMotor = useMotor(1)

	React.useEffect(function()
		local connection = powerAdded:Connect(function(amount)
			powerGoal.current += amount
			powerMotor:setGoal(Flipper.Spring.new(powerGoal.current, SPRING_SLOW))

			scaleMotor:setGoal(Flipper.Instant.new(scaleMotor:getValue() + amount * SCALE_PER_AMOUNT))
			scaleMotor:step()
			scaleMotor:setGoal(Flipper.Spring.new(1, SPRING_SLOW))

			setVisible(true)
			if promise.current then promise.current:cancel() end
			promise.current = Promise.delay(HANG_TIME):andThen(function()
				setVisible(false)
				promise.current = nil
			end)
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	React.useEffect(function()
		if visible then
			fadeMotor:setGoal(Flipper.Spring.new(0))

			return
		else
			local clearPower = setMotorGoalPromise(fadeMotor, Flipper.Spring.new(1), function(value)
				return value > 0.95
			end):andThen(function()
				powerGoal.current = 0
				powerMotor:setGoal(Flipper.Instant.new(0))
			end)

			return function()
				clearPower:cancel()
			end
		end
	end, { visible })

	return React.createElement("CanvasGroup", {
		Size = UDim2.fromOffset(200, 50),
		Position = UDim2.fromScale(0.5, 0.7),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		GroupTransparency = fadeBinding,
		Visible = fadeBinding:map(function(fade)
			return fade < 1
		end),
	}, {
		Scale = React.createElement("UIScale", {
			Scale = scaleBinding,
		}),

		Layout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		}),

		Icon = React.createElement("ImageLabel", {
			LayoutOrder = 1,
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			Image = CurrencyDefinitions.power.iconId,
		}),

		Text = React.createElement("TextLabel", {
			LayoutOrder = 2,
			Size = UDim2.fromScale(2, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 40,
			Text = powerBinding:map(function(power)
				return `+{math.round(power)}`
			end),
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0,
			Font = Enum.Font.GothamBold,
			BackgroundTransparency = 1,
		}),
	})
end

return PowerGainIndicator
