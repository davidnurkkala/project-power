local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local PlatformContext = require(ReplicatedStorage.Shared.React.Contexts.PlatformContext)
local React = require(ReplicatedStorage.Packages.React)

local function getInitialPlatform()
	local mouseAndKeyboard = UserInputService.MouseEnabled and UserInputService.KeyboardEnabled
	if UserInputService.TouchEnabled and not mouseAndKeyboard then
		return "Mobile"
	else
		return "Desktop"
	end
end

local PlatformManager: React.FC<{}> = function(props)
	local platform, setPlatform = React.useState(getInitialPlatform())

	React.useEffect(function()
		local connection = UserInputService.LastInputTypeChanged:Connect(function(type)
			if type == Enum.UserInputType.Touch then
				setPlatform("Mobile")
			else
				setPlatform("Desktop")
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, {})

	return React.createElement(PlatformContext.Provider, {
		value = platform,
	}, props.children)
end

return PlatformManager
