local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

return function(instance: Instance, attributeName: string)
	local attribute, setAttribute = React.useState(if instance then instance:GetAttribute(attributeName) else nil)

	React.useEffect(function()
		if not instance then return end

		local connection = instance:GetAttributeChangedSignal(attributeName):Connect(function()
			setAttribute(instance:GetAttribute(attributeName))
		end)

		return function()
			connection:Disconnect()
		end
	end, {
		instance,
		attributeName,
	})

	return attribute
end
