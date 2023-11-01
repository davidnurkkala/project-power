local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)

local Comm = require(ReplicatedStorage.Packages.Comm)
local CurrencyDefinitions = require(ReplicatedStorage.Shared.Data.CurrencyDefinitions)
local GenericLeaderboard = require(ReplicatedStorage.Shared.Classes.GenericLeaderboard)
local Promise = require(ReplicatedStorage.Packages.Promise)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponStandPortal = require(ReplicatedStorage.Shared.React.Components.WeaponStand.WeaponStandPortal)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)
local destroyEmitter = require(ReplicatedStorage.Shared.Util.destroyEmitter)

local WEAPON_STAND_PROMPT_DISTANCE = 9
local UNSELECTED_WEAPON_PROMPT_TEXT = "Select"

local WeaponStand = {}
WeaponStand.__index = WeaponStand

function WeaponStand:_clearHighlight()
	if self._highlight then
		self._trove:Remove(self._highlight)
		self._highlight = nil
	end
end

function WeaponStand:_createHighlight()
	self:_clearHighlight()
	self._highlight = self._trove:Construct(Instance, "Highlight") :: Highlight
	self._highlight.FillTransparency = 0.5
	self._highlight.FillColor = Color3.fromRGB(255, 255, 0)
	self._highlight.OutlineTransparency = 0
	self._highlight.OutlineColor = Color3.fromRGB(255, 0, 255)
	self._highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	self._highlight.Parent = self._object
end

function WeaponStand:_setOwned(owned: boolean)
	if owned then
		self._prompt.ActionText = UNSELECTED_WEAPON_PROMPT_TEXT
		self._ownershipChanged:Fire(owned)
	end
	self:_updatePrompt()
end

function WeaponStand:_setSelected(selected: boolean)
	self:_clearHighlight()
	if selected then self:_createHighlight() end
	self:_updatePrompt()
end

function WeaponStand:_updatePrompt()
	self._prompt.Enabled = self._owned and not self._selected
end

function WeaponStand:_spawnModel(selected: boolean)
	if self._model then
		self._trove:Remove(self._model)
		self._model = nil
	end

	self._model = self._trove:Add(self._weaponDefinition.model:Clone()) :: Model

	local modelHeight = self._model:GetExtentsSize().Y

	local weaponPosition = if self._object.Root:FindFirstChild("WeaponPosition") then self._object.Root.WeaponPosition.WorldCFrame else self._object:GetPivot()
	self._model:PivotTo(weaponPosition + Vector3.new(0, modelHeight / 2, 0))

	for _, desc in self._model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.Anchored = true

			if selected then
				desc.Transparency = math.max(desc.Transparency, 0.5)
				desc.Material = Enum.Material.Neon
			end
		end
	end

	self._model.Parent = self._object
end

function WeaponStand:_selectionEffect()
	local emitter1 = ReplicatedStorage.RojoAssets.Emitters.WeaponEquipEmitter1:Clone()
	local emitter2 = ReplicatedStorage.RojoAssets.Emitters.WeaponEquipEmitter2:Clone()
	local sound = ReplicatedStorage.RojoAssets.Sounds.WeaponSelect1:Clone()

	local modelPosition = self._model:GetBoundingBox().Position
	local delta = modelPosition - self._object.Root.Position

	local attachment = Instance.new("Attachment")
	attachment.Position = delta
	attachment.Parent = self._object.Root

	emitter1.Parent = attachment
	emitter2.Parent = attachment
	sound.Parent = attachment

	Promise.new(function(resolve)
		sound:Play()
		emitter1:Emit(1)
		resolve(destroyEmitter(emitter1))
	end)
		:andThen(function()
			emitter2:Emit(1)
			return destroyEmitter(emitter2)
		end)
		:andThenCall(attachment.Destroy, attachment)
end

function WeaponStand.new(object)
	local self = setmetatable({
		_object = object,
		_trove = Trove.new(),
		_selected = nil,
		_owned = nil,
		_weaponDefinition = WeaponUtil.getWeaponDefinition(object.Name),
	}, WeaponStand)

	if not self._weaponDefinition then error(`WeaponStand weaponDefinition not found for weapon {object.Name}`) end

	self:_spawnModel()

	self._clientComm = self._trove:Construct(Comm.ClientComm, object, true, "WeaponStand")
	self._selectRequested = self._clientComm:GetSignal("SelectRequested")
	self._ownershipChanged = Signal.new()

	self._prompt = self._trove:Construct(Instance, "ProximityPrompt") :: ProximityPrompt
	self._prompt.Enabled = false
	self._prompt.MaxActivationDistance = WEAPON_STAND_PROMPT_DISTANCE
	self._prompt.RequiresLineOfSight = false
	self._prompt.Parent = self._object.Root:FindFirstChild("WeaponPosition") or self._object.Root
	self._trove:Add(self._prompt.Triggered:Connect(function()
		if self._owned then
			if not self._selected then
				self._selectRequested:Fire()
				self:_selectionEffect()
			else
				warn("Attempted to select a weapon that is already selected.")
			end
		end
	end))

	local root = ReactRoblox.createRoot(Instance.new("Folder"))
	root:render(React.createElement(WeaponStandPortal, {
		target = self._object.Root,
		weaponDefinition = self._weaponDefinition,
		owned = self._owned,
		ownershipChanged = self._ownershipChanged,
	}))

	self._trove:Add(self._clientComm:GetProperty("Owned"):Observe(function(owned)
		if owned == nil then return end

		self._owned = owned
		self:_setOwned(owned)
	end))
	self._trove:Add(self._clientComm:GetProperty("Selected"):Observe(function(selected)
		if selected == nil then return end

		self._selected = selected
		self:_setSelected(selected)
		self:_spawnModel(selected)
	end))
	self._trove:Add(self._clientComm:GetProperty("New"):Observe(function(...)
		self:OnNewChanged(...)
	end))

	local leaderboardCFrame = self._object.Root.WeaponPosition.WorldCFrame * CFrame.new(0, 3, 3)
	self._trove:Add(
		GenericLeaderboard.new({
			cframe = leaderboardCFrame,
			remoteProperty = self._clientComm:GetProperty("Leaderboard"),
			icon = CurrencyDefinitions.kills.iconId,
		}),
		"destroy"
	)

	return self
end

function WeaponStand:OnNewChanged(new)
	if new then
		if self._newEffect then return end

		local effect = ReplicatedStorage.Assets.Effects.NewIndicator:Clone()
		local cframe = self._object:GetPivot() * CFrame.new(0, 10, 0)
		effect.CFrame = cframe
		effect.Parent = self._object

		self._newEffect = {
			part = effect,
			connection = RunService.Heartbeat:Connect(function()
				local clock = tick() % 1
				local rotation = (math.pi * 2) * clock
				local control = (math.pi * 2) * clock
				effect.CFrame = cframe * CFrame.Angles(0, rotation, 0) * CFrame.new(0, math.sin(control), 0)
			end),
		}
	else
		if not self._newEffect then return end

		self._newEffect.part:Destroy()
		self._newEffect.connection:Disconnect()
		self._newEffect = nil
	end
end

function WeaponStand:OnRemoved()
	self._trove:Destroy()
end

return ComponentService:registerComponentClass(script.Name, WeaponStand)
