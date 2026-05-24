--// PadUI - Clean ClickGUI Framework
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

pcall(function() CoreGui:FindFirstChild("PadUI"):Destroy() end)

-- ============================================================
--  LIGHTING EFFECTS
-- ============================================================
local Blur = Instance.new("BlurEffect")
Blur.Size = 0
Blur.Parent = Lighting

-- Bloom за панелями (белый свечение)
local Bloom = Instance.new("BloomEffect")
Bloom.Intensity  = 0
Bloom.Size       = 24
Bloom.Threshold  = 0.85
Bloom.Parent     = Lighting

local Theme = {
    Background  = Color3.fromRGB(7, 7, 7),
    Text        = Color3.fromRGB(255, 255, 255),
    TextDark    = Color3.fromRGB(125, 125, 125),
    Hover       = Color3.fromRGB(122, 122, 122),
    SettingsBG  = Color3.fromRGB(14, 14, 14),
    BindActive  = Color3.fromRGB(220, 220, 220),
    BindIdle    = Color3.fromRGB(60, 60, 60),
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

-- ============================================================
--  SETTINGS PANEL (singleton, переиспользуется)
-- ============================================================
local SettingsPanel = Instance.new("Frame")
SettingsPanel.Name              = "SettingsPanel"
SettingsPanel.Size              = UDim2.new(0, 160, 0, 72)
SettingsPanel.BackgroundColor3  = Theme.SettingsBG
SettingsPanel.BorderSizePixel   = 0
SettingsPanel.Visible           = false
SettingsPanel.ZIndex            = 100
SettingsPanel.Parent            = ScreenGui

local SPCorner = Instance.new("UICorner")
SPCorner.CornerRadius = UDim.new(0, 10)
SPCorner.Parent = SettingsPanel

-- Заголовок внутри настроек
local SPTitle = Instance.new("TextLabel")
SPTitle.BackgroundTransparency = 1
SPTitle.Position       = UDim2.new(0, 10, 0, 8)
SPTitle.Size           = UDim2.new(1, -20, 0, 14)
SPTitle.Font           = Enum.Font.GothamMedium
SPTitle.Text           = "Settings"
SPTitle.TextColor3     = Theme.TextDark
SPTitle.TextSize       = 11
SPTitle.TextXAlignment = Enum.TextXAlignment.Left
SPTitle.ZIndex         = 101
SPTitle.Parent         = SettingsPanel

-- Строка бинда
local BindRow = Instance.new("TextButton")
BindRow.Name                 = "BindRow"
BindRow.Size                 = UDim2.new(1, -12, 0, 28)
BindRow.Position             = UDim2.new(0, 6, 0, 30)
BindRow.BackgroundColor3     = Theme.BindIdle
BindRow.BackgroundTransparency = 0.5
BindRow.AutoButtonColor      = false
BindRow.Font                 = Enum.Font.Gotham
BindRow.TextSize             = 12
BindRow.TextColor3           = Theme.TextDark
BindRow.Text                 = "Bind: NONE"
BindRow.ZIndex               = 101
BindRow.Parent               = SettingsPanel

Instance.new("UICorner", BindRow).CornerRadius = UDim.new(0, 6)

-- ============================================================
--  BIND STATE
-- ============================================================
-- moduleBinds[moduleButton] = { key = Enum.KeyCode | nil, listening = false }
local moduleBinds = {}
local currentSettingsModule = nil  -- на какой модуль сейчас открыты настройки
local listeningForBind = false

local function getOrCreateBind(mod)
    if not moduleBinds[mod] then
        moduleBinds[mod] = { key = nil, listening = false }
    end
    return moduleBinds[mod]
end

local function closeSP()
    SettingsPanel.Visible = false
    currentSettingsModule = nil
    listeningForBind = false
    BindRow.Text = "Bind: NONE"
    BindRow.BackgroundColor3 = Theme.BindIdle
end

local function updateBindRow(mod)
    local bind = getOrCreateBind(mod)
    if bind.listening then
        BindRow.Text = "Press key..."
        BindRow.BackgroundColor3 = Theme.BindActive
        BindRow.TextColor3 = Theme.Background
    else
        if bind.key then
            BindRow.Text = "Bind: " .. bind.key.Name
            BindRow.BackgroundColor3 = Theme.BindIdle
            BindRow.TextColor3 = Theme.BindActive
        else
            BindRow.Text = "Bind: NONE"
            BindRow.BackgroundColor3 = Theme.BindIdle
            BindRow.TextColor3 = Theme.TextDark
        end
    end
end

-- Клик по строке бинда → начинаем слушать клавишу
BindRow.MouseButton1Click:Connect(function()
    if not currentSettingsModule then return end
    local bind = getOrCreateBind(currentSettingsModule)
    bind.listening = true
    listeningForBind = true
    updateBindRow(currentSettingsModule)
end)

-- Открыть настройки для конкретного модуля
local function openSettingsFor(mod, posX, posY)
    currentSettingsModule = mod
    listeningForBind = false
    local bind = getOrCreateBind(mod)
    bind.listening = false

    SettingsPanel.Position = UDim2.new(0, posX, 0, posY)
    SettingsPanel.Visible = true
    updateBindRow(mod)
end

-- Закрыть настройки при клике вне панели
UserInputService.InputBegan:Connect(function(input, gp)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mp = UserInputService:GetMouseLocation()
        local sp = SettingsPanel
        if sp.Visible then
            local ax = sp.AbsolutePosition.X
            local ay = sp.AbsolutePosition.Y
            local aw = sp.AbsoluteSize.X
            local ah = sp.AbsoluteSize.Y
            if mp.X < ax or mp.X > ax+aw or mp.Y < ay or mp.Y > ay+ah then
                closeSP()
            end
        end
    end
end)

-- ============================================================
--  ГЛОБАЛЬНЫЙ INPUT — бинды + сброс по Alt
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    -- если слушаем бинд
    if listeningForBind and currentSettingsModule then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            -- Escape = сброс бинда
            local bind = getOrCreateBind(currentSettingsModule)
            if input.KeyCode == Enum.KeyCode.Escape then
                bind.key = nil
            else
                bind.key = input.KeyCode
            end
            bind.listening = false
            listeningForBind = false
            updateBindRow(currentSettingsModule)
            return
        end
    end

    -- обычные бинды модулей
    if input.UserInputType == Enum.UserInputType.Keyboard and not gp then
        for mod, bind in pairs(moduleBinds) do
            if bind.key and input.KeyCode == bind.key then
                -- симулируем нажатие
                local enabled = mod:GetAttribute("Enabled")
                local newState = not enabled
                mod:SetAttribute("Enabled", newState)
                -- fires через FireEvent не получится напрямую, используем атрибут-триггер
                mod:SetAttribute("BindToggle", (mod:GetAttribute("BindToggle") or 0) + 1)
            end
        end
    end
end)

