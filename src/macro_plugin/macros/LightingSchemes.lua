local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Lighting = game:GetService("Lighting")
local Selection = game:GetService("Selection")

local macro = {}

-- consts
local KNOWN_LIGHTING_PROPS = {
	"Ambient",
	"Brightness",
	"ColorShift_Bottom",
	"ColorShift_Top",
	"ClockTime",
	"EnvironmentDiffuseScale",
	"EnvironmentSpecularScale",
	"ExposureCompensation",
	"GeographicLatitude",
	"GlobalShadows",
	"OutdoorAmbient",
	"ShadowSoftness",
}

function macro:Init() end

macro.Items = {
	{
		Type = "Title",
		Text = "Lighting Schemes",
	},
	{
		Type = "Button",
		Text = "Load Selected Scheme",
		Activate = function()
			local scheme = Selection:Get()[1]

			assert(scheme:IsA("Folder"), "Selected object is not a folder")

			Lighting:ClearAllChildren()

			-- load objects
			for _, object in scheme:GetChildren() do
				local clone = object:Clone()
				clone.Parent = Lighting
			end

			-- load lighting properties
			local props = scheme:GetAttributes()
			for property, value in pairs(props) do
				if not table.find(KNOWN_LIGHTING_PROPS, property) then continue end
				Lighting[property] = value
			end
			ChangeHistoryService:SetWaypoint("AfterLoadingLightingScheme")
		end,
	},
	{
		Type = "Button",
		Text = "Save Lighting as Scheme",
		Activate = function()
			local scheme = Instance.new("Folder")
			scheme.Name = "NewLightingScheme"
			for _, object in Lighting:GetChildren() do
				local clone = object:Clone()
				clone.Parent = scheme
			end

			for _, property in KNOWN_LIGHTING_PROPS do
				scheme:SetAttribute(property, Lighting[property])
			end

			scheme.Parent = workspace
			Selection:Set({ scheme })
			ChangeHistoryService:SetWaypoint("AfterSavingLightingScheme")
		end,
	},
}

return macro
