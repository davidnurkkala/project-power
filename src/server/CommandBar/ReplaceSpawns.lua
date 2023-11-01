local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

ChangeHistoryService:SetWaypoint("BeforeCommandBar")

for _, model in Selection:Get() do
	local part = model.PrimaryPart
	part.Shape = Enum.PartType.Block
	part.Size = Vector3.new(6, 1, 6)
	part.CFrame = CFrame.new(part.Position)
end

ChangeHistoryService:SetWaypoint("AfterCommandBar")
