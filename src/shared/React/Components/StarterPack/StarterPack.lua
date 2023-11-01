local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local FormatTime = require(ReplicatedStorage.Shared.Util.FormatTime)
local ProductDefinitions = require(ReplicatedStorage.Shared.Data.ProductDefinitions)
local React = require(ReplicatedStorage.Packages.React)
local Sift = require(ReplicatedStorage.Packages.Sift)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)

type Mapper<T> = ((T) -> T) -> T

local CLOSED = {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.25, 0, 0, 30),
	Size = UDim2.fromOffset(50, 50),
	Corner = UDim.new(0.5, 0),
}

local OPEN = {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(300, 200),
	Corner = UDim.new(0, 8),
}

local function lerp(a, b, w)
	return a + (b - a) * w
end

local function invert(value)
	return 1 - value
end

local function styleRobux(text)
	return `<b><font color="#4b974b"><stroke color="#27462d" thickness="2">{text}</stroke></font></b>`
end

local function usePromise(defaultValue, promiseFunc)
	local state, setState = React.useState(defaultValue)

	React.useEffect(function()
		setState(defaultValue)
		local internalPromise = promiseFunc():andThen(setState)

		return function()
			internalPromise:cancel()
		end
	end, { defaultValue, promiseFunc })

	return state, setState
end

