local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AutoRotateHelper = require(ReplicatedStorage.Shared.Util.AutoRotateHelper)
local ForcedRotationHelper = {}

local Instances = {}
local Processing = false

local function removeInstance(instance)
	local index = table.find(Instances, instance)
	if not index then return end

	table.remove(Instances, index)
end

local function setCFrame(root, cframe)
	root.CFrame = (cframe - cframe.Position) + root.Position
end

local function getCFrame(): CFrame?
	for index = #Instances, 1, -1 do
		local instance = Instances[index]
		if instance.cframe then return instance.cframe end
	end
	return nil
end

local function process(root)
	if Processing then return end
	Processing = true

	task.defer(function()
		local cframe = getCFrame()
		if cframe then setCFrame(root, cframe) end
		Processing = false
	end)
end

function ForcedRotationHelper.register(root: BasePart, human: Humanoid)
	AutoRotateHelper.disable(human)

	local instance = {
		cframe = nil,
		update = function(i, cframe)
			i.cframe = cframe
			process(root)
		end,
		destroy = function(i)
			removeInstance(i)
			AutoRotateHelper.enable(human)
		end,
	}

	table.insert(Instances, instance)

	return instance
end

function ForcedRotationHelper.getIsActive()
	return Instances[1] ~= nil
end

return ForcedRotationHelper
