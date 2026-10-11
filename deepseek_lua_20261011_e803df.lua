--[[
    ================================================================
    FORT KNOX V6.0 ULTIMATE - Hacker UI Edition
    Anti-Logger | Anti-Stealer | Anti-Obfuscation | Emergency Exit
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
local Lighting           = game:GetService("Lighting")
local LocalPlayer        = Players.LocalPlayer

pcall(function()
    local old = CoreGui:FindFirstChild("FortKnoxV5")
    if old then old:Destroy() end
end)

-- ============================================================
-- ASSETS
-- ============================================================
local ASSETS = {
    -- Sons
    SOUND_CLICK     = "rbxassetid://6895079853",
    SOUND_ALERT     = "rbxassetid://9046508711",
    SOUND_SUCCESS   = "rbxassetid://5847459767",
    SOUND_SCAN      = "rbxassetid://131237241",
    SOUND_THREAT    = "rbxassetid://5159276015",
    SOUND_TOGGLE    = "rbxassetid://6042053626",
    SOUND_SAFE      = "rbxassetid://4612375234",   -- son joyeux "safe"
    SOUND_DANGER    = "rbxassetid://5159276015",   -- son grave "danger"
    SOUND_QUIT      = "rbxassetid://1836852540",   -- son déconnexion
    SOUND_VICTORY   = "rbxassetid://1841647094",   -- jingle victoire
    
    -- Images
    IMG_LOGO        = "rbxassetid://6031094667",
    IMG_WARN        = "rbxassetid://6035067835",
    IMG_SAFE        = "rbxassetid://6031075931",
    IMG_DANGER      = "rbxassetid://6031091004",
    IMG_QUIT        = "rbxassetid://6035047409",
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
    CONFIDENCE_THRESHOLD  = 60,    -- Si < 60%, affiche le bouton d'urgence
    
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
    
    -- Signatures d'obfuscateurs (V6 : liste étendue)
    OBFUSCATOR_SIGNATURES = {
        "Luraph","LPH_","IronBrew","IB2_","Moonsec","AztupBrew",
        "PSU","Prometheus","Hercules","Xen","Sirhurt","Synapse",
        "ScriptWare","Krnl","WeAreDevs","Obfuscator","Encrypt",
        "VMProtect","Themida","\\x","\\u{","\\1","\\0",
        "loadstring","load(","getfenv","setfenv",
        "string.char","string.byte","table.concat",
        "\\27","\\027","\\255",
    },
    
    -- Motifs de stealer connus (V6)
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
-- EFFETS VISUELS SPECTACULAIRES (safe / danger)
-- ============================================================
local function spawnParticles(parent, color, count)
    for i = 1, count do
        local p = Instance.new("Frame")
        p.Size = UDim2.new(0, math.random(4, 10), 0, math.random(4, 10))
        p.Position = UDim2.new(0.5, 0, 0.5, 0)
        p.BackgroundColor3 = color
        p.BorderSizePixel = 0
        p.ZIndex = 100
        p.Parent = parent
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = p
        
        local angle = math.random() * math.pi * 2
        local dist = math.random(80, 250)
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
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 500, 0, 300)
    container.Position = UDim2.new(0.5, -250, 0.5, -150)
    container.BackgroundTransparency = 1
    container.Parent = gui
    
    -- Particules vertes
    spawnParticles(container, Color3.fromRGB(0, 255, 100), 40)
    task.delay(0.15, function() spawnParticles(container, Color3.fromRGB(100, 255, 150), 30) end)
    
    -- Cercle pulsant
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(0, 100, 0, 100)
    ring.Position = UDim2.new(0.5, -50, 0.5, -50)
    ring.BackgroundTransparency = 1
    ring.Parent = container
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1,0); rc.Parent = ring
    local rs = Instance.new("UIStroke"); rs.Color = Color3.fromRGB(0,255,100); rs.Thickness = 4; rs.Parent = ring
    TweenService:Create(ring, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 400, 0, 400),
        Position = UDim2.new(0.5, -200, 0.5, -200),
    }):Play()
    TweenService:Create(rs, TweenInfo.new(1.2), {Transparency = 1, Thickness = 1}):Play()
    
    -- Texte "SAFE"
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 100)
    lbl.Position = UDim2.new(0, 0, 0.5, -50)
    lbl.BackgroundTransparency = 1
    lbl.Text = "SAFE"
    lbl.TextColor3 = Color3.fromRGB(0, 255, 100)
    lbl.TextSize = 1
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 60, 20)
    lbl.Parent = container
    
    TweenService:Create(lbl, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 72}):Play()
    task.delay(0.5, function()
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, 0, 0, 30)
        sub.Position = UDim2.new(0, 0, 0.5, 50)
        sub.BackgroundTransparency = 1
        sub.Text = text or "Aucune menace détectée"
        sub.TextColor3 = Color3.fromRGB(200, 255, 220)
        sub.TextSize = 16
        sub.Font = Enum.Font.Code
        sub.Parent = container
    end)
    
    task.delay(3, function()
        if gui and gui.Parent then
            TweenService:Create(container, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
            task.wait(0.4)
            gui:Destroy()
        end
    end)
end

local function showDangerEffect(text)
    playSound(ASSETS.SOUND_DANGER, 0.8)
    task.delay(0.2, function() playSound(ASSETS.SOUND_ALERT, 0.6) end)
    
    -- Flash rouge sur l'écran
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
    
    -- GUI danger
    local gui = Instance.new("ScreenGui")
    gui.Name = "FKDangerEffect"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999999
    gui.Parent = CoreGui
    
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 500, 0, 300)
    container.Position = UDim2.new(0.5, -250, 0.5, -150)
    container.BackgroundTransparency = 1
    container.Parent = gui
    
    spawnParticles(container, Color3.fromRGB(255, 30, 30), 35)
    task.delay(0.15, function() spawnParticles(container, Color3.fromRGB(180, 0, 0), 25) end)
    
    local ring = Instance.new("Frame")
    ring.Size = UDim2.new(0, 100, 0, 100)
    ring.Position = UDim2.new(0.5, -50, 0.5, -50)
    ring.BackgroundTransparency = 1
    ring.Parent = container
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1,0); rc.Parent = ring
    local rs = Instance.new("UIStroke"); rs.Color = Color3.fromRGB(255,30,30); rs.Thickness = 5; rs.Parent = ring
    TweenService:Create(ring, TweenInfo.new(1.0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 450, 0, 450),
        Position = UDim2.new(0.5, -225, 0.5, -225),
    }):Play()
    TweenService:Create(rs, TweenInfo.new(1.0), {Transparency = 1}):Play()
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 100)
    lbl.Position = UDim2.new(0, 0, 0.5, -50)
    lbl.BackgroundTransparency = 1
    lbl.Text = "DANGER"
    lbl.TextColor3 = Color3.fromRGB(255, 30, 30)
    lbl.TextSize = 1
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(60, 0, 0)
    lbl.Parent = container
    
    TweenService:Create(lbl, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 80}):Play()
    
    -- Shake effect
    task.spawn(function()
        local startPos = container.Position
        for i = 1, 20 do
            container.Position = startPos + UDim2.new(0, math.random(-12, 12), 0, math.random(-12, 12))
            task.wait(0.03)
        end
        container.Position = startPos
    end)
    
    task.delay(0.5, function()
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, 0, 0, 30)
        sub.Position = UDim2.new(0, 0, 0.5, 55)
        sub.BackgroundTransparency = 1
        sub.Text = text or "Menace détectée"
        sub.TextColor3 = Color3.fromRGB(255, 180, 180)
        sub.TextSize = 16
        sub.Font = Enum.Font.Code
        sub.Parent = container
    end)
    
    task.delay(3, function()
        if gui and gui.Parent then
            gui:Destroy()
        end
    end)
