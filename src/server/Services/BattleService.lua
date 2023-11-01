local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Animations = require(ReplicatedStorage.Shared.Data.Animations)
local BotBuilder = require(ServerScriptService.Server.Bots.Util.BotBuilder)
local Comm = require(ReplicatedStorage.Packages.Comm)
local LevelUpService = require(ServerScriptService.Server.Services.LevelUpService)
local LifeDataHandler = require(ServerScriptService.Server.Classes.LifeDataHandler)
local Loader = require(ReplicatedStorage.Shared.Loader)
local PlaytimeRewardsService = require(ServerScriptService.Server.Services.PlaytimeRewardsService)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)
local Signal = require(ReplicatedStorage.Packages.Signal)
local StunService = require(ServerScriptService.Server.Services.StunService)

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local EventStream = require(ReplicatedStorage.Shared.Singletons.EventStream)
local LaunchHelper = require(ReplicatedStorage.Shared.Util.LaunchHelper)

local WeaponService = require(ServerScriptService.Server.Services.WeaponService)

local Arenas = workspace:FindFirstChild("Arenas") :: Folder

local TIME_PER_ARENA = 60 * 4
local ARENA_POSITION = Vector3.new(0, 896, 0)
local RANDOM = Random.new()
local HOLD_RADIUS = 256
local HOLD_HEIGHT = 512
local MINIMUM_FIGHTER_COUNT = 10

local function setMoverToPosition(mover: AlignPosition, position: Vector3)
	mover.Position = position
	local attachment = mover.Attachment0
	return Promise.race({
		Promise.delay(5),
		Promise.fromEvent(RunService.Stepped, function()
			return (position - attachment.WorldPosition).Magnitude <= 8
		end),
	})
end

local function isAlive(player: Player): boolean
	local char = player.Character
	if not char then return false end

	local human: Humanoid = char:FindFirstChild("Humanoid")
	if not human then return false end

	return human.Health > 0
end

local BattleService = {}
BattleService.className = "BattleService"
BattleService.priority = -1024

BattleService.arenaChanged = Signal.new()
BattleService.roundEndForced = Signal.new()

BattleService._enterBattlePromisesByPlayer = {}
BattleService._participantsSet = {}

BattleService._arena = nil
BattleService._canEnter = true
BattleService._arenas = {
	list = Sift.Array.shuffle(Arenas:GetChildren()),
	index = 1,
	get = function(self)
		local arena = self.list[self.index]:Clone()
		self.index += 1
		if self.index > #self.list then self.index = 1 end
		return arena
	end,
}

function BattleService:_initCollisionGroups()
	PhysicsService:RegisterCollisionGroup("None")
	for _, entry in PhysicsService:GetRegisteredCollisionGroups() do
		PhysicsService:CollisionGroupSetCollidable("None", entry.name, false)
	end
end

