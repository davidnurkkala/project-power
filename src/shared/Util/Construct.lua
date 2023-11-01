local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sift = require(ReplicatedStorage.Packages.Sift)

return function(className: string, properties: { [string]: any })
	local instance = Instance.new(className)
	for key, val in Sift.Dictionary.removeKey(properties, "Parent") do
		instance[key] = val
	end
	instance.Parent = properties.Parent
	return instance
end
