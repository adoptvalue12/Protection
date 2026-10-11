--[[
    ================================================================
    FORT KNOX V7.0 MOBILE EDITION
    Auto-Scan | Anti-Logger | Anti-Stealer | Mobile UI
    ================================================================
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local CoreGui            = game:GetService("CoreGui")
local SoundService       = game:GetService("SoundService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui         = game:GetService("StarterGui")
local LocalPlayer        = Players.LocalPlayer

-- Détection mobile
local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

pcall(function()
    for _, n in ipairs({"FortKnoxV5","FortKnoxV6","FortKnoxV7"}) do
        local old = CoreGui:FindFirstChild(n)
        if old then old:Destroy() end
    end
end)

-- ============================================================
-- ASSETS
-- ============================================================
local ASSETS = {
    SOUND_CLICK     = "rbxassetid://6895079853",
    SOUND_ALERT     = "rbxassetid://9046508711",
    SOUND_SUCCESS   = "rbxassetid://5847459767",
    SOUND_SCAN      = "rbxassetid://131237241",
    SOUND_THREAT    = "rbxassetid://5159276015",
    SOUND_TOGGLE    = "rbxassetid://6042053626",
    SOUND_SAFE      = "rbxassetid://4612375234",
    SOUND_DANGER    = "rbxassetid://5159276015",
    SOUND_QUIT      = "rbxassetid://1836852540",
    SOUND_VICTORY   = "rbxassetid://1841647094",
}

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
    AUTO_KICK_ON_CRITICAL = false,
    SHOW_ALERTS           = true,
    PLAY_SOUNDS           = true,
    MAXIMUM_SECURITY      = false,
    PROTECT_TRADES        = true,
    PROTECT_ROBUX         = true,
    PROTECT_CHAT          = true,
    PROTECT_HWID          = true,
    DETECT_HOOKS          = true,
    DETECT_OBFUSCATION    = true,
    SHOW_EMERGENCY_BUTTON = true,
    CONFIDENCE_THRESHOLD  = 60,
    AUTO_SCAN_ENABLED     = true,
    AUTO_QUARANTINE       = true,
    MONITOR_FILES         = true,
    MONITOR_CLIPBOARD     = true,
    MONITOR_GENV          = true,
    MONITOR_REMOTE        = true,
    MONITOR_TOOLS         = true,
    
    ALLOWED_URLS = {
        "https://raw.githubusercontent.com/",
        "https://pastebin.com/raw/",
        "https://cdn.jsdelivr.net/",
        "https://gitlab.com/",
    },
    
    BLOCKED_KEYWORDS = {
        "webhook","websec","token","cookie","steal","grab","hwid","ip",
        "discord.com/api/webhooks","discordapp.com/api/webhooks",
        "api.telegram.org","logger","rat","grabber","password","credential",
        "inventory","trade","scam","freeze","dupe","exploit","hack",
        ".roblosecurity","roblosecurity","rbx-cookie","getcookie",
        "gettoken","getauth","browserdata","localstorage",
        "sessiontoken","accesstoken","authtoken",
    },
    
    TRADE_GAMES = {
        [920587237] = "Adopt Me",
        [142823291] = "Murder Mystery 2",
    },
    
    OBFUSCATOR_SIGNATURES = {
        "Luraph","LPH_","IronBrew","IB2_","Moonsec","AztupBrew",
        "PSU","Prometheus","Hercules","Xen","Sirhurt","Synapse",
        "ScriptWare","Krnl","WeAreDevs","Obfuscator","Encrypt",
        "VMProtect","Themida","\\x","\\u{","\\1","\\0",
        "loadstring","load(","getfenv","setfenv",
        "string.char","string.byte","table.concat",
        "\\27","\\027","\\255",
    },
    
    STEALER_PATTERNS = {
        "getgenv().HttpPost","getgenv().request",
        "HttpPostAsync","HttpGetAsync",
        "GetCookies","getcookies","GetCookie",
        "getBrowserCookies","browsercookies",
        "DiscordWebhook","sendWebhook","sendwebhook",
        "HKLM:","HKCU:","SOFTWARE\\",
        "\\AppData\\","%appdata%","%localappdata%",
        "RobloxCookies","RobloxToken",
        "Chrome\\User Data","Brave\\User Data",
        "Solara","Wave","Delta","Synapse",
        "getcustomasset","writefile","readfile",
        "listfiles","delfile","appendfile",
    },
    
    -- Nouvelles signatures V7
    FILE_FUNCTIONS = {
        "writefile","appendfile","delfile","readfile",
        "listfiles","makefolder","writecustomasset",
    },
    
    CLIPBOARD_FUNCTIONS = {
        "setclipboard","toclipboard",
    },
    
    SUSPICIOUS_GLOBALS = {
        "_G.webhook","_G.token","_G.cookie","_G.hwid",
        "_G.stealer","_G.logger","_G.grabber",
    },
}

-- ============================================================
-- STATE
-- ============================================================
local State = {
    threats      = {},
    activities   = {},
    blocked      = 0,
    allowed      = 0,
    riskScore    = 0,
    scannerResult = nil,
    running      = true,
    startTime    = tick(),
    protectionConfidence = 100,
    emergencyMode = false,
    autoScans    = 0,
    lastScriptHash = "",
    knownScripts = {},
}

-- ============================================================
-- SONS
-- ============================================================
local function playSound(id, vol)
    if not CONFIG.PLAY_SOUNDS then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = id
        s.Volume  = vol or 0.5
        s.Parent  = SoundService
        s:Play()
        task.delay(5, function() if s then s:Destroy() end end)
    end)
end

-- ============================================================
-- EFFETS VISUELS (adaptés mobile)
-- ============================================================
local function spawnParticles(parent, color, count)
    for i = 1, count do
        local p = Instance.new("Frame")
        p.Size = UDim2.new(0, math.random(3, 8), 0, math.random(3, 8))
        p.Position = UDim2.new(0.5, 0, 0.5, 0)
        p.BackgroundColor3 = color
        p.BorderSizePixel = 0
        p.ZIndex = 100
        p.Parent = parent
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = p
        
        local angle = math.random() * math.pi * 2
        local dist = math.random(60, 200)
        local targetX = math.cos(angle) * dist
        local targetY = math.sin(angle) * dist
        
        TweenService:Create(p, TweenInfo.new(math.random(8, 15)/10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, targetX, 0.5, targetY),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 2, 0, 2)
        }):Play()
        task.delay(1.6, function() if p then p:Destroy() end end)
    end
end

local function showSafeEffect(text)
    playSound(ASSETS.SOUND_SAFE, 0.6)
    task.delay(0.3, function() playSound(ASSETS.SOUND_VICTORY, 0.4) end)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "FKSafeEffect"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.Parent = CoreGui
    
    local w = IS_MOBILE and 300 or 500
    local h = IS_MOBILE and 200 or 300
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, w, 0, h)
    container.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
    container.BackgroundTransparency = 1
    container.Parent = gui
    
    spawnParticles(container, Color3.fromRGB(0, 255, 100), 30)
    task.delay(0.15, function() spawnParticles(container, Color3.fromRGB(100, 255, 150), 20) end)
    
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(0, 80, 0, 80)
    ring.Position = UDim2.new(0.5, -40, 0.5, -40)
    ring.BackgroundTransparency = 1
    ring.Parent = container
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1,0); rc.Parent = ring
    local rs = Instance.new("UIStroke"); rs.Color = Color3.fromRGB(0,255,100); rs.Thickness = 3; rs.Parent = ring
    TweenService:Create(ring, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, w-80, 0, w-80),
        Position = UDim2.new(0.5, -(w-80)/2, 0.5, -(w-80)/2),
    }):Play()
    TweenService:Create(rs, TweenInfo.new(1.2), {Transparency = 1, Thickness = 1}):Play()
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 80)
    lbl.Position = UDim2.new(0, 0, 0.5, -40)
    lbl.BackgroundTransparency = 1
    lbl.Text = "SAFE"
    lbl.TextColor3 = Color3.fromRGB(0, 255, 100)
    lbl.TextSize = 1
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 60, 20)
    lbl.Parent = container
    
    local sizeTarget = IS_MOBILE and 48 or 72
    TweenService:Create(lbl, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = sizeTarget}):Play()
    task.delay(0.5, function()
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, 0, 0, 26)
        sub.Position = UDim2.new(0, 0, 0.5, 40)
        sub.BackgroundTransparency = 1
        sub.Text = text or "Aucune menace"
        sub.TextColor3 = Color3.fromRGB(200, 255, 220)
        sub.TextSize = IS_MOBILE and 12 or 15
        sub.Font = Enum.Font.Code
        sub.Parent = container
    end)
    
    task.delay(3, function()
        if gui and gui.Parent then gui:Destroy() end
    end)
