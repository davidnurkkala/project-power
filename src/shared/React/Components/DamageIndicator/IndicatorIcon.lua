local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local React = require(ReplicatedStorage.Packages.React)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)

-- consts
local POP_IN_TIME = 0.25

local VISIBILITY_SPRING = {
	frequency = 3,
	dampingRatio = 1,
}

local MIN_DAMAGE = 15
local MAX_DAMAGE = 100

local COLOR_NO_DAMAGE = Color3.fromRGB(255, 255, 255)
local COLOR_HALF_DAMAGE = Color3.fromRGB(255, 255, 0)
local COLOR_MAX_DAMAGE = Color3.fromRGB(255, 0, 0)

export type IndicatorIconProps = {
	damage: number,
	lifetime: number,
	unmount: () -> (),
}

local function getDamageColor(damage: number): Color3
	local percent = math.clamp((damage - MIN_DAMAGE) / (MAX_DAMAGE - MIN_DAMAGE), 0, 1)
	local alpha = percent ^ 0.5 -- sqrt for more early weapon damage to contrast more

	if alpha < 0.5 then return COLOR_NO_DAMAGE:Lerp(COLOR_HALF_DAMAGE, alpha * 2) end
	return COLOR_HALF_DAMAGE:Lerp(COLOR_MAX_DAMAGE, 2 * alpha - 1)
end

local IndicatorIcon: React.FC<IndicatorIconProps> = function(props)
	local damage = props.damage or 0

	local sizeBinding, setSizeBinding = React.useBinding(0)
	local visibilityBinding, visibilityMotor = useMotor(1)

	React.useEffect(function()
		local startTime = tick()
		local heartbeatConnection
		heartbeatConnection = RunService.Heartbeat:Connect(function(_dt)
			local percent = (tick() - startTime) / POP_IN_TIME
			setSizeBinding(math.min(1, percent))

			if tick() - startTime >= props.lifetime then
				heartbeatConnection:Disconnect()
				visibilityMotor:setGoal(Flipper.Spring.new(0, VISIBILITY_SPRING))
				visibilityMotor:onComplete(props.unmount)
			end
		end)
		return function()
			if heartbeatConnection then heartbeatConnection:Disconnect() end
		end
	end, {
		props.lifetime,
	})

	return React.createElement("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),

		Font = Enum.Font.FredokaOne,
		Text = tostring(damage),
		TextTransparency = visibilityBinding:map(function(value)
			return 1 - value
		end),
		TextColor3 = getDamageColor(damage),
		TextScaled = true,
	}, {
		UIStroke = React.createElement("UIStroke", {
			Color = Color3.new(0, 0, 0),
			Transparency = visibilityBinding:map(function(value)
				return 1 - value
			end),
			Thickness = 1,
		}),
		UIScale = React.createElement("UIScale", {
			Scale = sizeBinding:map(function(value)
				return math.sin(value * math.pi / 2) ^ 2
			end),
		}),
	})
end

return IndicatorIcon
