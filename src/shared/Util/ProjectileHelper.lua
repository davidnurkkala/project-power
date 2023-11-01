local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sift = require(ReplicatedStorage.Packages.Sift)

local ProjectileHelper = {}

function ProjectileHelper.isProjectileCollidable(part)
	return (part.CanCollide == true) and (part.CollisionGroup == "Default")
end

do
	local set = Sift.Array.toSet({ "Head", "UpperTorso", "LowerTorso", "HumanoidRootPart" })

	function ProjectileHelper.isHumanProjectilePart(charPart)
		return Sift.Set.has(set, charPart.Name)
	end
end

return ProjectileHelper
