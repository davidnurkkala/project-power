local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Comm = require(ReplicatedStorage.Packages.Comm)
local CurrencyDisplay = require(ReplicatedStorage.Shared.React.Components.HUD.CurrencyDisplay.CurrencyDisplay)
local FormatTime = require(ReplicatedStorage.Shared.Util.FormatTime)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local Trove = require(ReplicatedStorage.Packages.Trove)

local SPEED = 2
local RADIUS = 0.05

local function getTimeRemaining(timestamp)
	if not timestamp then return end

	local now = DateTime.now().UnixTimestamp
	if now > timestamp then return end

	return timestamp - now
end

return function(props)
	local boostExpireTimestamp, setBoostExpireTimestamp = React.useState(nil)
	local timeRemaining, setTimeRemaining = React.useState(nil)
	local boostColor, setBoostColor = React.useBinding(ColorSequence.new(Color3.fromRGB(235, 107, 102)))

	React.useEffect(function()
		local trove = Trove.new()

		trove
			:AddPromise(Promise.try(function()
				return trove:Construct(Comm.ClientComm, ReplicatedStorage, true, "BoosterService")
			end))
			:andThen(function(comm)
				trove:Add(comm:GetProperty("ExpireTimestamp"):Observe(setBoostExpireTimestamp))
			end)

		return function()
			trove:Clean()
		end
	end, {})

	React.useEffect(function()
		local thread = task.spawn(function()
			while true do
				setTimeRemaining(getTimeRemaining(boostExpireTimestamp))
				task.wait(0.5)
			end
		end)

		return function()
			setTimeRemaining(nil)
			task.cancel(thread)
		end
	end, { boostExpireTimestamp })

	React.useEffect(function()
		local promise
		local function loop()
			setBoostColor(ColorSequence.new(Color3.fromRGB(235, 107, 102)))
			promise = Promise.delay(1)
				:andThen(function()
					local alpha = 0
					return Promise.fromEvent(RunService.Heartbeat, function(dt)
						alpha = math.clamp(alpha + SPEED * dt, 0, 1)
						setBoostColor(ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 107, 102)),
							ColorSequenceKeypoint.new(math.max(0.01, alpha - RADIUS), Color3.fromRGB(235, 107, 102)),
							ColorSequenceKeypoint.new(math.clamp(alpha, 0.02, 0.98), Color3.new(1, 1, 1)),
							ColorSequenceKeypoint.new(math.min(0.99, alpha + RADIUS), Color3.fromRGB(235, 107, 102)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 107, 102)),
						}))

						return alpha >= 1
					end)
				end)
				:andThenCall(loop)
		end
		loop()

		return function()
			promise:cancel()
		end
	end, {})

	return React.createElement("Frame", {
		Position = props.position,
		AnchorPoint = props.anchorPoint,
		Size = props.size,
		BackgroundTransparency = 1,
	}, {
		Display = React.createElement(CurrencyDisplay, {
			currencyType = "power",
			position = UDim2.new(),
			anchorPoint = Vector2.new(),
			size = UDim2.fromScale(1, 1),
		}),

		BoostText = (timeRemaining ~= nil) and React.createElement("TextLabel", {
			Size = UDim2.fromScale(0.9, 1),
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromOffset(-5, 0),
			TextScaled = true,
			Text = `x2 boost active!\n{FormatTime(timeRemaining)}`,
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.new(1, 1, 1),
		}, {
			Stroke = React.createElement("UIStroke", {
				Color = Color3.new(0, 0, 0),
				Thickness = 2,
			}),

			Gradient = React.createElement("UIGradient", {
				Color = boostColor,
			}),
		}),
	})
end
