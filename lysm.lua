--// PadUI - Clean ClickGUI Framework
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

pcall(function() CoreGui:FindFirstChild("PadUI"):Destroy() end)

local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = Lighting

local Theme = {
    Background  = Color3.fromRGB(7, 7, 7),
    Text        = Color3.fromRGB(255, 255, 255),
    TextDark    = Color3.fromRGB(125, 125, 125),
    Hover       = Color3.fromRGB(122, 122, 122),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PadUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.Enabled = false
ScreenGui.Parent = CoreGui

local Holder = Instance.new("Frame")
Holder.BackgroundTransparency = 1
Holder.Parent = ScreenGui

local UIScale = Instance.new("UIScale")
UIScale.Scale = 0.92
UIScale.Parent = Holder

-- Dragging
local dragging, dragStart, startPos = false, nil, nil
Holder.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Holder.Position
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Holder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local function ResetModules()
    for _, obj in pairs(ScreenGui:GetDescendants()) do
        if obj:IsA("TextButton") and obj.Name == "Module" then
            if not obj:GetAttribute("Enabled") then
                obj.BackgroundTransparency = 1
                obj.TextColor3 = Theme.TextDark
                local d = obj:FindFirstChild("Dots")
                if d then d.TextColor3 = Theme.TextDark end
            end
        end
    end
end

local Open = false
local function ToggleGUI(state)
    Open = state
    if state then
        ScreenGui.Enabled = true
        ResetModules()
        UIScale.Scale = 0.965
        Holder.Position = UDim2.new(0.5, -Holder.AbsoluteSize.X / 2, 0.5, -155)
        TweenService:Create(Blur,    TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = 24}):Play()
        TweenService:Create(UIScale, TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Scale = 1}):Play()
    else
        ResetModules()
        TweenService:Create(Blur,    TweenInfo.new(0.22, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = 0}):Play()
        TweenService:Create(UIScale, TweenInfo.new(0.22, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Scale = 0.985}):Play()
        task.wait(0.18)
        ScreenGui.Enabled = false
    end
end

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightShift then
        ToggleGUI(not Open)
    end
end)

-- ============================================================
--  PUBLIC API
-- ============================================================
local PadUI = {}
local panelCount = 0
local PANEL_W, PANEL_GAP = 145, 5

function PadUI:AddCategory(name)
    panelCount += 1
    local idx = panelCount

    -- Resize Holder
    local totalW = panelCount * PANEL_W + (panelCount - 1) * PANEL_GAP
    Holder.Size     = UDim2.new(0, totalW, 0, 320)
    Holder.Position = UDim2.new(0.5, -totalW / 2, 0.5, -160)

    local Panel = Instance.new("Frame")
    Panel.Size             = UDim2.new(0, PANEL_W, 0, 320)
    Panel.Position         = UDim2.new(0, (idx - 1) * (PANEL_W + PANEL_GAP), 0, 0)
    Panel.BackgroundColor3 = Theme.Background
    Panel.BorderSizePixel  = 0
    Panel.Parent           = Holder

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 16)
    Corner.Parent = Panel

    local Title = Instance.new("TextLabel")
    Title.BackgroundTransparency = 1
    Title.Position       = UDim2.new(0, 12, 0, 10)
    Title.Size           = UDim2.new(1, -24, 0, 15)
    Title.Font           = Enum.Font.GothamMedium
    Title.Text           = name
    Title.TextColor3     = Theme.Text
    Title.TextSize       = 13
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent         = Panel

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.BackgroundTransparency = 1
    Scroll.Position              = UDim2.new(0, 4, 0, 36)
    Scroll.Size                  = UDim2.new(1, -8, 1, -40)
    Scroll.ScrollBarThickness    = 0
    Scroll.BorderSizePixel       = 0
    Scroll.Parent                = Panel

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 2)
    Layout.Parent  = Scroll
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 4)
    end)

    -- Category object
    local Category = {}

    function Category:AddModule(label, callback)
        local enabled = false

        local Module = Instance.new("TextButton")
        Module.Name                 = "Module"
        Module.Size                 = UDim2.new(1, 0, 0, 26)
        Module.BackgroundColor3     = Theme.Hover
        Module.BackgroundTransparency = 1
        Module.AutoButtonColor      = false
        Module.Text                 = label
        Module.Font                 = Enum.Font.Gotham
        Module.TextSize             = 13
        Module.TextColor3           = Theme.TextDark
        Module.TextXAlignment       = Enum.TextXAlignment.Left
        Module.Parent               = Scroll

        Instance.new("UICorner", Module).CornerRadius = UDim.new(0, 8)

        local Padding = Instance.new("UIPadding")
        Padding.PaddingLeft = UDim.new(0, 10)
        Padding.Parent = Module

        local Dots = Instance.new("TextLabel")
        Dots.Name                 = "Dots"
        Dots.BackgroundTransparency = 1
        Dots.AnchorPoint          = Vector2.new(1, 0)
        Dots.Position             = UDim2.new(1, -6, 0, 0)
        Dots.Size                 = UDim2.new(0, 18, 1, 0)
        Dots.Font                 = Enum.Font.GothamBold
        Dots.Text                 = "..."
        Dots.TextColor3           = Theme.TextDark
        Dots.TextSize             = 10
        Dots.Parent               = Module

        local function setStyle(on)
            TweenService:Create(Module, TweenInfo.new(0.12), {
                BackgroundTransparency = on and 0.82 or 1,
                TextColor3 = on and Theme.Text or Theme.TextDark,
            }):Play()
            TweenService:Create(Dots, TweenInfo.new(0.12), {
                TextColor3 = on and Theme.Text or Theme.TextDark,
            }):Play()
        end

        Module.MouseButton1Click:Connect(function()
            enabled = not enabled
            Module:SetAttribute("Enabled", enabled)
            setStyle(enabled)
            if callback then callback(enabled) end
        end)

        Module.MouseEnter:Connect(function()
            if not enabled then setStyle(true) end
        end)
        Module.MouseLeave:Connect(function()
            if not enabled then setStyle(false) end
        end)

        -- Module handle (чтобы можно было менять стейт снаружи)
        local handle = {}
        function handle:SetState(state)
            enabled = state
            Module:SetAttribute("Enabled", state)
            setStyle(state)
        end
        function handle:GetState() return enabled end
        function handle:SetLabel(text) Module.Text = text end
        return handle
    end

    return Category
end

return PadUI
