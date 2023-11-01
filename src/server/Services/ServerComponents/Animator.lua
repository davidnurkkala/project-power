local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Animator = {}
Animator.__index = Animator

function Animator:_animate(animationId: string, speed)
	local animator: Animator = self._animator
	if not animator then return end

	local animation: Animation = self._animationTrove:Construct(Instance, "Animation")
	animation.AnimationId = animationId
	animation.Parent = animator

	local animationTrack = animator:LoadAnimation(animation)
	animationTrack:Play(0, 1, speed)
	self._animationTrove:Add(function()
		animationTrack:Stop(0)

		animationTrack:Destroy()
	end)
end

function Animator:_stopAnimation()
	self._animationTrove:Clean()
end

function Animator.new(model: Model)
	local self = setmetatable({
		_trove = Trove.new(),
		_animationTrove = nil,
		_animator = nil,
	}, Animator)

	self._animationTrove = self._trove:Extend()

	local attributes = model:GetAttributes()
	assert(attributes.AnimationId, `Animator must have an 'AnimationId' string attribute`)

	local animator = model:FindFirstChildWhichIsA("Animator", true)
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = model
		self._trove:Add(function()
			self._animator = nil
			animator:Destroy()
		end)
	end
	self._animator = animator

	self._trove:Connect(animator:GetAttributeChangedSignal("AnimationId"), function()
		local animationId = model:GetAttribute("AnimationId")
		if self._currentAnimation and self._currentAnimation.AnimationId ~= animationId then
			-- clean up existing animation
			self:_stopAnimation()
		end

		if animationId and animationId ~= "" then
			-- play new animation
			self:_animate(animationId)
		end
	end)

	if attributes.AnimationId ~= "" then self:_animate(attributes.AnimationId, attributes.AnimationSpeed or 1) end

	return self
end

function Animator:OnRemoved()
	self._trove:Clean()
end

return ComponentService:registerComponentClass(script.Name, Animator)
