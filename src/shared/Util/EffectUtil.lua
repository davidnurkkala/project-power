local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Animations = require(ReplicatedStorage.Shared.Data.Animations)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local weaponDefinitions = require(ReplicatedStorage.Shared.Data.WeaponDefinitions)

local PI = math.pi
local TAU = PI * 2

local Effects = Instance.new("Folder")
Effects.Name = "Effects"
Effects.Parent = workspace

local PersistentEffectsByGuid = {}

local function desist(guid)
	if not guid then return end
	PersistentEffectsByGuid[guid] = nil
end

local function failsafe(guid)
	return task.delay(120, function()
		desist(guid)
	end)
end

local function persist(guid, effect)
	if not guid then return end
	PersistentEffectsByGuid[guid] = {
		effect = effect,
		thread = failsafe(guid),
	}
end

local function recall(guid, callback: (any) -> boolean?)
	if not guid then return end

	local data = PersistentEffectsByGuid[guid]
	if data then
		if callback(data.effect) then desist(guid) end

		-- if callback did not desist the effect, reset its cleanup timer
		if PersistentEffectsByGuid[guid] then
			task.cancel(data.thread)
			data.thread = failsafe(guid)
		end
	end
end

local function getNumberSequence(sequence: NumberSequence, time: number)
	if time == 0 then
		return sequence.Keypoints[1].Value
	elseif time == 1 then
		return sequence.Keypoints[#sequence.Keypoints].Value
	end

	for i = 1, #sequence.Keypoints - 1 do
		local currKeypoint = sequence.Keypoints[i]
		local nextKeypoint = sequence.Keypoints[i + 1]
		if time >= currKeypoint.Time and time < nextKeypoint.Time then
			local alpha = (time - currKeypoint.Time) / (nextKeypoint.Time - currKeypoint.Time)
			return currKeypoint.Value + (nextKeypoint.Value - currKeypoint.Value) * alpha
		end
	end

	return 0
end

local function sequence(...)
	local numbers = { ... }
	local keypoints = {}
	for index = 1, #numbers, 2 do
		table.insert(keypoints, NumberSequenceKeypoint.new(numbers[index], numbers[index + 1]))
	end
	return NumberSequence.new(keypoints)
end

local function lerp(a, b, alpha)
	return a + (b - a) * alpha
end

local function animation(duration, callback)
	return Promise.new(function(resolve, _, onCancel)
		callback(0)

		local heartbeat
		local t = 0
		heartbeat = RunService.Heartbeat:Connect(function(dt)
			t += dt

			local alpha = math.min(t / duration, 1)
			callback(alpha)

			if alpha == 1 then
				heartbeat:Disconnect()
				resolve()
			end
		end)

		onCancel(function()
			heartbeat:Disconnect()
			callback(1)
		end)
	end)
end

local function listeningPosition(): Vector3
	local char = Players.LocalPlayer.Character
	if not char then return Vector3.new() end

	return char:GetPivot().Position
end

local EffectUtil = {}

EffectUtil.replicationRequested = Signal.new()
EffectUtil.RAPID_REPLICATION_TIME = 1 / 20

function EffectUtil.guid()
	return HttpService:GenerateGUID(false)
end

function EffectUtil.part(): BasePart
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = Color3.new(1, 0, 1)
	return part
end

local PUNCH_EFFECT_TRANSPARENCY = sequence(0, 1, 0.25, 0, 0.75, 0, 1, 1)
local PUNCH_LENGTH = sequence(0, 0, 0.5, 1, 1, 1)
local PUNCH_WIDTH = sequence(0, 0, 0.9, 1, 1, 1)
function EffectUtil.punch(args: {
	root: BasePart,
	startOffset: CFrame,
	endOffset: CFrame,
	width: number,
	length: number,
	duration: number,
	color: Color3?,
})
	local part = EffectUtil.part()
	part.Size = Vector3.new()
	part.Transparency = 1

	local gui = Instance.new("SurfaceGui") :: SurfaceGui
	gui.LightInfluence = 0
	gui.Brightness = 2
	gui.Face = Enum.NormalId.Top
	gui.Adornee = part
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 64

	local image = Instance.new("ImageLabel")
	image.Size = UDim2.fromScale(1, 1)
	image.Image = "rbxassetid://13668406858"
	image.BackgroundTransparency = 1
	image.Parent = gui

	gui.Parent = part

	local function setCFrame(alpha)
		local offset = args.startOffset:Lerp(args.endOffset, alpha)
		part.CFrame = args.root.CFrame * offset

		local look = workspace.CurrentCamera.CFrame.LookVector
		local right = look:Cross(part.CFrame.LookVector).Unit
		local up = right:Cross(part.CFrame.LookVector).Unit
		part.CFrame = CFrame.fromMatrix(part.Position, right, up) * CFrame.Angles(0, math.pi / 2, 0)
	end

	animation(args.duration, function(alpha)
		local width = args.width * getNumberSequence(PUNCH_WIDTH, alpha)
		local length = args.length * getNumberSequence(PUNCH_LENGTH, alpha)
		part.Size = Vector3.new(length, 0, width)
		setCFrame(alpha)
		image.ImageTransparency = getNumberSequence(PUNCH_EFFECT_TRANSPARENCY, alpha)
	end):andThen(function()
		part:Destroy()
	end)

	part.Parent = Effects

	return "punch", args
end

function EffectUtil.stab(args: {
	root: BasePart,
	startOffset: CFrame,
	endOffset: CFrame,
	width: number,
	length: number,
	duration: number,
	color: Color3?,
})
	local part = EffectUtil.part()
	part.Size = Vector3.new()
	part.Transparency = 1

	local gui = Instance.new("SurfaceGui") :: SurfaceGui
	gui.LightInfluence = 0
	gui.Brightness = 2
	gui.Face = Enum.NormalId.Top
	gui.Adornee = part
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 64

	local image = Instance.new("ImageLabel")
	image.Size = UDim2.fromScale(1, 1)
	image.Image = "rbxassetid://14709880222"
	image.BackgroundTransparency = 1
	image.Rotation = 180
	image.Parent = gui

	gui.Parent = part

	local function setCFrame(alpha)
		local offset = args.startOffset:Lerp(args.endOffset, alpha)
		part.CFrame = args.root.CFrame * offset

		local look = workspace.CurrentCamera.CFrame.LookVector
		local right = look:Cross(part.CFrame.LookVector).Unit
		local up = right:Cross(part.CFrame.LookVector).Unit
		part.CFrame = CFrame.fromMatrix(part.Position, right, up) * CFrame.Angles(0, math.pi / 2, 0)
	end

	animation(args.duration, function(alpha)
		local width = lerp(args.width, args.width / 2, math.pow(alpha, 3))
		local length = lerp(0, args.length, math.pow(alpha, 0.5))
		part.Size = Vector3.new(length, 0, width)
		setCFrame(alpha)
		image.ImageTransparency = getNumberSequence(PUNCH_EFFECT_TRANSPARENCY, alpha)
	end):andThen(function()
		part:Destroy()
	end)

	part.Parent = Effects

	return "stab", args
end

function EffectUtil.debris1(args: {
	cframe: CFrame,
	radius: number,
	particleCount: number,
})
	local part = EffectUtil.part()
	part.Size = Vector3.new(args.radius * 2, 0, args.radius * 2)
	part.Transparency = 1
	part.CFrame = args.cframe

	local rocks = ReplicatedStorage.Assets.Emitters.Rocks1:Clone()
	rocks.Parent = part

	local dust = ReplicatedStorage.Assets.Emitters.Dust1:Clone()
	dust.Parent = part

	part.Parent = Effects

	task.defer(function()
		rocks:Emit(args.particleCount)
		dust:Emit(args.particleCount)
		task.wait(math.max(rocks.Lifetime.Max, dust.Lifetime.Max))
		part:Destroy()
	end)

	return "debris1", args
end

function EffectUtil.impact1(args: {
	cframe: CFrame,
	radius: number,
	duration: number,
	color: Color3?,
})
	local part = ReplicatedStorage.Assets.Effects.Impact1:Clone()
	part.Size = Vector3.new(args.radius * 2, 0, args.radius * 2)
	part.CFrame = args.cframe
	part.Parent = Effects

	animation(args.duration, function(alpha)
		part.Gui.Image.ImageTransparency = alpha
	end):andThen(function()
		part:Destroy()
	end)

	return "impact1", args
end

function EffectUtil.burst1(args: {
	cframe: CFrame,
	radius: number,
	duration: number,
	rotationSpeed: number?,
	partName: string?,
	power: number?,
})
	local part = ReplicatedStorage.Assets.Effects[args.partName or "Burst1"]:Clone()
	part.CFrame = args.cframe
	part.Parent = Effects

	local size = Vector3.new(2.5, 2.5, 2.5) * args.radius
	local rotation = (args.rotationSpeed or math.rad(360)) * args.duration

	animation(args.duration, function(alphaRaw)
		local alpha = math.pow(alphaRaw, args.power or 0.3)

		part.Size = lerp(Vector3.new(), size, alpha)
		part.Transparency = alpha
		part.CFrame = args.cframe * CFrame.Angles(0, rotation * alpha, 0)
	end):andThen(function()
		part:Destroy()
	end)

	return "burst1", args
end

local SLASH_1_TRANSPARENCY = sequence(0, 1, 0.25, 0, 0.75, 0, 1, 1)
function EffectUtil.slash1(args: {
	root: BasePart,
	cframe: CFrame,
	rotation: number,
	radius: number,
	duration: number,
	color: Color3?,
	partName: string?,
	guid: string?,
})
	local part = ReplicatedStorage.Assets.Effects[args.partName or "Slash1"]:Clone()
	part.Size = Vector3.new(args.radius * 2, 0, args.radius * 2)

	local scale = part:GetAttribute("Scale")
	if scale then
		part.Size *= Vector3.new(scale, 1, scale)
	end

	if args.color then
		part.TopGui.Image.ImageColor3 = args.color
		part.BotGui.Image.ImageColor3 = args.color
	end

	local function setTransparency(alpha)
		local t = getNumberSequence(SLASH_1_TRANSPARENCY, alpha)
		part.TopGui.Image.ImageTransparency = t
		part.BotGui.Image.ImageTransparency = t
	end

	local function setCFrame(alpha)
		local offset = args.cframe * CFrame.Angles(0, args.rotation * alpha, 0)
		part.CFrame = args.root.CFrame * offset
	end

	local function cleanUp()
		part:Destroy()
		desist(args.guid)
	end

	local promise = animation(args.duration, function(alpha)
		setTransparency(alpha)
		setCFrame(alpha)
	end):andThen(cleanUp)

	persist(args.guid, function()
		promise:cancel()
		cleanUp()
	end)

	part.Parent = Effects

	return "slash1", args
end

local SLASH_2_TRANSPARENCY = sequence(0, 0, 0.5, 1, 1, 1)
function EffectUtil.slash2(args: {
	root: BasePart,
	cframe: CFrame,
	rotation: number,
	radius: number,
	duration: number,
	color: Color3?,
	partName: string?,
	guid: string?,
})
	local part = ReplicatedStorage.Assets.Effects[args.partName or "Slash1"]:Clone()
	part.Size = Vector3.new(args.radius * 2, 0, args.radius * 2)

	local scale = part:GetAttribute("Scale")
	if scale then
		part.Size *= Vector3.new(scale, 1, scale)
	end

	if args.color then
		part.TopGui.Image.ImageColor3 = args.color
		part.BotGui.Image.ImageColor3 = args.color
	end

	local gradient = Instance.new("UIGradient")
	gradient.Transparency = SLASH_2_TRANSPARENCY
	gradient.Parent = part.TopGui.Image
	local gradient2 = gradient:Clone()
	gradient2.Parent = part.BotGui.Image
	local function setGradient(alpha)
		gradient.Rotation = 270 + math.deg(args.rotation) * alpha
		gradient2.Rotation = -gradient.Rotation
	end

	local function setCFrame(alpha)
		local offset = args.cframe * CFrame.Angles(0, args.rotation * alpha, 0)
		part.CFrame = args.root.CFrame * offset
	end

	local function cleanUp()
		part:Destroy()
		desist(args.guid)
	end

	local promise = animation(args.duration, function(alpha)
		setGradient(alpha)
		setCFrame(alpha)
	end):andThen(cleanUp)

	persist(args.guid, function()
		promise:cancel()
		cleanUp()
	end)

	part.Parent = Effects

	return "slash2", args
end

function EffectUtil.cancel(args: {
	guid: string?,
})
	recall(args.guid, function(cancelCallback)
		cancelCallback()
		return true
	end)
	return "cancel", args
end

function EffectUtil.dash(args: {
	root: BasePart,
	duration: number,
	soundDisabled: boolean?,
})
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1, 0)
	a0.Parent = args.root

	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1, 0)
	a1.Parent = args.root

	local trail = ReplicatedStorage.Assets.Trails.DashTrail:Clone()
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Parent = args.root

	if not args.soundDisabled then
		local sound = ReplicatedStorage.Assets.Sounds.Dash1:Clone()
		sound.Parent = args.root
		sound:Play()
		task.delay(sound.TimeLength, sound.Destroy, sound)
	end

	task.delay(args.duration, function()
		trail.Enabled = false
		task.wait(trail.Lifetime)
		a0:Destroy()
		a1:Destroy()
		trail:Destroy()
	end)

	return "dash", args
