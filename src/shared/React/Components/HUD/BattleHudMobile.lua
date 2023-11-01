local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActionButton = require(ReplicatedStorage.Shared.React.Components.HUD.Common.ActionButton)
local ActionButtonIcons = require(ReplicatedStorage.Shared.Data.ActionButtonIcons)
local ActionController = require(ReplicatedStorage.Shared.Controllers.ActionController)
local DashController = require(ReplicatedStorage.Shared.Controllers.DashController)
local ExperienceBar = require(ReplicatedStorage.Shared.React.Components.HUD.ExperienceBar.ExperienceBar)
local Flipper = require(ReplicatedStorage.Packages.Flipper)
local HealthBar = require(ReplicatedStorage.Shared.React.Components.HUD.HealthBar.HealthBar)
local JumpController = require(ReplicatedStorage.Shared.Controllers.JumpController)
local LevelLabel = require(ReplicatedStorage.Shared.React.Components.HUD.ExperienceBar.LevelLabel)
local LevelUpPerksLabel = require(ReplicatedStorage.Shared.React.Components.HUD.ExperienceBar.LevelUpPerksLabel)
local React = require(ReplicatedStorage.Packages.React)
local SilenceController = require(ReplicatedStorage.Shared.Controllers.SilenceController)
local TauntController = require(ReplicatedStorage.Shared.Controllers.TauntController)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponController = require(ReplicatedStorage.Shared.Controllers.WeaponController)
local useAttribute = require(ReplicatedStorage.Shared.React.Hooks.useAttribute)
local useCharacter = require(ReplicatedStorage.Shared.React.Hooks.useCharacter)
local useMotor = require(ReplicatedStorage.Shared.React.Hooks.Flipper.useMotor)

local PULSE_RATE = 0.5
local WHITE = Color3.new(1, 1, 1)
local RED = Color3.new(1, 0, 0)

local function lerp(a, b, w)
	return a + (b - a) * w
end

local function silencedIcon(props: {
	isSilenced: boolean,
})
	local fade, fadeMotor = useMotor(1)
	local pulseBinding, setPulseBinding = React.useBinding(0)

	React.useEffect(function()
		if props.isSilenced then
			fadeMotor:setGoal(Flipper.Spring.new(0))

			local thread = task.spawn(function()
				while true do
					local clock = (tick() % PULSE_RATE) / PULSE_RATE
					local value = math.cos(clock * math.pi * 2) * 0.5 + 0.5
					setPulseBinding(value)
					task.wait()
				end
			end)

			return function()
				task.cancel(thread)
				setPulseBinding(0)
			end
		else
			fadeMotor:setGoal(Flipper.Spring.new(1))

			return
		end
	end, { props.isSilenced })

	return React.createElement("ImageLabel", {
		Size = fade:map(function(value)
			local scale = lerp(1, 4, value)
			return UDim2.fromScale(scale, scale)
		end),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		Image = "rbxassetid://14975930911",
		ImageColor3 = pulseBinding:map(function(value)
			return WHITE:Lerp(RED, value)
		end),
		ImageTransparency = fade,
		ZIndex = 512,
	})
end

local BattleHudMobile: React.FC<{ player: Player }> = function(props)
	local player = props.player
	local isTauntEquipped = props.isTauntEquipped

	local isStunned = useAttribute(useCharacter(player), "IsStunned")
	local isStunnedIcon = isStunned and ActionButtonIcons.Stunned or nil

	local isSilenced, setIsSilenced = React.useState(false)

	local attackCooldown, setAttackCooldown = React.useState(WeaponController:getAttackCooldown())
	local specialCooldown, setSpecialCooldown = React.useState(WeaponController:getSpecialCooldown())

	React.useEffect(function()
		local trove = Trove.new()

		trove:Connect(WeaponController.weaponEquipped, function()
			setAttackCooldown(WeaponController:getAttackCooldown())
			setSpecialCooldown(WeaponController:getSpecialCooldown())
		end)

		trove:Add(SilenceController:observeSilenced(setIsSilenced))

		return function()
			trove:Clean()
		end
	end, {})

	return React.createElement(React.Fragment, nil, {
		HealthBar = React.createElement("Frame", {
			Size = UDim2.fromScale(0.6, 0.15),
			Position = UDim2.fromScale(0.475, 0.5),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
		}, {
			React.createElement(HealthBar, {
				player = player,
			}),
		}),
		ExperienceBar = React.createElement("Frame", {
			Size = UDim2.fromScale(0.35, 0.09),
			Position = UDim2.fromScale(0.445, 0.665),
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
		}, {
			React.createElement(ExperienceBar, {
				player = player,
			}),
		}),
		LevelLabel = React.createElement(LevelLabel, {
			player = player,
			position = UDim2.fromScale(-0.1, 0.385),
		}),
		LevelUpPerksLabel = React.createElement(LevelUpPerksLabel, {
			player = player,
			position = UDim2.fromScale(0.475, 0.5),
		}),
		ButtonsFrame = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(1, 1),
			ClipsDescendants = false,
		}, {
			Dash = React.createElement(ActionButton, {
				iconId = isStunnedIcon or ActionButtonIcons.Dash,
				hotkey = "Q",
				activationCallback = function(inputObject)
					ActionController:handleInputAction("dash", inputObject.UserInputState)
				end,
				cooldown = DashController:getCooldown(),
				position = UDim2.fromScale(1, 0.5),
				anchorPoint = Vector2.new(1, 0.5),
			}),
			Jump = React.createElement(ActionButton, {
				iconId = isStunnedIcon or ActionButtonIcons.Jump,
				iconScale = 0.75,
				hotkey = "SPACE",
				activationCallback = function()
					JumpController:normalJump()
				end,
				cooldown = JumpController:getCooldown(),
				position = UDim2.fromScale(0.5, 1),
				anchorPoint = Vector2.new(0.5, 1),
			}),
			Attack = React.createElement(ActionButton, {
				iconId = isStunnedIcon or ActionButtonIcons.Attack,
				hotkey = "LMB",
				activationCallback = function(inputObject)
					ActionController:handleInputAction("attack", inputObject.UserInputState)
				end,
				cooldown = attackCooldown,
				position = UDim2.fromScale(0, 0.5),
				anchorPoint = Vector2.new(0, 0.5),
			}),
			Special = React.createElement(ActionButton, {
				iconId = isStunnedIcon or ActionButtonIcons.Special,
				hotkey = "R",
				activationCallback = function(inputObject)
					ActionController:handleInputAction("special", inputObject.UserInputState)
				end,
				cooldown = specialCooldown,
				position = UDim2.fromScale(0.5, 0),
				anchorPoint = Vector2.new(0.5, 0),
			}, {
				Silenced = React.createElement(silencedIcon, {
					isSilenced = isSilenced,
				}),
			}),
			Taunt = isTauntEquipped and React.createElement(ActionButton, {
				iconId = isStunnedIcon or ActionButtonIcons.Taunt,
				hotkey = "T",
				activationCallback = function(inputObject)
					if inputObject.UserInputState ~= Enum.UserInputState.Begin then return end
					TauntController:taunt()
				end,
				cooldown = TauntController:getCooldown(),
				iconScale = 0.75,
				position = UDim2.fromScale(1, 0.1),
				anchorPoint = Vector2.new(1, 1),
			}),
		}),
	})
end

return BattleHudMobile
