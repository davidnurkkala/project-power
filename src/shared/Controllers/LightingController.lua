local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Loader)
local StackLoader = require(ReplicatedStorage.Shared.Classes.StackLoader)
local Trove = require(ReplicatedStorage.Packages.Trove)

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

local LightingController = {}
LightingController.className = "LightingController"
LightingController.priority = 0

function LightingController:_createLightingScheme(scheme: Folder): StackLoader.LoaderScheme
	local trove = Trove.new()
	local activeObjects = {}
	local originalProps = {}
	trove:Add(function()
		-- remove objects
		for i, object in activeObjects do
			object:Destroy()
			activeObjects[i] = nil
		end

		-- reset lighting properties
		for property, value in originalProps do
			Lighting[property] = value
		end
	end)

	local didLoad = false
	return {
		onLoad = function()
			if didLoad then return end
			didLoad = true

			-- load objects
			for _, object in scheme:GetChildren() do
				local clone = object:Clone()
				clone.Parent = Lighting
				table.insert(activeObjects, clone)
			end

			-- load lighting properties
			local props = scheme:GetAttributes()
			for property, value in pairs(props) do
				if not table.find(KNOWN_LIGHTING_PROPS, property) then continue end
				originalProps[property] = Lighting[property]
				Lighting[property] = value
			end
		end,
		onUnload = function()
			if not trove then return end
			trove:Destroy()
			trove = nil
		end,
	}
end

function LightingController:_createDefaultLightingScheme(): StackLoader.LoaderScheme
	local scheme = CollectionService:GetTagged("DefaultLightingScheme")[1]
	if scheme then return self:_createLightingScheme(scheme) end

	-- create a scheme based off Lighting on startup
	scheme = Instance.new("Folder")
	scheme.Name = "DefaultLighting"
	for _, object in Lighting:GetChildren() do
		local clone = object:Clone()
		clone.Parent = scheme
	end

	for _, property in KNOWN_LIGHTING_PROPS do
		scheme:SetAttribute(property, Lighting[property])
	end

	scheme.Parent = script

	return self:_createLightingScheme(scheme)
end

function LightingController:init()
	self._stackLoader = StackLoader.new()
	self._defaultToken = nil

	self._defaultLightingScheme = self:_createDefaultLightingScheme()

	-- clear lighting as it may have some initial objects we used for setting default scheme
	Lighting:ClearAllChildren()
end

function LightingController:start()
	self._defaultToken = self._stackLoader:load(self._defaultLightingScheme)
end

function LightingController:loadScheme(scheme: Folder)
	return self._stackLoader:load(self:_createLightingScheme(scheme))
end

function LightingController:unloadScheme(token)
	self._stackLoader:unload(token)
end

return Loader:registerSingleton(LightingController)
