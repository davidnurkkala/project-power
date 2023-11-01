local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Animations = require(ReplicatedStorage.Shared.Data.Animations)
local Damage = require(ReplicatedStorage.Shared.Classes.Damage)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local ForcedRotationHelper = require(ReplicatedStorage.Shared.Util.ForcedRotationHelper)
local JumpController = require(ReplicatedStorage.Shared.Controllers.JumpController)
local MouseUtil = require(ReplicatedStorage.Shared.Util.MouseUtil)
local Promise = require(ReplicatedStorage.Packages.Promise)
local StunController = require(ReplicatedStorage.Shared.Controllers.StunController)
local Trove = require(ReplicatedStorage.Packages.Trove)
local WeaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

type TargetFilter = (Damage.DamageTarget) -> boolean

local WeaponUtil = {}

WeaponUtil.globalCooldown = 0.1

function WeaponUtil.getWeaponDefinitions()
	return WeaponDefinitions
end

function WeaponUtil.getWeaponDefinition(weaponId: string): WeaponDefinitions.WeaponDefinition
	local weaponDefinitions = WeaponDefinitions[weaponId]
	assert(weaponDefinitions, "WeaponUtil: Could not find weapon definition for " .. weaponId)
	return weaponDefinitions
end

function WeaponUtil.getChar(player: Player?): Model?
	if RunService:IsClient() then player = Players.LocalPlayer end
	assert(player, "Missing player")

	return player.Character
end

function WeaponUtil.getRoot(player: Player?): BasePart?
	local char = WeaponUtil.getChar(player)
	if not char then return end

	return char.PrimaryPart
end

function WeaponUtil.getHuman(player: Player?): Humanoid?
	local char = WeaponUtil.getChar(player)
	if not char then return end

	return char:FindFirstChildWhichIsA("Humanoid")
end

function WeaponUtil.attachWeapon(player: Player, weaponAttachment: Attachment, characterAttachmentName: string, useMotor: boolean?, allC1: boolean?)
	local char = WeaponUtil.getChar(player)
	if not char then return end

	local characterAttachment = char:FindFirstChild(characterAttachmentName, true)
	if not characterAttachment then return end
	if not characterAttachment:IsA("Attachment") then return end

	if useMotor then
		local motor = Instance.new("Motor6D")
		motor.Part0 = characterAttachment.Parent
		motor.Part1 = weaponAttachment.Parent
		if allC1 then
			motor.C0 = CFrame.new()
			motor.C1 = weaponAttachment.CFrame * characterAttachment.CFrame:Inverse()
		else
			motor.C0 = characterAttachment.CFrame
			motor.C1 = weaponAttachment.CFrame
		end
		motor.Parent = motor.Part1
	else
		local constraint = Instance.new("RigidConstraint")
		constraint.Attachment0 = weaponAttachment
		constraint.Attachment1 = characterAttachment
		constraint.Parent = weaponAttachment.Parent
	end
end

function WeaponUtil.getTargetRoot(target: Damage.DamageTarget): BasePart?
	if target:IsA("Humanoid") then
		local char = target.Parent :: Model?
		if not char then return end
		return char.PrimaryPart
	elseif target:IsA("Model") then
		return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

function WeaponUtil.isTargetInRange(player: Player, target: Damage.DamageTarget, range: number, wiggleIn: number?): boolean
	local char = WeaponUtil.getChar(player)
	if not char then return false end
	if not char.PrimaryPart then return false end

	-- new variable to shut up the linter
	local wiggle: number = if wiggleIn == nil then 8 else wiggleIn
	range += wiggle

	if target:IsA("Model") then return true end -- we should probably send hit location and ensure it's in the bounding box of the model or something idc

	local model = target.Parent
	if not model then return false end
	if not model:IsA("Model") then return false end

	local position = model:GetPivot().Position
	local delta = position - char.PrimaryPart.Position

	return delta.Magnitude <= range
end

function WeaponUtil.findDamageTarget(part: BasePart): Damage.DamageTarget?
	local parent = part.Parent
	if not parent then return end
	if not parent:IsA("Model") then return end

	-- check for humanoid target
	local humanoid = parent:FindFirstChildWhichIsA("Humanoid")
	if humanoid then return humanoid end

	-- check for breakable target
	repeat
		if CollectionService:HasTag(parent, "Breakable") and (not parent:GetAttribute("IsBroken")) then return parent end
		parent = parent.Parent
	until parent == game

	return nil
end

function WeaponUtil.isTargetMe(target: Damage.DamageTarget): boolean
	if not target:IsA("Humanoid") then return false end
	return target.Parent == WeaponUtil.getChar()
end

function WeaponUtil.filterTarget(target: Damage.DamageTarget, filter: TargetFilter?)
	if filter then
		return filter(target)
	else
		if RunService:IsClient() then
			return not WeaponUtil.isTargetMe(target)
		else
			error("Only the client can exclude a filter")
		end
	end
end

function WeaponUtil.hitSphere(args: {
	position: Vector3,
	radius: number,
	filter: TargetFilter?,
}): { Damage.DamageTarget }
	local parts = workspace:GetPartBoundsInRadius(args.position, args.radius)

	local targetDict = {}
	for _, part in parts do
		local target = WeaponUtil.findDamageTarget(part)
		if not target then continue end

		targetDict[target] = true
	end

	local targets = {}
	for target in targetDict do
		if not WeaponUtil.filterTarget(target, args.filter) then continue end

		table.insert(targets, target)
	end

	return targets
