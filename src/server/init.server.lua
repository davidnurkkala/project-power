local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Loader = require(ReplicatedStorage.Shared.Loader)

Loader:addSource(ReplicatedStorage.Shared.Services)
Loader:addSource(script.Services)

Loader:load()