end

function EffectUtil.demonDash(args: {
	root: BasePart,
	duration: number,
	soundDisabled: boolean?,
})
	local character = args.root.Parent
	if not character or not character:IsA("Model") then return end

	local function makeAttachment(parent: any, cframe: CFrame)
		local attachment = Instance.new("Attachment")
		attachment.CFrame = cframe
		attachment.Parent = parent
		return attachment
	end

	local function spawnAfterImage(char: Model, transitionDuration: number)
		local clone = Instance.new("Model")

		for _, limb in char:GetChildren() do
			if not limb:IsA("BasePart") then continue end

			local limbClone = limb:Clone()
			limbClone:ClearAllChildren()
			limbClone.Color = Color3.fromRGB(0, 0, 20)
			limbClone.CanCollide = false
			limbClone.CanQuery = false
			limbClone.CanTouch = false
			limbClone.Anchored = true
			limbClone.Transparency = limbClone.Transparency == 1 and limbClone.Transparency or 0.2
			limbClone.Material = Enum.Material.Neon

			if limbClone:IsA("MeshPart") then limbClone.TextureID = "" end
			limbClone.Parent = clone

			local currentTransparency = limbClone.Transparency
			local tweenDuration = (1 - (currentTransparency / 1)) * transitionDuration
			local tween = TweenService:Create(limbClone, TweenInfo.new(tweenDuration), { Transparency = 1 })
			tween:Play()
		end

		clone.Parent = Effects
		task.delay(transitionDuration, clone.Destroy, clone)

		return clone
	end

	local function spawnSmearTrail(char, duration)
		local root = char.PrimaryPart
		if not root then return end

		local smearTrail = ReplicatedStorage.Assets.Trails["DemonSmear"]:Clone()

		local attachmentTop = makeAttachment(root, CFrame.new(0, 2, 0))
		local attachmentBottom = makeAttachment(root, CFrame.new(0, -2, 0))
		task.delay(duration, attachmentTop.Destroy, attachmentTop)
		task.delay(duration, attachmentBottom.Destroy, attachmentBottom)

		smearTrail.Attachment0 = attachmentTop
		smearTrail.Attachment1 = attachmentBottom
		smearTrail.Parent = attachmentTop
	end

	local function spawnAfterImageEmitter(parent: any)
		local afterImageEmitter = ReplicatedStorage.Assets.Emitters["DemonAfterImage"]:Clone()
		afterImageEmitter.Parent = parent
		afterImageEmitter:Emit(10)
		task.delay(afterImageEmitter.Lifetime.Max, afterImageEmitter.Destroy, afterImageEmitter)
		return afterImageEmitter
	end

	local function spawnEyeEffect(char, duration)
		local head = char:FindFirstChild("Head")
		if not head then return end
		local faceFrontAttachment = head:FindFirstChild("FaceFrontAttachment")
		if not faceFrontAttachment then return end

		local function makeEyeTrail(baseAttachment: Attachment, eyeAttachment: Attachment, trailDuration: number)
			local demonEyesTrail = ReplicatedStorage.Assets.Trails["DemonEyesTrail"]:Clone()
			demonEyesTrail.Attachment0 = eyeAttachment
			demonEyesTrail.Attachment1 = baseAttachment
			demonEyesTrail.Parent = eyeAttachment
			task.delay(trailDuration, demonEyesTrail.Destroy, demonEyesTrail)

			return demonEyesTrail
		end

		local function makeEyeGlow(eyeAttachment: Attachment): Attachment
			local baseEmitter = ReplicatedStorage.Assets.Emitters["DemonEyesShine"]
			baseEmitter.Lifetime = NumberRange.new(duration)

			local eyeEmitter = baseEmitter:Clone()
			eyeEmitter.Parent = eyeAttachment

			return eyeEmitter
		end

		local leftEyeAttachment = makeAttachment(faceFrontAttachment, CFrame.new(-0.3, 0, 0))
		local rightEyeAttachment = makeAttachment(faceFrontAttachment, CFrame.new(0.3, 0, 0))
		local leftEyeEmitter = makeEyeGlow(leftEyeAttachment)
		local rightEyeEmitter = makeEyeGlow(rightEyeAttachment)

		makeEyeTrail(faceFrontAttachment, leftEyeAttachment, duration)
		makeEyeTrail(faceFrontAttachment, rightEyeAttachment, duration)

		task.delay(math.max(leftEyeEmitter.Lifetime.Max, duration), function()
			leftEyeEmitter:Destroy()
			rightEyeEmitter:Destroy()
		end)

		leftEyeEmitter:Emit(1)
		rightEyeEmitter:Emit(1)
	end

	local clonePerSecond = 10
	local timeEnd = tick() + args.duration
	local lastTime = 0
	local c = nil
	RunService.Heartbeat:Connect(function()
		if not character then c:Disconnect() end

		local currentTime = tick()
		if currentTime > timeEnd then return end

		if currentTime - lastTime > 1 / clonePerSecond then
			lastTime = currentTime
			spawnAfterImage(character, 0.8)
		end
	end)

	task.spawn(spawnSmearTrail, character, args.duration)
	task.spawn(spawnEyeEffect, character, args.duration)

	if character.PrimaryPart then
		EffectUtil.sound({
			parent = character.PrimaryPart,
			position = nil,
			name = "DemonDash1",
		})
		EffectUtil.sound({
			parent = character.PrimaryPart,
			position = nil,
			name = "DemonDash2",
		})
		task.spawn(spawnAfterImageEmitter, character.PrimaryPart)
	end

	return "demonDash", args