end

function WeaponUtil.hitbox(args: {
	cframe: CFrame,
	size: Vector3,
	filter: TargetFilter?,
}): { Damage.DamageTarget }
	local parts = workspace:GetPartBoundsInBox(args.cframe, args.size)

	local targetDict = {}
	for _, part in parts do
		local target = WeaponUtil.findDamageTarget(part)
		if not target then continue end

		targetDict[target] = true
	end

	local targets = {}
	for target in targetDict do
		if not WeaponUtil.filterTarget(target, args.filter) then continue end

		table.insert(targets, target)
	end

	return targets
end

function WeaponUtil.forceJump()
	local human = WeaponUtil.getHuman()
	if not human then return Promise.reject() end

	local promise = Promise.fromEvent(human.StateChanged, function(_, state)
		return state == Enum.HumanoidStateType.Jumping
	end)

	JumpController:forceJump()

	return promise
end

function WeaponUtil.hitboxMelee(args: {
	root: BasePart,
	size: Vector3,
	filter: TargetFilter?,
	offset: CFrame?,
}): { Damage.DamageTarget }
	local offset = args.offset or CFrame.new()
	local cframe = args.root.CFrame * offset * CFrame.new(0, 0, -args.size.Z / 2)

	return WeaponUtil.hitbox({
		cframe = cframe,
		size = args.size,
		filter = args.filter,
	})
end

function WeaponUtil.hitboxLingering(args: {
	duration: number?,
	hitbox: () -> { Damage.DamageTarget },
	callback: (Damage.DamageTarget) -> boolean?,
})
	local duration = args.duration or 0.125

	local victims = {}
	local t = 0
	local stepped
	stepped = RunService.Stepped:Connect(function(_, dt)
		for _, target in args.hitbox() do
			if victims[target] then continue end
			if args.callback(target) then continue end

			victims[target] = true
		end

		t += dt
		if t >= duration then stepped:Disconnect() end
	end)
end

function WeaponUtil.channel(args: {
	duration: number,
	onFinished: (boolean) -> (),
})
	local successThread, stunned

	successThread = task.delay(args.duration, function()
		stunned:Disconnect()
		task.spawn(args.onFinished, true)
	end)

	stunned = StunController.stunned:Connect(function()
		stunned:Disconnect()
		task.cancel(successThread)
		task.spawn(args.onFinished, false)
	end)
end

function WeaponUtil.channelPromise(duration)
	return Promise.race({
		Promise.fromEvent(StunController.stunned):andThen(function()
			return Promise.reject()
		end),
		Promise.delay(duration),
	})
end

type Animator = {
	play: (Animator, string, ...any) -> AnimationTrack,
	stop: (Animator, string, ...any) -> (),
	stopHard: (Animator, string) -> (),
	get: (Animator, string) -> AnimationTrack?,
}

function WeaponUtil.createAnimator(player: Player?): Animator?
	if RunService:IsClient() then player = Players.LocalPlayer end
	assert(player, "Missing player")

	local char = WeaponUtil.getChar(player)
	if not char then return end

	local human = char:FindFirstChild("Humanoid")
	if not human then return end

	return {
		_tracks = {} :: { AnimationTrack },

		play = function(a, name, ...)
			local track = a._tracks[name]
			if not track then
				track = human:LoadAnimation(Animations[name])
				a._tracks[name] = track
			end
			track:Play(...)
			return track
		end,

		get = function(a, name)
			return a._tracks[name]
		end,

		stop = function(a, name, ...)
			local track = a._tracks[name]
			if not track then return end
			track:Stop(...)
		end,

		stopHard = function(a, name)
			local track = a._tracks[name]
			if not track then return end
			track:Stop(0)
			track:AdjustWeight(0)
		end,
	}
end

function WeaponUtil.createWaistTilter()
	local char = WeaponUtil.getChar()
	if not char then return end
	local root = WeaponUtil.getRoot()
	if not root then return end
	local human = WeaponUtil.getHuman()
	if not human then return end

	local trove = Trove.new()
	local waist = char.UpperTorso.Waist

	local rotator = ForcedRotationHelper.register(root, human)
	trove:Add(rotator, "destroy")

	local cframe = CFrame.new()
	local pauseValue = 0

	local replicator = EffectController:getRapidReplicator()
	trove:Connect(RunService.Stepped, function()
		if pauseValue > 0 then return end
		if human:GetState() == Enum.HumanoidStateType.FallingDown then return end

		local here = (waist.Part0.CFrame * waist.C0).Position
		local there = MouseUtil.raycast().position
		local delta = (there - here)
		local dy = delta.Y
		local dx = math.sqrt(delta.X ^ 2 + delta.Z ^ 2)
		local angle = math.atan2(dy, dx)

		cframe = CFrame.lookAt(root.Position, there)
		rotator:update(CFrame.lookAt(root.Position, root.Position + delta * Vector3.new(1, 0, 1)))

		replicator(EffectUtil.setMotorTransform({
			motor = waist,
			transform = CFrame.Angles(angle, 0, 0) * waist.Transform,
		}))
	end)

	return {
		getCFrame = function(_)
			return cframe
		end,
		setPaused = function(_, paused)
			pauseValue += if paused then 1 else -1
		end,
		pause = function(self)
			self:setPaused(true)
			return function()
				self:setPaused(false)
			end
		end,
		destroy = function()
			trove:Clean()
		end,
	}
end

return WeaponUtil
