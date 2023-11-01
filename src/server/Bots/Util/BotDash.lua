local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local EffectService = require(ServerScriptService.Server.Services.EffectService)
local FaceTowards = require(ServerScriptService.Server.Bots.Util.FaceTowards)
local Promise = require(ReplicatedStorage.Packages.Promise)

local DASH_IMPULSE_TIME = 0.25
local DASH_SPEED = 80

local function flatRootCFrame(root: BasePart)
	return (root.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
end

return function(args: {
	animator: any,
	root: BasePart,
	direction: Vector3?,
})
	local animator = args.animator
	local root = args.root
	local direction = args.direction or flatRootCFrame(root)

	animator:play("Dash", 0)

	EffectService:effect("dash", {
		root = root,
		duration = DASH_IMPULSE_TIME,
	})

	local duration = DASH_IMPULSE_TIME
	return Promise.fromEvent(RunService.Stepped, function(_, dt)
		root.AssemblyLinearVelocity = direction * DASH_SPEED
		FaceTowards(root, root.Position + direction)

		duration -= dt
		return duration <= 0
	end):andThen(function()
		animator:stopHard("Dash")
	end)
end
