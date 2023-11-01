local ChangeHistoryService = game:GetService("ChangeHistoryService")
local macro = {}

function macro:Init() end

macro.Items = {
	{
		Type = "Title",
		Text = "Merge Assets",
	},
	{
		Type = "Button",
		Text = "Merge",
		Activate = function()
			local target = game.ReplicatedStorage:FindFirstChild("Assets")
			if not target then
				warn("Missing target Assets in ReplicatedStorage. How did you break the game this badly?")
				return
			end

			local source = game.ServerStorage:FindFirstChild("Assets")
			if not source then
				warn("Missing source Assets in ServerStorage.")
				return
			end

			for _, sourceFolder in source:GetChildren() do
				local targetFolder = target:FindFirstChild(sourceFolder.Name)
				if not targetFolder then
					targetFolder = Instance.new("Folder")
					targetFolder.Name = sourceFolder.Name
					targetFolder.Parent = target
				end
				for _, object in sourceFolder:GetChildren() do
					if targetFolder:FindFirstChild(object.Name) then continue end
					object:Clone().Parent = targetFolder
				end
			end

			source:Destroy()

			ChangeHistoryService:SetWaypoint("Merged asset folders")
		end,
	},
	{
		Type = "Button",
		Text = "Help",
		Activate = function()
			print(
				"Merges assets for you to prevent some tedious work.",
				"Place the newer version of the Assets folder in ServerStorage, then click the merge button.",
				"The source folder will be automatically deleted afterwards."
			)
		end,
	},
}

return macro
