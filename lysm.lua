--[[
    PadUI.lua (v2)
    ClickGUI framework — Minecraft cheat client aesthetic
    
    Binds:
      M3 (middle click) on module → press key to bind
      Left Alt + click on module  → clear bind
      RightShift                  → toggle GUI
    
    Keybind list (watermark-style):
      Shows active (toggled ON) modules that have a bind
      Format: "Module Name [KEY]"
      Slide-in / slide-out animation
]]

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TextService      = game:GetService("TextService")
local Lighting         = game:GetService("Lighting")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")

pcall(function() CoreGui:FindFirstChild("PadUI"):Destroy() end)

-- ══════════════════════════════════════════════════════════════════
--  THEME
-- ══════════════════════════════════════════════════════════════════
local Theme = {
    Background  = Color3.fromRGB(7, 7, 7),
    Text        = Color3.fromRGB(255, 255, 255),
    TextDark    = Color3.fromRGB(125, 125, 125),
    Hover       = Color3.fromRGB(122, 122, 122),
    BindActive  = Color3.fromRGB(220, 220, 220),
    BindIdle    = Color3.fromRGB(60, 60, 60),
    SettingsBG  = Color3.fromRGB(14, 14, 14),
}

-- ══════════════════════════════════════════════════════════════════
--  KEYBIND LIST CONFIG  (matches watermark.lua style)
-- ══════════════════════════════════════════════════════════════════
local KB = {
    x          = 10,
    y          = 60,
    headerH    = 22,
    rowH       = 20,
    rowGap     = 2,
    padL       = 6,
    slideSpeed = 8,
    sizeSpeed  = 10,
    textSize   = 12,
    keyTextSize= 11,
    cornerRadius = 6,
    bgColor    = Color3.fromRGB(18, 19, 20),
    bgTrans    = 0.71,
    outlineColor = Color3.fromRGB(255, 255, 255),
    outlineTrans = 0.78,
    shadowColor  = Color3.fromRGB(0, 0, 0),
    shadowTrans  = 0.82,
    sepColor     = Color3.fromRGB(180, 180, 180),
    sepTrans     = 0.45,
}

-- ══════════════════════════════════════════════════════════════════
--  LIGHTING
-- ══════════════════════════════════════════════════════════════════
local Blur = Instance.new("BlurEffect")
Blur.Size   = 0
Blur.Parent = Lighting

local Bloom = Instance.new("BloomEffect")
Bloom.Intensity  = 0
Bloom.Size       = 24
Bloom.Threshold  = 0.85
Bloom.Parent     = Lighting

-- ══════════════════════════════════════════════════════════════════
--  SCREEN GUI
-- ══════════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "PadUI"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Global
ScreenGui.IgnoreGuiInset  = true
ScreenGui.Enabled         = false
ScreenGui.Parent          = CoreGui

-- ── Keybind list lives in its own always-on ScreenGui ──────────────
local KBGui = Instance.new("ScreenGui")
KBGui.Name            = "PadUI_KB"
KBGui.ResetOnSpawn    = false
KBGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
KBGui.IgnoreGuiInset  = true
KBGui.Enabled         = true
KBGui.Parent          = CoreGui

-- ── Holder (main panel group) ───────────────────────────────────────
local Holder = Instance.new("Frame")
Holder.BackgroundTransparency = 1
Holder.Parent = ScreenGui

local UIScale = Instance.new("UIScale")
UIScale.Scale  = 0.92
UIScale.Parent = Holder

-- ══════════════════════════════════════════════════════════════════
--  BIND STATE  (global registry)
-- ══════════════════════════════════════════════════════════════════
-- moduleBinds[moduleButton] = { key=Enum.KeyCode|nil, listening=false, name=string, enabled=false }
local moduleBinds     = {}
local listeningModule = nil   -- which module is waiting for a key

