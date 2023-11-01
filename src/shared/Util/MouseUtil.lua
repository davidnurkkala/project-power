local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local MouseUtil = {}

function MouseUtil.raycast(): { instance: Instance?, position: Vector3, normal: Vector3 }
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { Players.LocalPlayer.Character }

	local mousePosition = UserInputService:GetMouseLocation()
	local ray = workspace.CurrentCamera:ViewportPointToRay(mousePosition.X, mousePosition.Y)

	local origin = ray.Origin
	local direction = ray.Direction
	local length = 512

	local result = workspace:Raycast(origin, direction * length, params)

	if result then
		return {
			instance = result.Instance,
			position = result.Position,
			normal = result.Normal,
		}
	else
		return {
			instance = nil,
			position = origin + direction * length,
			normal = -direction,
		}
	end
end

return MouseUtil
