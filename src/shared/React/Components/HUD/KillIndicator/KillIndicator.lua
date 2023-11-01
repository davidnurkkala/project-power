local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local Flipper = require(ReplicatedStorage.Packages.Flipper)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local setMotorGoalPromise = require(ReplicatedStorage.Shared.React.Hooks.setMotorGoalPromise)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)

local SPRING_SLOW = { frequency = 1 }
local HANG_TIME = 1.5

local KillIndicator: React.FC<any> = function(props)
	local killAdded = props.KillAdded

	local visible, setVisible = React.useState(false)
	local queue = React.useRef({}).current
	local promise = React.useRef(nil)
	local scaleBinding, scaleMotor = useMotor(1)
	local fadeBinding, fadeMotor = useMotor(1)
	local nameBinding, setNameBinding = React.useBinding("")

	React.useEffect(function()
		local function loop()
			setNameBinding(table.remove(queue, 1))

			return Promise.delay(0.01)
				:andThen(function()
					scaleMotor:setGoal(Flipper.Instant.new(1.25))
					scaleMotor:step()
					scaleMotor:setGoal(Flipper.Spring.new(1, SPRING_SLOW))
					return setMotorGoalPromise(fadeMotor, Flipper.Spring.new(0), function(value)
						return value < 0.01
					end)
				end)
				:andThen(function()
					return Promise.delay(HANG_TIME)
				end)
				:andThen(function()
					return setMotorGoalPromise(fadeMotor, Flipper.Spring.new(1), function(value)
						return value > 0.99
					end)
				end)
				:andThen(function()
					if queue[1] then
						return loop()
					else
						setVisible(false)
						promise.current = nil
						return
					end
				end)
		end

		local connection = killAdded:Connect(function(name)
			table.insert(queue, name)

			if not promise.current then
				setVisible(true)
				promise.current = loop()
			end
		end)

		return function()
			connection:Disconnect()
			if promise.current then promise.current:cancel() end
		end
	end, {})

	React.useEffect(function()
		if visible then
			fadeMotor:setGoal(Flipper.Spring.new(0))
		else
			fadeMotor:setGoal(Flipper.Spring.new(1))
		end
	end, { visible })

	return React.createElement("CanvasGroup", {
		Size = UDim2.fromOffset(500, 50),
		Position = UDim2.fromScale(0.5, 0.1),
		AnchorPoint = Vector2.new(0.5, 0),
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
			Image = CurrencyDefinitions.kills.iconId,
		}),

		Text = React.createElement("TextLabel", {
			LayoutOrder = 2,
			Size = UDim2.fromScale(2, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = 40,
			Text = nameBinding,
			TextColor3 = Color3.new(1, 1, 1),
			TextStrokeTransparency = 0,
			Font = Enum.Font.GothamBold,
			BackgroundTransparency = 1,
		}),
	})
end

return KillIndicator
