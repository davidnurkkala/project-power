local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local EffectService = require(ServerScriptService.Server.Services.EffectService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Trove = require(ReplicatedStorage.Packages.Trove)

-- constants
local DEBRIS_COLLISION_GROUP = "Debris"
local LIFESPAN = 2 -- seconds

local Breakable = {}
Breakable.__index = Breakable

local function partTransparencyTween(part: BasePart, alpha: number)
	local tweenAlpha = TweenService:GetValue(alpha, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	part.Transparency = tweenAlpha
end

local function modelTransparencyTween(model: Model, alpha: number)
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		partTransparencyTween(part, alpha)
	end
end

function Breakable:_breakPart(part: BasePart, player: Player)
	-- set collision group to debris
	part.CollisionGroup = DEBRIS_COLLISION_GROUP

	-- unanchor part then apply impulse
	part.Anchored = false
	part:SetNetworkOwner(player)

	-- add to broken pieces
	self._brokenPieces[part] = tick()

	return part
end

function Breakable:_regenerate()
	if not self._model then return end

	local parent = self._model.Parent
	if not parent then return end

	local copy = self._baseModel and self._baseModel:Clone()
	if not copy then return end

	copy.Parent = parent

	self._model:Destroy() -- will kill this component
end

function Breakable:_breakModel(model: Model, player: Player)
	local main = if model.PrimaryPart then model.PrimaryPart else model:FindFirstChildWhichIsA("BasePart", true)
	if not main then return end

	-- weld all parts to main part
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		if part == main then continue end

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = main
		weld.Part1 = part
		weld.Parent = part

		part.CollisionGroup = DEBRIS_COLLISION_GROUP
		part.Anchored = false
	end

	-- unanchor main part then apply impulse
	main.CollisionGroup = DEBRIS_COLLISION_GROUP
	main.Anchored = false
	main:SetNetworkOwner(player)

	-- add to broken pieces
	self._brokenPieces[model] = tick()

	return main
end

function Breakable.new(model: Model)
	local self = setmetatable({
		_broken = false,
		_isRegenerating = false,
		_doesRegenerate = false,
		_regenTime = -1,
		_model = model,
		_brokenPieces = {},
		_trove = Trove.new(),
		_health = model:GetAttribute("Health") or 0,
	}, Breakable)

	local regenTime: number? = model:GetAttribute("RegenTime")
	if regenTime then
		self._doesRegenerate = true
		self._regenTime = regenTime
		self._baseModel = self._trove:Clone(model)
	end

	self._trove:Connect(RunService.Heartbeat, function(_dt: number)
		local now = tick()
		for part, addTime in self._brokenPieces do
			if now - addTime >= LIFESPAN then
				part:Destroy()
				self._brokenPieces[part] = nil
				continue
			end

			local alpha = math.clamp((now - addTime) / LIFESPAN, 0, 1)
			if part:IsA("Model") then
				modelTransparencyTween(part, alpha)
			elseif part:IsA("BasePart") then
				partTransparencyTween(part, alpha)
			end
		end

		local shouldRegenerate = self._doesRegenerate and self._broken and not self._isRegenerating
		if shouldRegenerate then
			self._isRegenerating = true
			self._trove:AddPromise(Promise.delay(self._regenTime):andThen(function()
				self:_regenerate()
			end))
		end
	end)

	return self
end

function Breakable:takeDamage(player, amount)
	self._health -= amount
	if self._health <= 0 then self:breakApart(player) end
end

function Breakable:breakApart(player: Player)
	if self._broken then return end

	local children = if self._model then self._model:GetChildren() else {}
	if #children == 0 then return end

	self._broken = true
	self._model:SetAttribute("IsBroken", true)

	local parts = {}

	for _, child in children do
		if child:IsA("BasePart") then
			table.insert(parts, self:_breakPart(child, player))
		elseif child:IsA("Model") then
			table.insert(parts, self:_breakModel(child, player))
		end
	end

	-- lol
	player = player or Players:GetPlayers()[1]
	if not player then return end

	EffectService:effectPlayer(player, "impulseBreakable", {
		parts = parts,
		direction = Vector3.new(0, 1, 0),
		spread = 30,
		intensity = { 64, 128 },
	})
end

function Breakable:OnRemoved()
	self._baseModel = nil
	self._trove:Clean()
end

return ComponentService:registerComponentClass(script.Name, Breakable)