-- ── Small "press key…" tooltip that follows the mouse ──────────────
local ListenHint = Instance.new("TextLabel")
ListenHint.Name                 = "ListenHint"
ListenHint.BackgroundColor3     = Theme.SettingsBG
ListenHint.BackgroundTransparency = 0.15
ListenHint.BorderSizePixel      = 0
ListenHint.Size                 = UDim2.new(0, 100, 0, 22)
ListenHint.Font                 = Enum.Font.GothamMedium
ListenHint.Text                 = "Press key…"
ListenHint.TextColor3           = Theme.BindActive
ListenHint.TextSize             = 11
ListenHint.ZIndex               = 200
ListenHint.Visible              = false
ListenHint.Parent               = ScreenGui
Instance.new("UICorner", ListenHint).CornerRadius = UDim.new(0, 6)

local function getOrCreate(mod, name)
    if not moduleBinds[mod] then
        moduleBinds[mod] = { key = nil, listening = false, name = name, enabled = false }
    end
    return moduleBinds[mod]
end

local function startListening(mod)
    if listeningModule and listeningModule ~= mod then
        -- cancel previous
        local prev = moduleBinds[listeningModule]
        if prev then prev.listening = false end
    end
    local bind = moduleBinds[mod]
    if not bind then return end
    bind.listening = true
    listeningModule = mod
    ListenHint.Visible = true
end

local function stopListening()
    if listeningModule then
        local bind = moduleBinds[listeningModule]
        if bind then bind.listening = false end
    end
    listeningModule = nil
    ListenHint.Visible = false
end

-- Move hint with mouse
RunService.RenderStepped:Connect(function()
    if ListenHint.Visible then
        local mp = UserInputService:GetMouseLocation()
        ListenHint.Position = UDim2.fromOffset(mp.X + 12, mp.Y + 4)
    end
end)

-- ── Global input: catch bind key, toggle via bind ───────────────────
UserInputService.InputBegan:Connect(function(input, gp)
    -- listening for a new bind key
    if listeningModule then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local bind = moduleBinds[listeningModule]
            if bind then
                if input.KeyCode == Enum.KeyCode.Escape then
                    bind.key = nil
                else
                    bind.key = input.KeyCode
                end
            end
            stopListening()
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton3 then
            -- M3 again = cancel
            stopListening()
            return
        end
    end

    -- fire module toggles via keybind
    if input.UserInputType == Enum.UserInputType.Keyboard and not gp then
        for mod, bind in pairs(moduleBinds) do
            if bind.key and input.KeyCode == bind.key then
                mod:SetAttribute("BindToggle", (mod:GetAttribute("BindToggle") or 0) + 1)
            end
        end
    end
end)

-- ══════════════════════════════════════════════════════════════════
--  KEYBIND LIST DRAWING  (watermark.lua style, pools)
-- ══════════════════════════════════════════════════════════════════
local FONT_TEXT = Enum.Font.GothamBold

local function measure(str, size, font)
    return TextService:GetTextSize(str, size, font, Vector2.new(2000, 100)).X
end

-- Frame pool
local framePool, frameCursor = {}, 0
local function beginFrames() frameCursor = 0 end
local function getFrame(z)
    frameCursor += 1
    if not framePool[frameCursor] then
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0
        f.Parent = KBGui
        framePool[frameCursor] = f
    end
    local f = framePool[frameCursor]
    f.Visible = true
    f.ZIndex  = z or 2
    return f
end
local function endFrames()
    for i = frameCursor + 1, #framePool do framePool[i].Visible = false end
end

-- Label pool
local labelPool, labelCursor = {}, 0
local function beginLabels() labelCursor = 0 end
local function getLabel(z)
    labelCursor += 1
    if not labelPool[labelCursor] then
        local l = Instance.new("TextLabel")
        l.BackgroundTransparency = 1
        l.BorderSizePixel        = 0
        l.TextXAlignment         = Enum.TextXAlignment.Left
        l.Parent                 = KBGui
        labelPool[labelCursor]   = l
    end
    local l = labelPool[labelCursor]
    l.Visible = true
    l.ZIndex  = z or 5
    return l
end
local function endLabels()
    for i = labelCursor + 1, #labelPool do labelPool[i].Visible = false end
end

