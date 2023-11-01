local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Badges = ReplicatedStorage.Shared.Data.Badges

local Badger = require(ReplicatedStorage.Shared.Singletons.Badger)
local Sift = require(ReplicatedStorage.Packages.Sift)

export type BadgeId = string
export type BadgeDefinition = {
	maker: (Player) -> Badger.Condition,
	badgeId: number?,
	id: BadgeId,
}

return Sift.Dictionary.map(Badges:GetChildren(), function(object)
	if not object:IsA("ModuleScript") then return end

	return Sift.Dictionary.set(require(object), "id", object.Name), object.Name
end) :: { [BadgeId]: BadgeDefinition }
