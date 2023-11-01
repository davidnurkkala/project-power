-- App to handle rendering of the plugin's UI
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local components = script.Parent
local pluginMain = components.Parent
local pluginUtil = pluginMain:FindFirstChild("Packages") or ReplicatedStorage:FindFirstChild("Packages")

-- get roact/rodux
local Roact = require(pluginUtil:WaitForChild("Roact"))

-- consts
local THEME_COLOR = Enum.StudioStyleGuideColor
local THEME_COLOR_MOD = Enum.StudioStyleGuideModifier

-- create AssetRenameApp
local AssetRenameApp = Roact.PureComponent:extend("AssetRenameApp")

-- get components

-- define props
AssetRenameApp.defaultProps = {
    selectionName = 1;
    selectionSize = 1;
    onTextboxCompletion = function(text)
        print("rename to: "..text)
    end;
    onLostFocus = function()
        print("lost focus")
    end;
}

function AssetRenameApp:init()
    self.state = {}
    self._textBoxRef = Roact.createRef()
end

function AssetRenameApp:render()
    local context = self.props.context

    return Roact.createElement(context.Provider, {
        value = "poseLoaderTheme"
    },{
        AssetRenameApp = context.with(function(theme)
            return Roact.createElement("Frame", {
                BackgroundColor3 = theme:GetColor(THEME_COLOR.MainBackground);
                BorderColor3 = theme:GetColor(THEME_COLOR.Border);
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.fromScale(1,1);
            }, {
                Body = Roact.createElement("Frame", {
                    AnchorPoint = Vector2.new(0.5,0.5);
                    BackgroundColor3 = theme:GetColor(THEME_COLOR.HeaderSection);
                    BorderColor3 = theme:GetColor(THEME_COLOR.Border);
                    BorderMode = Enum.BorderMode.Outline;
                    Size = UDim2.new(1,-8,1,-8);
                    Position = UDim2.new(0.5,0,0.5,0);
                }, {
                    -- label for active scheme
                    Header = Roact.createElement("TextLabel", {
                        BackgroundTransparency = 1;
                        Font = self.props.font;
                        Text = `Rename {self.props.selectionSize == 1 and "'"..self.props.selectionName.."'" or self.props.selectionSize.." Assets"}:`;
                        TextColor3 = theme:GetColor(THEME_COLOR.SubText);
                        TextSize = self.props.textSize;
                        TextXAlignment = Enum.TextXAlignment.Left;
                        Size = UDim2.new(0, 96, 0, 16);
                    }, {
                        Padding = Roact.createElement("UIPadding", {
                            PaddingLeft = UDim.new(0, self.props.textPadding)
                        });
                    });
                    -- name for active scheme
                    TextBox = Roact.createElement("TextBox", {
                        BackgroundColor3 = theme:GetColor(THEME_COLOR.InputFieldBackground);
                        BorderColor3 = theme:GetColor(THEME_COLOR.InputFieldBorder);
                        Font = self.props.propFont;
                        Text = "Name Here";
                        TextColor3 = theme:GetColor(THEME_COLOR.MainText);
                        TextSize = self.props.propTextSize;
                        TextXAlignment = Enum.TextXAlignment.Center;
                        Position = UDim2.new(0, 0, 0, 24);
                        Size = UDim2.new(1, 0, 1, -32);
                        TextTruncate = Enum.TextTruncate.AtEnd;

                        [Roact.Ref] = self._textBoxRef;
                        [Roact.Event.FocusLost] = function(rbx, enterPressed)
                            if enterPressed then
                                local newName = rbx.Text
                                self.props.onTextboxCompletion(newName)
                            end
                            --close the menu
                            self.props.onLostFocus()
                        end
                    });
                })
            })
        end);
    })
end

function AssetRenameApp:didMount()
    -- focus on the textbox
    local textBox = self._textBoxRef:getValue()
    if textBox then
        textBox:CaptureFocus()
    end
end

function AssetRenameApp:willUnmount()

end

return AssetRenameApp