local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local setMotorGoalPromise = require(ReplicatedStorage.Shared.React.Hooks.setMotorGoalPromise)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)

local KillImage: React.FC<any> = function(props)
	local image = props.image
	local finish = props.finish
	local fadeBinding, fadeMotor = useMotor(1)

	React.useEffect(function()
		if not image then return end

		local promise = setMotorGoalPromise(fadeMotor, Flipper.Spring.new(0), function(value)
				return value < 0.01
			end)
			:andThen(function()
				return Promise.delay(3)
			end)
			:andThen(function()
				return setMotorGoalPromise(fadeMotor, Flipper.Spring.new(1), function(value)
					return value > 0.99
				end)
			end)
			:andThen(finish)

		return function()
			promise:cancel()
		end
	end, { image })

	return React.createElement("ImageLabel", {
		ZIndex = -8192,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ImageTransparency = fadeBinding,
		Image = image,
		ScaleType = Enum.ScaleType.Fit,
	})
end

return KillImage