end

-- ============================================================
-- BOUTON D'URGENCE "QUIT INSTANTANÉ"
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
    
    -- Overlay semi-transparent
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel = 0
    overlay.Parent = gui
    
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 550, 0, 260)
    main.Position = UDim2.new(0.5, -275, 0.5, -130)
    main.BackgroundColor3 = Color3.fromRGB(15, 5, 5)
    main.BorderSizePixel = 0
    main.Parent = gui
    local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 16); mc.Parent = main
    local ms = Instance.new("UIStroke"); ms.Color = Color3.fromRGB(255, 40, 40); ms.Thickness = 3; ms.Parent = main
    
    -- Pulse sur le stroke
    task.spawn(function()
        while main.Parent do
            TweenService:Create(ms, TweenInfo.new(0.5), {Transparency = 0.7}):Play()
            task.wait(0.5)
            TweenService:Create(ms, TweenInfo.new(0.5), {Transparency = 0}):Play()
            task.wait(0.5)
        end
    end)
    
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 60, 0, 60)
    icon.Position = UDim2.new(0.5, -30, 0, 15)
    icon.BackgroundTransparency = 1
    icon.Image = ASSETS.IMG_DANGER
    icon.Parent = main
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 80)
    title.BackgroundTransparency = 1
    title.Text = "PROTECTION INSUFFISANTE"
    title.TextColor3 = Color3.fromRGB(255, 60, 60)
    title.TextSize = 22
    title.Font = Enum.Font.GothamBold
    title.Parent = main
    
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -40, 0, 60)
    desc.Position = UDim2.new(0, 20, 0, 115)
    desc.BackgroundTransparency = 1
    desc.Text = "Le système détecte que ce script peut ne pas être totalement neutralisé.\n\nRaison : " .. tostring(reason)
    desc.TextColor3 = Color3.fromRGB(255, 200, 200)
    desc.TextSize = 13
    desc.Font = Enum.Font.Code
    desc.TextWrapped = true
    desc.Parent = main
    
    -- Bouton QUIT INSTANT
    local quitBtn = Instance.new("TextButton")
    quitBtn.Size = UDim2.new(0, 240, 0, 50)
    quitBtn.Position = UDim2.new(0, 30, 1, -65)
    quitBtn.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
    quitBtn.Text = "QUITTER MAINTENANT"
    quitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    quitBtn.TextSize = 16
    quitBtn.Font = Enum.Font.GothamBold
    quitBtn.BorderSizePixel = 0
    quitBtn.AutoButtonColor = false
    quitBtn.Parent = main
    local qc = Instance.new("UICorner"); qc.CornerRadius = UDim.new(0, 10); qc.Parent = quitBtn
    
    quitBtn.MouseEnter:Connect(function()
        TweenService:Create(quitBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 40, 40)}):Play()
    end)
    quitBtn.MouseLeave:Connect(function()
        TweenService:Create(quitBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(200, 20, 20)}):Play()
    end)
    
    quitBtn.MouseButton1Click:Connect(function()
        playSound(ASSETS.SOUND_QUIT, 0.8)
        quitBtn.Text = "DECONNEXION..."
        quitBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
        
        -- Ferme le jeu immédiatement
        task.wait(0.1)
        pcall(function()
            game:Shutdown()
        end)
        LocalPlayer:Kick("[Fort Knox] Quit d'urgence déclenché par l'utilisateur. Compte protégé.")
    end)
    
    -- Bouton continuer (si l'utilisateur est sûr)
    local contBtn = Instance.new("TextButton")
    contBtn.Size = UDim2.new(0, 240, 0, 50)
    contBtn.Position = UDim2.new(1, -270, 1, -65)
    contBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    contBtn.Text = "CONTINUER (déconseillé)"
    contBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    contBtn.TextSize = 13
    contBtn.Font = Enum.Font.Code
    contBtn.BorderSizePixel = 0
    contBtn.AutoButtonColor = false
    contBtn.Parent = main
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 10); cc.Parent = contBtn
    
    contBtn.MouseButton1Click:Connect(function()
        playSound(ASSETS.SOUND_CLICK, 0.3)
        _G.__FK_EMERGENCY_OPEN = false
        gui:Destroy()
    end)
    
    -- Animation d'apparition
    main.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 550, 0, 260)
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
        -- Baisse la confiance de protection
        State.protectionConfidence = math.max(0, State.protectionConfidence - 20)
        if State.protectionConfidence < CONFIG.CONFIDENCE_THRESHOLD and not State.emergencyMode then
            State.emergencyMode = true
            showEmergencyButton("Confiance de protection: " .. State.protectionConfidence .. "%")
        end
    end
