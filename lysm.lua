--// PadUI - Clean ClickGUI Framework
--// With: RMB Settings, Keybinds, Alt-Reset, Bloom Glow, Linoria Compat

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting         = game:GetService("Lighting")
local CoreGui          = game:GetService("CoreGui")
local RunService       = game:GetService("RunService")

pcall(function() CoreGui:FindFirstChild("PadUI"):Destroy() end)

-- ============================================================
--  BLOOM / GLOW EFFECT
-- ============================================================
local Blur = Instance.new("BlurEffect")
Blur.Size   = 0
Blur.Parent = Lighting

local Bloom = Instance.new("BloomEffect")
Bloom.Intensity   = 0
Bloom.Size        = 24
Bloom.Threshold   = 0.85
Bloom.Parent      = Lighting

local Theme = {
    Background  = Color3.fromRGB(7, 7, 7),
    Text        = Color3.fromRGB(255, 255, 255),
    TextDark    = Color3.fromRGB(125, 125, 125),
    Hover       = Color3.fromRGB(122, 122, 122),
    Accent      = Color3.fromRGB(200, 200, 200),
    SettingsBG  = Color3.fromRGB(14, 14, 14),
    BindBG      = Color3.fromRGB(22, 22, 22),
    BindActive  = Color3.fromRGB(40, 40, 40),
}

-- ============================================================
--  LINORIA COMPAT GLOBALS
-- ============================================================
if not getgenv then getgenv = function() return _G end end
local genv = getgenv()
genv.Options  = genv.Options  or {}
genv.Toggles  = genv.Toggles  or {}
local Options = genv.Options
local Toggles = genv.Toggles

-- ============================================================
--  SCREEN GUI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "PadUI"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Global
ScreenGui.Enabled         = false
ScreenGui.Parent          = CoreGui

local Holder = Instance.new("Frame")
Holder.BackgroundTransparency = 1
Holder.Parent = ScreenGui

local UIScale = Instance.new("UIScale")
UIScale.Scale  = 0.92
UIScale.Parent = Holder

-- ============================================================
--  DRAG
-- ============================================================
local dragging, dragStart, startPos = false, nil, nil
Holder.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = Holder.Position
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Holder.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ============================================================
--  SETTINGS POPUP (shared singleton)
-- ============================================================
local SettingsPopup = Instance.new("Frame")
SettingsPopup.Name                 = "SettingsPopup"
SettingsPopup.Size                 = UDim2.new(0, 160, 0, 90)
SettingsPopup.BackgroundColor3     = Theme.SettingsBG
SettingsPopup.BorderSizePixel      = 0
SettingsPopup.Visible              = false
SettingsPopup.ZIndex               = 100
SettingsPopup.Parent               = ScreenGui
Instance.new("UICorner", SettingsPopup).CornerRadius = UDim.new(0, 10)

local SP_Stroke = Instance.new("UIStroke", SettingsPopup)
SP_Stroke.Color        = Color3.fromRGB(45, 45, 45)
SP_Stroke.Thickness    = 1
SP_Stroke.Transparency = 0

-- Bind row label
local BindLabel = Instance.new("TextLabel", SettingsPopup)
BindLabel.BackgroundTransparency = 1
BindLabel.Position     = UDim2.new(0, 10, 0, 10)
BindLabel.Size         = UDim2.new(0, 60, 0, 20)
BindLabel.Font         = Enum.Font.Gotham
BindLabel.TextSize     = 11
BindLabel.TextColor3   = Theme.TextDark
BindLabel.Text         = "Bind"
BindLabel.TextXAlignment = Enum.TextXAlignment.Left
BindLabel.ZIndex       = 101

-- Bind button
local BindButton = Instance.new("TextButton", SettingsPopup)
BindButton.Size                 = UDim2.new(1, -20, 0, 24)
BindButton.Position             = UDim2.new(0, 10, 0, 32)
BindButton.BackgroundColor3     = Theme.BindBG
BindButton.AutoButtonColor      = false
BindButton.Font                 = Enum.Font.GothamMedium
BindButton.TextSize             = 11
BindButton.TextColor3           = Theme.TextDark
BindButton.Text                 = "None"
BindButton.ZIndex               = 101
Instance.new("UICorner", BindButton).CornerRadius = UDim.new(0, 6)