end

local function showDangerEffect(text)
    playSound(ASSETS.SOUND_DANGER, 0.8)
    task.delay(0.2, function() playSound(ASSETS.SOUND_ALERT, 0.6) end)
    
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    flash.BackgroundTransparency = 0.7
    flash.BorderSizePixel = 0
    flash.ZIndex = 100
    local flashGui = Instance.new("ScreenGui")
    flashGui.IgnoreGuiInset = true
    flashGui.DisplayOrder = 999998
    flashGui.Parent = CoreGui
    flash.Parent = flashGui
    
    TweenService:Create(flash, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
    task.delay(0.3, function() flashGui:Destroy() end)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "FKDangerEffect"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.Parent = CoreGui
    
    local w = IS_MOBILE and 300 or 500
    local h = IS_MOBILE and 200 or 300
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, w, 0, h)
    container.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
    container.BackgroundTransparency = 1
    container.Parent = gui
    
    spawnParticles(container, Color3.fromRGB(255, 30, 30), 30)
    task.delay(0.15, function() spawnParticles(container, Color3.fromRGB(180, 0, 0), 20) end)
    
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(0, 80, 0, 80)
    ring.Position = UDim2.new(0.5, -40, 0.5, -40)
    ring.BackgroundTransparency = 1
    ring.Parent = container
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1,0); rc.Parent = ring
    local rs = Instance.new("UIStroke"); rs.Color = Color3.fromRGB(255,30,30); rs.Thickness = 4; rs.Parent = ring
    TweenService:Create(ring, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, w-60, 0, w-60),
        Position = UDim2.new(0.5, -(w-60)/2, 0.5, -(w-60)/2),
    }):Play()
    TweenService:Create(rs, TweenInfo.new(1.0), {Transparency = 1}):Play()
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 80)
    lbl.Position = UDim2.new(0, 0, 0.5, -40)
    lbl.BackgroundTransparency = 1
    lbl.Text = "DANGER"
    lbl.TextColor3 = Color3.fromRGB(255, 30, 30)
    lbl.TextSize = 1
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(60, 0, 0)
    lbl.Parent = container
    
    local sizeTarget = IS_MOBILE and 50 or 80
    TweenService:Create(lbl, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = sizeTarget}):Play()
    
    task.spawn(function()
        local startPos = container.Position
        for i = 1, 15 do
            container.Position = startPos + UDim2.new(0, math.random(-10, 10), 0, math.random(-10, 10))
            task.wait(0.03)
        end
        container.Position = startPos
    end)
    
    task.delay(0.5, function()
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -20, 0, 26)
        sub.Position = UDim2.new(0, 10, 0.5, 45)
        sub.BackgroundTransparency = 1
        sub.Text = text or "Menace détectée"
        sub.TextColor3 = Color3.fromRGB(255, 180, 180)
        sub.TextSize = IS_MOBILE and 11 or 14
        sub.Font = Enum.Font.Code
        sub.TextWrapped = true
        sub.Parent = container
    end)
    
    task.delay(3, function()
        if gui and gui.Parent then gui:Destroy() end
    end)
end

-- ============================================================
-- BOUTON D'URGENCE (adapté mobile)
-- ============================================================
local function showEmergencyButton(reason)
    if not CONFIG.SHOW_EMERGENCY_BUTTON then return end
    if _G.__FK_EMERGENCY_OPEN then return end
    _G.__FK_EMERGENCY_OPEN = true
    
    playSound(ASSETS.SOUND_THREAT, 0.7)
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "FKEmergency"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999999
    gui.Parent = CoreGui
    
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel = 0
    overlay.Parent = gui
    
    local w = IS_MOBILE and 320 or 550
    local h = IS_MOBILE and 240 or 260
    
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, w, 0, h)
    main.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
    main.BackgroundColor3 = Color3.fromRGB(15, 5, 5)
    main.BorderSizePixel = 0
    main.Parent = gui
    local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 14); mc.Parent = main
    local ms = Instance.new("UIStroke"); ms.Color = Color3.fromRGB(255, 40, 40); ms.Thickness = 3; ms.Parent = main
    
    task.spawn(function()
        while main.Parent do
            TweenService:Create(ms, TweenInfo.new(0.5), {Transparency = 0.7}):Play()
            task.wait(0.5)
            TweenService:Create(ms, TweenInfo.new(0.5), {Transparency = 0}):Play()
            task.wait(0.5)
        end
    end)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 15)
    title.BackgroundTransparency = 1
    title.Text = "PROTECTION INSUFFISANTE"
    title.TextColor3 = Color3.fromRGB(255, 60, 60)
    title.TextSize = IS_MOBILE and 16 or 22
    title.Font = Enum.Font.GothamBold
    title.Parent = main
    
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -20, 0, 80)
    desc.Position = UDim2.new(0, 10, 0, 50)
    desc.BackgroundTransparency = 1
    desc.Text = "Ce script peut ne pas être totalement neutralisé.\n\nRaison : " .. tostring(reason)
    desc.TextColor3 = Color3.fromRGB(255, 200, 200)
    desc.TextSize = IS_MOBILE and 11 or 13
    desc.Font = Enum.Font.Code
    desc.TextWrapped = true
    desc.Parent = main
    
    local btnW = IS_MOBILE and 130 or 240
    local btnH = IS_MOBILE and 42 or 50
    
    local quitBtn = Instance.new("TextButton")
    quitBtn.Size = UDim2.new(0, btnW, 0, btnH)
    quitBtn.Position = UDim2.new(0, 15, 1, -(btnH + 15))
    quitBtn.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
    quitBtn.Text = "QUITTER"
    quitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    quitBtn.TextSize = IS_MOBILE and 13 or 16
    quitBtn.Font = Enum.Font.GothamBold
    quitBtn.BorderSizePixel = 0
    quitBtn.AutoButtonColor = false
    quitBtn.Parent = main
    local qc = Instance.new("UICorner"); qc.CornerRadius = UDim.new(0, 10); qc.Parent = quitBtn
    
    quitBtn.MouseButton1Click:Connect(function()
        playSound(ASSETS.SOUND_QUIT, 0.8)
        quitBtn.Text = "..."
        task.wait(0.1)
        pcall(function() game:Shutdown() end)
        LocalPlayer:Kick("[Fort Knox] Quit d'urgence. Compte protégé.")
    end)
    
    local contBtn = Instance.new("TextButton")
    contBtn.Size = UDim2.new(0, btnW, 0, btnH)
    contBtn.Position = UDim2.new(1, -(btnW + 15), 1, -(btnH + 15))
    contBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    contBtn.Text = "CONTINUER"
    contBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    contBtn.TextSize = IS_MOBILE and 12 or 13
    contBtn.Font = Enum.Font.Code
    contBtn.BorderSizePixel = 0
    contBtn.AutoAccessory = false
    contBtn.Parent = main
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 10); cc.Parent = contBtn
    
    contBtn.MouseButton1Click:Connect(function()
        playSound(ASSETS.SOUND_CLICK, 0.3)
        _G.__FK_EMERGENCY_OPEN = false
        gui:Destroy()
    end)
    
    main.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, w, 0, h)
    }):Play()
end

