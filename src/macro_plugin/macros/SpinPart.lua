local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local getSelection = require(ServerStorage.MACRO_PLUGIN.CustomUtil.getSelection)

local radius = 12
local trove = nil

return {
	Init = function() end,
	Items = {
		{ Type = "Title", Text = "Spin Part for Trail Dev" },
		{
			Type = "Button",
			Text = "Start",
			Activate = function(button)
				if trove then
					trove:Clean()
					trove = nil
					button:UpdateText("Start")
				else
					local part = getSelection()[1]
					if not part and part:IsA("BasePart") then
						warn("Select a part.")
						return
					end

					trove = Trove.new()

					local originalCFrame = part.CFrame
					trove:Add(function()
						part.CFrame = originalCFrame
					end)

					local cframe = CFrame.new(part.Position + Vector3.new(radius, 0, 0))
					local rotation = 0
					local rotSpeed = -math.pi
					trove:Connect(RunService.Heartbeat, function(dt)
						rotation += rotSpeed * dt
						part.CFrame = cframe * CFrame.Angles(0, rotation, 0) * CFrame.new(-radius, 0, 0)
					end)

					button:UpdateText("Stop")
				end
			end,
		},
	},
}