end

function EffectUtil.demonAttack(args: {
	character: Model,
	duration: number,
})
	if not args.character then return end
	local configs = {
		LeftHand = { "LeftGripAttachment", "LeftWristRigAttachment" },
		RightHand = { "RightGripAttachment", "RightWristRigAttachment" },
		LeftFoot = { "LeftFootAttachment", "LeftAnkleRigAttachment" },
		RightFoot = { "RightFootAttachment", "RightAnkleRigAttachment" },
	}

	local function spawnHandEffect(hand: Part, duration: number): ParticleEmitter
		local emitter = ReplicatedStorage.Assets.Emitters["DemonHand"]:Clone()
		emitter.Parent = hand
		task.delay(duration, function()
			if emitter then emitter.Enabled = false end
		end)
		task.delay(emitter.Lifetime.Max + duration, emitter.Destroy, emitter)

		return emitter
	end

	local function spawnLimbTrail(limbName: string, attachName0: string, attachName1: string, duration: number)
		local limb = args.character:FindFirstChild(limbName)
		if not limb then return end

		local attachment0 = limb:FindFirstChild(attachName0)
		if not attachment0 then return end

		local attachment1 = limb:FindFirstChild(attachName1)
		if not attachment1 then return end

		local trail = ReplicatedStorage.Assets.Trails["DemonLimbTrail"]:Clone()
		trail.Attachment0 = attachment0
		trail.Attachment1 = attachment1

		task.delay(duration, function()
			if trail then trail.Enabled = false end
		end)

		trail.Parent = Effects
		trail.Enabled = true
		task.delay(duration + trail.Lifetime, trail.Destroy, trail)

		return trail
	end

	local leftHand = args.character:FindFirstChild("LeftHand")
	local rightHand = args.character:FindFirstChild("RightHand")

	if leftHand then spawnHandEffect(leftHand, args.duration) end
	if rightHand then spawnHandEffect(rightHand, args.duration) end

	for limbName, attachments in configs do
		spawnLimbTrail(limbName, attachments[1], attachments[2], args.duration)
	end

	return "demonAttack", args
