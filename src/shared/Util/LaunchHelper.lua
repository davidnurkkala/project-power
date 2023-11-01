local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Animation = require(ReplicatedStorage.Shared.Util.Animation)
local Animations = require(ReplicatedStorage.Shared.Data.Animations)
local AutoRotateHelper = require(ReplicatedStorage.Shared.Util.AutoRotateHelper)
local EffectController = require(ReplicatedStorage.Shared.Controllers.EffectController)
local EffectUtil = require(ReplicatedStorage.Shared.Util.EffectUtil)
local Promise = require(ReplicatedStorage.Packages.Promise)

local function lerp(a, b, w)
	return a + (b - a) * w
end

return function(player: Player, launcher: BasePart, destination: CFrame)
	return Promise.new(function(resolve)
		local cframe = launcher.CFrame

		local back = cframe * CFrame.new(0, 3, launcher.Size.Z / 2 - 3)

		local char = player.Character :: Model
		local humanoid = char.Humanoid :: Humanoid
		local root = char.PrimaryPart :: BasePart
		local start = root.CFrame

		local distance = (back.Position - start.Position).Magnitude
		local speed = 128
		local duration = distance / speed

		local launchTime = 0.4
		local airTime = 1

		if RunService:IsServer() then
			resolve(Promise.delay(duration + launchTime + airTime):andThen(function()
				root.CFrame = destination
			end))
		else
			local front = cframe * CFrame.new(0, 3, -launcher.Size.Z / 2)
			local extension = front * CFrame.new(0, 0, -128)
			local riser = destination * CFrame.new(0, 256, 0)

			local rise = math.max(0, distance - 16) * 2
			local mid = start:Lerp(back, 0.5) + Vector3.new(0, rise, 0)

			local charge = (launcher:FindFirstChild("Charge") :: Sound):Clone()
			local launch = (launcher:FindFirstChild("Launch") :: Sound):Clone()

			charge.Parent = root
			launch.Parent = root

			root.Anchored = true

			local track = humanoid:LoadAnimation(Animations.Dash)

			local camera = workspace.CurrentCamera
			local startFov = camera.FieldOfView
			local goalFov = 110

			AutoRotateHelper.disable(humanoid)

			local rootReplicator = EffectController:getRapidReplicator()

			resolve(Animation(duration, function(scalar)
					local a = start:Lerp(mid, scalar)
					local b = mid:Lerp(back, scalar)

					rootReplicator(EffectUtil.setRootCFrame({
						root = root,
						cframe = a:Lerp(b, scalar),
					}))
				end)
				:andThen(function()
					track:Play(0)
					charge:Play()

					local attachment = Instance.new("Attachment")
					attachment.Position = Vector3.new(0, -4, 0)
					attachment.Parent = root

					local emitter = ReplicatedStorage.RojoAssets.Emitters.Sparks1:Clone()
					emitter.Rate = 512
					emitter.Parent = attachment

					return Animation(launchTime, function(scalar)
						scalar = math.pow(scalar, 3)

						camera.FieldOfView = lerp(startFov, goalFov, scalar)

						rootReplicator(EffectUtil.setRootCFrame({
							root = root,
							cframe = back:Lerp(front, scalar),
						}))
					end):finally(function()
						attachment:Destroy()
					end)
				end)
				:andThen(function()
					charge:Stop()
					launch:Play()

					local top = Instance.new("Attachment")
					top.Position = Vector3.new(0, 1.5, 0)
					top.Parent = root

					local bot = Instance.new("Attachment")
					bot.Position = Vector3.new(0, -1.5, 0)
					bot.Parent = root

					local trail = ReplicatedStorage.Assets.Trails.LaunchTrail:Clone()
					trail.Attachment0 = top
					trail.Attachment1 = bot
					trail.Parent = root

					return Animation(airTime, function(scalar)
						local a = front:Lerp(extension, scalar)
						local b = riser:Lerp(destination, scalar)
						local here = a:Lerp(b, scalar)
						local there = a:Lerp(b, scalar + 0.01)
						local delta = (there.Position - here.Position) * Vector3.new(1, 0, 1)

						rootReplicator(EffectUtil.setRootCFrame({
							root = root,
							cframe = CFrame.lookAt(here.Position, here.Position + delta),
						}))

						camera.FieldOfView = lerp(goalFov, startFov, scalar)
					end):finally(function()
						trail.Enabled = false
						task.delay(trail.Lifetime, function()
							top:Destroy()
							bot:Destroy()
						end)
					end)
				end)
				:andThen(function()
					rootReplicator(EffectUtil.setRootCFrame({
						root = root,
						cframe = destination,
					}))

					local radius = 8
					local effectCFrame = destination * CFrame.new(0, -3.9, 0)

					EffectController:replicate(EffectUtil.impact1({
						cframe = effectCFrame,
						radius = radius,
						duration = 2,
						color = Color3.new(0, 0, 0),
					}))

					EffectController:replicate(EffectUtil.burst1({
						cframe = effectCFrame,
						radius = radius,
						duration = 0.5,
					}))

					EffectController:replicate(EffectUtil.debris1({
						cframe = effectCFrame,
						radius = radius,
						particleCount = 16,
					}))

					EffectController:replicate(EffectUtil.sound({
						name = "Impact1",
						position = effectCFrame.Position,
					}))
				end)
				:finally(function()
					track:Stop(0)
					track:AdjustWeight(0)
					track:Destroy()

					root.Anchored = false

					charge:Destroy()
					launch:Destroy()

					camera.FieldOfView = startFov

					AutoRotateHelper.enable(humanoid)
				end))
		end
	end)
end
