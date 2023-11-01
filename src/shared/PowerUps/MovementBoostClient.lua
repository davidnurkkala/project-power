local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DashController = require(ReplicatedStorage.Shared.Controllers.DashController)
local Promise = require(ReplicatedStorage.Packages.Promise)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

return function(definition)
	local human = WeaponUtil.getHuman()

	local walkSpeed = human.WalkSpeed * definition.speed
	local jumpHeight = human.JumpHeight * definition.jump

	human.WalkSpeed += walkSpeed
	human.JumpHeight += jumpHeight
	DashController:getCooldown():adjustSpeed(definition.cooldown)

	Promise.race({
		Promise.delay(definition.duration),
		Promise.fromEvent(human.Died),
	}):andThen(function()
		human.WalkSpeed -= walkSpeed
		human.JumpHeight -= jumpHeight
		DashController:getCooldown():adjustSpeed(-definition.cooldown)
	end)
end