end

function EffectUtil.demonFlip(args: {
	character: Model,
})
	local root = args.character.PrimaryPart
	if not root then return end

	local rootAttachment = root:FindFirstChild("RootRigAttachment")
	if not rootAttachment then return end

	local symbolEmitter = root:FindFirstChild("DemonSymbol")
	if not symbolEmitter then return end

	symbolEmitter:Emit(1)

	EffectUtil.sound({
		parent = root,
		name = "DemonSymbol",
	})

	return "demonFlip", args
end

function EffectUtil.demonDrop(args: {
	character: Model,
	rayInstance: Instance,
	rayPosition: Vector3,
})
	local function spawnDebris(cframe, speed, partHit)
		local part = EffectUtil.part()
		part.Anchored = false
		part.Massless = true
		part.Color = partHit.Color
		part.Material = partHit.Material
		part.Parent = Effects
		part.Size = part.Size * math.random(1, 2)

		part.CFrame = cframe
		part.AssemblyLinearVelocity = (part.CFrame.LookVector + part.CFrame.UpVector).Unit * math.random(speed * 0.8, speed)
		part.Orientation = Vector3.new(math.random(360), math.random(360), math.random(360))
		task.delay(3, part.Destroy, part)

		return part
	end

	local blocksAmount = 8
	for i = 1, blocksAmount do
		local rot = i * (360 / blocksAmount)
		local cf = CFrame.new(args.rayPosition) * CFrame.Angles(0, math.rad(rot), 0)
		spawnDebris(cf, 50, args.rayInstance)
	end

	local emitterPart = EffectUtil.part()
	emitterPart.Transparency = 1
	emitterPart.CFrame = CFrame.new(args.rayPosition + Vector3.new(0, 2, 0))
	emitterPart.Parent = Effects

	local emitter = ReplicatedStorage.Assets.Emitters["ImpactSmoke"]:Clone()
	emitter.Parent = emitterPart
	emitter.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
	emitter:Emit(40)
	task.delay(emitter.Lifetime.Max, emitter.Destroy, emitter)

	EffectUtil.sound({
		position = args.rayPosition,
		name = "RockImpact1",
	})

	return "demonDrop", args
end

function EffectUtil.gojoBall(args: {
	part: any,
	root: BasePart,
	direction: Vector3,
	sizeStart: number,
	sizeEnd: number,
	duration: number,
	persistent: boolean?,
	guid: string,
})
	local persistent = if args.persistent == nil then false else args.persistent

	local part = args.part:Clone()
	part.Parent = Effects

	local emitters = Sift.Array.map(part:GetDescendants(), function(object)
		if not object:isA("ParticleEmitter") then return end
		object:Emit(1)
		return {
			emitter = object,
			ratio = object.Size.Keypoints[1].Value / part.Size.X,
		}
	end)

	local promise = animation(args.duration, function(scalar)
			local size = lerp(args.sizeStart, args.sizeEnd, scalar)
			local offset = CFrame.new(args.direction * size * 0.5)
			local cframe = args.root.CFrame * offset

			part.Size = Vector3.one * size
			part.CFrame = cframe

			for _, emitter in emitters do
				emitter.emitter.Size = NumberSequence.new(size * emitter.ratio)
			end
		end)
		:andThen(function()
			if persistent then
				return Promise.fromEvent(RunService.Heartbeat, function()
					local offset = CFrame.new(args.direction * args.sizeEnd * 0.5)
					local cframe = args.root.CFrame * offset
					part.CFrame = cframe

					return false
				end)
			else
				return
			end
		end)
		:finally(function()
			if not persistent then part:Destroy() end

			desist(args.guid)
		end)

	persist(args.guid, function()
		if persistent then part:Destroy() end
		promise:cancel()
	end)