-- ============================================================
-- LOGGING
-- ============================================================
local function log(level, msg, details)
    local t = os.date("%H:%M:%S")
    local entry = {time = t, level = level, msg = msg, details = details}
    table.insert(State.activities, entry)
    if #State.activities > 100 then table.remove(State.activities, 1) end
    print(("[%s][%s] %s%s"):format(t, level, msg, details and (" | "..tostring(details)) or ""))
    if _G.__FK_UI and _G.__FK_UI.addActivity then
        _G.__FK_UI.addActivity(entry)
    end
    if level == "THREAT" then
        table.insert(State.threats, entry)
        State.riskScore = math.min(100, State.riskScore + 15)
        if _G.__FK_UI and _G.__FK_UI.updateRisk then _G.__FK_UI.updateRisk(State.riskScore) end
        State.protectionConfidence = math.max(0, State.protectionConfidence - 15)
        if State.protectionConfidence < CONFIG.CONFIDENCE_THRESHOLD and not State.emergencyMode then
            State.emergencyMode = true
            showEmergencyButton("Confiance: " .. State.protectionConfidence .. "%")
        end
    end
end

-- ============================================================
-- UI COMPACTE MOBILE
-- ============================================================
local function buildUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "FortKnoxV7"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = CoreGui
    gui.DisplayOrder = 999999
    
    local GREEN = Color3.fromRGB(0, 255, 100)
    local BG    = Color3.fromRGB(8, 12, 8)
    local PANEL = Color3.fromRGB(15, 22, 15)
    local RED   = Color3.fromRGB(255, 60, 60)
    local YELLOW= Color3.fromRGB(255, 200, 0)
    
    -- Dimensions adaptées mobile
    local W = IS_MOBILE and 340 or 680
    local H = IS_MOBILE and 320 or 460
    local HEADER_H = IS_MOBILE and 38 or 45
    local SIDEBAR_W = IS_MOBILE and 70 or 140
    local TAB_H = IS_MOBILE and 32 or 36
    local TAB_SPACING = IS_MOBILE and 36 or 42
    local FONT_S = IS_MOBILE and 10 or 13
    local FONT_T = IS_MOBILE and 11 or 15
    
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, W, 0, H)
    main.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    main.BackgroundColor3 = BG
    main.BorderSizePixel = 0
    main.Parent = gui
    local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 12); mc.Parent = main
    local ms = Instance.new("UIStroke"); ms.Color = GREEN; ms.Thickness = 2; ms.Transparency = 0.2; ms.Parent = main
    
    -- HEADER
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, HEADER_H)
    header.BackgroundColor3 = Color3.fromRGB(10, 18, 10)
    header.BorderSizePixel = 0
    header.Parent = main
    local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0, 12); hc.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "FORT KNOX v7.0"
    title.TextColor3 = GREEN
    title.TextSize = FONT_T
    title.Font = Enum.Font.Code
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local function makeHeaderBtn(txt, xPos, color)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, IS_MOBILE and 26 or 30, 0, IS_MOBILE and 26 or 30)
        b.Position = UDim2.new(1, xPos, 0.5, -13)
        b.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
        b.Text = txt
        b.TextColor3 = color
        b.TextSize = IS_MOBILE and 13 or 16
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Parent = header
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = b
        return b
    end
    
    local btnClose = makeHeaderBtn("X", -8, RED)
    local btnMin   = makeHeaderBtn("-", IS_MOBILE and -38 or -46, YELLOW)
    
    -- SIDEBAR
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -(HEADER_H + 20))
    sidebar.Position = UDim2.new(0, 8, 0, HEADER_H + 8)
    sidebar.BackgroundColor3 = PANEL
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main
    local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 8); sc.Parent = sidebar
    
    local tabs = {
        {name = "Dash"},
        {name = "Scan"},
        {name = "Log"},
        {name = "Threat"},
        {name = "Set"},
    }
    
    local tabButtons = {}
    local contentFrames = {}
    
    for i, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -8, 0, TAB_H)
        btn.Position = UDim2.new(0, 4, 0, 4 + (i-1)*TAB_SPACING)
        btn.BackgroundColor3 = Color3.fromRGB(15, 22, 15)
        btn.Text = tab.name
        btn.TextColor3 = Color3.fromRGB(150, 180, 150)
        btn.TextSize = FONT_S
        btn.Font = Enum.Font.Code
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Parent = sidebar
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = btn
        
        tabButtons[tab.name] = btn
        
        btn.MouseButton1Click:Connect(function()
            playSound(ASSETS.SOUND_CLICK, 0.3)
            for _, f in pairs(contentFrames) do f.Visible = false end
            for _, b in pairs(tabButtons) do
                b.BackgroundColor3 = Color3.fromRGB(15,22,15)
                b.TextColor3 = Color3.fromRGB(150,180,150)
            end
            contentFrames[tab.name].Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(0,40,20)
            btn.TextColor3 = GREEN
        end)
    end
    
    -- CONTENT
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -(SIDEBAR_W + 24), 1, -(HEADER_H + 20))
    content.Position = UDim2.new(0, SIDEBAR_W + 16, 0, HEADER_H + 8)
    content.BackgroundColor3 = PANEL
    content.BorderSizePixel = 0
    content.Parent = main
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 8); cc.Parent = content
    
    for _, tab in ipairs(tabs) do
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -14, 1, -14)
        f.Position = UDim2.new(0, 7, 0, 7)
        f.BackgroundTransparency = 1
        f.Visible = false
        f.Parent = content
        contentFrames[tab.name] = f
    end
    contentFrames["Dash"].Visible = true
    tabButtons["Dash"].BackgroundColor3 = Color3.fromRGB(0,40,20)
    tabButtons["Dash"].TextColor3 = GREEN
    
    -- DASHBOARD
    local dash = contentFrames["Dash"]
    
    local riskValue = Instance.new("TextLabel")
    riskValue.Size = UDim2.new(1, 0, 0, IS_MOBILE and 30 or 40)
    riskValue.BackgroundTransparency = 1
    riskValue.Text = "0%  SECURISE"
    riskValue.TextColor3 = GREEN
    riskValue.TextSize = IS_MOBILE and 20 or 28
    riskValue.Font = Enum.Font.Code
    riskValue.TextXAlignment = Enum.TextXAlignment.Left
    riskValue.Parent = dash
    
    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1, 0, 0, 8)
    barBG.Position = UDim2.new(0, 0, 0, IS_MOBILE and 34 or 44)
    barBG.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
    barBG.BorderSizePixel = 0
    barBG.Parent = dash
    local bgc = Instance.new("UICorner"); bgc.CornerRadius = UDim.new(1,0); bgc.Parent = barBG
    
    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = GREEN
    barFill.BorderSizePixel = 0
    barFill.Parent = barBG
    local bfc = Instance.new("UICorner"); bfc.CornerRadius = UDim.new(1,0); bfc.Parent = barFill
    
    local confLabel = Instance.new("TextLabel")
    confLabel.Size = UDim2.new(1, 0, 0, 16)
    confLabel.Position = UDim2.new(0, 0, 0, IS_MOBILE and 46 or 60)
    confLabel.BackgroundTransparency = 1
    confLabel.Text = "CONFIANCE: 100%"
    confLabel.TextColor3 = GREEN
    confLabel.TextSize = IS_MOBILE and 10 or 12
    confLabel.Font = Enum.Font.Code
    confLabel.TextXAlignment = Enum.TextXAlignment.Left
    confLabel.Parent = dash
    
    -- Stat boxes (3 en ligne)
    local statWidth = IS_MOBILE and 76 or 155
    local statHeight = IS_MOBILE and 50 or 65
    
    local function statBox(name, xPos)
        local box = Instance.new("Frame")
        box.Size = UDim2.new(0, statWidth, 0, statHeight)
        box.Position = UDim2.new(0, xPos, 0, IS_MOBILE and 66 or 84)
        box.BackgroundColor3 = Color3.fromRGB(10, 18, 10)
        box.BorderSizePixel = 0
        box.Parent = dash
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = box
        local s = Instance.new("UIStroke"); s.Color = GREEN; s.Thickness = 1; s.Transparency = 0.7; s.Parent = box
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 14)
        lbl.Position = UDim2.new(0, 5, 0, 3)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(120, 180, 120)
        lbl.TextSize = IS_MOBILE and 8 or 10
        lbl.Font = Enum.Font.Code
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = box
        
        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(1, -10, 0, 26)
        val.Position = UDim2.new(0, 5, 0, 18)
        val.BackgroundTransparency = 1
        val.Text = "0"
        val.TextColor3 = GREEN
        val.TextSize = IS_MOBILE and 18 or 24
        val.Font = Enum.Font.Code
        val.TextXAlignment = Enum.TextXAlignment.Left
        val.Parent = box
        return val
    end
    
    local statBlocked = statBox("BLOQ", 0)
    local statThreats = statBox("MENAC", statWidth + 6)
    local statAllowed = statBox("AUTO", (statWidth + 6) * 2)
    
    -- Boutons test
    local testBtnH = IS_MOBILE and 26 or 32
    local testBtnW = IS_MOBILE and 100 or 160
    local testY = IS_MOBILE and 122 or 158
    
    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0, testBtnW, 0, testBtnH)
    testBtn.Position = UDim2.new(0, 0, 0, testY)
    testBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 20)
    testBtn.Text = "TEST SAFE"
    testBtn.TextColor3 = GREEN
    testBtn.TextSize = IS_MOBILE and 10 or 11
    testBtn.Font = Enum.Font.Code
    testBtn.BorderSizePixel = 0
    testBtn.Parent = dash
    local tbc = Instance.new("UICorner"); tbc.CornerRadius = UDim.new(0, 5); tbc.Parent = testBtn
    testBtn.MouseButton1Click:Connect(function() showSafeEffect("Test - tout OK") end)
    
    local testBtn2 = Instance.new("TextButton")
    testBtn2.Size = UDim2.new(0, testBtnW, 0, testBtnH)
    testBtn2.Position = UDim2.new(0, testBtnW + 6, 0, testY)
    testBtn2.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    testBtn2.Text = "TEST DANGER"
    testBtn2.TextColor3 = RED
    testBtn2.TextSize = IS_MOBILE and 10 or 11
    testBtn2.Font = Enum.Font.Code
    testBtn2.BorderSizePixel = 0
    testBtn2.Parent = dash
    local tbc2 = Instance.new("UICorner"); tbc2.CornerRadius = UDim.new(0, 5); tbc2.Parent = testBtn2
    testBtn2.MouseButton1Click:Connect(function() showDangerEffect("Test - menace") end)
    
    -- SCANNER
    local scan = contentFrames["Scan"]
    
    local scanTitle = Instance.new("TextLabel")
    scanTitle.Size = UDim2.new(1, 0, 0, 16)
    scanTitle.BackgroundTransparency = 1
    scanTitle.Text = "CODE A ANALYSER:"
    scanTitle.TextColor3 = GREEN
    scanTitle.TextSize = IS_MOBILE and 10 or 12
    scanTitle.Font = Enum.Font.Code
    scanTitle.TextXAlignment = Enum.TextXAlignment.Left
    scanTitle.Parent = scan
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, IS_MOBILE and 130 or 170)
    box.Position = UDim2.new(0, 0, 0, 20)
    box.BackgroundColor3 = Color3.fromRGB(5, 10, 5)
    box.TextColor3 = Color3.fromRGB(150, 255, 150)
    box.PlaceholderText = "-- Colle le script ici --"
    box.PlaceholderColor3 = Color3.fromRGB(80, 120, 80)
    box.TextSize = IS_MOBILE and 10 or 12
    box.Font = Enum.Font.Code
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.TextWrapped = true
    box.ClearTextOnFocus = false
    box.MultiLine = true
    box.BorderSizePixel = 0
    box.Parent = scan
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 5); bc.Parent = box
    local bs = Instance.new("UIStroke"); bs.Color = GREEN; bs.Thickness = 1; bs.Transparency = 0.6; bs.Parent = box
    
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0, IS_MOBILE and 120 or 170, 0, IS_MOBILE and 28 or 34)
    scanBtn.Position = UDim2.new(0, 0, 0, IS_MOBILE and 156 or 200)
    scanBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 20)
    scanBtn.Text = "> SCAN"
    scanBtn.TextColor3 = GREEN
    scanBtn.TextSize = IS_MOBILE and 11 or 13
    scanBtn.Font = Enum.Font.Code
    scanBtn.BorderSizePixel = 0
    scanBtn.Parent = scan
    local sb = Instance.new("UICorner"); sb.CornerRadius = UDim.new(0, 5); sb.Parent = scanBtn
    
    local scanResult = Instance.new("TextLabel")
    scanResult.Size = UDim2.new(1, 0, 1, IS_MOBILE and -195 or -245)
    scanResult.Position = UDim2.new(0, 0, 0, IS_MOBILE and 190 or 242)
    scanResult.BackgroundTransparency = 1
    scanResult.Text = ""
    scanResult.TextColor3 = GREEN
    scanResult.TextSize = IS_MOBILE and 10 or 12
    scanResult.Font = Enum.Font.Code
    scanResult.TextXAlignment = Enum.TextXAlignment.Left
    scanResult.TextYAlignment = Enum.TextYAlignment.Top
    scanResult.TextWrapped = true
    scanResult.Parent = scan
    
    -- ACTIVITY
    local act = contentFrames["Log"]
    local actScroll = Instance.new("ScrollingFrame")
    actScroll.Size = UDim2.new(1, 0, 1, IS_MOBILE and -32 or -35)
    actScroll.BackgroundColor3 = Color3.fromRGB(5, 10, 5)
    actScroll.BorderSizePixel = 0
    actScroll.ScrollBarThickness = 3
    actScroll.ScrollBarImageColor3 = GREEN
    actScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    actScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    actScroll.Parent = act
    local asc = Instance.new("UICorner"); asc.CornerRadius = UDim.new(0, 5); asc.Parent = actScroll
    
    local actLayout = Instance.new("UIListLayout")
    actLayout.SortOrder = Enum.SortOrder.LayoutOrder
    actLayout.Padding = UDim.new(0, 2)
    actLayout.Parent = actScroll
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, IS_MOBILE and 80 or 100, 0, IS_MOBILE and 22 or 26)
    clearBtn.Position = UDim2.new(1, IS_MOBILE and -80 or -100, 1, IS_MOBILE and -24 or -30)
    clearBtn.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
    clearBtn.Text = "EFFACER"
    clearBtn.TextColor3 = RED
    clearBtn.TextSize = IS_MOBILE and 9 or 11
    clearBtn.Font = Enum.Font.Code
    clearBtn.BorderSizePixel = 0
    clearBtn.Parent = act
    local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0, 5); cbc.Parent = clearBtn
    clearBtn.MouseButton1Click:Connect(function()
        for _, ch in ipairs(actScroll:GetChildren()) do
            if ch:IsA("TextLabel") then ch:Destroy() end
        end
        playSound(ASSETS.SOUND_CLICK, 0.3)
    end)
    
    -- THREATS
    local thr = contentFrames["Threat"]
    local thrScroll = Instance.new("ScrollingFrame")
    thrScroll.Size = UDim2.new(1, 0, 1, 0)
    thrScroll.BackgroundColor3 = Color3.fromRGB(5, 10, 5)
    thrScroll.BorderSizePixel = 0
    thrScroll.ScrollBarThickness = 3
    thrScroll.ScrollBarImageColor3 = RED
    thrScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    thrScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    thrScroll.Parent = thr
    local tsc = Instance.new("UICorner"); tsc.CornerRadius = UDim.new(0, 5); tsc.Parent = thrScroll
    local thrLayout = Instance.new("UIListLayout"); thrLayout.SortOrder = Enum.SortOrder.LayoutOrder; thrLayout.Padding = UDim.new(0, 2); thrLayout.Parent = thrScroll
    
    -- SETTINGS
    local stg = contentFrames["Set"]
    local stgScroll = Instance.new("ScrollingFrame")
    stgScroll.Size = UDim2.new(1, 0, 1, 0)
    stgScroll.BackgroundTransparency = 1
    stgScroll.BorderSizePixel = 0
    stgScroll.ScrollBarThickness = 3
    stgScroll.ScrollBarImageColor3 = GREEN
    stgScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    stgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    stgScroll.Parent = stg
    local stgLayout = Instance.new("UIListLayout")
    stgLayout.SortOrder = Enum.SortOrder.LayoutOrder
    stgLayout.Padding = UDim.new(0, 4)
    stgLayout.Parent = stgScroll
    
    local function toggleOption(label, key, default)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, IS_MOBILE and 26 or 30)
        f.BackgroundColor3 = Color3.fromRGB(10, 18, 10)
        f.BorderSizePixel = 0
        f.Parent = stgScroll
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = f
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -60, 1, 0)
        lbl.Position = UDim2.new(0, 8, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = GREEN
        lbl.TextSize = IS_MOBILE and 10 or 12
        lbl.Font = Enum.Font.Code
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f
        
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, IS_MOBILE and 42 or 50, 0, IS_MOBILE and 18 or 22)
        sw.Position = UDim2.new(1, IS_MOBILE and -50 or -60, 0.5, IS_MOBILE and -9 or -11)
        sw.BackgroundColor3 = default and GREEN or Color3.fromRGB(40, 40, 40)
        sw.Text = default and "ON" or "OFF"
        sw.TextColor3 = default and BG or Color3.fromRGB(150,150,150)
        sw.TextSize = IS_MOBILE and 9 or 11
        sw.Font = Enum.Font.Code
        sw.BorderSizePixel = 0
        sw.Parent = f
        local sc2 = Instance.new("UICorner"); sc2.CornerRadius = UDim.new(1,0); sc2.Parent = sw
        
        local state = default
        sw.MouseButton1Click:Connect(function()
            state = not state
            CONFIG[key] = state
            sw.Text = state and "ON" or "OFF"
            sw.BackgroundColor3 = state and GREEN or Color3.fromRGB(40, 40, 40)
            sw.TextColor3 = state and BG or Color3.fromRGB(150,150,150)
            playSound(ASSETS.SOUND_TOGGLE, 0.3)
        end)
    end
    
    toggleOption("Auto-Scan", "AUTO_SCAN_ENABLED", CONFIG.AUTO_SCAN_ENABLED)
    toggleOption("Quarantaine auto", "AUTO_QUARANTINE", CONFIG.AUTO_QUARANTINE)
    toggleOption("Kick critique", "AUTO_KICK_ON_CRITICAL", CONFIG.AUTO_KICK_ON_CRITICAL)
    toggleOption("Alertes", "SHOW_ALERTS", CONFIG.SHOW_ALERTS)
    toggleOption("Sons", "PLAY_SOUNDS", CONFIG.PLAY_SOUNDS)
    toggleOption("Securite max", "MAXIMUM_SECURITY", CONFIG.MAXIMUM_SECURITY)
    toggleOption("Trade", "PROTECT_TRADES", CONFIG.PROTECT_TRADES)
    toggleOption("Robux", "PROTECT_ROBUX", CONFIG.PROTECT_ROBUX)
    toggleOption("Chat", "PROTECT_CHAT", CONFIG.PROTECT_CHAT)
    toggleOption("HWID", "PROTECT_HWID", CONFIG.PROTECT_HWID)
    toggleOption("Hooks", "DETECT_HOOKS", CONFIG.DETECT_HOOKS)
    toggleOption("Obfuscation", "DETECT_OBFUSCATION", CONFIG.DETECT_OBFUSCATION)
    toggleOption("Monitor fichiers", "MONITOR_FILES", CONFIG.MONITOR_FILES)
    toggleOption("Monitor clipboard", "MONITOR_CLIPBOARD", CONFIG.MONITOR_CLIPBOARD)
    toggleOption("Monitor _G", "MONITOR_GENV", CONFIG.MONITOR_GENV)
    toggleOption("Monitor Remotes", "MONITOR_REMOTE", CONFIG.MONITOR_REMOTE)
    toggleOption("Monitor Tools", "MONITOR_TOOLS", CONFIG.MONITOR_TOOLS)
    
    -- Drag
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    local minimized = false
    btnMin.MouseButton1Click:Connect(function()
        minimized = not minimized
        playSound(ASSETS.SOUND_CLICK, 0.3)
        local targetSize = minimized and UDim2.new(0, W, 0, HEADER_H) or UDim2.new(0, W, 0, H)
        TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
        sidebar.Visible = not minimized
        content.Visible = not minimized
    end)
    
    btnClose.MouseButton1Click:Connect(function()
        playSound(ASSETS.SOUND_CLICK, 0.3)
        gui:Destroy()
        -- Crée un mini bouton flottant
        local miniGui = Instance.new("ScreenGui")
        miniGui.Name = "FKMini"
        miniGui.IgnoreGuiInset = true
        miniGui.DisplayOrder = 999999
        miniGui.Parent = CoreGui
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 44, 0, 44)
        btn.Position = UDim2.new(0, 10, 0.5, -22)
        btn.BackgroundColor3 = BG
        btn.Text = "FK"
        btn.TextColor3 = GREEN
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.BorderSizePixel = 0
        btn.Parent = miniGui
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = btn
        local s = Instance.new("UIStroke"); s.Color = GREEN; s.Thickness = 2; s.Parent = btn
        
        task.spawn(function()
            while btn.Parent do
                TweenService:Create(s, TweenInfo.new(0.8), {Transparency = 0.6}):Play()
                task.wait(0.8)
                TweenService:Create(s, TweenInfo.new(0.8), {Transparency = 0}):Play()
                task.wait(0.8)
            end
        end)
        
        -- Drag mini
        local d2, ds2, sp2
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                d2 = true; ds2 = input.Position; sp2 = btn.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then d2 = false end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if d2 and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - ds2
                btn.Position = UDim2.new(sp2.X.Scale, sp2.X.Offset + delta.X, sp2.Y.Scale, sp2.Y.Offset + delta.Y)
            end
        end)
        
        btn.MouseButton1Click:Connect(function()
            playSound(ASSETS.SOUND_CLICK, 0.3)
            miniGui:Destroy()
            buildUI()
        end)
    end)
    
    _G.__FK_UI = {
        updateRisk = function(score)
            local color = GREEN
            local label = "SECURISE"
            if score >= 70 then color = RED; label = "CRITIQUE"
            elseif score >= 40 then color = YELLOW; label = "SUSPECT"
            elseif score >= 15 then color = Color3.fromRGB(200,255,100); label = "PRUDENCE" end
            riskValue.Text = tostring(math.floor(score)) .. "%  " .. label
            riskValue.TextColor3 = color
            TweenService:Create(barFill, TweenInfo.new(0.4), {
                Size = UDim2.new(score/100, 0, 1, 0),
                BackgroundColor3 = color
            }):Play()
            statBlocked.Text = tostring(State.blocked)
            statThreats.Text = tostring(#State.threats)
            statAllowed.Text = tostring(State.allowed)
            confLabel.Text = "CONFIANCE: " .. State.protectionConfidence .. "%"
            confLabel.TextColor3 = State.protectionConfidence >= 60 and GREEN or RED
        end,
        addActivity = function(entry)
            local color = GREEN
            if entry.level == "BLOCK" then color = RED
            elseif entry.level == "THREAT" then color = RED
            elseif entry.level == "DETECT" then color = YELLOW end
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, IS_MOBILE and 16 or 18)
            lbl.BackgroundTransparency = 1
            lbl.Text = ("[%s] %s"):format(entry.time, entry.msg)
            lbl.TextColor3 = color
            lbl.TextSize = IS_MOBILE and 9 or 11
            lbl.Font = Enum.Font.Code
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextTruncate = Enum.TextTruncate.AtEnd
            lbl.Parent = actScroll
        end,
        addThreat = function(entry)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, 0, 0, IS_MOBILE and 38 or 44)
            f.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
            f.BorderSizePixel = 0
            f.Parent = thrScroll
            local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = f
            
            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1, -14, 0, 18)
            t.Position = UDim2.new(0, 7, 0, 3)
            t.BackgroundTransparency = 1
            t.Text = "[!] " .. entry.msg
            t.TextColor3 = RED
            t.TextSize = IS_MOBILE and 10 or 12
            t.Font = Enum.Font.Code
            t.TextXAlignment = Enum.TextXAlignment.Left
            t.TextTruncate = Enum.TextTruncate.AtEnd
            t.Parent = f
            
            local d = Instance.new("TextLabel")
            d.Size = UDim2.new(1, -14, 0, 16)
            d.Position = UDim2.new(0, 7, 0, 20)
            d.BackgroundTransparency = 1
            d.Text = entry.details or ""
            d.TextColor3 = Color3.fromRGB(200, 150, 150)
            d.TextSize = IS_MOBILE and 8 or 10
            d.Font = Enum.Font.Code
            d.TextXAlignment = Enum.TextXAlignment.Left
            d.TextTruncate = Enum.TextTruncate.AtEnd
            d.Parent = f
        end,
    }
    
    return gui, scanBtn, box, scanResult
