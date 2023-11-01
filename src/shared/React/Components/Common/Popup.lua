local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local React = require(ReplicatedStorage.Packages.React)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local useTween = require(ReplicatedStorage.Shared.React.Hooks.useTween)

export type PopupProps = {
	anchorPoint: Vector2,
	size: UDim2,
	position: UDim2,
	targetPosition: UDim2,
	tweenInInfo: TweenInfo,
	tweenOutInfo: TweenInfo,

	closeForced: Signal.Signal<any>?,
	onTweenIn: any?,
	onTweenOut: any?,
	lifeTime: number?,
}

local Popup: React.FC<PopupProps> = function(props)
	local lifetime = props.lifeTime or 5
	local tweenBinding, tweenMotor = useTween(0)

	-- lifetime lifecycle
	React.useEffect(function()
		local startTime = tick()
		local isUnmounting = false

		tweenMotor:tweenToValue(0, 1, props.tweenInInfo, function(promise)
			promise:andThen(function()
				if not props.onTweenIn then return end
				props.onTweenIn()
			end)
		end)

		local function handleUnmount()
			if isUnmounting then return end
			isUnmounting = true

			-- tween out
			tweenMotor:tweenToValue(1, 0, props.tweenOutInfo, function(promise)
				promise:andThen(function()
					if not props.onTweenOut then return end
					props.onTweenOut()
				end)
			end)
		end

		local trove = Trove.new()
		if lifetime >= 0 then trove:Connect(RunService.Heartbeat, function()
			if (tick() - startTime) < lifetime then return end
			handleUnmount()
		end) end

		if props.closeForced then trove:Connect(props.closeForced, handleUnmount) end

		return function()
			trove:Clean()
		end
	end, { props.lifeTime, props.closeForced })

	return React.createElement("Frame", {
		AnchorPoint = props.anchorPoint,
		BackgroundTransparency = 1,
		Size = props.size,
		ZIndex = 1024,
		Position = tweenBinding:map(function(value)
			return props.position:Lerp(props.targetPosition, value)
		end),
	}, props.children)
end

return Popup
