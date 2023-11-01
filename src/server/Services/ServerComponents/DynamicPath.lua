local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)

local DynamicPath = {}
DynamicPath.__index = DynamicPath

function DynamicPath.new(model)
	local self = setmetatable({
		_model = model,
		_visual = model.Model,
		_path = nil,
		_position = nil,
		_orientation = nil,
		_attachment = nil,
		_trove = Trove.new(),
		_pathIndex = 2,
		_pathingForwards = true,
	}, DynamicPath)

	self:_initVisual()
	self:_initPath()
	self:_teleport(self:_pathCFrame(1, 2))
	self:_next()

	return self
end

function DynamicPath:_initPath()
	self._path = {}
	for _, object in self._model.Path:GetChildren() do
		self._path[tonumber(object.Name)] = object.Position
	end
	self._model.Path:Destroy()
end

function DynamicPath:_pathCFrame(indexHere, indexThere)
	local here = self._path[indexHere]
	local there = self._path[indexThere]
	local delta = there - here
	if self._model:GetAttribute("StayFlat") then
		delta *= Vector3.new(1, 0, 1)
	end
	return CFrame.lookAt(here, here + delta)
end

function DynamicPath:_next()
	local index = self._pathIndex
	local nextIndex = if self._pathingForwards then (index + 1) else (index - 1)

	if (index == #self._path) and self._pathingForwards then nextIndex = index - 1 end

	local promise = self:_moveTo(self:_pathCFrame(index, nextIndex)):andThen(function()
		if self._pathingForwards then
			self._pathIndex += 1
			if self._pathIndex == #self._path then
				if self._model:GetAttribute("TwoWay") then self._pathingForwards = false end
			elseif self._pathIndex > #self._path then
				self._pathIndex = 2
				self:_teleport(self:_pathCFrame(1, 2))
			end
		else
			self._pathIndex -= 1
			if self._pathIndex == 1 then self._pathingForwards = true end
		end

		self:_next()
	end)
	self._trove:AddPromise(promise)
end

function DynamicPath:_tryFaceTowards(position)
	if self._model:GetAttribute("FaceDirection") then
		local cframe = self:getCFrame()
		local delta = position - cframe.Position

		if self._model:GetAttribute("StayFlat") then
			delta *= Vector3.new(1, 0, 1)
		end

		local direction = delta.Unit
		self._orientation.CFrame = CFrame.lookAt(Vector3.new(), delta)

		return Promise.new(function(resolve)
			repeat
				task.wait()
				local dot = self:getCFrame().LookVector:Dot(direction)
			until dot > 0.975
			resolve()
		end)
	else
		return Promise.resolve()
	end
end

function DynamicPath:_moveTo(cframe)
	return self:_tryFaceTowards(cframe.Position):andThen(function()
		self._position.Position = cframe.Position
		return Promise.new(function(resolve)
			repeat
				task.wait()
				local distance = (cframe.Position - self:getCFrame().Position).Magnitude
			until distance < 5
			resolve()
		end)
	end)
end

function DynamicPath:getCFrame()
	return self._attachment.WorldCFrame
end

function DynamicPath:_teleport(cframe)
	self._attachment.Parent.CFrame = cframe * self._attachment.CFrame:Inverse()
	self._position.Position = cframe.Position
	self._orientation.CFrame = cframe
end

function DynamicPath:_initVisual()
	local attachment = self._visual:FindFirstChild("DynamicAttachment", true)
	self._attachment = attachment

	for _, object in self._visual:GetDescendants() do
		if not object:IsA("BasePart") then continue end
		object.Anchored = false
	end

	local alignPosition = Instance.new("AlignPosition")
	alignPosition.RigidityEnabled = false
	alignPosition.ApplyAtCenterOfMass = false
	alignPosition.Position = attachment.WorldPosition
	alignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPosition.MaxVelocity = self._model:GetAttribute("Speed")
	alignPosition.MaxForce = math.huge
	alignPosition.Attachment0 = attachment
	alignPosition.Parent = self._model
	self._position = alignPosition

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.RigidityEnabled = false
	alignOrientation.CFrame = attachment.WorldCFrame
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.MaxAngularVelocity = math.rad(self._model:GetAttribute("TurnSpeed"))
	alignOrientation.MaxTorque = math.huge
	alignOrientation.Attachment0 = attachment
	alignOrientation.Parent = self._model
	self._orientation = alignOrientation
end

function DynamicPath:OnRemoved()
	self._trove:Clean()
end

return ComponentService:registerComponentClass(script.Name, DynamicPath)
