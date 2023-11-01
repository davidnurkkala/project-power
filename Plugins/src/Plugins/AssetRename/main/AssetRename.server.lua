local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")

local pluginMain = script.Parent
local pluginSource = pluginMain.Parent
local pluginUtil = pluginSource:FindFirstChild("Packages") or ReplicatedStorage:FindFirstChild("Packages")
assert(pluginUtil, "Util including roact. not found")

local Roact = require(pluginUtil:WaitForChild("Roact"))
local Components = pluginSource:WaitForChild("Components")
local Contexts = pluginSource:WaitForChild("Contexts")

-- consts
local WIDGET_TITLE = "Asset Rename"
local WIDGET_INFO = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,  -- Widget will be initialized in floating panel
	true,   -- Widget will be initially enabled
	true,   -- override the previous enabled state
	200,    -- Default width of the floating window
	75,    -- Default height of the floating window
	200,    -- Minimum width of the floating window
	75   -- Minimum height of the floating window
)

local activeWidget = nil
local pluginApp= nil
local pluginMountedApp = nil
local active = false

-- Plugin App
local PluginApp = require(Components:WaitForChild("AssetRenameApp"))
local PluginContext = require(Contexts:WaitForChild("Context"))

local function disable()
	active = false
	if activeWidget then
		plugin:Deactivate()
		activeWidget:Destroy()
		activeWidget = nil
	end

    -- unmount roact tree
	if pluginMountedApp then
		Roact.unmount(pluginMountedApp)
	end
end

local function renameInstances(selection: {Instance}, name: string)
	for _, instance in selection do
		instance.Name = name
	end
end

local function enable(selection: {Instance})
	if active then return end
	active = true
	if not activeWidget then
		activeWidget = plugin:CreateDockWidgetPluginGui("PoseLoaderWidget", WIDGET_INFO)
		activeWidget.Title = WIDGET_TITLE
		activeWidget:BindToClose(function()
			disable()
		end)

        -- initialize the plugin app
        pluginApp = Roact.createElement(PluginApp, {
			selectionSize = #selection,
			selectionName = selection[1] and selection[1].Name or "No Selection",
			context = PluginContext,
			onTextboxCompletion = function(text: string)
				renameInstances(selection, text)
			end,
			onLostFocus = function()
				disable()
			end,
		})
	end

    -- mount roact tree
	assert(pluginApp and activeWidget, "roact tree or active widget does not exist.")
	pluginMountedApp = Roact.mount(pluginApp, activeWidget, "AssetRenameApp")
end

local function onKeybindPressed(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
	if inputState ~= Enum.UserInputState.Begin then return end
	if active then return end

	local selection = Selection:Get()
	if #selection == 0 then return end
	enable(selection)
end

local function init()
	-- register keybind
	if not RunService:IsEdit() then return end
	ContextActionService:BindAction("AssetRenameKeybind", onKeybindPressed, false, Enum.KeyCode.F2)
end

init()