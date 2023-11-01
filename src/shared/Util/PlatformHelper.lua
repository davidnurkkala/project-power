local UserInputService = game:GetService("UserInputService")

local PlatformHelper = {}

function PlatformHelper.isMobile()
	local isMouseAndKeyboard = UserInputService.MouseEnabled and UserInputService.KeyboardEnabled
	return UserInputService.TouchEnabled and not isMouseAndKeyboard
end

return PlatformHelper
