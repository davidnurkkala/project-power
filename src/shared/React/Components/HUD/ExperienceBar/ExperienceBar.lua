local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FillBar = require(ReplicatedStorage.Shared.React.Components.Common.FillBar)
local React = require(ReplicatedStorage.Packages.React)
local Trove = require(ReplicatedStorage.Packages.Trove)
local useCharacter = require(ReplicatedStorage.Shared.React.Hooks.useCharacter)

export type ExperienceBarProps = {
	player: Player,
}

local ExperienceBar: React.FC<ExperienceBarProps> = function(props: ExperienceBarProps)
	local player = props.player
	local character = useCharacter(player) :: Model

	local maxExperience, setMaxExperience = React.useState(100)
	local experience, setExperience = React.useState(0)

	React.useEffect(function()
		if not character then return end

		setMaxExperience(character:GetAttribute("MaxExperience") or 100)
		setExperience(character:GetAttribute("Experience") or 0)

		local trove = Trove.new()

		trove:Connect(character:GetAttributeChangedSignal("MaxExperience"), function()
			setMaxExperience(character:GetAttribute("MaxExperience") or 100)
		end)

		trove:Connect(character:GetAttributeChangedSignal("Experience"), function()
			setExperience(character:GetAttribute("Experience") or 0)
		end)

		return function()
			trove:Clean()
		end
	end, {
		player,
		character,
	})

	if not character then return end

	return React.createElement(FillBar, {
		flipped = true,
		maxValue = maxExperience,
		value = experience,
		fillColor = Color3.fromRGB(211, 193, 1),
		backgroundColor = Color3.new(0, 0, 0),
		roundingUDim = UDim.new(0.2, 0),
		gradientRotation = -45,
	})
end

return ExperienceBar
