local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Animation = require(ReplicatedStorage.Shared.Util.Animation)
local Animations = require(ReplicatedStorage.Shared.Data.Animations)
local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local EffectService = require(ServerScriptService.Server.Services.EffectService)
local Promise = require(ReplicatedStorage.Packages.Promise)

local LobbyKillBox = {}
LobbyKillBox.__index = LobbyKillBox

function LobbyKillBox.new(model: Model)
	local self = setmetatable({}, LobbyKillBox)

	for _, part in model:GetChildren() do
		part.Touched:Connect(function(other)
			local char = other.Parent
			local player = Players:GetPlayerFromCharacter(char)
			if not player then return end
			if char:FindFirstChildWhichIsA("ForceField") then return end
			if char:GetAttribute("InLobbyKillSequence") then return end

			char:SetAttribute("InLobbyKillSequence", true)

			local warning = ReplicatedStorage.Assets.Effects.LobbyBreakInWarning:Clone()

			Promise.try(function()
				local root = char.PrimaryPart
				root.Anchored = true

				local humanoid = char.Humanoid
				humanoid:LoadAnimation(Animations.LobbyTouch):Play()

				local start = root.CFrame
				local goal = CFrame.new(0, 2048, 0) * CFrame.Angles(0, math.pi * 2 * math.random(), 0)

				warning:PivotTo(goal * CFrame.new(0, 0, -10) * CFrame.Angles(0, math.pi, 0))
				warning.Parent = workspace

				return Animation(1, function(scalar)
					root.CFrame = start:Lerp(goal, scalar)
				end):andThen(function()
					return Promise.new(function(resolve, _, onCancel)
						while not onCancel() and (humanoid.Health > 1) do
							-- explosion vfx
							EffectService:effect("burst1", {
								cframe = goal * CFrame.Angles(math.pi * 2 * math.random(), 0, math.pi * 2 * math.random()),
								radius = 4 + 4 * math.random(),
								duration = 0.2 + 0.3 * math.random(),
								partName = "BurstFire1",
								power = 0.4,
							})

							-- explosion sfx
							local sound = ReplicatedStorage.Assets.Sounds["RocketExplosion" .. math.random(1, 3)]:Clone()
							sound.Volume = 1
							sound.Parent = root
							sound:Play()

							local damage = 5 + 5 * math.random()
							humanoid.Health = math.max(1, humanoid.Health - damage)

							if humanoid.Health > 1 then task.wait(0.2 + 0.3 * math.random()) end
						end

						resolve()
					end)
				end):andThen(function()
					root.Anchored = false
					humanoid.Health = 0
					char:BreakJoints()

					local random = Random.new()
					for _, object in char:GetDescendants() do
						if object:IsA("BasePart") then
							local bv = Instance.new("BodyVelocity")
							bv.MaxForce = Vector3.one * 1e9
							bv.Velocity = random:NextUnitVector() * random:NextNumber(32, 128)
							bv.Parent = object
						end
					end
				end)
			end)
				:catch(function()
					player:LoadCharacter()
				end)
				:finally(function()
					warning:Destroy()
				end)
		end)
	end

	return self
end

function LobbyKillBox:OnRemoved()
	-- will never be removed
end

return ComponentService:registerComponentClass(script.Name, LobbyKillBox)
