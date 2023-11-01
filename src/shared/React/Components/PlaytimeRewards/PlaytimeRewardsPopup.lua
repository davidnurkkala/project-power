local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Configuration = require(ReplicatedStorage.Shared.Data.Configuration)
local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local Flipper = require(ReplicatedStorage.Packages.Flipper)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)

local function lerp(a, b, w)
	return a + (b - a) * w
end

local function label(props)
	props = Sift.Dictionary.merge({
		Font = Enum.Font.Gotham,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeColor3 = Color3.new(0, 0, 0),
		TextStrokeTransparency = 0,
		TextSize = 12,
		BackgroundTransparency = 1,
		RichText = true,
	}, props)

	return React.createElement("TextLabel", props)
end

return function(props: {
	count: number,
	timestamp: number,
	finish: () -> (),
})
	local refreshTime, setRefreshTime = React.useState(nil)
	local zoomBinding, zoomMotor = useMotor(0)
	local coolBinding, coolMotor = useMotor(0)

	React.useEffect(function()
		local promise = Promise.try(function()
			zoomMotor:setGoal(Flipper.Spring.new(1))
			return Promise.delay(0.4)
		end)
			:andThen(function()
				coolMotor:setGoal(Flipper.Spring.new(1))
				return Promise.delay(4.2)
			end)
			:andThen(function()
				zoomMotor:setGoal(Flipper.Spring.new(0))
				return Promise.delay(0.4)
			end)
			:andThenCall(props.finish)

		return function()
			promise:cancel()
		end
	end, {})

	React.useEffect(function()
		local connection = RunService.Heartbeat:Connect(function()
			local remaining = props.timestamp - DateTime.now().UnixTimestamp
			if remaining < 0 then setRefreshTime(nil) end

			local t = DateTime.fromUnixTimestamp(remaining):ToUniversalTime()
			setRefreshTime(string.format("%02d:%02d:%02d", t.Hour, t.Minute, t.Second))
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return React.createElement("ImageLabel", {
		Size = UDim2.fromOffset(350, 0),
		BackgroundTransparency = 1,
		Image = "rbxassetid://14556129799",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = zoomBinding:map(function(value)
			return UDim2.new(0.5, 0, lerp(-0.5, 0, value), 15)
		end),
	}, {
		Constraint = React.createElement("UIAspectRatioConstraint", {
			AspectRatio = 512 / 152,
			AspectType = Enum.AspectType.ScaleWithParentSize,
		}),

		Time = refreshTime and React.createElement(label, {
			Size = UDim2.fromScale(0.62, 0.17),
			Position = UDim2.fromScale(0.19, 0.82),
			Font = Enum.Font.GothamBold,
			Text = `Refreshes in {refreshTime}`,
		}),

		RewardContainer = React.createElement("Frame", {
			Size = UDim2.fromScale(0.96, 0.45),
			Position = UDim2.fromScale(0.02, 0.07),
			BackgroundTransparency = 1,
		}, {
			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0.076, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			Rewards = React.createElement(
				React.Fragment,
				nil,
				Sift.Dictionary.map(Configuration.PlaytimeRewards.Rewards, function(reward, index)
					local key = `Reward{index}`
					local element = React.createElement("Frame", {
						LayoutOrder = index,
						Size = UDim2.fromScale(1, 1),
						SizeConstraint = Enum.SizeConstraint.RelativeYY,
						BackgroundTransparency = 1,
					}, {
						Image = React.createElement("ImageLabel", {
							BackgroundTransparency = 1,
							Image = CurrencyDefinitions[reward.Currency].iconId,
							Size = UDim2.fromScale(0.8, 0.8),
							Position = UDim2.fromScale(0.5, 0.5),
							AnchorPoint = Vector2.new(0.5, 0.5),
							ScaleType = Enum.ScaleType.Fit,
						}),

						Text = React.createElement(label, {
							ZIndex = 4,
							Size = UDim2.fromScale(1, 0.35),
							Position = UDim2.fromScale(0, 1),
							AnchorPoint = Vector2.new(0, 1),
							TextYAlignment = Enum.TextYAlignment.Bottom,
							TextScaled = true,
							Text = `<stroke thickness="2">{tostring(reward.Amount)}</stroke>`,
							Font = Enum.Font.GothamBold,
						}),

						Cross = React.createElement("ImageLabel", {
							ZIndex = 8,
							Position = UDim2.fromScale(0.5, 0.5),
							AnchorPoint = Vector2.new(0.5, 0.5),
							Size = if props.count == reward.RoundCountRequired
								then coolBinding:map(function(value)
									local size = lerp(16, 0.8, value)
									return UDim2.fromScale(size, size)
								end)
								else UDim2.fromScale(0.8, 0.8),
							ImageTransparency = if props.count == reward.RoundCountRequired
								then coolBinding:map(function(value)
									return 1 - value
								end)
								else 0,
							Image = "rbxassetid://14556485571",
							BackgroundTransparency = 1,
							Visible = props.count >= reward.RoundCountRequired,
						}),

						RoundCount = React.createElement(label, {
							Size = UDim2.fromScale(1, 0.5),
							Position = UDim2.fromScale(0, 1.1),
							Text = `<stroke thickness="2">Play {reward.RoundCountRequired}\nround{if reward.RoundCountRequired > 1 then "s" else ""}</stroke>`,
							Font = Enum.Font.GothamBold,
						}),
					})

					return element, key
				end)
			),
		}),
	})
end
