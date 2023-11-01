local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Animation = require(ReplicatedStorage.Shared.Util.Animation)
local React = require(ReplicatedStorage.Packages.React)

type Promise = any
type AnimationMotor = {
	active: Promise,
	tweenToValue: (initialValue: number, targetValue: number, tweenInfo: TweenInfo, promiseCallback: (promise: Promise) -> ()) -> (),
	cancel: () -> (),
}

local function animationMotor(setBinding)
	local motor = {
		active = nil,
	}
	function motor:tweenToValue(initialValue, targetValue, tweenInfo, promiseCallback)
		if self.active then self.active:cancel() end
		self.active = Animation(tweenInfo.Time, function(alpha: number)
			-- normalize the value so that GetValue is given a 0-1 value, then reapply the transformation to amplify the value to its intended range.
			local scalar = math.abs(targetValue - initialValue)
			local lerpedValue = ((targetValue - initialValue) * alpha + initialValue) / scalar
			setBinding(scalar * TweenService:GetValue(lerpedValue, tweenInfo.EasingStyle, tweenInfo.EasingDirection))
		end)
		if promiseCallback then promiseCallback(self.active) end
	end

	function motor:cancel()
		if not self.active then return end
		self.active:cancel()
	end

	return motor :: AnimationMotor
end

return function(initialValue: number)
	local binding, setBinding = React.useBinding(initialValue)
	local motorRef = React.useRef(animationMotor(setBinding))
	React.useEffect(function()
		return function()
			motorRef.current:cancel()
		end
	end, { motorRef.current })

	return binding, motorRef.current
end
