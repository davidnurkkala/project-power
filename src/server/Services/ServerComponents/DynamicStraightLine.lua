local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local Trove = require(ReplicatedStorage.Packages.Trove)

local DynamicStraightLine = {}
DynamicStraightLine.__index = DynamicStraightLine

function DynamicStraightLine.new(dynamic)
	local self = setmetatable({
		_model = dynamic.Model,
		_start = dynamic.Start.Position,
		_finish = dynamic.Finish.Position,
	}, DynamicStraightLine)

	dynamic.Start:Destroy()
	dynamic.Finish:Destroy()

	for _, object in self._model:GetDescendants() do
		if not object:IsA("BasePart") then continue end
		object.Anchored = false
	end

	local speed = dynamic:GetAttribute("Speed")

	local attachment = Instance.new("Attachment")
	attachment.Parent = self._model.PrimaryPart

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.RigidityEnabled = false
	alignPosition.ApplyAtCenterOfMass = true
	alignPosition.Position = attachment.WorldPosition
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.MaxVelocity = speed
	alignPosition.MaxForce = math.huge
	alignPosition.Attachment0 = attachment
	alignPosition.Parent = dynamic

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.RigidityEnabled = true
	alignOrientation.CFrame = attachment.WorldCFrame
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.Parent = dynamic

	local function reset()
		local here = self._model:GetPivot()
		local delta = self._start - here.Position
		self._model:PivotTo(here + delta)
		alignPosition.Position = self._start
	end

	local delta = self._finish - self._start
	local distance = delta.Magnitude
	local direction = delta.Unit
	local current = 0

	self._trove = Trove.new()

	self._trove:Add(task.spawn(function()
		while true do
			current += speed * task.wait(0.2)

			alignPosition.Position = self._start + direction * current

			if current >= distance then
				current = 0
				reset()
			end
		end
	end))

	reset()

	return self
end

function DynamicStraightLine:OnRemoved()
	self._trove:Clean()
end

return ComponentService:registerComponentClass(script.Name, DynamicStraightLine)