end

function EffectUtil.sound(args: {
	parent: Instance?,
	position: Vector3?,
	name: string,
	duration: number?,
	pitchRange: NumberRange?,
	looping: boolean?,
	fadeIn: number?,
	guid: string?,
})
	local looping = if args.looping == nil then false else args.looping
	local baseSound = ReplicatedStorage.Assets.Sounds[args.name]
	local length = baseSound.TimeLength

	local sound = baseSound:Clone()
	sound.Looped = looping
	local cleanUp

	if args.pitchRange then
		local pitch = Instance.new("PitchShiftSoundEffect")
		pitch.Octave = math.random(args.pitchRange.Min, args.pitchRange.Max)
		pitch.Parent = sound
	end

	if args.fadeIn then
		local volume = sound.Volume
		animation(1, function(scalar)
			sound.Volume = lerp(0, volume, scalar)
		end):finally(function()
			sound.Volume = volume
		end)
	end

	if args.parent then
		sound.Parent = args.parent
		sound:Play()

		cleanUp = function()
			sound:Destroy()
			desist(args.guid)
		end
	else
		local part = EffectUtil.part()
		part.Size = Vector3.new()
		part.Position = args.position
		part.Parent = Effects

		sound.Parent = part
		sound:Play()

		cleanUp = function()
			part:Destroy()
			desist(args.guid)
		end
	end

	local thread
	if not looping then thread = task.delay(args.duration or length, cleanUp) end

	persist(args.guid, function()
		if thread then task.cancel(thread) end

		cleanUp()
	end)

	return "sound", args
end

function EffectUtil.randomSpin(position)
	return CFrame.new(position) * CFrame.Angles(math.pi * 2 * math.random(), 0, math.pi * 2 * math.random())
end

function EffectUtil.hitEffect(args: {
	part: BasePart,
	emitterName: string,
	particleCount: number,
	soundName: string?,
	pitchRange: NumberRange?,
	color: (Color3 | ColorSequence)?,
})
	local attachment = Instance.new("Attachment")
	attachment.Parent = args.part

	local lifetime = 0

	local emitter = ReplicatedStorage.Assets.Emitters[args.emitterName]:Clone() :: ParticleEmitter
	if args.color then emitter.Color = if typeof(args.color) == "Color3" then ColorSequence.new(args.color) else args.color end
	lifetime = math.max(lifetime, emitter.Lifetime.Max)
	emitter.Parent = attachment

	if args.soundName then EffectUtil.sound({
		parent = args.part,
		name = args.soundName,
		pitchRange = args.pitchRange,
	}) end

	task.defer(function()
		emitter:Emit(args.particleCount)
		task.wait(lifetime)
		attachment:Destroy()
	end)

	return "hitEffect", args
end

function EffectUtil.spinModel(args: {
	root: BasePart,
	model: Model,
	duration: number,
	offset: CFrame,
	rotationSpeed: number,
	guid: string?,
})
	local model = args.model:Clone()

	for _, object in model:GetDescendants() do
		if object:IsA("Motor6D") then
			object:Destroy()
		elseif object:IsA("BasePart") then
			object.CanCollide = false
			object.Anchored = true
			object.CanTouch = false
			object.CanQuery = false
		end
	end

	model.Parent = Effects

	local function cleanUp()
		model:Destroy()
		desist(args.guid)
	end

	local rotation = args.rotationSpeed * args.duration

	local promise = animation(args.duration, function(alpha)
		local cframe = args.root.CFrame * CFrame.Angles(0, rotation * alpha, 0) * args.offset
		model:PivotTo(cframe)
	end):andThen(cleanUp)

	persist(args.guid, function()
		promise:cancel()
		cleanUp()
	end)

	return "spinModel", args
end

function EffectUtil.hideModel(args: {
	model: Model,
	guid: string,
})
	local trove = Trove.new()

	for _, object in args.model:GetDescendants() do
		if not object:IsA("BasePart") then continue end
		local transparency = object.Transparency
		trove:Add(function()
			object.Transparency = transparency
		end)
		object.Transparency = 1
	end

	persist(args.guid, function()
		trove:Clean()
	end)

	return "hideModel", args
end

function EffectUtil.balefire(args: {
	root: BasePart,
	duration: number,
	range: number,
	guid: string?,
})
	local part = ReplicatedStorage.Assets.Effects.MagicCircleFire1:Clone()

	local a0 = Instance.new("Attachment")
	a0.Parent = part

	local a1 = Instance.new("Attachment")
	a1.CFrame = CFrame.new(0, 0, -args.range)
	a1.Parent = part

	local beam = ReplicatedStorage.Assets.Beams.BalefireBeam:Clone()
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Parent = part

	local function setTransparency(t)
		part.FrontGui.Image.ImageTransparency = t
		part.BackGui.Image.ImageTransparency = t
	end
	local function setRadius(r)
		part.Size = Vector3.new(r * 2, r * 2, 0)
	end

	local function setWidth(w)
		beam.Width0 = w
		beam.Width1 = w
	end

	local function setBeamTransparency(t)
		beam.Transparency = sequence(0, 1, 0.05, t, 1, t)
	end

	setBeamTransparency(0)

	local soundGuid = EffectUtil.guid()
	EffectUtil.sound({
		guid = soundGuid,
		name = "BalefireCharge",
		parent = args.root,
	})

	local function cleanUp()
		part:Destroy()
		desist(args.guid)
		desist(soundGuid)
	end

	local promise = animation(args.duration, function(alpha)
		alpha = math.pow(alpha, 0.5)

		setTransparency(lerp(1, 0, alpha))
		setRadius(lerp(16, 2, alpha))

		local rotation = lerp(TAU, 0, alpha)
		part.CFrame = args.root.CFrame * CFrame.new(0, 0, -4) * CFrame.Angles(0, 0, rotation)
	end):andThen(function()
		local ray = Ray.new(args.root.CFrame.Position, args.root.CFrame.LookVector)
		local here = listeningPosition()
		local position = ray:ClosestPoint(here)

		EffectUtil.sound({
			name = "BalefireCast",
			position = position,
		})

		return animation(0.2, function(alpha)
			alpha = math.pow(alpha, 0.5)

			setTransparency(lerp(0, 1, alpha))
			setRadius(lerp(2, 16, alpha))
			setWidth(lerp(0.5, 8, alpha))
			setBeamTransparency(lerp(0, 1, alpha))
		end):andThen(cleanUp)
	end)

	persist(args.guid, function()
		promise:cancel()
		EffectUtil.cancel({ guid = soundGuid })
		cleanUp()
	end)

	part.Parent = Effects

	return "balefire", args