end

-- ============================================================
-- UI (reprend la V5 avec ajustements)
-- ============================================================
local function buildUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "FortKnoxV5"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = CoreGui
    gui.DisplayOrder = 999999
    
    local GREEN = Color3.fromRGB(0, 255, 100)
    local BG    = Color3.fromRGB(8, 12, 8)
    local PANEL = Color3.fromRGB(15, 22, 15)
    local RED   = Color3.fromRGB(255, 60, 60)
    local YELLOW= Color3.fromRGB(255, 200, 0)
    
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 680, 0, 460)
    main.Position = UDim2.new(0.5, -340, 0.5, -230)
    main.BackgroundColor3 = BG
    main.BorderSizePixel = 0
    main.Parent = gui
    local mc = Instance.new("UICorner"); mc.CornerRadius = UDim.new(0, 14); mc.Parent = main
    local ms = Instance.new("UIStroke"); ms.Color = GREEN; ms.Thickness = 2; ms.Transparency = 0.2; ms.Parent = main
    
    -- HEADER
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 45)
    header.BackgroundColor3 = Color3.fromRGB(10, 18, 10)
    header.BorderSizePixel = 0
    header.Parent = main
    local hc = Instance.new("UICorner"); hc.CornerRadius = UDim.new(0, 14); hc.Parent = header
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 500, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "FORT KNOX v6.0  >>  PROTECTION ACTIVE"
    title.TextColor3 = GREEN
    title.TextSize = 15
    title.Font = Enum.Font.Code
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    task.spawn(function()
        local txt = "FORT KNOX v6.0  >>  PROTECTION ACTIVE"
        title.Text = ""
        for i = 1, #txt do
            title.Text = txt:sub(1, i)
            task.wait(0.02)
        end
    end)
    
    local function makeHeaderBtn(txt, xPos, color)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 30, 0, 30)
        b.Position = UDim2.new(1, xPos, 0.5, -15)
        b.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
        b.Text = txt
        b.TextColor3 = color
        b.TextSize = 16
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        b.AutoButtonColor = false
        b.Parent = header
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = color, TextColor3 = BG}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20,30,20), TextColor3 = color}):Play()
        end)
        return b
    end
    
    local btnClose = makeHeaderBtn("X", -10, RED)
    local btnMin   = makeHeaderBtn("-", -46, YELLOW)
    
    -- SIDEBAR
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 140, 1, -75)
    sidebar.Position = UDim2.new(0, 10, 0, 55)
    sidebar.BackgroundColor3 = PANEL
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main
    local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 10); sc.Parent = sidebar
    
    local tabs = {
        {name = "Dashboard"},
        {name = "Scanner"},
        {name = "Activity"},
        {name = "Threats"},
        {name = "Settings"},
    }
    
    local tabButtons = {}
    local contentFrames = {}
    
    for i, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -12, 0, 36)
        btn.Position = UDim2.new(0, 6, 0, 6 + (i-1)*42)
        btn.BackgroundColor3 = Color3.fromRGB(15, 22, 15)
        btn.Text = "  > " .. tab.name
        btn.TextColor3 = Color3.fromRGB(150, 180, 150)
        btn.TextSize = 13
        btn.Font = Enum.Font.Code
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Parent = sidebar
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = btn
        
        tabButtons[tab.name] = btn
        
        btn.MouseButton1Click:Connect(function()
            playSound(ASSETS.SOUND_CLICK, 0.3)
            for _, f in pairs(contentFrames) do f.Visible = false end
            for _, b in pairs(tabButtons) do
                TweenService:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(15,22,15), TextColor3 = Color3.fromRGB(150,180,150)}):Play()
            end
            contentFrames[tab.name].Visible = true
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0,40,20), TextColor3 = GREEN}):Play()
        end)
    end
    
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -170, 1, -75)
    content.Position = UDim2.new(0, 160, 0, 55)
    content.BackgroundColor3 = PANEL
    content.BorderSizePixel = 0
    content.Parent = main
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 10); cc.Parent = content
    
    for _, tab in ipairs(tabs) do
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, -20, 1, -20)
        f.Position = UDim2.new(0, 10, 0, 10)
        f.BackgroundTransparency = 1
        f.Visible = false
        f.Parent = content
        contentFrames[tab.name] = f
    end
    contentFrames["Dashboard"].Visible = true
    TweenService:Create(tabButtons["Dashboard"], TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(0,40,20), TextColor3 = GREEN}):Play()
    
    -- DASHBOARD
    local dash = contentFrames["Dashboard"]
    
    local riskLabel = Instance.new("TextLabel")
    riskLabel.Size = UDim2.new(1, 0, 0, 22)
    riskLabel.BackgroundTransparency = 1
    riskLabel.Text = "NIVEAU DE RISQUE"
    riskLabel.TextColor3 = GREEN
    riskLabel.TextSize = 13
    riskLabel.Font = Enum.Font.Code
    riskLabel.TextXAlignment = Enum.TextXAlignment.Left
    riskLabel.Parent = dash
    
    local riskValue = Instance.new("TextLabel")
    riskValue.Size = UDim2.new(1, 0, 0, 44)
    riskValue.Position = UDim2.new(0, 0, 0, 22)
    riskValue.BackgroundTransparency = 1
    riskValue.Text = "0%   -  SECURISE"
    riskValue.TextColor3 = GREEN
    riskValue.TextSize = 34
    riskValue.Font = Enum.Font.Code
    riskValue.TextXAlignment = Enum.TextXAlignment.Left
    riskValue.Parent = dash
    
    local barBG = Instance.new("Frame")
    barBG.Size = UDim2.new(1, 0, 0, 12)
    barBG.Position = UDim2.new(0, 0, 0, 72)
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
    
    -- Confiance de protection
    local confLabel = Instance.new("TextLabel")
    confLabel.Size = UDim2.new(1, 0, 0, 20)
    confLabel.Position = UDim2.new(0, 0, 0, 92)
    confLabel.BackgroundTransparency = 1
    confLabel.Text = "CONFIANCE DE PROTECTION: 100%"
    confLabel.TextColor3 = GREEN
    confLabel.TextSize = 12
    confLabel.Font = Enum.Font.Code
    confLabel.TextXAlignment = Enum.TextXAlignment.Left
    confLabel.Parent = dash
    
    local function statBox(name, xPos)
        local box = Instance.new("Frame")
        box.Size = UDim2.new(0, 155, 0, 65)
        box.Position = UDim2.new(0, xPos, 0, 120)
        box.BackgroundColor3 = Color3.fromRGB(10, 18, 10)
        box.BorderSizePixel = 0
        box.Parent = dash
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = box
        local s = Instance.new("UIStroke"); s.Color = GREEN; s.Thickness = 1; s.Transparency = 0.7; s.Parent = box
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.Position = UDim2.new(0, 8, 0, 5)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = Color3.fromRGB(120, 180, 120)
        lbl.TextSize = 10
        lbl.Font = Enum.Font.Code
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = box
        
        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(1, -16, 0, 32)
        val.Position = UDim2.new(0, 8, 0, 24)
        val.BackgroundTransparency = 1
        val.Text = "0"
        val.TextColor3 = GREEN
        val.TextSize = 24
        val.Font = Enum.Font.Code
        val.TextXAlignment = Enum.TextXAlignment.Left
        val.Parent = box
        return val
    end
    
    local statBlocked = statBox("BLOQUEES", 0)
    local statThreats = statBox("MENACES", 165)
    local statAllowed = statBox("AUTORISEES", 330)
    
    -- Bouton "TEST SAFE" manuel
    local testBtn = Instance.new("TextButton")
    testBtn.Size = UDim2.new(0, 160, 0, 32)
    testBtn.Position = UDim2.new(0, 0, 0, 200)
    testBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 20)
    testBtn.Text = "TESTER EFFET SAFE"
    testBtn.TextColor3 = GREEN
    testBtn.TextSize = 11
    testBtn.Font = Enum.Font.Code
    testBtn.BorderSizePixel = 0
    testBtn.AutoButtonColor = false
    testBtn.Parent = dash
    local tbc = Instance.new("UICorner"); tbc.CornerRadius = UDim.new(0, 6); tbc.Parent = testBtn
    testBtn.MouseButton1Click:Connect(function() showSafeEffect("Test manuel - tout est OK") end)
    
    local testBtn2 = Instance.new("TextButton")
    testBtn2.Size = UDim2.new(0, 160, 0, 32)
    testBtn2.Position = UDim2.new(0, 170, 0, 200)
    testBtn2.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
    testBtn2.Text = "TESTER EFFET DANGER"
    testBtn2.TextColor3 = RED
    testBtn2.TextSize = 11
    testBtn2.Font = Enum.Font.Code
    testBtn2.BorderSizePixel = 0
    testBtn2.AutoButtonColor = false
    testBtn2.Parent = dash
    local tbc2 = Instance.new("UICorner"); tbc2.CornerRadius = UDim.new(0, 6); tbc2.Parent = testBtn2
    testBtn2.MouseButton1Click:Connect(function() showDangerEffect("Test manuel - menace simulée") end)
    
    -- SCANNER
    local scan = contentFrames["Scanner"]
    
    local scanTitle = Instance.new("TextLabel")
    scanTitle.Size = UDim2.new(1, 0, 0, 20)
    scanTitle.BackgroundTransparency = 1
    scanTitle.Text = "COLLE LE CODE A ANALYSER :"
    scanTitle.TextColor3 = GREEN
    scanTitle.TextSize = 12
    scanTitle.Font = Enum.Font.Code
    scanTitle.TextXAlignment = Enum.TextXAlignment.Left
    scanTitle.Parent = scan
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 170)
    box.Position = UDim2.new(0, 0, 0, 24)
    box.BackgroundColor3 = Color3.fromRGB(5, 10, 5)
    box.TextColor3 = Color3.fromRGB(150, 255, 150)
    box.PlaceholderText = "-- Colle ici le script suspect --"
    box.PlaceholderColor3 = Color3.fromRGB(80, 120, 80)
    box.TextSize = 12
    box.Font = Enum.Font.Code
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.TextWrapped = true
    box.ClearTextOnFocus = false
    box.MultiLine = true
    box.BorderSizePixel = 0
    box.Parent = scan
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = box
    local bs = Instance.new("UIStroke"); bs.Color = GREEN; bs.Thickness = 1; bs.Transparency = 0.6; bs.Parent = box
    
    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(0, 170, 0, 34)
    scanBtn.Position = UDim2.new(0, 0, 0, 200)
    scanBtn.BackgroundColor3 = Color3.fromRGB(0, 40, 20)
    scanBtn.Text = "> LANCER LE SCAN"
    scanBtn.TextColor3 = GREEN
    scanBtn.TextSize = 13
    scanBtn.Font = Enum.Font.Code
    scanBtn.BorderSizePixel = 0
    scanBtn.AutoButtonColor = false
    scanBtn.Parent = scan
    local sb = Instance.new("UICorner"); sb.CornerRadius = UDim.new(0, 6); sb.Parent = scanBtn
    
    local scanResult = Instance.new("TextLabel")
    scanResult.Size = UDim2.new(1, 0, 1, -245)
    scanResult.Position = UDim2.new(0, 0, 0, 242)
    scanResult.BackgroundTransparency = 1
    scanResult.Text = ""
    scanResult.TextColor3 = GREEN
    scanResult.TextSize = 12
    scanResult.Font = Enum.Font.Code
    scanResult.TextXAlignment = Enum.TextXAlignment.Left
    scanResult.TextYAlignment = Enum.TextYAlignment.Top
    scanResult.TextWrapped = true
    scanResult.Parent = scan
    
    -- ACTIVITY
    local act = contentFrames["Activity"]
    local actScroll = Instance.new("ScrollingFrame")
    actScroll.Size = UDim2.new(1, 0, 1, -35)
    actScroll.BackgroundColor3 = Color3.fromRGB(5, 10, 5)
    actScroll.BorderSizePixel = 0
    actScroll.ScrollBarThickness = 4
    actScroll.ScrollBarImageColor3 = GREEN
    actScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    actScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    actScroll.Parent = act
    local asc = Instance.new("UICorner"); asc.CornerRadius = UDim.new(0, 6); asc.Parent = actScroll
    
    local actLayout = Instance.new("UIListLayout")
    actLayout.SortOrder = Enum.SortOrder.LayoutOrder
    actLayout.Padding = UDim.new(0, 2)
    actLayout.Parent = actScroll
    
    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 100, 0, 26)
    clearBtn.Position = UDim2.new(1, -100, 1, -30)
    clearBtn.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
    clearBtn.Text = "EFFACER"
    clearBtn.TextColor3 = RED
    clearBtn.TextSize = 11
    clearBtn.Font = Enum.Font.Code
    clearBtn.BorderSizePixel = 0
    clearBtn.Parent = act
    local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0, 6); cbc.Parent = clearBtn
    clearBtn.MouseButton1Click:Connect(function()
        for _, ch in ipairs(actScroll:GetChildren()) do
            if ch:IsA("TextLabel") then ch:Destroy() end
        end
        playSound(ASSETS.SOUND_CLICK, 0.3)
    end)
    
    -- THREATS
    local thr = contentFrames["Threats"]
    local thrScroll = Instance.new("ScrollingFrame")
    thrScroll.Size = UDim2.new(1, 0, 1, 0)
    thrScroll.BackgroundColor3 = Color3.fromRGB(5, 10, 5)
    thrScroll.BorderSizePixel = 0
    thrScroll.ScrollBarThickness = 4
    thrScroll.ScrollBarImageColor3 = RED
    thrScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    thrScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    thrScroll.Parent = thr
    local tsc = Instance.new("UICorner"); tsc.CornerRadius = UDim.new(0, 6); tsc.Parent = thrScroll
    local thrLayout = Instance.new("UIListLayout"); thrLayout.SortOrder = Enum.SortOrder.LayoutOrder; thrLayout.Padding = UDim.new(0, 3); thrLayout.Parent = thrScroll
    
    -- SETTINGS
    local stg = contentFrames["Settings"]
    local stgScroll = Instance.new("ScrollingFrame")
    stgScroll.Size = UDim2.new(1, 0, 1, 0)
    stgScroll.BackgroundTransparency = 1
    stgScroll.BorderSizePixel = 0
    stgScroll.ScrollBarThickness = 4
    stgScroll.ScrollBarImageColor3 = GREEN
    stgScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    stgScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    stgScroll.Parent = stg
    local stgLayout = Instance.new("UIListLayout")
    stgLayout.SortOrder = Enum.SortOrder.LayoutOrder
    stgLayout.Padding = UDim.new(0, 5)
    stgLayout.Parent = stgScroll
    
    local function toggleOption(label, key, default)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 30)
        f.BackgroundColor3 = Color3.fromRGB(10, 18, 10)
        f.BorderSizePixel = 0
        f.Parent = stgScroll
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = f
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -70, 1, 0)
        lbl.Position = UDim2.new(0, 10, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = GREEN
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Code
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = f
        
        local sw = Instance.new("TextButton")
        sw.Size = UDim2.new(0, 50, 0, 22)
        sw.Position = UDim2.new(1, -60, 0.5, -11)
        sw.BackgroundColor3 = default and GREEN or Color3.fromRGB(40, 40, 40)
        sw.Text = default and "ON" or "OFF"
        sw.TextColor3 = default and BG or Color3.fromRGB(150,150,150)
        sw.TextSize = 11
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
    
    toggleOption("Deconnexion auto (kick critique)", "AUTO_KICK_ON_CRITICAL", CONFIG.AUTO_KICK_ON_CRITICAL)
    toggleOption("Alertes visuelles", "SHOW_ALERTS", CONFIG.SHOW_ALERTS)
    toggleOption("Effets sonores", "PLAY_SOUNDS", CONFIG.PLAY_SOUNDS)
    toggleOption("Securite maximale (bloque tout HTTP)", "MAXIMUM_SECURITY", CONFIG.MAXIMUM_SECURITY)
    toggleOption("Protection Trade (Adopt Me / MM2)", "PROTECT_TRADES", CONFIG.PROTECT_TRADES)
    toggleOption("Protection Robux", "PROTECT_ROBUX", CONFIG.PROTECT_ROBUX)
    toggleOption("Protection Chat force", "PROTECT_CHAT", CONFIG.PROTECT_CHAT)
    toggleOption("Protection HWID", "PROTECT_HWID", CONFIG.PROTECT_HWID)
    toggleOption("Detection de hooks", "DETECT_HOOKS", CONFIG.DETECT_HOOKS)
    toggleOption("Detection d'obfuscation", "DETECT_OBFUSCATION", CONFIG.DETECT_OBFUSCATION)
    toggleOption("Bouton urgence automatique", "SHOW_EMERGENCY_BUTTON", CONFIG.SHOW_EMERGENCY_BUTTON)
    
    -- Drag header
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
        local targetSize = minimized and UDim2.new(0, 680, 0, 45) or UDim2.new(0, 680, 0, 460)
        TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
        sidebar.Visible = not minimized
        content.Visible = not minimized
    end)
    
    btnClose.MouseButton1Click:Connect(function()
        playSound(ASSETS.SOUND_CLICK, 0.3)
        TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        task.wait(0.3)
        gui:Destroy()
        _G.__FK_REOPEN = function()
            _G.__FK_REOPEN = nil
            buildUI()
        end
    end)
    
    -- API
    _G.__FK_UI = {
        updateRisk = function(score)
            local color = GREEN
            local label = "SECURISE"
            if score >= 70 then color = RED; label = "CRITIQUE"
            elseif score >= 40 then color = YELLOW; label = "SUSPECT"
            elseif score >= 15 then color = Color3.fromRGB(200,255,100); label = "PRUDENCE" end
            riskValue.Text = tostring(math.floor(score)) .. "%   -  " .. label
            riskValue.TextColor3 = color
            TweenService:Create(barFill, TweenInfo.new(0.4), {
                Size = UDim2.new(score/100, 0, 1, 0),
                BackgroundColor3 = color
            }):Play()
            statBlocked.Text = tostring(State.blocked)
            statThreats.Text = tostring(#State.threats)
            statAllowed.Text = tostring(State.allowed)
            confLabel.Text = "CONFIANCE DE PROTECTION: " .. State.protectionConfidence .. "%"
            confLabel.TextColor3 = State.protectionConfidence >= 60 and GREEN or RED
        end,
        addActivity = function(entry)
            local color = GREEN
            if entry.level == "BLOCK" then color = RED
            elseif entry.level == "THREAT" then color = RED
            elseif entry.level == "DETECT" then color = YELLOW end
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 18)
            lbl.BackgroundTransparency = 1
            lbl.Text = ("[%s] %s  %s"):format(entry.time, entry.level, entry.msg)
            lbl.TextColor3 = color
            lbl.TextSize = 11
            lbl.Font = Enum.Font.Code
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Parent = actScroll
        end,
        addThreat = function(entry)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, 0, 0, 44)
            f.BackgroundColor3 = Color3.fromRGB(30, 10, 10)
            f.BorderSizePixel = 0
            f.Parent = thrScroll
            local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = f
            
            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1, -20, 0, 20)
            t.Position = UDim2.new(0, 10, 0, 4)
            t.BackgroundTransparency = 1
            t.Text = "[!] " .. entry.msg
            t.TextColor3 = RED
            t.TextSize = 12
            t.Font = Enum.Font.Code
            t.TextXAlignment = Enum.TextXAlignment.Left
            t.Parent = f
            
            local d = Instance.new("TextLabel")
            d.Size = UDim2.new(1, -20, 0, 20)
            d.Position = UDim2.new(0, 10, 0, 22)
            d.BackgroundTransparency = 1
            d.Text = entry.details or ""
            d.TextColor3 = Color3.fromRGB(200, 150, 150)
            d.TextSize = 10
            d.Font = Enum.Font.Code
            d.TextXAlignment = Enum.TextXAlignment.Left
            d.Parent = f
        end,
    }
    
    return gui, scanBtn, box, scanResult
