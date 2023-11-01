local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local PowerUpDefinitions = require(ReplicatedStorage.Shared.Data.PowerUpDefinitions)
local PowerUpService = require(ServerScriptService.Server.Services.PowerUpService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Trove = require(ReplicatedStorage.Packages.Trove)
local pickRandom = require(ReplicatedStorage.Shared.Util.pickRandom)

local RESPAWN_DURATION = 15

local BasePowerUpPad = {}
BasePowerUpPad.__index = BasePowerUpPad

function BasePowerUpPad.new(model, ids)
	local self = setmetatable({
		_ids = ids,
		_model = model,
		_trove = Trove.new(),
	}, BasePowerUpPad)

	local cframe = model:GetPivot() * CFrame.new(0, 5, 0)
	self._offset = self:getRootPart().CFrame:ToObjectSpace(cframe)

	self:spawn()

	return self
end

function BasePowerUpPad:getRootPart()
	return self._model:FindFirstChildWhichIsA("BasePart", true)
end

function BasePowerUpPad:spawn()
	local cframe = self:getRootPart().CFrame * self._offset
	local position = cframe.Position

	local id = pickRandom(self._ids)
	local instance = PowerUpService:createPowerUp(id, self:getRootPart(), position)
	self._trove:Add(instance, "destroy")
	self._trove:AddPromise(Promise.fromEvent(instance.destroyed)
		:andThen(function()
			return Promise.delay(RESPAWN_DURATION)
		end)
		:andThen(function()
			self:spawn()
		end))
end

function BasePowerUpPad:OnRemoved()
	self._trove:Clean()
end

return ComponentService:registerComponentClass(script.Name, BasePowerUpPad)