end

function EffectUtil.setRootCFrameHelper(args: {
	root: BasePart,
	cframe: CFrame,
})
	if args.root.Parent == Players.LocalPlayer.Character then return end

	local cframe = args.root.CFrame
	animation(EffectUtil.RAPID_REPLICATION_TIME, function(alpha)
		args.root.CFrame = cframe:Lerp(args.cframe, alpha)
	end)
end

function EffectUtil.setRootCFrame(args: {
	root: BasePart,
	cframe: CFrame,
})
	args.root.CFrame = args.cframe

	return "setRootCFrameHelper", args
end

local MotorTransformers: { [Motor6D]: any } = {}

function EffectUtil.setMotorTransformHelper(args: {
	motor: Motor6D,
	transform: CFrame,
})
	if args.motor:IsDescendantOf(Players.LocalPlayer.Character) then return end

	if MotorTransformers[args.motor] then MotorTransformers[args.motor]:Clean() end

	local trove = Trove.new()

	trove:Add(function()
		MotorTransformers[args.motor] = nil
	end)

	trove:Connect(RunService.Stepped, function()
		EffectUtil.setMotorTransform(args)
	end)

	trove:AddPromise(Promise.delay(EffectUtil.RAPID_REPLICATION_TIME * 2):andThen(function()
		trove:Clean()
	end))

	MotorTransformers[args.motor] = trove
end

function EffectUtil.setMotorTransform(args: {
	motor: Motor6D,
	transform: CFrame,
})
	args.motor.Transform = args.transform

	return "setMotorTransformHelper", args
end

function EffectUtil.trail(args: {
	root: BasePart,
	offset0: CFrame,
	offset1: CFrame,
	trailName: string,
	guid: string,
})
	local a0 = Instance.new("Attachment")
	a0.CFrame = args.offset0
	a0.Parent = args.root

	local a1 = Instance.new("Attachment")
	a1.CFrame = args.offset1
	a1.Parent = args.root

	local trail = ReplicatedStorage.Assets.Trails[args.trailName]:Clone()
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Parent = args.root

	persist(args.guid, function()
		trail.Enabled = false
		task.delay(trail.Lifetime, function()
			a0:Destroy()
			a1:Destroy()
			trail:Destroy()
		end)
	end)

	return "trail", args
end

function EffectUtil.emitAtCFrame(args: {
	emitterName: string,
	particleCount: number,
	cframe: CFrame,
	useAttachment: boolean?,
})
	local part = EffectUtil.part()
	part.CFrame = args.cframe
	part.Transparency = 1
	part.Parent = Effects

	local clonedEmitter = ReplicatedStorage.Assets.Emitters[args.emitterName]:Clone()

	if args.useAttachment then
		local attachment = Instance.new("Attachment")
		attachment.Parent = part
		clonedEmitter.Parent = attachment
	else
		clonedEmitter.Parent = part
	end

	clonedEmitter:Emit(args.particleCount)
	task.delay(clonedEmitter.Lifetime.Max, part.Destroy, part)

	return "emitAtCFrame", args
end

function EffectUtil.emit(args: {
	emitter: ParticleEmitter,
	particleCount: number,
})
	args.emitter:Emit(args.particleCount)

	return "emit", args
end

function EffectUtil.enable(args: {
	guid: string,
	object: { Enabled: boolean },
})
	args.object.Enabled = true
	persist(args.guid, function()
		args.object.Enabled = false
	end)

	return "enable", args
end

function EffectUtil.impulseBreakable(args: {
	parts: { BasePart },
	direction: Vector3,
	spread: number?,
	intensity: { number },
})
	local baseCFrame = CFrame.lookAt(Vector3.new(), args.direction)
	local spread = math.rad(args.spread or 0)

	for _, part in args.parts do
		local cframe = baseCFrame * CFrame.Angles(0, math.pi * 2 * math.random(), 0) * CFrame.Angles(spread * math.random(), 0, 0)
		local velocity = cframe.LookVector * math.random(args.intensity[1], args.intensity[2])
		part.AssemblyLinearVelocity = velocity
	end
end

function EffectUtil.levelUp(args: {
	human: Humanoid,
})
	local root = args.human.RootPart

	EffectUtil.sound({
		parent = root,
		name = "LevelUp1",
	})

	local attachment = Instance.new("Attachment")
	attachment.Parent = root

	local emitters = Sift.Array.map(ReplicatedStorage.Assets.Emitters.LevelUp2:GetChildren(), function(emitter)
		return emitter:Clone()
	end)

	local lifetime = 0
	for _, emitter in emitters do
		lifetime = math.max(lifetime, emitter.Lifetime.Max)
		emitter.Parent = attachment
		task.defer(emitter.Emit, emitter, 1)
	end

	task.delay(lifetime, attachment.Destroy, attachment)
end