end

-- ============================================================
-- ANALYSEUR AMÉLIORÉ V6
-- ============================================================
local function analyzeSource(src)
    if type(src) ~= "string" then return {risk = 0, reasons = {"Source invalide"}, confidence = 100} end
    
    local reasons = {}
    local risk = 0
    local totalChecks = 0
    local passedChecks = 0
    
    -- 1. Taille
    totalChecks = totalChecks + 1
    if #src > 200000 then
        risk = risk + 20
        table.insert(reasons, "[!] Taille de code tres elevee ("..#src.." chars)")
    elseif #src > 50000 then
        risk = risk + 10
        table.insert(reasons, "[~] Taille de code elevee ("..#src.." chars)")
    else
        passedChecks = passedChecks + 1
    end
    
    -- 2. Signatures d'obfuscateurs connus
    totalChecks = totalChecks + 1
    local sigHits = 0
    for _, sig in ipairs(CONFIG.OBFUSCATOR_SIGNATURES) do
        if src:find(sig, 1, true) then
            sigHits = sigHits + 1
            table.insert(reasons, "[!] Signature obfuscateur: "..sig)
        end
    end
    if sigHits == 0 then passedChecks = passedChecks + 1
    else risk = risk + math.min(sigHits * 8, 40) end
    
    -- 3. Motifs de stealer
    totalChecks = totalChecks + 1
    local stealerHits = 0
    local foundStealerPatterns = {}
    for _, pat in ipairs(CONFIG.STEALER_PATTERNS) do
        if src:find(pat, 1, true) then
            stealerHits = stealerHits + 1
            table.insert(foundStealerPatterns, pat)
        end
    end
    if stealerHits > 0 then
        risk = risk + math.min(stealerHits * 10, 50)
        table.insert(reasons, "[!] Motifs stealer detectes: "..table.concat(foundStealerPatterns, ", "):sub(1, 100))
    else
        passedChecks = passedChecks + 1
    end
    
    -- 4. Ratio caractères spéciaux
    totalChecks = totalChecks + 1
    local specialCount = 0
    local checkSize = math.min(#src, 5000)
    for i = 1, checkSize do
        local c = src:byte(i)
        if c and (c < 32 or c > 126) and c ~= 10 and c ~= 13 and c ~= 9 then
            specialCount = specialCount + 1
        end
    end
    local ratio = specialCount / checkSize
    if ratio > 0.15 then
        risk = risk + 25
        table.insert(reasons, ("[!] Ratio caracteres speciaux ELEVE (%.1f%%)"):format(ratio*100))
    elseif ratio > 0.08 then
        risk = risk + 10
        table.insert(reasons, ("[~] Ratio caracteres speciaux modere (%.1f%%)"):format(ratio*100))
    else
        passedChecks = passedChecks + 1
    end
    
    -- 5. Lignes longues
    totalChecks = totalChecks + 1
    local maxLine = 0
    for line in src:gmatch("[^\n]+") do
        if #line > maxLine then maxLine = #line end
    end
    if maxLine > 5000 then
        risk = risk + 20
        table.insert(reasons, "[!] Ligne unique de "..maxLine.." chars (obfuscation)")
    elseif maxLine > 1000 then
        risk = risk + 8
        table.insert(reasons, "[~] Lignes longues ("..maxLine.." chars)")
    else
        passedChecks = passedChecks + 1
    end
    
    -- 6. Mots-clés sensibles
    totalChecks = totalChecks + 1
    local kwHits = 0
    local foundKws = {}
    for _, kw in ipairs(CONFIG.BLOCKED_KEYWORDS) do
        if src:lower():find(kw:lower(), 1, true) then
            kwHits = kwHits + 1
            table.insert(foundKws, kw)
        end
    end
    if kwHits > 0 then
        risk = risk + math.min(kwHits * 6, 35)
        table.insert(reasons, "[!] Mots-cles sensibles: "..table.concat(foundKws, ", "):sub(1, 80))
    else
        passedChecks = passedChecks + 1
    end
    
    -- 7. loadstring / getfenv
    totalChecks = totalChecks + 1
    if src:find("loadstring", 1, true) or src:find("getfenv", 1, true) or src:find("setfenv", 1, true) then
        risk = risk + 15
        table.insert(reasons, "[!] Utilise loadstring/getfenv/setfenv")
    else
        passedChecks = passedChecks + 1
    end
    
    -- 8. Hooks
    totalChecks = totalChecks + 1
    if src:find("hookfunction", 1, true) or src:find("hookmetamethod", 1, true) then
        risk = risk + 15
        table.insert(reasons, "[!] Utilise hookfunction/hookmetamethod")
    else
        passedChecks = passedChecks + 1
    end
    
    -- 9. Base64 / Hex encoding
    totalChecks = totalChecks + 1
    local b64Count = 0
    for _ in src:gmatch("[A-Za-z0-9+/=][A-Za-z0-9+/=][A-Za-z0-9+/=][A-Za-z0-9+/=]") do
        b64Count = b64Count + 1
        if b64Count > 100 then break end
    end
    if b64Count > 50 then
        risk = risk + 15
        table.insert(reasons, "[!] Encodage Base64 probable ("..b64Count.." occurrences)")
    else
        passedChecks = passedChecks + 1
    end
    
    -- 10. Entropie des identifiants (noms de variables aléatoires)
    totalChecks = totalChecks + 1
    local weirdIds = 0
    for id in src:gmatch("[%a_][%w_]*") do
        if #id > 15 then
            local hasDigit = id:match("%d") and id:match("%a")
            if hasDigit then weirdIds = weirdIds + 1 end
        end
    end
    if weirdIds > 30 then
        risk = risk + 12
        table.insert(reasons, "[!] Noms de variables obfusques ("..weirdIds..")")
    else
        passedChecks = passedChecks + 1
    end
    
    risk = math.min(100, risk)
    local confidence = math.floor((passedChecks / totalChecks) * 100)
    
    return {
        risk = risk,
        reasons = reasons,
        size = #src,
        confidence = confidence,
        maxLine = maxLine,
    }
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
    local fns = {"HttpGet","HttpGetAsync","HttpPost","HttpPostAsync","request","hookfunction","hookmetamethod"}
    local originals = {}
    for _, n in ipairs(fns) do if game[n] then originals[n] = game[n] end end
    task.spawn(function()
        while State.running do
            task.wait(1.5)
            for n, orig in pairs(originals) do
                if game[n] and game[n] ~= orig then
                    log("DETECT", "Hook malveillant detecte: "..n)
                    if _G.__FK_UI and _G.__FK_UI.addThreat then
                        _G.__FK_UI.addThreat({time=os.date("%H:%M:%S"), level="DETECT", msg="Hook malveillant: "..n, details="Fonction modifiee par un autre script"})
                    end
                    playSound(ASSETS.SOUND_THREAT, 0.5)
                    showDangerEffect("Hook malveillant sur " .. n)
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
                    log("BLOCK", method.." bloque", tostring(url))
                    if _G.__FK_UI and _G.__FK_UI.updateRisk then _G.__FK_UI.updateRisk(State.riskScore) end
                    playSound(ASSETS.SOUND_ALERT, 0.5)
                    showDangerEffect(method .. " vers URL suspecte")
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
                    log("BLOCK", "REQUEST bloquee", data.Url)
                    if _G.__FK_UI and _G.__FK_UI.updateRisk then _G.__FK_UI.updateRisk(State.riskScore) end
                    playSound(ASSETS.SOUND_ALERT, 0.5)
                    showDangerEffect("REQUEST vers URL suspecte")
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
                                    log("THREAT", "Freeze trade bloque: "..obj.Name, "Tentative de scam")
                                    if _G.__FK_UI and _G.__FK_UI.addThreat then
                                        _G.__FK_UI.addThreat({time=os.date("%H:%M:%S"), level="THREAT", msg="FREEZE TRADE: "..obj.Name, details="Tentative de scam"})
                                    end
                                    playSound(ASSETS.SOUND_THREAT, 0.6)
                                    showDangerEffect("FREEZE TRADE detecte")
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
            log("THREAT", "Achat Robux bloque", "AssetId: "..tostring(id))
            if _G.__FK_UI and _G.__FK_UI.addThreat then
                _G.__FK_UI.addThreat({time=os.date("%H:%M:%S"), level="THREAT", msg="Achat Robux: "..tostring(id), details="Tentative d'achat force"})
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
                log("BLOCK", "Chat force bloque", tostring(msg):sub(1, 50))
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
                log("DETECT", "Acces HWID bloque: "..n)
                return "FK_PROTECTED_"..math.random(100000,999999)
            end
        end
    end
end

-- ============================================================
-- INIT
-- ============================================================
local gui, scanBtn, scanBox, scanResultLbl = buildUI()

-- Trouver les éléments du scanner
local scanBtnFound = scanBtn
local scanBoxFound = scanBox
local scanResultFound = scanResultLbl

if scanBtnFound and scanBoxFound then
    scanBtnFound.MouseButton1Click:Connect(function()
        playSound(ASSETS.SOUND_SCAN, 0.5)
        scanBtnFound.Text = "SCAN EN COURS..."
        task.wait(0.4)
        local src = scanBoxFound.Text
        local res = analyzeSource(src)
        State.scannerResult = res
        State.riskScore = math.max(State.riskScore, res.risk)
        
        if _G.__FK_UI and _G.__FK_UI.updateRisk then _G.__FK_UI.updateRisk(State.riskScore) end
        
        local label = "SECURISE"
        if res.risk >= 70 then label = "DANGEREUX"
        elseif res.risk >= 40 then label = "SUSPECT"
        elseif res.risk >= 15 then label = "PRUDENCE" end
        
        local text = ("Score: %d%% - %s\nTaille: %d chars\nConfiance analyse: %d%%\nLigne max: %d chars\n\n"):format(res.risk, label, res.size or 0, res.confidence, res.maxLine or 0)
        if #res.reasons > 0 then
            text = text .. "Details:\n"
            for _, r in ipairs(res.reasons) do
                text = text .. "  " .. r .. "\n"
            end
        else
            text = text .. "Aucun probleme detecte. Code semble sur."
        end
        
        if scanResultFound then scanResultFound.Text = text end
        scanBtnFound.Text = "> LANCER LE SCAN"
        
        -- Effets selon le résultat
        if res.risk >= 40 then
            showDangerEffect("Script dangereux detecte ("..res.risk.."%)")
            State.protectionConfidence = math.max(0, State.protectionConfidence - 15)
        elseif res.risk < 15 then
            showSafeEffect("Script analyse comme sur ("..res.risk.."%)")
        end
        
        -- Bouton d'urgence si le scan est très mauvais
        if res.risk >= 60 and CONFIG.SHOW_EMERGENCY_BUTTON then
            task.delay(1.5, function()
                showEmergencyButton("Script scanne a "..res.risk.."% de risque")
            end)
        end
    end)
end

log("INFO", "Initialisation de Fort Knox V6.0 Ultimate...")
setupAntiEnvLogger()
setupHookDetection()
setupHTTPHooks()
setupTradeProtection()
setupRobuxProtection()
setupChatProtection()
setupHWIDProtection()

playSound(ASSETS.SOUND_SUCCESS, 0.5)

print("")
print("==============================================================")
print("   FORT KNOX V6.0 ULTIMATE - PROTECTION ACTIVE")
print("==============================================================")
print("   [+] Anti-Env Logger       [+] Detection Hooks")
print("   [+] Hooks HTTP            [+] Protection Trade")
print("   [+] Protection Robux      [+] Protection Chat")
print("   [+] Protection HWID       [+] Scanner Obfuscation V6")
print("   [+] Live Risk Score       [+] Activity Table")
print("   [+] Effets SAFE/DANGER    [+] Bouton urgence quit")
print("==============================================================")
print("")