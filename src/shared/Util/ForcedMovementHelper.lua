local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Packages.Promise)
local ForcedMovementHelper = {}

local Stacks = {}

local function getStack(root: BasePart)
	if not Stacks[root] then
		Stacks[root] = {
			root = root,
			thread = nil,
			layers = {},
		}
		Promise.fromEvent(root.AncestryChanged, function()
			return not root:IsDescendantOf(workspace)
		end):andThen(function()
			Stacks[root] = nil
		end)
	end
	return Stacks[root]
end

local function processStack(stack)
	if stack.promise then return stack.promise end

	stack.promise = Promise.new(function(resolve)
		task.defer(function()
			local x, y, z
			for _, layer in stack.layers do
				x = layer.x or x
				y = layer.y or y
				z = layer.z or z
			end
			stack.root.AssemblyLinearVelocity =
				Vector3.new(x or stack.root.AssemblyLinearVelocity.X, y or stack.root.AssemblyLinearVelocity.Y, z or stack.root.AssemblyLinearVelocity.Z)
			stack.promise = nil

			resolve()
		end)
	end)

	return stack.promise
end

local function removeLayer(stack, layer)
	table.remove(stack.layers, table.find(stack.layers, layer))
	if #stack.layers == 0 then Stacks[stack.root] = nil end
end

function ForcedMovementHelper.instant(root: BasePart, x, y, z)
	local stack = getStack(root)
	local layer = {
		x = x,
		y = y,
		z = z,
	}
	table.insert(stack.layers, layer)
	processStack(stack):andThen(function()
		removeLayer(stack, layer)
	end)
end

function ForcedMovementHelper.register(root: BasePart)
	local stack = getStack(root)

	local layer = {
		x = nil,
		y = nil,
		z = nil,
		update = function(self, x, y, z)
			self.x = x
			self.y = y
			self.z = z
			processStack(stack)
		end,
		destroy = function(self)
			removeLayer(stack, self)
		end,
	}

	table.insert(stack.layers, layer)

	return layer
end

return ForcedMovementHelper