local function makeBlock(x, y, w, h, zBase)
    zBase = zBase or 1
    local s = getFrame(zBase)
    s.BackgroundColor3       = KB.shadowColor
    s.BackgroundTransparency = KB.shadowTrans
    s.Position               = UDim2.fromOffset(x + 1, y + 1)
    s.Size                   = UDim2.fromOffset(w, h)
    if not s:FindFirstChildOfClass("UICorner") then
        Instance.new("UICorner", s).CornerRadius = UDim.new(0, KB.cornerRadius)
    end
    local f = getFrame(zBase + 1)
    f.BackgroundColor3       = KB.bgColor
    f.BackgroundTransparency = KB.bgTrans
    f.Position               = UDim2.fromOffset(x, y)
    f.Size                   = UDim2.fromOffset(w, h)
    if not f:FindFirstChildOfClass("UICorner") then
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, KB.cornerRadius)
    end
    if not f:FindFirstChildOfClass("UIStroke") then
        local st        = Instance.new("UIStroke", f)
        st.Color        = KB.outlineColor
        st.Transparency = KB.outlineTrans
        st.Thickness    = 0.5
    end
end

local function drawStrPlain(str, x, y, color, font, size, alignRight, z)
    if alignRight then
        x = x - measure(str, size, font)
    end
    local curX = x
    for i = 1, #str do
        local ch  = str:sub(i, i)
        local cw  = measure(ch, size, font)
        local lbl = getLabel(z or 5)
        lbl.Text       = ch
        lbl.Font       = font
        lbl.TextSize   = size
        lbl.TextColor3 = color
        lbl.Position   = UDim2.fromOffset(math.floor(curX), math.floor(y))
        lbl.Size       = UDim2.fromOffset(cw + 1, size + 2)
        curX = curX + cw
    end
    return curX
end

-- ── Per-entry slide state ─────────────────────────────────────────
-- entries: { mod=TextButton, name=string, keyName=string, slideT=float, active=bool }
local kbEntries = {}
local smoothW   = -1
local smoothH   = -1

local function easeOut(t)
    t = math.clamp(t, 0, 1)
    return 1 - (1 - t)^3
end

local function smoothTo(cur, target, dt, speed)
    if not (dt > 0) then return target end
    return cur + (target - cur) * (1 - math.exp(-speed * dt))
end

local lastKBTime = tick()