function BattleService:init()
	self:_initCollisionGroups()

	-- arenas health check
	for _, arena in Arenas:GetChildren() do
		assert(arena:FindFirstChild("Spawns"), `Arena {arena.Name} does not have a Spawns folder.`)
		assert(#arena.Spawns:GetChildren() > 0, `Arena {arena.Name} has an empty Spawns folder.`)
	end

	Arenas.Parent = ReplicatedStorage

	local inProgressArena = workspace:FindFirstChild("InProgressArena")
	inProgressArena:Destroy()

	self._comm = Comm.ServerComm.new(ReplicatedStorage, "BattleService")
	self._launchRequested = self._comm:CreateSignal("LaunchRequested")

	self:_speedUpPlayers()
end

function BattleService:start()
	self:_cycle()
end

function BattleService:_setPlayerCollidable(player, state)
	if not player.Character then return end
	for _, object in player.Character:GetDescendants() do
		if not object:IsA("BasePart") then continue end
		object.CollisionGroup = if state then "Players" else "None"
	end
end

function BattleService:_speedUpPlayers()
	local function onCharacterAdded(char)
		local humanoid = char:WaitForChild("Humanoid", 2.5)
		if not humanoid then return end

		humanoid.WalkSpeed *= 1.75
	end

	local function onPlayerAdded(player)
		if player.Character then onCharacterAdded(player.Character) end
		player.CharacterAdded:Connect(onCharacterAdded)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

function BattleService:_cycle()
	self._canEnter = false

	self.arenaChanged:Fire()
	self._participantsSet = Sift.Array.toSet(Sift.Array.filter(Players:GetPlayers(), function(player)
		return self:getIsInBattle(player)
	end))

	local botBuilder = BotBuilder.new()

	self:_holdPlayers()
		:andThen(function(releasePlayers)
			self:_clearArena()
			self:_createArena()
			self._canEnter = true
			return Promise.delay(3):andThenCall(releasePlayers)
		end)
		:andThen(function()
			local spawningBots = true
			task.spawn(function()
				while spawningBots do
					local fighterCount = botBuilder:getBotCount() + #Players:GetPlayers()

					if fighterCount < MINIMUM_FIGHTER_COUNT then
						Promise.try(function()
							botBuilder:createBot("BotNoob", {
								cframe = CFrame.new(self:getSpawnPosition()),
							})
						end):catch(function() end)
					end

					task.wait(1)
				end
			end)

			return Promise.race({
				Promise.delay(TIME_PER_ARENA),
				Promise.fromEvent(self.roundEndForced),
			}):andThen(function()
				spawningBots = false
				botBuilder:destroy()
			end)
		end)
		:andThen(function()
			for rewardee in self._participantsSet do
				EventStream:event("RoundEnded", { player = rewardee })
				PlaytimeRewardsService:rewardPlayer(rewardee)
			end
		end)
		:andThen(function()
			self:_cycle()
		end)
end

function BattleService:_getValidPlayers()
	return Sift.Array.filter(Players:GetPlayers(), function(player)
		return isAlive(player) and self:getIsInBattle(player)
	end)
end

function BattleService:_holdPlayers()
	return Promise.new(function(resolve)
		local heldPlayers = self:_getValidPlayers()

		local thetaStep = (math.pi * 2) / #heldPlayers

		local holds = {} :: {
			{
				attachment: Attachment,
				forceField: ForceField,
				mover: AlignPosition,
			}
		}

		for index, player in heldPlayers do
			local theta = (index - 1) * thetaStep
			local position = Vector3.new(math.cos(theta) * HOLD_RADIUS, HOLD_HEIGHT, math.sin(theta) * HOLD_RADIUS) + ARENA_POSITION

			local char = player.Character
			if not char then continue end

			local root = char.PrimaryPart
			if not root then continue end

			local forceField = Instance.new("ForceField")
			forceField.Parent = char

			local attachment = Instance.new("Attachment")
			attachment.Parent = root

			local mover = Instance.new("AlignPosition")
			mover.Mode = Enum.PositionAlignmentMode.OneAttachment
			mover.Attachment0 = attachment
			mover.ApplyAtCenterOfMass = true
			mover.ReactionForceEnabled = true
			mover.MaxForce = 1e9
			mover.MaxVelocity = 1e3
			mover.Position = position
			mover.Parent = attachment

			self:_setPlayerCollidable(player, false)

			table.insert(holds, {
				player = player,
				attachment = attachment,
				forceField = forceField,
				mover = mover,
				promise = setMoverToPosition(mover, position),
			})
		end

		resolve(Promise.all(Sift.Array.map(holds, function(hold)
			return hold.promise
		end)):andThen(function()
			return function()
				return Promise.all(Sift.Array.map(holds, function(hold)
					local position = self:getSpawnPosition()

					return setMoverToPosition(hold.mover, position + Vector3.new(0, 4, 0))
						:andThen(function()
							hold.attachment:Destroy()
							self:_setPlayerCollidable(hold.player, true)
							return Promise.delay(2)
						end)
						:andThen(function()
							hold.forceField:Destroy()
						end)
				end))
			end
		end))
	end)
end

function BattleService:_clearArena()
	if not self._arena then return end

	-- TODO: consider something more artful than this
	self._arena:Destroy()
end

function BattleService:_createArena()
	local arena = self._arenas:get()

	arena:PivotTo(CFrame.new(ARENA_POSITION))

	for _, model in arena.Spawns:GetChildren() do
		model.PrimaryPart.Transparency = 1
	end

	arena.Parent = workspace

	self._arena = arena

	if arena:FindFirstChild("StartupSounds") then
		for _, sound in arena.StartupSounds:GetChildren() do
			sound:Play()
		end
	end
end

function BattleService:_debugAddDummies()
	for dx = -256, 256, 64 do
		for dz = -256, 256, 64 do
			local position = ARENA_POSITION + Vector3.new(dx, 256, dz)

			local dummy = ServerStorage.TargetDummy:Clone()
			dummy.Name = "Target Dummy"

			local humanoid: Humanoid = dummy.Humanoid
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
			humanoid.Died:Connect(function()
				local sound = Instance.new("Sound")
				sound.Name = "VineBoom"
				sound.SoundId = "rbxassetid://9088081730"
				sound.Parent = dummy.PrimaryPart
				sound:Play()
				task.delay(3, dummy.Destroy, dummy)
			end)

			dummy:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.pi * 2 * math.random(), 0))
			dummy.Parent = self._arena

			dummy.PrimaryPart:SetNetworkOwner(nil)
		end
	end
end

