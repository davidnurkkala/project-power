local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelUpDefinitions = require(ReplicatedStorage.Shared.Data.LevelUpDefinitions)
local React = require(ReplicatedStorage.Packages.React)
local Trove = require(ReplicatedStorage.Packages.Trove)
local useCharacter = require(ReplicatedStorage.Shared.React.Hooks.useCharacter)

local MAX_LEVEL = #LevelUpDefinitions.perksByLevel

export type LevelLabelProps = {
	player: Player,
	position: UDim2,
}

local LevelLabel: React.FC<LevelLabelProps> = function(props: LevelLabelProps)
	local player = props.player
	local char = useCharacter(player) :: Model

	local level, setLevel = React.useState(1)

	React.useEffect(function()
		if not char then return end

		setLevel(char:GetAttribute("Level") or 1)

		local trove = Trove.new()

		trove:Connect(char:GetAttributeChangedSignal("Level"), function()
			setLevel(char:GetAttribute("Level") or 1)
		end)

		return function()
			trove:Clean()
		end
	end, {
		player,
		char,
	})

	return React.createElement("TextLabel", {
		Size = UDim2.fromScale(0.3, 0.1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		TextStrokeTransparency = 0,
		TextSize = 24,
		Text = if level == MAX_LEVEL then `MAX LEVEL` else `Level {level}`,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Bottom,
		Position = props.position,
	})
end

return LevelLabel