local function tickKeybindList()
    local now = tick()
    local dt  = math.clamp(now - lastKBTime, 0, 0.1)
    lastKBTime = now

    beginFrames()
    beginLabels()

    -- Sync entries from moduleBinds
    -- Add/update entries for modules that are ON and have a bind
    for mod, bind in pairs(moduleBinds) do
        local shouldShow = bind.enabled and bind.key ~= nil
        local found = false
        for _, e in ipairs(kbEntries) do
            if e.mod == mod then
                found = true
                e.active  = shouldShow
                e.keyName = bind.key and bind.key.Name or ""
                break
            end
        end
        if not found and shouldShow then
            table.insert(kbEntries, {
                mod     = mod,
                name    = bind.name,
                keyName = bind.key and bind.key.Name or "",
                slideT  = 0,
                active  = true,
            })
        end
    end

    -- Animate
    for i = #kbEntries, 1, -1 do
        local e = kbEntries[i]
        local target = e.active and 1 or 0
        e.slideT = smoothTo(e.slideT, target, dt, KB.slideSpeed)
        if not e.active and e.slideT < 0.01 then
            table.remove(kbEntries, i)
        end
    end

    if #kbEntries == 0 and smoothH < 1 then
        endFrames()
        endLabels()
        return
    end

    local kx = KB.x
    local ky = KB.y
    local ts = KB.textSize
    local ks = KB.keyTextSize

    -- Target width
    local header   = "Key Binds"
    local headerTW = measure(header, ts, FONT_TEXT)
    local targetW  = headerTW + KB.padL * 2 + 16

    for _, e in ipairs(kbEntries) do
        local label   = e.name .. " [" .. e.keyName .. "]"
        local labelW  = measure(label, ts, FONT_TEXT)
        local rowW    = KB.padL * 2 + labelW
        if rowW > targetW then targetW = rowW end
    end
    targetW = math.max(targetW, 100)

    if smoothW < 0 then smoothW = targetW end
    smoothW = smoothTo(smoothW, targetW, dt, KB.sizeSpeed)
    local panelW = math.floor(smoothW)

    -- Target height
    local targetH = KB.headerH
    for _, e in ipairs(kbEntries) do
        targetH += (KB.rowH + KB.rowGap) * easeOut(e.slideT)
    end
    if smoothH < 0 then smoothH = targetH end
    smoothH = smoothTo(smoothH, targetH, dt, KB.sizeSpeed)

    -- Header
    makeBlock(kx, ky, panelW, KB.headerH, 1)
    local textY = ky + (KB.headerH - ts) / 2 - 1
    drawStrPlain(header, kx + KB.padL, textY, Color3.fromRGB(220, 220, 220), FONT_TEXT, ts, false, 5)

    -- Horizontal sep under header
    local hSep = getFrame(4)
    hSep.BackgroundColor3       = KB.sepColor
    hSep.BackgroundTransparency = KB.sepTrans
    hSep.Position               = UDim2.fromOffset(kx, ky + KB.headerH - 1)
    hSep.Size                   = UDim2.fromOffset(panelW, 1)

    -- Rows
    local rowY = ky + KB.headerH + KB.rowGap
    local textColor = Color3.fromRGB(210, 210, 210)
    local dimColor  = Color3.fromRGB(130, 130, 130)

    for _, e in ipairs(kbEntries) do
        local pc = easeOut(e.slideT)
        if pc < 0.01 then
            rowY += (KB.rowH + KB.rowGap) * pc
        else
            -- slide in from left
            local rowX = kx - panelW + panelW * pc
            makeBlock(math.floor(rowX), math.floor(rowY), panelW, KB.rowH, 1)

            local nameY = math.floor(rowY + (KB.rowH - ts) / 2) - 1

            -- "Name" left side
            drawStrPlain(e.name, math.floor(rowX) + KB.padL, nameY, textColor, FONT_TEXT, ts, false, 5)

            -- "[KEY]" right side in dimmer color
            local keyStr = "[" .. e.keyName .. "]"
            drawStrPlain(keyStr, math.floor(rowX) + panelW - KB.padL, nameY, dimColor, FONT_TEXT, ks, true, 5)

            rowY += (KB.rowH + KB.rowGap) * pc
        end
    end

    endFrames()
    endLabels()
end

RunService.RenderStepped:Connect(tickKeybindList)

-- ══════════════════════════════════════════════════════════════════
--  DRAGGING
-- ══════════════════════════════════════════════════════════════════
local dragging, dragStart, startPos = false, nil, nil
Holder.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = Holder.Position
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local d = input.Position - dragStart
        Holder.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end
end)

-- ══════════════════════════════════════════════════════════════════
--  GUI TOGGLE
-- ══════════════════════════════════════════════════════════════════
local Open = false

local function ToggleGUI(state)
    Open = state
    if state then
        ScreenGui.Enabled = true
        UIScale.Scale = 0.965
        Holder.Position = UDim2.new(0.5, -Holder.AbsoluteSize.X / 2, 0.5, -155)
        TweenService:Create(Blur,    TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = 24}):Play()
        TweenService:Create(Bloom,   TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Intensity = 0.55}):Play()
        TweenService:Create(UIScale, TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Scale = 1}):Play()
    else
        stopListening()
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

