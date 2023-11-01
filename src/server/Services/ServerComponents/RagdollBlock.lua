local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local Sift = require(ReplicatedStorage.Packages.Sift)
local StunService = require(ServerScriptService.Server.Services.StunService)
local Trove = require(ReplicatedStorage.Packages.Trove)

local MODES = {
	Absolute = true,
	Relative = true,
}

local RagdollBlock = {}
RagdollBlock.__index = RagdollBlock

function RagdollBlock.new(root: BasePart)
	local self = setmetatable({
		_trove = Trove.new(),
	}, RagdollBlock)

	local attributes = root:GetAttributes()

	assert(attributes.Mode, `RagdollBlock must have a Mode string attribute of one of: {table.concat(Sift.Set.toArray(MODES), ", ")}`)
	assert(attributes.Duration, "RagdollBlock must have Duration number attribute describing stun duration in seconds")
	assert(attributes.Direction, "RagdollBlock must have a Direction Vector3 attribute describing launch direction")
	assert(attributes.Speed, "RagdollBlock must have a Speed number attribute describing the speed of launch")

	local spread = math.rad(attributes.Spread or 0)

	self._trove:Connect(root.Touched, function(part)
		local char = part.Parent
		if not char then return end
		local humanoid = char:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then return end

		local direction = attributes.Direction
		if attributes.Mode == "Relative" then direction = root.CFrame:VectorToWorldSpace(direction) end

		local launchCFrame = CFrame.lookAt(Vector3.new(), direction)
			* CFrame.Angles(0, 0, math.pi * 2 * math.random())
			* CFrame.Angles(spread * math.random(), 0, 0)

		local velocity = launchCFrame.LookVector * attributes.Speed

		StunService:stunTarget(humanoid, attributes.Duration, velocity)
	end)

	return self
end

function RagdollBlock:OnRemoved()
	self._trove:Clean()
end

return ComponentService:registerComponentClass(script.Name, RagdollBlock)
