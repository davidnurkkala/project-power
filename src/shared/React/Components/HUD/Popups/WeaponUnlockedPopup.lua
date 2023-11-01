local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local Popup = require(ReplicatedStorage.Shared.React.Components.Common.Popup)

local React = require(ReplicatedStorage.Packages.React)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)
local WeaponPreview = require(ReplicatedStorage.Shared.React.Components.Common.WeaponPreview)
local setMotorGoalPromise = require(ReplicatedStorage.Shared.React.Hooks.setMotorGoalPromise)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)
local useSound = require(ReplicatedStorage.Shared.React.Hooks.useSound)

export type WeaponUnlockedPopupProps = {
	weaponDef: WeaponDefinitions.WeaponDefinition,
}

local Popups = function(props)
	local activationBinding, activationMotor = useMotor(1)
	local flameBinding, flameMotor = useMotor(0)
	local showPreview, setShowPreview = React.useState(false)

	local tweenInSwoosh = useSound({
		soundId = "rbxassetid://13746030152",
		volume = 0.5,
		playbackSpeed = 1,
	})

	local weaponNameSwoosh = useSound({
		soundId = "rbxassetid://6074550510",
		volume = 0.5,
		playbackSpeed = 1,
	})

	React.useEffect(function()
		tweenInSwoosh:Play()
	end, {})

	return React.createElement(Popup, {
		anchorPoint = Vector2.new(0.5, 0),
		size = UDim2.new(1, 0, 0.4, 0),
		position = UDim2.new(0.5, 0, -1, 0),
		targetPosition = UDim2.new(0.5, 0, 0, 100),

		lifeTime = 8,
		tweenInInfo = TweenInfo.new(0.8, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		tweenOutInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),

		onTweenIn = function()
			weaponNameSwoosh:Play()
			setMotorGoalPromise(activationMotor, Flipper.Spring.new(0, { frequency = 8, dampingRatio = 1 }), function(value)
					return value < 0.9
				end)
				:andThen(function()
					return setMotorGoalPromise(flameMotor, Flipper.Linear.new(1), function(value)
						return value > 0.95
					end)
				end)
				:andThen(function()
					setShowPreview(true)
				end)
		end,
		onTweenOut = function()
			setShowPreview(false)
			flameMotor:setGoal(Flipper.Instant.new(0))
			activationMotor:setGoal(Flipper.Instant.new(1))

			if props.onTweenOut then props.onTweenOut() end
		end,
	}, {
		Header = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0.25, 0),

			Font = Enum.Font.Bangers,
			Text = `UNLOCKED`,
			TextColor3 = Color3.new(1, 1, 0),
			TextScaled = true,
		}, {
			UIStroke = React.createElement("UIStroke", {
				Thickness = 2,
				Color = Color3.new(0, 0, 0),
			}),
		}),
		Flames = React.createElement("ImageLabel", {
			Visible = flameBinding:map(function(value)
				return (value > 0) and (value < 1)
			end),
			BackgroundTransparency = 1,
			Image = "rbxassetid://14339274598",
			ImageTransparency = flameBinding:map(function(value)
				return value ^ 2
			end),
			Size = flameBinding:map(function(value)
				return UDim2.fromScale(0, 0):Lerp(UDim2.fromScale(2, 2), value ^ 0.5)
			end),
			Rotation = flameBinding:map(function(value)
				return 180 * value
			end),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.625),
			ZIndex = -1024,
		}),
		Preview = showPreview and React.createElement("Frame", {
			ZIndex = -1024,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(0.75, 0.75),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			Position = UDim2.fromScale(0.5, 0.8),
			AnchorPoint = Vector2.new(0.5, 0),
		}, {
			Preview = React.createElement(WeaponPreview, {
				def = props.weaponDef,
			}),
		}),
		unlock = React.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Position = activationBinding:map(function(value)
				return UDim2.new(0, 0, 0.25, 0):Lerp(UDim2.new(0, 0, 0.5, 0), value)
			end),
			Size = UDim2.new(1, 0, 0.75, 0),

			Font = Enum.Font.Bangers,
			Text = props.weaponDef.name,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,

			TextTransparency = activationBinding:map(function(value)
				return value
			end),
		}, {
			UIStroke = React.createElement("UIStroke", {
				Thickness = 2,
				Color = Color3.new(0, 0, 0),
				Transparency = activationBinding:map(function(value)
					return value
				end),
			}),
		}),
	})
end

return Popups