end

-- ============================================================
-- ANALYSEUR V7 (encore plus complet)
-- ============================================================
local function analyzeSource(src)
    if type(src) ~= "string" then return {risk = 0, reasons = {"Source invalide"}, confidence = 100} end
    
    local reasons = {}
    local risk = 0
    local totalChecks = 0
    local passedChecks = 0
    
    totalChecks = totalChecks + 1
    if #src > 200000 then
        risk = risk + 20; table.insert(reasons, "[!] Taille extreme ("..#src..")")
    elseif #src > 50000 then
        risk = risk + 10; table.insert(reasons, "[~] Taille elevee ("..#src..")")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    local sigHits = 0
    for _, sig in ipairs(CONFIG.OBFUSCATOR_SIGNATURES) do
        if src:find(sig, 1, true) then sigHits = sigHits + 1 end
    end
    if sigHits > 0 then risk = risk + math.min(sigHits * 8, 40)
        table.insert(reasons, "[!] Obfuscateur detecte ("..sigHits..")")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    local stHits = 0
    for _, pat in ipairs(CONFIG.STEALER_PATTERNS) do
        if src:find(pat, 1, true) then stHits = stHits + 1 end
    end
    if stHits > 0 then risk = risk + math.min(stHits * 10, 50)
        table.insert(reasons, "[!] Motifs stealer ("..stHits..")")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    local specialCount = 0
    local checkSize = math.min(#src, 5000)
    for i = 1, checkSize do
        local c = src:byte(i)
        if c and (c < 32 or c > 126) and c ~= 10 and c ~= 13 and c ~= 9 then specialCount = specialCount + 1 end
    end
    local ratio = specialCount / checkSize
    if ratio > 0.15 then risk = risk + 25; table.insert(reasons, "[!] Caracteres speciaux ELEVE")
    elseif ratio > 0.08 then risk = risk + 10; table.insert(reasons, "[~] Caracteres speciaux modere")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    local maxLine = 0
    for line in src:gmatch("[^\n]+") do if #line > maxLine then maxLine = #line end end
    if maxLine > 5000 then risk = risk + 20; table.insert(reasons, "[!] Ligne de "..maxLine.." chars")
    elseif maxLine > 1000 then risk = risk + 8; table.insert(reasons, "[~] Lignes longues")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    local kwHits = 0
    for _, kw in ipairs(CONFIG.BLOCKED_KEYWORDS) do
        if src:lower():find(kw:lower(), 1, true) then kwHits = kwHits + 1 end
    end
    if kwHits > 0 then risk = risk + math.min(kwHits * 6, 35)
        table.insert(reasons, "[!] Mots-cles sensibles ("..kwHits..")")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    if src:find("loadstring", 1, true) or src:find("getfenv", 1, true) or src:find("setfenv", 1, true) then
        risk = risk + 15; table.insert(reasons, "[!] loadstring/getfenv/setfenv")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    if src:find("hookfunction", 1, true) or src:find("hookmetamethod", 1, true) then
        risk = risk + 15; table.insert(reasons, "[!] Hooks")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    local b64Count = 0
    for _ in src:gmatch("[A-Za-z0-9+/=][A-Za-z0-9+/=][A-Za-z0-9+/=][A-Za-z0-9+/=]") do
        b64Count = b64Count + 1
        if b64Count > 100 then break end
    end
    if b64Count > 50 then risk = risk + 15; table.insert(reasons, "[!] Base64 probable")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    local weirdIds = 0
    for id in src:gmatch("[%a_][%w_]*") do
        if #id > 15 and id:match("%d") and id:match("%a") then weirdIds = weirdIds + 1 end
    end
    if weirdIds > 30 then risk = risk + 12; table.insert(reasons, "[!] Vars obfusques ("..weirdIds..")")
    else passedChecks = passedChecks + 1 end
    
    -- V7 : nouvelles vérifications
    totalChecks = totalChecks + 1
    local fileHits = 0
    for _, f in ipairs(CONFIG.FILE_FUNCTIONS) do
        if src:find(f, 1, true) then fileHits = fileHits + 1 end
    end
    if fileHits > 0 then risk = risk + math.min(fileHits * 8, 30)
        table.insert(reasons, "[!] Fichiers: "..fileHits.." fonctions")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    local clipHits = 0
    for _, c in ipairs(CONFIG.CLIPBOARD_FUNCTIONS) do
        if src:find(c, 1, true) then clipHits = clipHits + 1 end
    end
    if clipHits > 0 then risk = risk + 12; table.insert(reasons, "[!] Clipboard")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    if src:find("game:HttpGet", 1, true) and src:find("loadstring", 1, true) then
        risk = risk + 20; table.insert(reasons, "[!] Remote loadstring pattern")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    if src:find("getrawmetatable", 1, true) or src:find("setreadonly", 1, true) then
        risk = risk + 15; table.insert(reasons, "[!] Meta manipulation")
    else passedChecks = passedChecks + 1 end
    
    totalChecks = totalChecks + 1
    local urlCount = 0
    for _ in src:gmatch("https?://[^%s\"']+") do urlCount = urlCount + 1 end
    if urlCount > 10 then risk = risk + 10; table.insert(reasons, "[!] "..urlCount.." URLs")
    else passedChecks = passedChecks + 1 end
    
    risk = math.min(100, risk)
    local confidence = math.floor((passedChecks / totalChecks) * 100)
    
    return {risk = risk, reasons = reasons, size = #src, confidence = confidence, maxLine = maxLine}
end

-- ============================================================
-- AUTO-SCAN (surveille l'exécution de nouveaux scripts)
-- ============================================================
local function setupAutoScan()
    if not CONFIG.AUTO_SCAN_ENABLED then return end
    
    -- Hook loadstring / getgenv().loadstring pour détecter l'exécution
    local function hookLoader(fn, name)
        if type(fn) ~= "function" then return end
        pcall(function()
            local old = fn
            hookfunction(fn, function(...)
                local args = {...}
                local code = args[1]
                
                if type(code) == "string" and #code > 50 then
                    State.autoScans = State.autoScans + 1
                    log("INFO", "[AUTO-SCAN] Nouveau script detecte via "..name)
                    
                    local res = analyzeSource(code)
                    State.scannerResult = res
                    State.riskScore = math.max(State.riskScore, res.risk)
                    
                    if _G.__FK_UI and _G.__FK_UI.updateRisk then
                        _G.__FK_UI.updateRisk(State.riskScore)
                    end
                    
                    if res.risk >= 60 then
                        log("THREAT", "[AUTO-SCAN] Script dangereux bloque!", "Risque: "..res.risk.."%")
                        if _G.__FK_UI and _G.__FK_UI.addThreat then
                            _G.__FK_UI.addThreat({time=os.date("%H:%M:%S"), level="THREAT", msg="Auto-scan: risque "..res.risk.."%", details=(res.reasons[1] or "")})
                        end
                        playSound(ASSETS.SOUND_THREAT, 0.7)
                        showDangerEffect("Script bloque auto: "..res.risk.."%")
                        
                        if CONFIG.AUTO_QUARANTINE then
                            -- Quarantine : bloque l'exécution
                            task.delay(1, function()
                                showEmergencyButton("Auto-scan: script "..res.risk.."% risque")
                            end)
                            return nil
                        end
                    elseif res.risk >= 30 then
                        log("DETECT", "[AUTO-SCAN] Script suspect", "Risque: "..res.risk.."%")
                        if _G.__FK_UI and _G.__FK_UI.addThreat then
                            _G.__FK_UI.addThreat({time=os.date("%H:%M:%S"), level="DETECT", msg="Auto-scan suspect: "..res.risk.."%", details=""})
                        end
                        playSound(ASSETS.SOUND_ALERT, 0.5)
                    else
                        log("INFO", "[AUTO-SCAN] Script analyse sur", "Risque: "..res.risk.."%")
                        if res.risk < 15 then
                            playSound(ASSETS.SOUND_SUCCESS, 0.4)
                        end
                    end
                end
                
                return old(...)
            end)
        end)
    end
    
    -- Hook les loaders principaux
    if loadstring then hookLoader(loadstring, "loadstring") end
    if load then hookLoader(load, "load") end
    if getgenv and getgenv().loadstring then hookLoader(getgenv().loadstring, "getgenv.loadstring") end
    if getgenv and getgenv().load then hookLoader(getgenv().load, "getgenv.load") end
    
    log("INFO", "Auto-Scan active - surveille loadstring")
    
    -- Surveillance périodique de _G pour nouvelles fonctions suspectes
    if CONFIG.MONITOR_GENV then
        local lastGenv = {}
        task.spawn(function()
            while State.running do
                task.wait(2)
                local genv = getgenv and getgenv() or _G
                for k, v in pairs(genv) do
                    if not lastGenv[k] then
                        if type(k) == "string" then
                            local lower = k:lower()
                            if lower:find("steal") or lower:find("grab") or lower:find("webhook") or lower:find("logger") then
                                log("DETECT", "Global suspect detecte: "..k)
                                if _G.__FK_UI and _G.__FK_UI.addThreat then
                                    _G.__FK_UI.addThreat({time=os.date("%H:%M:%S"), level="DETECT", msg="Global suspect: "..k, details=""})
                                end
                                playSound(ASSETS.SOUND_ALERT, 0.5)
                            end
                        end
                        lastGenv[k] = true
                    end
                end
            end
        end)
    end
end

-- ============================================================
-- PROTECTIONS
-- ============================================================
local function setupAntiEnvLogger()
    local RanTimes = 0
    local c = RunService.Heartbeat:Connect(function() RanTimes = RanTimes + 1 end)
    repeat task.wait() until RanTimes >= 3
    c:Disconnect()
    log("INFO", "Anti-Env Logger V3 active")
end

local function setupHookDetection()
    if not CONFIG.DETECT_HOOKS then return end
    local fns = {"HttpGet","HttpGetAsync","HttpPost","HttpPostAsync","request","hookfunction","hookmetamethod","loadstring"}
    local originals = {}
    for _, n in ipairs(fns) do if game[n] then originals[n] = game[n] end end
    task.spawn(function()
        while State.running do
            task.wait(1.5)
            for n, orig in pairs(originals) do
                if game[n] and game[n] ~= orig then
                    log("DETECT", "Hook malveillant: "..n)
                    if _G.__FK_UI and _G.__FK_UI.addThreat then
                        _G.__FK_UI.addThreat({time=os.date("%H:%M:%S"), level="DETECT", msg="Hook: "..n, details=""})
                    end
                    playSound(ASSETS.SOUND_THREAT, 0.5)
                    showDangerEffect("Hook sur " .. n)
                end
            end
        end
    end)
end

local function isBlocked(url)
    if type(url) ~= "string" then return true end
    for _, a in ipairs(CONFIG.ALLOWED_URLS) do
        if url:find(a, 1, true) then return false end
    end
    if CONFIG.MAXIMUM_SECURITY then return true end
    local l = url:lower()
    for _, k in ipairs(CONFIG.BLOCKED_KEYWORDS) do
        if l:find(k:lower(), 1, true) then return true end
    end
    return false
end

local function setupHTTPHooks()
    local function hookSimple(fn, name, method)
        if type(fn) ~= "function" then return end
        pcall(function()
            local old = fn
            hookfunction(fn, function(self, url, ...)
                if isBlocked(url) then
                    State.blocked = State.blocked + 1
                    log("BLOCK", method.." bloque", tostring(url):sub(1, 60))
                    if _G.__FK_UI and _G.__FK_UI.updateRisk then _G.__FK_UI.updateRisk(State.riskScore) end
                    playSound(ASSETS.SOUND_ALERT, 0.5)
                    showDangerEffect(method .. " URL suspecte")
                    return nil
                else
                    State.allowed = State.allowed + 1
                    if _G.__FK_UI and _G.__FK_UI.updateRisk then _G.__FK_UI.updateRisk(State.riskScore) end
                    return old(self, url, ...)
                end
            end)
        end)
    end
    local function hookReq(fn, name)
        if type(fn) ~= "function" then return end
        pcall(function()
            local old = fn
            hookfunction(fn, function(data)
                if type(data) == "table" and data.Url and isBlocked(data.Url) then
                    State.blocked = State.blocked + 1
                    log("BLOCK", "REQUEST bloquee", data.Url:sub(1, 60))
                    if _G.__FK_UI and _G.__FK_UI.updateRisk then _G.__FK_UI.updateRisk(State.riskScore) end
                    playSound(ASSETS.SOUND_ALERT, 0.5)
                    showDangerEffect("REQUEST URL suspecte")
                    return {StatusMessage="Blocked",Success=false,StatusCode=403,Body="",Headers={}}
                end
                State.allowed = State.allowed + 1
                if _G.__FK_UI and _G.__FK_UI.updateRisk then _G.__FK_UI.updateRisk(State.riskScore) end
                return old(data)
            end)
        end)
    end
    hookSimple(game.HttpGet, "HttpGet", "GET")
    hookSimple(game.HttpGetAsync, "HttpGetAsync", "GET")
    hookSimple(game.HttpPost, "HttpPost", "POST")
    hookSimple(game.HttpPostAsync, "HttpPostAsync", "POST")
    hookReq(request, "request")
    if syn and syn.request then hookReq(syn.request, "syn.request") end
    if http_request then hookReq(http_request, "http_request") end
    log("INFO", "Hooks HTTP actives")
end

local function setupTradeProtection()
    if not CONFIG.PROTECT_TRADES then return end
    task.spawn(function()
        local keywords = {"Trade","Freeze","AcceptTrade","ConfirmTrade","Scam","SendTrade"}
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                for _, kw in ipairs(keywords) do
                    if obj.Name:lower():find(kw:lower(), 1, true) then
                        pcall(function()
                            local old = obj.FireServer
                            hookfunction(old, function(self, ...)
                                if obj.Name:lower():find("freeze") or obj.Name:lower():find("scam") then
                                    State.blocked = State.blocked + 1
                                    log("THREAT", "Freeze trade bloque: "..obj.Name)
                                    if _G.__FK_UI and _G.__FK_UI.addThreat then
                                        _G.__FK_UI.addThreat({time=os.date("%H:%M:%S"), level="THREAT", msg="FREEZE: "..obj.Name, details="Scam trade"})
                                    end
                                    playSound(ASSETS.SOUND_THREAT, 0.6)
                                    showDangerEffect("FREEZE TRADE")
                                    return nil
                                end
                                return old(self, ...)
                            end)
                        end)
                    end
                end
            end
        end
    end)
end

local function setupRobuxProtection()
    if not CONFIG.PROTECT_ROBUX then return end
    pcall(function()
        hookfunction(MarketplaceService.PromptPurchase, function(self, p, id, ...)
            State.blocked = State.blocked + 1
            log("THREAT", "Achat Robux bloque", "ID: "..tostring(id))
            if _G.__FK_UI and _G.__FK_UI.addThreat then
                _G.__FK_UI.addThreat({time=os.date("%H:%M:%S"), level="THREAT", msg="Robux: "..tostring(id), details=""})
            end
            playSound(ASSETS.SOUND_THREAT, 0.6)
            showDangerEffect("Achat Robux bloque")
            return nil
        end)
    end)
end

local function setupChatProtection()
    if not CONFIG.PROTECT_CHAT then return end
    local rs = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if rs and rs:FindFirstChild("SayMessageRequest") then
        pcall(function()
            local old = rs.SayMessageRequest.FireServer
            hookfunction(old, function(self, msg, ...)
                State.blocked = State.blocked + 1
                log("BLOCK", "Chat force bloque", tostring(msg):sub(1, 40))
                playSound(ASSETS.SOUND_ALERT, 0.4)
                showDangerEffect("Chat force bloque")
                return nil
            end)
        end)
    end
end

local function setupHWIDProtection()
    if not CONFIG.PROTECT_HWID then return end
    for _, n in ipairs({"gethwid","get_hwid","getHWID","getuserid","get_user_id"}) do
        if getgenv()[n] then
            getgenv()[n] = function()
                log("DETECT", "HWID bloque: "..n)
                return "FK_PROTECTED_"..math.random(100000,999999)
            end
        end
    end
end

-- V7 : Monitor des fichiers
local function setupFileMonitor()
    if not CONFIG.MONITOR_FILES then return end
    for _, fn in ipairs(CONFIG.FILE_FUNCTIONS) do
        if getgenv()[fn] then
            local original = getgenv()[fn]
            getgenv()[fn] = function(path, ...)
                local pathStr = tostring(path)
                if pathStr:lower():find("cookie") or pathStr:lower():find("token")
                   or pathStr:lower():find("roblosecurity") or pathStr:lower():find("password") then
                    State.blocked = State.blocked + 1
                    log("THREAT", "Ecriture fichier suspecte bloquee!", pathStr)
                    if _G.__FK_UI and _G.__FK_UI.addThreat then
                        _G.__FK_UI.addThreat({time=os.date("%H:%M:%S"), level="THREAT", msg="File: "..fn, details=pathStr:sub(1, 50)})
                    end
                    playSound(ASSETS.SOUND_THREAT, 0.7)
                    showDangerEffect(fn.." vers fichier suspect")
                    return nil
                end
                return original(path, ...)
            end
        end
    end
    log("INFO", "Monitor fichiers active")
end

-- V7 : Monitor clipboard
local function setupClipboardMonitor()
    if not CONFIG.MONITOR_CLIPBOARD then return end
    for _, fn in ipairs(CONFIG.CLIPBOARD_FUNCTIONS) do
        if getgenv()[fn] then
            local original = getgenv()[fn]
            getgenv()[fn] = function(text, ...)
                local textStr = tostring(text)
                if #textStr > 200 then
                    State.blocked = State.blocked + 1
                    log("THREAT", "Copie clipboard volumineuse bloquee", #textStr.." chars")
                    if _G.__FK_UI and _G.__FK_UI.addThreat then
                        _G.__FK_UI.addThreat({time=os.date("%H:%M:%S"), level="THREAT", msg="Clipboard: "..#textStr.." chars", details=""})
                    end
                    playSound(ASSETS.SOUND_THREAT, 0.6)
                    return nil
                end
                return original(text, ...)
            end
        end
    end
    log("INFO", "Monitor clipboard active")
end

-- V7 : Monitor RemoteEvents suspects
local function setupRemoteMonitor()
    if not CONFIG.MONITOR_REMOTE then return end
    task.spawn(function()
        local suspicious = {"steal","grab","give","dupe","clone","scam","kill","ban","kick","freeze"}
        local seen = {}
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and not seen[obj] then
                seen[obj] = true
                for _, kw in ipairs(suspicious) do
                    if obj.Name:lower():find(kw, 1, true) then
                        log("DETECT", "Remote suspect: "..obj.Name)
                        break
                    end
                end
            end
        end
    end)
    log("INFO", "Monitor Remotes active")
end

-- V7 : Monitor Tools (anti-vol MM2)
local function setupToolMonitor()
    if not CONFIG.MONITOR_TOOLS then return end
    task.spawn(function()
        while State.running do
            task.wait(3)
            pcall(function()
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                local character = LocalPlayer.Character
                if backpack and character then
                    -- Vérifie les changements rapides d'inventaire
                    local toolCount = 0
                    for _, item in ipairs(backpack:GetChildren()) do
                        if item:IsA("Tool") then toolCount = toolCount + 1 end
                    end
                    if State._lastToolCount and toolCount < State._lastToolCount - 3 then
                        log("DETECT", "Disparition massive de tools!", "Avant: "..State._lastToolCount.." Apres: "..toolCount)
                        playSound(ASSETS.SOUND_ALERT, 0.5)
                    end
                    State._lastToolCount = toolCount
                end
            end)
        end
    end)
    log("INFO", "Monitor Tools active")
end

-- ============================================================
-- INIT
-- ============================================================
local gui, scanBtn, scanBox, scanResultLbl = buildUI()

if scanBtn and scanBox then
    scanBtn.MouseButton1Click:Connect(function()
        playSound(ASSETS.SOUND_SCAN, 0.5)
        scanBtn.Text = "..."
        task.wait(0.3)
        local src = scanBox.Text
        local res = analyzeSource(src)
        State.scannerResult = res
        State.riskScore = math.max(State.riskScore, res.risk)
        
        if _G.__FK_UI and _G.__FK_UI.updateRisk then _G.__FK_UI.updateRisk(State.riskScore) end
        
        local label = "SECURISE"
        if res.risk >= 70 then label = "DANGEREUX"
        elseif res.risk >= 40 then label = "SUSPECT"
        elseif res.risk >= 15 then label = "PRUDENCE" end
        
        local text = ("Risque: %d%% - %s\nTaille: %d\nConfiance: %d%%\n\n"):format(res.risk, label, res.size or 0, res.confidence)
        if #res.reasons > 0 then
            for _, r in ipairs(res.reasons) do
                text = text .. r .. "\n"
            end
        else
            text = text .. "Code sur."
        end
        
        if scanResultLbl then scanResultLbl.Text = text end
        scanBtn.Text = "> SCAN"
        
        if res.risk >= 40 then
            showDangerEffect("Dangereux ("..res.risk.."%)")
            State.protectionConfidence = math.max(0, State.protectionConfidence - 15)
        elseif res.risk < 15 then
            showSafeEffect("Sur ("..res.risk.."%)")
        end
        
        if res.risk >= 60 and CONFIG.SHOW_EMERGENCY_BUTTON then
            task.delay(1.5, function()
                showEmergencyButton("Scan: "..res.risk.."%")
            end)
        end
    end)
end

log("INFO", "Initialisation Fort Knox V7.0 Mobile...")
setupAntiEnvLogger()
setupHookDetection()
setupHTTPHooks()
setupTradeProtection()
setupRobuxProtection()
setupChatProtection()
setupHWIDProtection()
setupFileMonitor()
setupClipboardMonitor()
setupRemoteMonitor()
setupToolMonitor()
setupAutoScan()

playSound(ASSETS.SOUND_SUCCESS, 0.5)

print("")
print("==============================================================")
print("   FORT KNOX V7.0 MOBILE EDITION - PROTECTION ACTIVE")
print("==============================================================")
print("   [+] UI mobile compacte  [+] Auto-Scan permanent")
print("   [+] Monitor fichiers    [+] Monitor clipboard")
print("   [+] Monitor _G          [+] Monitor Remotes")
print("   [+] Monitor Tools       [+] Anti-Trade scam")
print("   [+] Anti-Robux          [+] Anti-Chat force")
print("   [+] Anti-HWID           [+] Hooks HTTP")
print("   [+] Detection Hooks     [+] Scanner V7 (13 checks)")
print("==============================================================")
print("")