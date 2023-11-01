local ReplicatedStorage = game:GetService("ReplicatedStorage")

local React = require(ReplicatedStorage.Packages.React)

return function(_props: {
	player: Player,
	isTauntEquipped: boolean,
})
	return React.createElement("Frame")
end