-- Divider
local SP_Div = Instance.new("Frame", SettingsPopup)
SP_Div.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SP_Div.BorderSizePixel  = 0
SP_Div.Position         = UDim2.new(0, 10, 0, 62)
SP_Div.Size             = UDim2.new(1, -20, 0, 1)
SP_Div.ZIndex           = 101

-- Reset bind hint
local ResetHint = Instance.new("TextLabel", SettingsPopup)
ResetHint.BackgroundTransparency = 1
ResetHint.Position     = UDim2.new(0, 10, 0, 68)
ResetHint.Size         = UDim2.new(1, -20, 0, 16)
ResetHint.Font         = Enum.Font.Gotham
ResetHint.TextSize     = 10
ResetHint.TextColor3   = Color3.fromRGB(70, 70, 70)
ResetHint.Text         = "Alt+Hover to reset bind"
ResetHint.TextXAlignment = Enum.TextXAlignment.Left
ResetHint.ZIndex       = 101

-- ============================================================
--  POPUP STATE
-- ============================================================
local currentPopupModule = nil   -- handle текущего открытого модуля
local listeningForBind   = false

local function ClosePopup()
    SettingsPopup.Visible = false
    currentPopupModule    = nil
    listeningForBind      = false
    BindButton.Text       = "None"
    BindButton.BackgroundColor3 = Theme.BindBG
    BindButton.TextColor3 = Theme.TextDark
end

-- Закрытие по клику вне попапа
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if SettingsPopup.Visible then
            -- проверяем что клик не по попапу
            local mPos = UserInputService:GetMouseLocation()
            local sp    = SettingsPopup.AbsolutePosition
            local ss    = SettingsPopup.AbsoluteSize
            local inside = mPos.X >= sp.X and mPos.X <= sp.X + ss.X
                       and mPos.Y >= sp.Y and mPos.Y <= sp.Y + ss.Y
            if not inside then
                ClosePopup()
            end
        end
    end
end)

-- ============================================================
--  KEYBIND RUNTIME
-- ============================================================
-- moduleBinds[handle] = {key=KeyCode|nil, mode="Toggle"}
local moduleBinds = {}

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    -- Слушаем нажатие для назначения бинда
    if listeningForBind and currentPopupModule then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local kc = input.KeyCode
            if kc == Enum.KeyCode.Escape then
                -- отмена
                listeningForBind = false
                local existing = moduleBinds[currentPopupModule]
                local keyName = (existing and existing.key) and existing.key.Name or "None"
                BindButton.Text = keyName
                BindButton.BackgroundColor3 = Theme.BindBG
                BindButton.TextColor3 = Theme.TextDark
                return
            end
            -- назначаем бинд
            moduleBinds[currentPopupModule] = moduleBinds[currentPopupModule] or {}
            moduleBinds[currentPopupModule].key = kc
            moduleBinds[currentPopupModule].mode = "Toggle"
            BindButton.Text = kc.Name
            BindButton.BackgroundColor3 = Theme.BindBG
            BindButton.TextColor3 = Theme.Text
            listeningForBind = false
            -- обновляем Linoria Options если есть
            if currentPopupModule._linoriaKeyPickerId then
                local opt = Options[currentPopupModule._linoriaKeyPickerId]
                if opt and opt.SetValue then
                    pcall(function() opt:SetValue({kc.Name, "Toggle"}) end)
                end
            end
            return
        end
    end

    -- Срабатывание бинда
    if input.UserInputType == Enum.UserInputType.Keyboard then
        for handle, bindData in pairs(moduleBinds) do
            if bindData.key and input.KeyCode == bindData.key then
                -- toggle модуль
                handle:SetState(not handle:GetState())
            end
        end
    end
end)

-- ============================================================
--  ALT + HOVER RESET
-- ============================================================
-- регистрируется в AddModule через MouseEnter

-- ============================================================
--  HELPERS
-- ============================================================
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
        TweenService:Create(Bloom,   TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Intensity = 0.6}):Play()
        TweenService:Create(UIScale, TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Scale = 1}):Play()
    else
        ClosePopup()
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
--  BIND BUTTON LOGIC
-- ============================================================
BindButton.MouseButton1Click:Connect(function()
    if not currentPopupModule then return end
    listeningForBind = true
    BindButton.Text             = "Press key..."
    BindButton.BackgroundColor3 = Theme.BindActive
    BindButton.TextColor3       = Theme.Text
end)