-- ============================================================
--  DRAGGING
-- ============================================================
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
        TweenService:Create(Bloom,   TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Intensity = 0.55}):Play()
        TweenService:Create(UIScale, TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Scale = 1}):Play()
    else
        closeSP()
        ResetModules()
        TweenService:Create(Blur,    TweenInfo.new(0.22, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = 0}):Play()
        TweenService:Create(Bloom,   TweenInfo.new(0.22, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Intensity = 0}):Play()
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

    local Category = {}

    function Category:AddModule(label, callback)
        local enabled = false

        local Module = Instance.new("TextButton")
        Module.Name                   = "Module"
        Module.Size                   = UDim2.new(1, 0, 0, 26)
        Module.BackgroundColor3       = Theme.Hover
        Module.BackgroundTransparency = 1
        Module.AutoButtonColor        = false
        Module.Text                   = label
        Module.Font                   = Enum.Font.Gotham
        Module.TextSize               = 13
        Module.TextColor3             = Theme.TextDark
        Module.TextXAlignment         = Enum.TextXAlignment.Left
        Module.Parent                 = Scroll

        Instance.new("UICorner", Module).CornerRadius = UDim.new(0, 8)

        local Padding = Instance.new("UIPadding")
        Padding.PaddingLeft = UDim.new(0, 10)
        Padding.Parent = Module

        -- Dots — теперь показывают бинд если есть
        local Dots = Instance.new("TextLabel")
        Dots.Name                 = "Dots"
        Dots.BackgroundTransparency = 1
        Dots.AnchorPoint          = Vector2.new(1, 0)
        Dots.Position             = UDim2.new(1, -6, 0, 0)
        Dots.Size                 = UDim2.new(0, 30, 1, 0)
        Dots.Font                 = Enum.Font.GothamBold
        Dots.Text                 = "..."
        Dots.TextColor3           = Theme.TextDark
        Dots.TextSize             = 9
        Dots.TextTruncate         = Enum.TextTruncate.AtEnd
        Dots.Parent               = Module

        local function refreshDots()
            local bind = moduleBinds[Module]
            if bind and bind.key then
                Dots.Text = bind.key.Name:sub(1, 5)
            else
                Dots.Text = "..."
            end
        end

        local function setStyle(on)
            TweenService:Create(Module, TweenInfo.new(0.12), {
                BackgroundTransparency = on and 0.82 or 1,
                TextColor3 = on and Theme.Text or Theme.TextDark,
            }):Play()
            TweenService:Create(Dots, TweenInfo.new(0.12), {
                TextColor3 = on and Theme.Text or Theme.TextDark,
            }):Play()
        end

        -- ЛКМ — включить/выключить
        Module.MouseButton1Click:Connect(function()
            enabled = not enabled
            Module:SetAttribute("Enabled", enabled)
            setStyle(enabled)
            if callback then callback(enabled) end
        end)

        -- ПКМ — открыть настройки
        Module.MouseButton2Click:Connect(function()
            if currentSettingsModule == Module and SettingsPanel.Visible then
                closeSP()
                return
            end
            local mp = UserInputService:GetMouseLocation()
            openSettingsFor(Module, mp.X + 6, mp.Y - 10)
        end)

        -- Hover подсветка
        Module.MouseEnter:Connect(function()
            if not enabled then setStyle(true) end
        end)
        Module.MouseLeave:Connect(function()
            if not enabled then setStyle(false) end
        end)

        -- Слушаем бинд-тоггл атрибут (устанавливается из global InputBegan)
        Module:GetAttributeChangedSignal("BindToggle"):Connect(function()
            enabled = Module:GetAttribute("Enabled")
            setStyle(enabled)
            refreshDots()
            if callback then callback(enabled) end
        end)

        -- Alt + hover = сброс бинда
        Module.MouseEnter:Connect(function()
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then
                local bind = moduleBinds[Module]
                if bind then
                    bind.key = nil
                    refreshDots()
                    -- если настройки открыты на этот же модуль — обновить
                    if currentSettingsModule == Module then
                        updateBindRow(Module)
                    end
                end
            end
        end)

        -- обновляем Dots когда закрываются настройки (bind мог измениться)
        SettingsPanel:GetPropertyChangedSignal("Visible"):Connect(function()
            if not SettingsPanel.Visible then
                refreshDots()
            end
        end)

        local handle = {}
        function handle:SetState(state)
            enabled = state
            Module:SetAttribute("Enabled", state)
            setStyle(state)
        end
        function handle:GetState() return enabled end
        function handle:SetLabel(text) Module.Text = text end
        function handle:GetBind()
            local b = moduleBinds[Module]
            return b and b.key or nil
        end
        return handle
    end

    return Category
end

return PadUI
