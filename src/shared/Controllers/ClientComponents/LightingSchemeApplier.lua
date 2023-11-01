local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local LightingController = require(ReplicatedStorage.Shared.Controllers.LightingController)

-- consts

local LightingSchemeApplier = {}
LightingSchemeApplier.__index = LightingSchemeApplier

function LightingSchemeApplier.new(scheme: Folder)
	local self = setmetatable({
		_scheme = scheme,
		_token = nil,
	}, LightingSchemeApplier)

	if not scheme:IsA("Folder") then return self end

	self._applicationThread = task.spawn(function()
		task.wait()
		self._token = LightingController:loadScheme(scheme)
	end)

	return self
end

function LightingSchemeApplier:OnRemoved()
	if self._applicationThread then
		task.cancel(self._applicationThread)
		self._applicationThread = nil
	end
	if self._token then
		LightingController:unloadScheme(self._token)
		self._token = nil
	end
	self._scheme = nil
end

return ComponentService:registerComponentClass(script.Name, LightingSchemeApplier)
