local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local EffectService = require(ServerScriptService.Server.Services.EffectService)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local PersistentServerEffect = require(ServerScriptService.Server.Classes.PersistentServerEffect)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local PowerUpModel = {}
PowerUpModel.__index = PowerUpModel

function PowerUpModel.new(modelName, rootPart, position)
	local self = setmetatable({
		_model = nil,
		_trove = Trove.new(),
		activated = Signal.new(),
	}, PowerUpModel)

	local model = self._trove:Construct(Instance.new, "Model")
	model.Name = `{modelName}PowerUp`

	local part = ReplicatedStorage.Assets.PowerUps[modelName]:Clone()
	part.Name = "Root"
	part.CFrame = CFrame.new(position)
	part.Parent = model
	model.PrimaryPart = part

	local offset = rootPart.CFrame:ToObjectSpace(part.CFrame)

	part.Touched:Connect(function(otherPart)
		local target = WeaponUtil.findDamageTarget(otherPart)
		if not target then return end
		if not target:IsA("Humanoid") then return end
		local player = Players:GetPlayerFromCharacter(target.Parent)
		if not player then return end

		self.activated:Fire(player)
	end)

	model.Parent = workspace

	local guid = EffectUtil.guid()
	self._trove:Add(
		PersistentServerEffect.new("powerUpSpin", {
			guid = guid,
			model = model,
			rootPart = rootPart,
		}),
		"destroy"
	)
	self._trove:Add(function()
		EffectService:effect("cancel", { guid = guid })
	end)

	local lastPosition = rootPart.Position
	self._trove:Connect(RunService.Heartbeat, function()
		if rootPart.Position:FuzzyEq(lastPosition) then return end
		lastPosition = rootPart.Position

		model:PivotTo(rootPart.CFrame * offset)
	end)

	self._model = model

	return self
end

function PowerUpModel:destroy()
	self._trove:Clean()
end

return PowerUpModel
