-- Controls the theme for the Plugin's Roact application by referencing Studio's theme. 

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local components = script.Parent
local pluginMain = components.Parent
local pluginUtil = pluginMain:FindFirstChild("Packages") or ReplicatedStorage:FindFirstChild("Packages")

-- get roact/rodux
local Roact = require(pluginUtil:WaitForChild("Roact"))

-- get studio's theme
local studioSettings = settings().Studio
local theme = studioSettings.Theme

-- create context and component
local PluginContextWrapper = Roact.Component:extend("PluginContextWrapper")
local pluginAppContext = Roact.createContext({})

function PluginContextWrapper:init()
    self:setState({
        theme = theme
    })
    self._themeChangedConnection = studioSettings.ThemeChanged:Connect(function() 
        theme = studioSettings.Theme
        self:setState({
            theme = theme
        })
    end)
end

function PluginContextWrapper:render()
    return Roact.createElement(pluginAppContext.Provider, {
        value = self.state.theme,
    }, self.props[Roact.Children])
end


local function with(callback)
	return Roact.createElement(pluginAppContext.Consumer, {
		render = callback,
	})
end

return {
	Provider = PluginContextWrapper,
	Consumer = pluginAppContext.Consumer,
	with = with,
}