local function burst(props: {
	visible: boolean,
	transparency: Mapper<number>,
})
	local rot, setRot = React.useState(0)

	React.useEffect(function()
		if not props.visible then return end

		local connection = RunService.Heartbeat:Connect(function()
			local clock = tick() % 4 / 4
			setRot(-360 * clock)
		end)

		return function()
			connection:Disconnect()
		end
	end, { props.visible })

	return React.createElement("ImageLabel", {
		Visible = props.visible,
		ZIndex = -1024,
		BackgroundTransparency = 1,
		Image = "rbxassetid://14339274308",
		ImageTransparency = props.transparency(function(value)
			return lerp(1, 0.5, value)
		end),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(2, 2),
		Rotation = rot,
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

local function timer(props: {
	expireTimestamp: string,
	visible: boolean,
	transparency: Mapper<number>,
	textProps: any?,
})
	local timeText, setTimeText = React.useState("")

	React.useEffect(function()
		local connection = RunService.Heartbeat:Connect(function()
			local now = DateTime.now().UnixTimestamp
			local expire = DateTime.fromIsoDate(props.expireTimestamp).UnixTimestamp
			local seconds = expire - now
			if seconds <= 0 then return end

			setTimeText(FormatTime(seconds))
		end)

		return function()
			connection:Disconnect()
		end
	end, { props.expireTimestamp })

	return React.createElement(
		"TextLabel",
		Sift.Dictionary.merge({
			Text = `Starter Pack!\n{timeText}`,
			Font = Enum.Font.GothamBold,
			Visible = props.visible,
			TextTransparency = props.transparency(invert),
			TextStrokeTransparency = props.transparency(invert),
			TextSize = 20,
			TextYAlignment = Enum.TextYAlignment.Bottom,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 1),
			TextColor3 = Color3.new(1, 1, 1),
		}, props.textProps or {})
	)
end

return function(props: {
	expireTimestamp: string,
	visible: boolean,
	buy: () -> any,
})
	local open, setOpen = React.useState(false)
	local fadeBinding, fadeMotor = useMotor(0)

	local price = usePromise(
		nil,
		React.useCallback(function()
			return ProductDefinitions.other.products.StarterPack.getPrice():andThen(function(amount, _currency)
				return amount
			end)
		end, {})
	)

	React.useEffect(function()
		if not props.visible then
			setOpen(false)
			return
		end

		if math.random() < 0.15 then setOpen(true) end
	end, { props.visible })

	local isOpen = React.useCallback(function()
		return fadeBinding:map(function(fade)
			return fade >= 0.5
		end)
	end, { fadeBinding })

	local openBinding = React.useCallback(function(mapper)
		local floor = 0.7
		return fadeBinding:map(function(fade)
			if fade < floor then
				return mapper(0)
			else
				return mapper((fade - floor) / (1 - floor))
			end
		end)
	end, { fadeBinding })

	local isClosed = React.useCallback(function()
		return fadeBinding:map(function(fade)
			return fade < 0.5
		end)
	end, { fadeBinding })

	local closedBinding = React.useCallback(function(mapper)
		local ceiling = 0.3
		return fadeBinding:map(function(fade)
			if fade > ceiling then
				return mapper(0)
			else
				return mapper(1 - fade / ceiling)
			end
		end)
	end, { fadeBinding })

	React.useEffect(function()
		if open then
			fadeMotor:setGoal(Flipper.Spring.new(1))
		else
			fadeMotor:setGoal(Flipper.Spring.new(0))
		end
	end, { open })

	return React.createElement("Frame", {
		Visible = props.visible,
		BackgroundTransparency = 0.5,
		BackgroundColor3 = Color3.new(0, 0, 0),
		AnchorPoint = fadeBinding:map(function(fade)
			return CLOSED.AnchorPoint:Lerp(OPEN.AnchorPoint, fade)
		end),
		Position = fadeBinding:map(function(fade)
			return CLOSED.Position:Lerp(OPEN.Position, fade)
		end),
		Size = fadeBinding:map(function(fade)
			return CLOSED.Size:Lerp(OPEN.Size, fade)
		end),
	}, {
		Corner = React.createElement("UICorner", {
			CornerRadius = fadeBinding:map(function(fade)
				local scale = lerp(CLOSED.Corner.Scale, OPEN.Corner.Scale, fade)
				local offset = lerp(CLOSED.Corner.Offset, OPEN.Corner.Offset, fade)
				return UDim.new(scale, offset)
			end),
		}),

		OpenButton = React.createElement("ImageButton", {
			Visible = isClosed(),
			Size = UDim2.fromScale(1, 1),
			Image = "rbxassetid://14240198696",
			ImageTransparency = closedBinding(invert),
			BackgroundTransparency = 1,
			[React.Event.Activated] = function()
				setOpen(true)
			end,
			ZIndex = -32,
		}),

		Burst = React.createElement(burst, {
			visible = isClosed(),
			transparency = closedBinding,
		}),

		TimerText = React.createElement(timer, {
			expireTimestamp = props.expireTimestamp,
			visible = isClosed(),
			transparency = closedBinding,
		}),

		Icon = React.createElement("ImageLabel", {
			Visible = isOpen(),
			Size = UDim2.fromScale(1, 1),
			ScaleType = Enum.ScaleType.Fit,
			Image = "rbxassetid://14240198696",
			ImageTransparency = openBinding(function(value)
				return lerp(1, 0.75, value)
			end),
			BackgroundTransparency = 1,
			ZIndex = -32,
		}),

		CloseButton = React.createElement("TextButton", {
			Visible = isOpen(),
			BackgroundTransparency = openBinding(invert),
			TextTransparency = openBinding(invert),
			Size = UDim2.fromOffset(30, 30),
			Position = UDim2.fromScale(1, 0),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "X",
			TextSize = 25,
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.new(1, 1, 1),
			[React.Event.Activated] = function()
				setOpen(false)
			end,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = OPEN.Corner,
			}),

			Stroke = React.createElement("UIStroke", {
				Color = Color3.new(1, 1, 1),
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Transparency = openBinding(function(value)
					return 1 - value
				end),
			}),
		}),

		Contents = React.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, -30),
			Position = UDim2.fromOffset(0, 30),
			BackgroundTransparency = 1,
		}, {
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),

			Title = React.createElement(label, {
				Size = UDim2.new(1, 0, 0, 30),
				TextScaled = true,
				Text = "Project Power Starter Pack",
				Font = Enum.Font.Bangers,

				Visible = isOpen(),
				TextTransparency = openBinding(invert),
				TextStrokeTransparency = openBinding(invert),
			}),

			Description = React.createElement(label, {
				Size = UDim2.new(1, 0, 1, -80),
				Position = UDim2.fromScale(0, 0.5),
				AnchorPoint = Vector2.new(0, 0.5),
				TextScaled = true,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				RichText = true,
				Text = `Unlock the first <b>ten</b> weapons <i>instantly!</i>\n\nGet <b>25%</b> more Power <i>forever!</i>\n\nUnlock the exclusive <b>"Poverty Detected"</b> kill image!`,

				Visible = isOpen(),
				TextTransparency = openBinding(invert),
				TextStrokeTransparency = openBinding(invert),
			}),

			TimeLeft = React.createElement(timer, {
				expireTimestamp = props.expireTimestamp,
				visible = isOpen(),
				transparency = openBinding,
				textProps = {
					Size = UDim2.new(0.5, 0, 0, 30),
					Position = UDim2.fromScale(0, 1),
					AnchorPoint = Vector2.new(0, 1),
					TextScaled = true,
				},
			}),

			Buy = React.createElement("TextButton", {
				Visible = isOpen(),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = openBinding(invert),
				Size = UDim2.new(0.5, 0, 0, 30),
				Position = UDim2.fromScale(1, 1),
				AnchorPoint = Vector2.new(1, 1),
				TextColor3 = Color3.new(1, 1, 1),
				Text = `<b>Buy</b> {if price then styleRobux(`{price} R$`) else ``}`,
				RichText = true,
				Font = Enum.Font.Gotham,
				TextScaled = true,
				TextTransparency = openBinding(invert),
				[React.Event.Activated] = function()
					props.buy()
				end,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),

				Padding = React.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4),
					PaddingRight = UDim.new(0, 4),
					PaddingLeft = UDim.new(0, 4),
				}),

				Stroke = React.createElement("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Transparency = openBinding(invert),
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			}),
		}),
	})
end
