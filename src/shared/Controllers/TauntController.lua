local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Animations = require(ReplicatedStorage.Shared.Data.Animations)
local Cooldown = require(ReplicatedStorage.Shared.Classes.Cooldown)
local Loader = require(ReplicatedStorage.Shared.Loader)
local ProductController = require(ReplicatedStorage.Shared.Controllers.ProductController)
local ProductDefinitions = require(ReplicatedStorage.Shared.Data.ProductDefinitions)
local Promise = require(ReplicatedStorage.Packages.Promise)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

local TauntController = {}
TauntController.className = "TauntController"
TauntController.priority = 0

function TauntController:init() end

function TauntController:start()
	self._cooldown = Cooldown.new(0.1)
end

function TauntController:getCooldown()
	return self._cooldown
end

function TauntController:stopTaunting()
	if self._track then
		self._track:Stop(0)
		self._track:AdjustWeight(0)
		self._track:Destroy()
		self._track = nil
	end
end

function TauntController:taunt()
	if not self._cooldown:isReady() then return end
	self._cooldown:use()

	self:stopTaunting()

	return ProductController.productData:OnReady():andThen(function(data)
		if not data.equipped then return end
		local id = data.equipped.taunt
		if not id then return end
		local def = ProductDefinitions.taunt.products[id]
		if not def then return end

		local human = WeaponUtil.getHuman()
		if not human then return end

		local animation = Animations[`Taunt{id}`]
		if not animation then return end

		self._track = human:LoadAnimation(animation)
		self._track:Play(0)

		Promise.race({
			Promise.fromEvent(human:GetPropertyChangedSignal("MoveDirection"), function()
				return not human.MoveDirection:FuzzyEq(Vector3.new())
			end),
			Promise.fromEvent(human.StateChanged, function()
				return human:GetState() == Enum.HumanoidStateType.FallingDown
			end),
		}):andThen(function()
			self:stopTaunting()
		end)
	end)
end

return Loader:registerSingleton(TauntController)