function BattleService:getIsInBattle(player: Player): boolean
	if not isAlive(player) then return false end

	local char = player.Character
	if not char then return false end

	return char:GetAttribute("InBattle") :: boolean
end

function BattleService:getPlayersInBattle(): { Player }
	local players = {}

	for _, player in Players:GetPlayers() do
		if self:getIsInBattle(player) then table.insert(players, player) end
	end

	return players
end

function BattleService:getArena(): Model
	return self._arena
end

function BattleService:getSpawnPosition(wiggleRadius: number?): Vector3?
	local arena = self:getArena()
	local spawns = arena.Spawns:GetChildren()
	local object = spawns[RANDOM:NextInteger(1, #spawns)] :: Instance
	local wiggle = Vector3.new(RANDOM:NextNumber(-1, 1), 0, RANDOM:NextNumber(-1, 1)) * (wiggleRadius or 8)

	if object:IsA("Model") then object = object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true) end

	assert(object:IsA("BasePart"), "Arena has a spawn without any parts in it.")

	return object.Position + wiggle
end

function BattleService:_getRealSpawnCFrame(callingPosition: Vector3)
	return Promise.new(function(resolve)
		local arena
		repeat
			arena = self:getArena()
			local pass = (arena ~= nil) and (arena:FindFirstChild("Spawns") ~= nil)
			if not pass then task.wait() end
		until pass

		local spawnPosition
		repeat
			spawnPosition = self:getSpawnPosition()

			local isFarAway = (spawnPosition - callingPosition).Magnitude > 64
			if not isFarAway then task.wait() end
		until isFarAway

		local cframe = CFrame.new(spawnPosition + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.pi * 2 * RANDOM:NextNumber(), 0)
		resolve(cframe)
	end)
		:timeout(3)
		:catch(function()
			return Promise.reject("could not find real spawn position in time")
		end)
end

function BattleService:setUpHuman(char, human)
	human.MaxHealth = 200
	human.Health = human.MaxHealth
	human.JumpHeight *= 2
	human.RequiresNeck = false
	human.BreakJointsOnDeath = false
	char.ChildRemoved:Connect(function(child)
		if child.Name == "HumanoidRootPart" then human.Health = 0 end
	end)
	human.Died:Connect(function()
		EventStream:event("PlayerDied", { player = Players:GetPlayerFromCharacter(char) })

		if not char.PrimaryPart then return end
		StunService:ragdollModel(char, Vector3.new())
	end)
end

function BattleService:setUpAnimations(char)
	local animate = char:FindFirstChild("Animate")
	if not animate then return end

	if animate:FindFirstChild("jump") then animate.jump:Destroy() end
	local jump = Instance.new("StringValue")
	jump.Name = "jump"
	local jumpAnim = Animations.Jump:Clone()
	jumpAnim.Name = "JumpAnim"
	jumpAnim.Parent = jump
	jump.Parent = animate

	if animate:FindFirstChild("fall") then animate.fall:Destroy() end
	local fall = Instance.new("StringValue")
	fall.Name = "fall"
	local fallAnim = Animations.Fall:Clone()
	fallAnim.Name = "FallAnim"
	fallAnim.Parent = fall
	fall.Parent = animate
end

function BattleService:setUpForBattle(char, human, tag)
	if tag == nil then tag = "InBattle" end

	return Promise.try(function()
		self:setUpHuman(char, human)
		self:setUpAnimations(char)

		ComponentService:tagObjectAs(char, tag)
		char:SetAttribute(tag, true)

		LevelUpService:setUp(char)
	end)
end

function BattleService:_waitForCanEnter()
	if not self._canEnter then
		return Promise.new(function(resolve)
			repeat
				task.wait()
			until self._canEnter
			resolve()
		end)
			:timeout(10)
			:catch(function()
				return Promise.reject("_canEnter was not set to true in time")
			end)
	else
		return Promise.resolve()
	end
end

function BattleService:_hasStayedFarAway(char, position, duration)
	local timeAway = 0
	return Promise.fromEvent(RunService.Heartbeat, function(dt)
		local isFarAway = (char:GetPrimaryPartCFrame().Position - position).Magnitude > 64
		if isFarAway then
			timeAway += dt
			return timeAway >= duration
		else
			return true
		end
	end):andThen(function()
		if timeAway >= duration then
			return Promise.resolve()
		else
			return Promise.reject("did not stay far away enough from original position")
		end
	end)
end

function BattleService:launchPlayer(player: Player, launcher: BasePart)
	if self._enterBattlePromisesByPlayer[player] then return end

	local logLines = {}
	local function log(line)
		table.insert(logLines, line)
	end

	log("started")
	self._enterBattlePromisesByPlayer[player] = Promise.race({
		Promise.new(function(_resolve, reject)
			while player.Parent do
				task.wait()
			end
			reject("left the game")
		end),
		self:_waitForCanEnter()
			:andThen(function()
				log("can enter, proceeding")
				return Promise.new(function(resolve, reject)
					if not isAlive(player) then reject("not alive") end
					if self:getIsInBattle(player) then reject("already in battle") end

					local char = player.Character
					if not char then reject("no character") end
					if not char.PrimaryPart then reject("no primary part") end

					local human = char:FindFirstChildWhichIsA("Humanoid")
					if not human then reject("no humanoid") end

					resolve(char, human)
				end)
			end)
			:andThen(function(char, human)
				log("setting up human, animations, tags, attributes, and level up")
				self:setUpForBattle(char, human):expect()

				log("getting spawn position")
				local callingPosition = char:GetPrimaryPartCFrame().Position
				return self:_getRealSpawnCFrame(callingPosition):andThen(function(cframe)
					log("spawn position acqured, proceeding")
					return char, cframe
				end)
			end)
			:andThen(function(char, cframe)
				log("instantiating forcefield")
				local forceField = Instance.new("ForceField")
				forceField.Parent = char

				self._launchRequested:Fire(player, launcher, cframe)
				return LaunchHelper(player, launcher, cframe):finally(function()
					log("removing forcefield")
					Promise.delay(2):andThenCall(forceField.Destroy, forceField)
				end)
			end)
			:andThen(function()
				log("equipping weapon")
				WeaponService:equipWeapon(player)

				log("sending event")
				EventStream:event("PlayerEnteredBattle", { player = player })

				log("instantiating analytics object")
				LifeDataHandler.new(player)

				log("setting participation")
				self._participantsSet[player] = true
			end),
	})
		:timeout(10, "took too long")
		:catch(function(err)
			warn(`Did not allow player {player} into battle because: {err}, log to follow:`)
			warn(table.concat(logLines, "\n"))
			player:LoadCharacter()
		end)
		:finally(function()
			self._enterBattlePromisesByPlayer[player] = nil
		end)
end

function BattleService:addPlayer(player: Player)
	if self._enterBattlePromisesByPlayer[player] then return end

	local logLines = {}
	local function log(line)
		table.insert(logLines, line)
	end

	log("started")
	self._enterBattlePromisesByPlayer[player] = Promise.race({
		Promise.new(function(_resolve, reject)
			while player.Parent do
				task.wait()
			end
			reject("left the game")
		end),
		self:_waitForCanEnter()
			:andThen(function()
				log("can enter, proceeding")
				return Promise.new(function(resolve, reject)
					if not isAlive(player) then reject("not alive") end
					if self:getIsInBattle(player) then reject("already in battle") end

					local char = player.Character
					if not char then reject("no character") end
					if not char.PrimaryPart then reject("no primary part") end

					local human = char:FindFirstChildWhichIsA("Humanoid")
					if not human then reject("no humanoid") end

					resolve(char, human)
				end)
			end)
			:andThen(function(char, human)
				log("setting up human/animations")
				self:setUpHuman(char, human)
				self:setUpAnimations(char)

				Promise.try(function()
					log("tagging")
					ComponentService:tagObjectAs(char, "InBattle")

					log("attribute")
					char:SetAttribute("InBattle", true)

					log("level up service setup")
					LevelUpService:setUp(char)
				end):expect()

				log("getting spawn position")
				local callingPosition = char:GetPrimaryPartCFrame().Position
				return self:_getRealSpawnCFrame(callingPosition):andThen(function(cframe)
					log("spawn position acqured, proceeding")
					return char, callingPosition, cframe
				end)
			end)
			:andThen(function(char, callingPosition, cframe)
				log("instantiating forcefield")
				local forceField = Instance.new("ForceField")
				forceField.Parent = char

				log("teleporting player")
				return Promise.retry(function()
					char:SetPrimaryPartCFrame(cframe)
					return self:_hasStayedFarAway(char, callingPosition, 1)
				end, 4):finally(function()
					log("removing forcefield")
					Promise.delay(2):andThenCall(forceField.Destroy, forceField)
				end)
			end)
			:andThen(function()
				log("equipping weapon")
				WeaponService:equipWeapon(player)

				log("sending event")
				EventStream:event("PlayerEnteredBattle", { player = player })

				log("instantiating analytics object")
				LifeDataHandler.new(player)

				log("setting participation")
				self._participantsSet[player] = true
			end),
	})
		:timeout(10, "took too long")
		:catch(function(err)
			warn(`Did not allow player {player} into battle because: {err}, log to follow:`)
			warn(table.concat(logLines, "\n"))
			player:LoadCharacter()
		end)
		:finally(function()
			self._enterBattlePromisesByPlayer[player] = nil
		end)
end

return Loader:registerSingleton(BattleService)