function EffectUtil.reattach(args: {
	guid: string,
	motor: Motor6D,
	attachment0: Attachment,
	attachment1: Attachment,
})
	args.motor.Enabled = false

	local rigid = Instance.new("RigidConstraint")
	rigid.Attachment0 = args.attachment0
	rigid.Attachment1 = args.attachment1
	rigid.Parent = args.attachment0.Parent

	persist(args.guid, function()
		rigid:Destroy()
		args.motor.Enabled = true
	end)

	return "reattach", args
end

function EffectUtil.flash(args: {
	light: Light,
	duration: number,
	smooth: boolean?,
})
	local smooth = if args.smooth == nil then false else args.smooth
	local light = args.light :: Light

	if smooth then
		light.Enabled = true

		if not light:GetAttribute("OriginalRange") then light:SetAttribute("OriginalRange", light.Range) end

		animation(args.duration, function(alpha)
			light.Range = lerp(light:GetAttribute("OriginalRange"), 0, alpha)
		end):andThen(function()
			light.Enabled = false
		end)
	else
		light.Enabled = true
		task.delay(args.duration, function()
			light.Enabled = false
		end)
	end

	return "flash", args
end

function EffectUtil.powerUpSpin(args: {
	guid: string,
	model: Model,
	rootPart: BasePart,
})
	local fadeModel = args.model:Clone()

	local offset = args.rootPart.CFrame:ToObjectSpace(args.model:GetPivot())
	local amplitude = 1
	local rotationSpeed = math.pi * 2

	local trove = Trove.new()
	trove:Connect(RunService.Heartbeat, function()
		local clock = tick() % 1

		local cframe = args.rootPart.CFrame * offset
		local dy = math.sin(rotationSpeed * clock) * amplitude
		args.model:PivotTo(cframe * CFrame.new(0, dy, 0) * CFrame.Angles(0, rotationSpeed * clock, 0))
	end)
	trove:Add(function()
		fadeModel.Parent = Effects

		offset = args.rootPart.CFrame:ToObjectSpace(args.model:GetPivot())

		local parts = Sift.Array.filter(fadeModel:GetDescendants(), function(object)
			return object:IsA("BasePart")
		end)
		animation(0.2, function(alpha)
			alpha = math.pow(alpha, 0.5)

			fadeModel:ScaleTo(1 + alpha * 3)
			fadeModel:PivotTo(args.rootPart.CFrame * offset)

			for _, part in parts do
				part.Transparency = math.max(part.Transparency, alpha)
			end
		end):andThen(function()
			fadeModel:Destroy()
		end)
	end)

	persist(args.guid, function()
		trove:Clean()
	end)
end

function EffectUtil.projectile(args: {
	guid: string,
	name: string,
	cframe: CFrame,
	speed: number,
	owner: Player,
	gravity: number?,
	lifetime: number?,
	onTouched: (BasePart, BasePart) -> boolean,
	onFinished: ((BasePart) -> ())?,
	onStartedAll: ((BasePart) -> ())?,
})
	local gravity = args.gravity or 1
	local lifetime = args.lifetime or 10

	local part: BasePart = ReplicatedStorage.Assets.Effects[args.name]:Clone()
	part.CFrame = args.cframe

	local attachment = Instance.new("Attachment")
	attachment.Parent = part

	local orientation = Instance.new("AlignOrientation")
	orientation.RigidityEnabled = true
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.Attachment0 = attachment
	orientation.CFrame = args.cframe
	orientation.Parent = part

	local lift = Instance.new("VectorForce")
	lift.ApplyAtCenterOfMass = true
	lift.RelativeTo = Enum.ActuatorRelativeTo.World
	lift.Force = Vector3.new(0, part:GetMass() * workspace.Gravity * (1 - gravity), 0)
	lift.Attachment0 = attachment
	lift.Parent = part

	local trove = Trove.new()

	trove:Connect(RunService.Stepped, function()
		orientation.CFrame = CFrame.lookAt(Vector3.new(), part.AssemblyLinearVelocity)
	end)

	trove:Add(function()
		EffectUtil.replicationRequested:Fire(EffectUtil.cancel({
			guid = args.guid,
		}))
	end)

	trove:AddPromise(Promise.delay(lifetime):andThen(function()
		trove:Clean()
	end))

	trove:Connect(part.Touched, function(touchedPart)
		if Players.LocalPlayer ~= args.owner then return end
		if args.onTouched(touchedPart, part) then trove:Clean() end
	end)

	part.Parent = Effects
	part.AssemblyLinearVelocity = args.cframe.LookVector * args.speed

	for _, object in part:GetDescendants() do
		if object:IsA("Sound") and object.Looped then object:Play() end
	end

	if args.onStartedAll then args.onStartedAll(part) end

	persist(args.guid, function()
		if args.onFinished and Players.LocalPlayer == args.owner then args.onFinished(part) end

		part.Anchored = true

		local fadeTime = 0

		for _, object in part:GetDescendants() do
			if object:IsA("ParticleEmitter") then
				object.Enabled = false
				fadeTime = math.max(fadeTime, object.Lifetime.Max)
			elseif object:IsA("Trail") then
				object.Enabled = false
				fadeTime = math.max(fadeTime, object.Lifetime)
			end
		end

		local promises = {}
		for _, object in part:GetDescendants() do
			if object:IsA("PointLight") then
				local range = object.Range
				table.insert(
					promises,
					animation(fadeTime, function(alpha)
						object.Range = lerp(range, 0, alpha)
					end)
				)
			elseif object:IsA("Sound") and object.Looped then
				object:Stop()
			end
		end

		local transparency = part.Transparency
		table.insert(
			promises,
			animation(fadeTime, function(alpha)
				part.Transparency = lerp(transparency, 1, alpha)
			end)
		)

		Promise.all(promises):andThen(function()
			part:Destroy()
		end)
	end)

	return "projectile", args
end

function EffectUtil.emitter(args: {
	parent: BasePart | Attachment,
	name: string,
	duration: number?,
	guid: string?,
})
	local emitter = ReplicatedStorage.Assets.Emitters[args.name]:Clone()

	emitter.Parent = args.parent
	emitter.Enabled = true

	local trove = Trove.new()
	trove:Add(function()
		emitter.Enabled = false
		task.delay(emitter.Lifetime.Max, emitter.Destroy, emitter)
	end)

	if args.guid then persist(args.guid, function()
		trove:Clean()
		desist(args.guid)
	end) end

	if args.duration then trove:AddPromise(Promise.delay(args.duration):andThen(function()
		trove:Clean()
	end)) end

	return "emitter", args