-- ══════════════════════════════════════════════════════════════════
--  PUBLIC API
-- ══════════════════════════════════════════════════════════════════
local PadUI      = {}
local panelCount = 0
local PANEL_W    = 145
local PANEL_GAP  = 5

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
    Instance.new("UICorner", Panel).CornerRadius = UDim.new(0, 16)

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
        Instance.new("UIPadding", Module).PaddingLeft = UDim.new(0, 10)

        -- Bind label (right side, shows key or "...")
        local BindLabel = Instance.new("TextLabel")
        BindLabel.Name                 = "BindLabel"
        BindLabel.BackgroundTransparency = 1
        BindLabel.AnchorPoint          = Vector2.new(1, 0)
        BindLabel.Position             = UDim2.new(1, -6, 0, 0)
        BindLabel.Size                 = UDim2.new(0, 36, 1, 0)
        BindLabel.Font                 = Enum.Font.GothamBold
        BindLabel.Text                 = "..."
        BindLabel.TextColor3           = Theme.TextDark
        BindLabel.TextSize             = 9
        BindLabel.TextTruncate         = Enum.TextTruncate.AtEnd
        BindLabel.Parent               = Module

        -- Listening indicator dot (shows when M3 pressed, waiting for key)
        local ListenDot = Instance.new("Frame")
        ListenDot.AnchorPoint        = Vector2.new(1, 0.5)
        ListenDot.Position           = UDim2.new(1, -6, 0.5, 0)
        ListenDot.Size               = UDim2.new(0, 5, 0, 5)
        ListenDot.BackgroundColor3   = Theme.BindActive
        ListenDot.BorderSizePixel    = 0
        ListenDot.Visible            = false
        ListenDot.Parent             = Module
        Instance.new("UICorner", ListenDot).CornerRadius = UDim.new(1, 0)

        -- Register in global bind table
        getOrCreate(Module, label)

        local function refreshBindLabel()
            local bind = moduleBinds[Module]
            if not bind then return end
            if bind.listening then
                BindLabel.Text      = ""
                ListenDot.Visible   = true
            elseif bind.key then
                BindLabel.Text      = bind.key.Name:sub(1, 5)
                BindLabel.TextColor3 = Theme.BindActive
                ListenDot.Visible   = false
            else
                BindLabel.Text      = "..."
                BindLabel.TextColor3 = Theme.TextDark
                ListenDot.Visible   = false
            end
        end

        local function setStyle(on)
            TweenService:Create(Module, TweenInfo.new(0.12), {
                BackgroundTransparency = on and 0.82 or 1,
                TextColor3             = on and Theme.Text or Theme.TextDark,
            }):Play()
            TweenService:Create(BindLabel, TweenInfo.new(0.12), {
                TextColor3 = on and Theme.Text or Theme.TextDark,
            }):Play()
        end

        -- LMB — toggle
        Module.MouseButton1Click:Connect(function()
            enabled = not enabled
            Module:SetAttribute("Enabled", enabled)
            moduleBinds[Module].enabled = enabled
            setStyle(enabled)
            refreshBindLabel()
            if callback then callback(enabled) end
        end)

        -- M3 (middle click) — start listening for bind
        Module.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton3 then
                local bind = moduleBinds[Module]
                if not bind then return end
                -- if already listening on this module → cancel
                if bind.listening then
                    stopListening()
                    refreshBindLabel()
                    return
                end
                startListening(Module)
                refreshBindLabel()

                -- poll until stopListening clears it, then refresh
                task.spawn(function()
                    while moduleBinds[Module] and moduleBinds[Module].listening do
                        task.wait()
                    end
                    refreshBindLabel()
                end)
            end
        end)

        -- Left Alt + LMB — clear bind
        Module.MouseButton1Click:Connect(function()
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
            or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then
                local bind = moduleBinds[Module]
                if bind then
                    bind.key = nil
                    refreshBindLabel()
                end
                -- don't toggle when clearing
                enabled = not enabled  -- undo the toggle that fired first
                Module:SetAttribute("Enabled", enabled)
                moduleBinds[Module].enabled = enabled
                setStyle(enabled)
            end
        end)

        -- Hover highlight
        Module.MouseEnter:Connect(function()
            if not enabled then setStyle(true) end
        end)
        Module.MouseLeave:Connect(function()
            if not enabled then setStyle(false) end
        end)

        -- Bind-toggle via keybind (attribute signal)
        Module:GetAttributeChangedSignal("BindToggle"):Connect(function()
            enabled = not enabled
            Module:SetAttribute("Enabled", enabled)
            moduleBinds[Module].enabled = enabled
            setStyle(enabled)
            refreshBindLabel()
            if callback then callback(enabled) end
        end)

        local handle = {}
        function handle:SetState(state)
            enabled = state
            Module:SetAttribute("Enabled", state)
            moduleBinds[Module].enabled = state
            setStyle(state)
            refreshBindLabel()
        end
        function handle:GetState()   return enabled end
        function handle:SetLabel(t)  Module.Text = t end
        function handle:GetBind()
            local b = moduleBinds[Module]
            return b and b.key or nil
        end
        return handle
    end

    return Category
end

return PadUI
