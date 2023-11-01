-- App to handle rendering of the plugin's UI
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local components = script.Parent
local pluginSource = components.Parent
local pluginUtil = pluginSource:FindFirstChild("Packages") or ReplicatedStorage:FindFirstChild("Packages")

-- get roact/rodux
local roact = require(pluginUtil:WaitForChild("Roact"))

-- consts
local THEME_COLOR = Enum.StudioStyleGuideColor
local THEME_COLOR_MOD = Enum.StudioStyleGuideModifier

-- create PoseLoaderApp
local Header = roact.PureComponent:extend("Header")

Header.defaultProps = {
    theme = nil; -- must be passed by parent
    position = UDim2.new();
    height = 36;

    labelWidth = 120;
    spacing = 12;

    font = Enum.Font.SourceSansSemibold;
    textSize = 18;

    propFont = Enum.Font.SourceSansBold;
    propTextSize = 16;

    textPadding = 18;
}

function Header:init()
    self.state = {}
end

function Header:render()
    local theme = self.props.theme
    local height = self.props.height

    local rigText = self.props.activeRig and self.props.activeRig.Name or "None"
    local schemeText = self.props.activeScheme

    local labelWidth = self.props.labelWidth
    local spacing = self.props.spacing

    local propPosX = labelWidth + spacing
    local sizeOffset = labelWidth+spacing*2

    return roact.createElement("Frame", {
        BackgroundColor3 = theme:GetColor(THEME_COLOR.HeaderSection);
        BorderColor3 = theme:GetColor(THEME_COLOR.Border);
        BorderMode = Enum.BorderMode.Outline;
        Size = UDim2.new(1,0,0,height);
        Position = self.props.position;
    }, {
        -- label for active scheme
        Header = roact.createElement("TextLabel", {
            BackgroundTransparency = 1;
            Font = self.props.font;
            Text = "Rename (1) Asset(s):";
            TextColor3 = theme:GetColor(THEME_COLOR.SubText);
            TextSize = self.props.textSize;
            TextXAlignment = Enum.TextXAlignment.Left;
            Size = UDim2.new(0, 96, 0.5, 0);
        }, {
            Padding = roact.createElement("UIPadding", {
                PaddingLeft = UDim.new(0, self.props.textPadding)
            });
        });
        -- name for active scheme
        TextBox = roact.createElement("TextLabel", {
            BackgroundColor3 = theme:GetColor(THEME_COLOR.InputFieldBackground);
            BorderColor3 = theme:GetColor(THEME_COLOR.InputFieldBorder);
            Font = self.props.propFont;
            Text = schemeText ~= "" and schemeText or "None";
            TextColor3 = theme:GetColor(THEME_COLOR.InfoText);
            TextSize = self.props.propTextSize;
            TextXAlignment = Enum.TextXAlignment.Center;
            Position = UDim2.new(0, propPosX, 0, spacing/2);
            Size = UDim2.new(1, -sizeOffset, 0.5, -spacing);
            TextTruncate = Enum.TextTruncate.AtEnd;
        });
    })
end

function Header:didMount()

end

function Header:didUpdate()

end

function Header:willUnmount()

end

return Header