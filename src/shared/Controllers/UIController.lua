local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local App = require(ReplicatedStorage.Shared.React.Components.App)
local Loader = require(ReplicatedStorage.Shared.Loader)
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local UIController = {}
UIController.className = "UIController"
UIController.priority = 0

function UIController:init() end

function UIController:start()
	local root = ReactRoblox.createRoot(Instance.new("Folder"))
	root:render(ReactRoblox.createPortal(React.createElement(App), Players.LocalPlayer.PlayerGui, "UIController"))
end

return Loader:registerSingleton(UIController)