-- ============================================================
--  BLOOM GLOW LOOP (пульс за падами когда GUI открыт)
-- ============================================================
RunService.RenderStepped:Connect(function()
    if Open then
        local t = tick()
        local pulse = 0.45 + math.sin(t * 1.8) * 0.15
        Bloom.Intensity = pulse
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

    -- Белый bloom-glow frame за падом
    local GlowFrame = Instance.new("Frame")
    GlowFrame.Size             = UDim2.new(0, PANEL_W + 30, 0, 350)
    GlowFrame.Position         = UDim2.new(0, (idx - 1) * (PANEL_W + PANEL_GAP) - 15, 0, -15)
    GlowFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    GlowFrame.BackgroundTransparency = 0.92
    GlowFrame.BorderSizePixel  = 0
    GlowFrame.ZIndex           = 0
    GlowFrame.Parent           = Holder
    Instance.new("UICorner", GlowFrame).CornerRadius = UDim.new(0, 24)

    -- Анимация glow
    task.spawn(function()
        while true do
            RunService.RenderStepped:Wait()
            if Open then
                local t = tick()
                GlowFrame.BackgroundTransparency = 0.90 + math.sin(t * 1.4 + idx) * 0.04
            else
                GlowFrame.BackgroundTransparency = 0.97
            end
        end
    end)

    local Panel = Instance.new("Frame")
    Panel.Size             = UDim2.new(0, PANEL_W, 0, 320)
    Panel.Position         = UDim2.new(0, (idx - 1) * (PANEL_W + PANEL_GAP), 0, 0)
    Panel.BackgroundColor3 = Theme.Background
    Panel.BorderSizePixel  = 0
    Panel.ZIndex           = 2
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
    Title.ZIndex         = 3
    Title.Parent         = Panel

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.BackgroundTransparency = 1
    Scroll.Position              = UDim2.new(0, 4, 0, 36)
    Scroll.Size                  = UDim2.new(1, -8, 1, -40)
    Scroll.ScrollBarThickness    = 0
    Scroll.BorderSizePixel       = 0
    Scroll.ZIndex                = 3
    Scroll.Parent                = Panel

    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 2)
    Layout.Parent  = Scroll
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 4)
    end)

    -- -------------------------------------------------------
    --  Category object
    -- -------------------------------------------------------
    local Category = {}

    -- Linoria AddRightGroupbox / AddLeftGroupbox → просто возвращает себя
    function Category:AddRightGroupbox(_) return self end
    function Category:AddLeftGroupbox(_)  return self end
    function Category:AddDivider() end  -- visual divider — skip (нет слотов)

    -- -------------------------------------------------------
    --  AddModule — основная функция
    -- -------------------------------------------------------
    function Category:AddModule(label, callback)
        local enabled = false
        local handle  = {}
        handle._linoriaKeyPickerId = nil

        moduleBinds[handle] = {key = nil, mode = "Toggle"}

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
        Module.ZIndex                 = 4
        Module.Parent                 = Scroll

        Instance.new("UICorner", Module).CornerRadius = UDim.new(0, 8)

        local Padding = Instance.new("UIPadding")
        Padding.PaddingLeft = UDim.new(0, 10)
        Padding.Parent = Module

        -- Dots / bind indicator
        local Dots = Instance.new("TextLabel")
        Dots.Name                   = "Dots"
        Dots.BackgroundTransparency = 1
        Dots.AnchorPoint            = Vector2.new(1, 0)
        Dots.Position               = UDim2.new(1, -6, 0, 0)
        Dots.Size                   = UDim2.new(0, 30, 1, 0)
        Dots.Font                   = Enum.Font.GothamBold
        Dots.Text                   = "..."
        Dots.TextColor3             = Theme.TextDark
        Dots.TextSize               = 9
        Dots.ZIndex                 = 5
        Dots.Parent                 = Module

        local function updateDotsText()
            local bd = moduleBinds[handle]
            if bd and bd.key then
                Dots.Text = bd.key.Name
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

        -- ЛКМ — toggle
        Module.MouseButton1Click:Connect(function()
            enabled = not enabled
            Module:SetAttribute("Enabled", enabled)
            setStyle(enabled)
            if callback then callback(enabled) end
            -- Linoria Toggles sync
            if handle._linoriaToggleId then
                local tog = Toggles[handle._linoriaToggleId]
                if tog then tog.Value = enabled end
            end
        end)

        -- ПКМ — открыть настройки
        Module.MouseButton2Click:Connect(function()
            if currentPopupModule == handle then
                ClosePopup()
                return
            end
            ClosePopup()
            currentPopupModule = handle
            listeningForBind   = false

            -- позиция попапа рядом с модулем
            local absPos  = Module.AbsolutePosition
            local absSize = Module.AbsoluteSize
            SettingsPopup.Position = UDim2.new(
                0, absPos.X + absSize.X + 4,
                0, absPos.Y - 4
            )

            -- текущий бинд
            local bd = moduleBinds[handle]
            if bd and bd.key then
                BindButton.Text       = bd.key.Name
                BindButton.TextColor3 = Theme.Text
            else
                BindButton.Text       = "None"
                BindButton.TextColor3 = Theme.TextDark
            end
            BindButton.BackgroundColor3 = Theme.BindBG

            SettingsPopup.Visible = true
        end)

        -- Hover
        Module.MouseEnter:Connect(function()
            if not enabled then setStyle(true) end
            -- Alt + Hover = ресет бинда
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or
               UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then
                moduleBinds[handle] = {key = nil, mode = "Toggle"}
                updateDotsText()
                if handle._linoriaKeyPickerId then
                    local opt = Options[handle._linoriaKeyPickerId]
                    if opt and opt.SetValue then
                        pcall(function() opt:SetValue({"None", "Toggle"}) end)
                    end
                end
                -- Если попап открыт для этого модуля — обновить кнопку
                if currentPopupModule == handle then
                    BindButton.Text       = "None"
                    BindButton.TextColor3 = Theme.TextDark
                end
            end
        end)
        Module.MouseLeave:Connect(function()
            if not enabled then setStyle(false) end
        end)

        -- Handle API
        function handle:SetState(state)
            enabled = state
            Module:SetAttribute("Enabled", state)
            setStyle(state)
            if callback then callback(state) end
            if self._linoriaToggleId then
                local tog = Toggles[self._linoriaToggleId]
                if tog then tog.Value = state end
            end
        end
        function handle:GetState()   return enabled           end
        function handle:SetLabel(t)  Module.Text = t          end
        function handle:SetBind(keyCode)
            moduleBinds[self] = {key = keyCode, mode = "Toggle"}
            updateDotsText()
        end
        function handle:GetBind()
            local bd = moduleBinds[self]
            return bd and bd.key or nil
        end

        return handle
    end

    -- -------------------------------------------------------
    --  Linoria AddToggle
    --  KillauraGroup:AddToggle("KA_Enabled", {Text=..., Default=..., Callback=...})
    -- -------------------------------------------------------
    function Category:AddToggle(id, opts)
        opts = opts or {}
        local cb = opts.Callback
        local handle = self:AddModule(opts.Text or id, cb)
        handle._linoriaToggleId = id

        -- Объект совместимости для Toggles[id]
        local togObj = {Value = opts.Default or false}
        setmetatable(togObj, {
            __index = function(t, k)
                if k == "Value" then return rawget(t, "Value") end
            end,
            __newindex = function(t, k, v)
                if k == "Value" then
                    rawset(t, "Value", v)
                    handle:SetState(v)
                end
            end,
        })
        Toggles[id] = togObj

        if opts.Default then
            handle:SetState(true)
        end

        -- Объект для цепочки :AddKeyPicker
        local toggleHandle = {_moduleHandle = handle, _id = id}
        function toggleHandle:AddKeyPicker(pickerId, pickerOpts)
            pickerOpts = pickerOpts or {}
            handle._linoriaKeyPickerId = pickerId

            -- Options[pickerId]
            local pickerObj = {
                Value    = {pickerOpts.Default or "None", pickerOpts.Mode or "Toggle"},
                _handle  = handle,
            }
            function pickerObj:SetValue(val)
                local keyName = (type(val) == "table") and val[1] or val
                if keyName == "None" or keyName == nil then
                    handle:SetBind(nil)
                else
                    local kc = Enum.KeyCode[keyName]
                    if kc then handle:SetBind(kc) end
                end
                self.Value = (type(val) == "table") and val or {val, "Toggle"}
            end
            Options[pickerId] = pickerObj
            return pickerObj
        end
        return toggleHandle
    end

    -- -------------------------------------------------------
    --  Linoria AddButton
    -- -------------------------------------------------------
    function Category:AddButton(opts)
        opts = opts or {}
        -- Рендерим как модуль без toggle, только клик
        local btn = Instance.new("TextButton")
        btn.Name                   = "ModuleBtn"
        btn.Size                   = UDim2.new(1, 0, 0, 22)
        btn.BackgroundColor3       = Color3.fromRGB(20, 20, 20)
        btn.BackgroundTransparency = 0.4
        btn.AutoButtonColor        = false
        btn.Text                   = opts.Text or "Button"
        btn.Font                   = Enum.Font.Gotham
        btn.TextSize               = 11
        btn.TextColor3             = Theme.TextDark
        btn.TextXAlignment         = Enum.TextXAlignment.Center
        btn.ZIndex                 = 4
        btn.Parent                 = Scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        btn.MouseButton1Click:Connect(function()
            if opts.Func then opts.Func() end
        end)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {TextColor3 = Theme.Text}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1), {TextColor3 = Theme.TextDark}):Play()
        end)
    end

    -- -------------------------------------------------------
    --  Linoria AddSlider
    -- -------------------------------------------------------
    function Category:AddSlider(id, opts)
        opts = opts or {}
        local val   = opts.Default or opts.Min or 0
        local min   = opts.Min    or 0
        local max   = opts.Max    or 100
        local round = opts.Rounding or 0
        local cb    = opts.Callback

        local Container = Instance.new("Frame")
        Container.Size                   = UDim2.new(1, 0, 0, 38)
        Container.BackgroundTransparency = 1
        Container.ZIndex                 = 4
        Container.Parent                 = Scroll

        local Lbl = Instance.new("TextLabel", Container)
        Lbl.BackgroundTransparency = 1
        Lbl.Position     = UDim2.new(0, 10, 0, 0)
        Lbl.Size         = UDim2.new(1, -20, 0, 16)
        Lbl.Font         = Enum.Font.Gotham
        Lbl.TextSize     = 10
        Lbl.TextColor3   = Theme.TextDark
        Lbl.Text         = (opts.Text or id) .. ": " .. val
        Lbl.TextXAlignment = Enum.TextXAlignment.Left
        Lbl.ZIndex       = 5

        local Track = Instance.new("Frame", Container)
        Track.Position         = UDim2.new(0, 10, 0, 20)
        Track.Size             = UDim2.new(1, -20, 0, 6)
        Track.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Track.BorderSizePixel  = 0
        Track.ZIndex           = 5
        Instance.new("UICorner", Track).CornerRadius = UDim.new(0, 3)

        local Fill = Instance.new("Frame", Track)
        Fill.BackgroundColor3 = Theme.Accent
        Fill.BorderSizePixel  = 0
        Fill.ZIndex           = 6
        Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 3)

        local function updateFill(v)
            local pct = math.clamp((v - min) / (max - min), 0, 1)
            Fill.Size = UDim2.new(pct, 0, 1, 0)
            local rnd = math.pow(10, round)
            local disp = math.floor(v * rnd + 0.5) / rnd
            Lbl.Text = (opts.Text or id) .. ": " .. disp
        end
        updateFill(val)

        local draggingSlider = false
        Track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSlider = true
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSlider = false
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if draggingSlider and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local rel = (inp.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X
                local newVal = min + math.clamp(rel, 0, 1) * (max - min)
                local rnd = math.pow(10, round)
                newVal = math.floor(newVal * rnd + 0.5) / rnd
                val = newVal
                updateFill(val)
                if cb then cb(val) end
                if Options[id] then Options[id].Value = val end
            end
        end)

        local sliderObj = {Value = val}
        function sliderObj:SetValue(v)
            val = math.clamp(v, min, max)
            updateFill(val)
            if cb then cb(val) end
        end
        Options[id] = sliderObj
        return sliderObj
    end

    -- AddDivider как метод (Linoria вызывает его на groupbox)
    function Category:AddDivider()
        local Div = Instance.new("Frame")
        Div.Size             = UDim2.new(1, -16, 0, 1)
        Div.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Div.BorderSizePixel  = 0
        Div.Parent           = Scroll
    end

    return Category
end

-- ============================================================
--  Linoria-style Tabs shim
--  local Tabs = { Combat = lib:AddCategory("Combat") }
-- ============================================================
function PadUI:MakeTabs(tabDefs)
    local out = {}
    for k, name in pairs(tabDefs) do
        out[k] = self:AddCategory(name)
    end
    return out
end

return PadUI