end

function EffectUtil.floorImpact1(args: {
	cframe: CFrame,
	effectName: string?,
	part: BasePart?,
	material: Enum.Material?,
	color: Color3?,
	size: Vector3?,
	startDuration: number?,
	lifetimeDuration: number?,
})
	local effectName = args.effectName or "FloorImpact1"
	local startDuration = args.startDuration or 0.25
	local lifetimeDuration = args.lifetimeDuration or 1.8

	--// init
	local part = ReplicatedStorage.Assets.Effects[effectName]:Clone()
	part.CFrame = args.cframe
	part.CanCollide = false
	part.CanQuery = false

	local baseSize = part.Size
	part.Size = Vector3.new(0, 0, 0)

	if args.part then
		part.Material = args.part.Material
		part.Color = args.part.Color
	else
		part.Material = args.material or part.Material
		part.Color = args.color or part.Color
	end
	part.Parent = Effects

	local startSize = Vector3.new()
	local endSize = args.size or baseSize
	animation(startDuration, function(alpha)
			part.Size = lerp(startSize, endSize, alpha)
		end)
		:andThen(function()
			return Promise.delay(lifetimeDuration)
		end)
		:andThen(function()
			local startTransparency = part.Transparency
			local endTransparency = 1
			return animation(1, function(alpha)
				part.Transparency = lerp(startTransparency, endTransparency, alpha)
			end)
		end)
		:andThen(function()
			part:Destroy()
		end)

	return "floorImpact1", args
end

function EffectUtil.forcePush(args: {
	root: BasePart,
	cframe: CFrame,
	radius: number,
	duration: number,
	power: number,
})
	local part = ReplicatedStorage.Assets.Effects.ForcePush1:Clone()
	local start = Vector3.new()
	local finish = Vector3.new(args.radius, 0, args.radius)

	local function setCFrame()
		part.CFrame = args.root.CFrame * args.cframe * CFrame.new(0, 0, -part.Size.Z / 2)
	end

	animation(args.duration, function(alpha)
		setCFrame()

		local transparency = math.pow(alpha, args.power)
		part.TopGui.Image.ImageTransparency = transparency
		part.BotGui.Image.ImageTransparency = transparency

		local size = -math.pow(1 - alpha, args.power) + 1
		part.Size = start:Lerp(finish, size)
	end):andThen(function()
		--part:Destroy()
	end)

	part.Parent = Effects
end

function EffectUtil.dhorakVengeanceSkull(args: {
	root: BasePart,
})
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(4, 1)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
	billboard.Adornee = args.root
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Image = "rbxassetid://14113139017"
	image.Size = UDim2.fromScale(1, 1)
	image.ScaleType = Enum.ScaleType.Fit
	image.Parent = billboard
	billboard.Parent = Effects
	task.delay(3, billboard.Destroy, billboard)

	local model = ReplicatedStorage.Assets.Effects.DhorakVengeanceSkull:Clone()
	model.Parent = Effects

	local fadeTime = 0.3

	local function setCFrame()
		model.Skull.CFrame = args.root.CFrame
	end

	local track = model.AnimationController:LoadAnimation(Animations.DhorakSkullVengeance) :: AnimationTrack
	Promise.new(function(resolve)
		while track.Length <= 0 do
			task.wait()
		end
		resolve()
	end)
		:timeout(2)
		:andThen(function()
			track:Play(0)
			return animation(fadeTime, function(alpha)
				setCFrame()
				model.Skull.Transparency = 1 - alpha
			end)
		end)
		:andThen(function()
			return animation(track.Length - (fadeTime * 2), function()
				setCFrame()
			end)
		end)
		:andThen(function()
			return animation(fadeTime, function(alpha)
				setCFrame()
				model.Skull.Transparency = alpha
			end)
		end)
		:andThen(function()
			model:Destroy()
		end)

	return "dhorakVengeanceSkull", args
end

function EffectUtil.lightningStrike(args: {
	cframe: CFrame,
	duration: number,
})
	local effect = ReplicatedStorage.Assets.Effects.LightningStrike:Clone()
	effect.CFrame = args.cframe
	effect.Parent = workspace

	task.delay(args.duration, effect.Destroy, effect)

	return "lightningStrike", args
end

function EffectUtil.paddleSpecial(args: {
	guid: string,
	paddle: BasePart,
})
	local paddle = args.paddle

	-- paddle validation
	if not paddle or not paddle.Parent then return end
	if paddle.Parent.Name ~= "Paddle" then return end

	local motor = args.paddle:FindFirstChildOfClass("Motor6D")
	if not motor then return end

	local paddleReference = ReplicatedStorage.Assets.Weapons.Paddle.PrimaryPart
	local startSize = paddleReference.Size
	local multiplier = 4
	local duration = weaponDefinitions.Paddle.specialChargeDuration + 0.1
	local maxSize = startSize * multiplier

	EffectUtil.emit({
		emitter = paddle.GrowthEffect,
		particleCount = 20,
	})
	EffectUtil.sound({
		name = "PaddleSpecialPoof",
		parent = paddle,
	})
	EffectUtil.sound({
		name = "PaddleSpecialSparkle",
		parent = paddle,
	})

	local trove = Trove.new()
	local tween = TweenService:Create(args.paddle, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Size = startSize * multiplier })
	trove:Add(function()
		args.paddle.Size = maxSize
		TweenService:Create(args.paddle, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Size = startSize }):Play()
		desist(args.guid)
		motor.C0 = motor.C0 * CFrame.new(0, -2, 0)
	end)
	tween:Play()
	motor.C0 = motor.C0 * CFrame.new(0, 2, 0)

	trove:AddPromise(Promise.delay(duration):andThenCall(trove.Clean, trove))

	return "paddleSpecial", args
end

return EffectUtil
