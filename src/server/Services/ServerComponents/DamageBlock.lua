local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ComponentService = require(ReplicatedStorage.Shared.Services.ComponentService)
local DamageService = require(ServerScriptService.Server.Services.DamageService)
local HitLimiter = require(ServerScriptService.Server.Classes.HitLimiter)
local WeaponUtil = require(ReplicatedStorage.Shared.Util.WeaponUtil)

-- constants
local DAMAGE = 200
local COOLDOWN = 1

local DamageBlock = {}
DamageBlock.__index = DamageBlock

function DamageBlock.new(part: BasePart)
	local self = setmetatable({
		_part = part,
		_hitLimiter = HitLimiter.new(COOLDOWN),
	}, DamageBlock)

	local modifier = Instance.new("PathfindingModifier")
	modifier.Label = "DamageBlock"
	modifier.Parent = part

	local damageSource = {
		Name = part.Name,
	}

	self._touchedConnection = part.Touched:Connect(function(hit)
		local target = WeaponUtil.findDamageTarget(hit)
		if not target then return end
		if self._hitLimiter:limitTarget(target) then return end

		-- do not damage or kill players when the part in question
		-- is not near to their root (prevent weapon swinging, ragdoll spazzing from killing you)
		if target:IsA("Humanoid") then
			local char = target.Parent
			if not char then return end
			local root = char.PrimaryPart
			if not root then return end
			local distance = (hit.Position - root.Position).Magnitude
			if distance > 5 then return end
		end

		DamageService:damage({
			source = damageSource,
			target = target,
			amount = part:GetAttribute("Damage") or DAMAGE,
		})
	end)

	return self
end

function DamageBlock:OnRemoved()
	if self._touchedConnection then
		self._touchedConnection:Disconnect()
		self._touchedConnection = nil
	end
end

return ComponentService:registerComponentClass(script.Name, DamageBlock)
