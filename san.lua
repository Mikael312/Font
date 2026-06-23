local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local camera = cloneref(workspace).CurrentCamera
local Lighting = cloneref(game:GetService("Lighting"))

local C = {
    white     = Color3.fromRGB(255, 255, 255),
    black     = Color3.fromRGB(0, 0, 0),
    coal      = Color3.fromRGB(18, 18, 20),
    graphite  = Color3.fromRGB(28, 28, 30),
    steel     = Color3.fromRGB(43, 43, 43),
    silver    = Color3.fromRGB(197, 194, 195),
    mauve     = Color3.fromRGB(117, 98, 101),
    rose      = Color3.fromRGB(242, 75, 103),
    yellow    = Color3.fromRGB(205, 198, 75),
    grey      = Color3.fromRGB(99, 99, 102),
    obsidian  = Color3.fromRGB(10, 10, 11),
    cool      = Color3.fromRGB(166, 138, 145),
    gold      = Color3.fromRGB(212, 175, 55),
    green     = Color3.fromRGB(80, 200, 120),
    red       = Color3.fromRGB(255, 80, 80),
    ivory     = Color3.fromRGB(255, 255, 240),
}

local configPath = "Linux/config.json"
local Config = {}

local function SaveConfig()
    if not isfolder("Linux") then makefolder("Linux") end
    writefile(configPath, HttpService:JSONEncode(Config))
end

local function LoadConfig()
    if isfile(configPath) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(configPath))
        end)
        if success and data then Config = data end
    end
end

LoadConfig()

local activeNotifications = {}
local NOTIF_HEIGHT = 52
local NOTIF_SPACING = 8
local MAX_NOTIFS = 4

local NotifTypes = {
    Info    = { color = Color3.fromRGB(80, 170, 255),  icon = "rbxassetid://120213151644791" },
    Alert   = { color = Color3.fromRGB(220, 40,  40),  icon = "rbxassetid://101056990277297" },
    Success = { color = Color3.fromRGB(80, 200, 120),  icon = "rbxassetid://80709093925104"  },
    Default = { color = Color3.fromRGB(180, 140, 255), icon = "rbxassetid://120213151644791" },
    Warn    = { color = Color3.fromRGB(220, 40,  40),  icon = "rbxassetid://119470614664959" },
}

local function updateNotificationPositions()
    for i, notifData in ipairs(activeNotifications) do
        local newYPos = 20 + ((i - 1) * (NOTIF_HEIGHT + NOTIF_SPACING))
        TweenService:Create(notifData.frame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -315, 0, newYPos)
        }):Play()
    end
end

local function removeNotification(notifData)
    for i, data in ipairs(activeNotifications) do
        if data == notifData then table.remove(activeNotifications, i) break end
    end
    updateNotificationPositions()
end

local function showNotification(opts)
    opts = opts or {}
    local message  = opts.message or ""
    local subtitle = opts.subtitle or ""
    local ntype    = NotifTypes[opts.type] or NotifTypes.Default
    local color    = ntype.color
    local icon     = ntype.icon

    if #activeNotifications >= MAX_NOTIFS then
        local oldest = activeNotifications[1]
        if oldest.barTween then oldest.barTween:Cancel() end
        table.remove(activeNotifications, 1)
        updateNotificationPositions()
        TweenService:Create(oldest.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 20, 0, oldest.frame.Position.Y.Offset),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.3, function() oldest.frame:Destroy() end)
    end

    local notifGui = game:GetService("CoreGui"):FindFirstChild("Notifications")
    if not notifGui then
        notifGui = Instance.new("ScreenGui")
        notifGui.Name = "Notifications"
        notifGui.ResetOnSpawn = false
        notifGui.Parent = game:GetService("CoreGui")
    end

    local startYPos = 20 + (#activeNotifications * (NOTIF_HEIGHT + NOTIF_SPACING))

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(0, 300, 0, NOTIF_HEIGHT)
    notif.Position = UDim2.new(1, 20, 0, startYPos)
    notif.BackgroundColor3 = C.coal
    notif.BackgroundTransparency = 1
    notif.BorderSizePixel = 0
    notif.Active = true
    notif.Parent = notifGui
    Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 6)

    local nStroke = Instance.new("UIStroke", notif)
    nStroke.Thickness = 1
    nStroke.Color = C.steel
    nStroke.Transparency = 0.7

    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Size = UDim2.new(0, 20, 0, 20)
    iconLabel.Position = UDim2.new(0, 14, 0.5, -10)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = icon
    iconLabel.ImageColor3 = color
    iconLabel.ZIndex = 2
    iconLabel.Parent = notif

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -46, 0, 16)
    textLabel.Position = UDim2.new(0, 42, 0, 10)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextColor3 = C.white
    textLabel.TextSize = 12
    textLabel.Font = Enum.Font.BuilderSans
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextWrapped = false
    textLabel.ZIndex = 2
    textLabel.Parent = notif

    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(1, -46, 0, 13)
    subLabel.Position = UDim2.new(0, 42, 0, 28)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = subtitle
    subLabel.TextColor3 = C.grey
    subLabel.TextSize = 11
    subLabel.Font = Enum.Font.BuilderSans
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.TextWrapped = false
    subLabel.ZIndex = 2
    subLabel.Parent = notif

    local barContainer = Instance.new("Frame")
    barContainer.Size = UDim2.new(1, 0, 0, 2)
    barContainer.Position = UDim2.new(0, 0, 1, -2)
    barContainer.BackgroundTransparency = 1
    barContainer.ZIndex = 2
    barContainer.Parent = notif

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    progressBar.BackgroundColor3 = color
    progressBar.BorderSizePixel = 0
    progressBar.ZIndex = 2
    progressBar.Parent = barContainer
    Instance.new("UICorner", progressBar).CornerRadius = UDim.new(0, 2)

    local notifData = { frame = notif, progressBar = progressBar, barTween = nil }
    table.insert(activeNotifications, notifData)

    TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -315, 0, startYPos),
        BackgroundTransparency = 0
    }):Play()

    local duration = 2.5
    local barTween = TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 1, 0)
    })
    notifData.barTween = barTween
    barTween:Play()

    local function dismiss()
        if notifData.barTween then notifData.barTween:Cancel() end
        if notif.Parent then
            TweenService:Create(notif, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 20, 0, notif.Position.Y.Offset),
                BackgroundTransparency = 1
            }):Play()
            task.delay(0.35, function() if notif.Parent then notif:Destroy() end end)
            removeNotification(notifData)
        end
    end

    notif.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dismiss()
        end
    end)

    task.delay(duration, dismiss)
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Linux"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = game.CoreGui

local dynamicIsland = Instance.new("Frame")
dynamicIsland.Name = "DynamicIsland"
dynamicIsland.Size = UDim2.new(0, 158, 0, 32)
dynamicIsland.Position = UDim2.new(0.5, -79, 0, 6)
dynamicIsland.BackgroundColor3 = C.black
dynamicIsland.BorderSizePixel = 0
dynamicIsland.ClipsDescendants = true
dynamicIsland.Active = false
dynamicIsland.Parent = screenGui
Instance.new("UICorner", dynamicIsland).CornerRadius = UDim.new(1, 0)

dynamicIsland.Size = UDim2.new(0, 80, 0, 32)
dynamicIsland.Position = UDim2.new(0.5, -40, 0, 6)
dynamicIsland.BackgroundTransparency = 1

TweenService:Create(dynamicIsland, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 158, 0, 32),
    Position = UDim2.new(0.5, -79, 0, 6),
    BackgroundTransparency = 0
}):Play()

local islandStroke = Instance.new("UIStroke", dynamicIsland)
islandStroke.Color = C.steel
islandStroke.Thickness = 1
islandStroke.Transparency = 0.6

local islandIcon = Instance.new("ImageLabel")
islandIcon.Size = UDim2.new(0, 22, 0, 22)
islandIcon.Position = UDim2.new(0, 10, 0.5, -11)
islandIcon.BackgroundTransparency = 1
islandIcon.Image = "rbxassetid://93121632026559"
islandIcon.Parent = dynamicIsland
Instance.new("UICorner", islandIcon).CornerRadius = UDim.new(1, 0)

local islandIconStroke = Instance.new("UIStroke", islandIcon)
islandIconStroke.Color = C.steel
islandIconStroke.Thickness = 1
islandIconStroke.Transparency = 0.5

local waveContainer = Instance.new("Frame")
waveContainer.Name = "WaveContainer"
waveContainer.Size = UDim2.new(0, 28, 0, 16)
waveContainer.Position = UDim2.new(1, -38, 0.5, -8)
waveContainer.AnchorPoint = Vector2.new(0, 0)
waveContainer.BackgroundTransparency = 1
waveContainer.Parent = dynamicIsland

local bars = {}
local barCount = 5
local barWidth = 2 
local barGap = 3    

for i = 1, barCount do
    local bar = Instance.new("Frame")
    bar.Name = "Bar" .. i
    bar.Size = UDim2.new(0, barWidth, 0, 4)
    bar.Position = UDim2.new(0, (i - 1) * (barWidth + barGap), 0.5, 0)
    bar.AnchorPoint = Vector2.new(0, 0.5)
    bar.BackgroundColor3 = C.white
    bar.BorderSizePixel = 0
    bar.Parent = waveContainer
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.ivory),
        ColorSequenceKeypoint.new(1, C.mauve)
    })
    grad.Rotation = 90
    grad.Parent = bar

    bars[i] = bar
end

local function animateBar(bar)
    local targetH = math.random(3, 14)
    TweenService:Create(bar, TweenInfo.new(
        math.random(15, 35) / 100,
        Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut
    ), {
        Size = UDim2.new(0, barWidth, 0, targetH)
    }):Play()
end

task.spawn(function()
    while true do
        for _, bar in ipairs(bars) do
            animateBar(bar)
        end
        task.wait(0.25)
    end
end)

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(0, 60, 0, 32)
timeLabel.Position = UDim2.new(0.5, -145, 0, 6)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "00:00"
timeLabel.TextColor3 = C.white
timeLabel.TextSize = 12
timeLabel.Font = Enum.Font.BuilderSans
timeLabel.TextXAlignment = Enum.TextXAlignment.Right
timeLabel.Parent = screenGui

local fpsLabel = Instance.new("TextLabel")
fpsLabel.Size = UDim2.new(0, 60, 0, 32)
fpsLabel.Position = UDim2.new(0.5, 52, 0, 6)
fpsLabel.BackgroundTransparency = 1
fpsLabel.Text = "-- fps"
fpsLabel.TextColor3 = C.white
fpsLabel.TextSize = 12
fpsLabel.Font = Enum.Font.BuilderSans
fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
fpsLabel.Parent = screenGui

local frames = 0
local last = tick()
RunService.RenderStepped:Connect(function()
    frames += 1
    local now = tick()
    if now - last >= 1 then
        fpsLabel.Text = frames .. " fps"
        frames = 0
        last = now
    end
end)

task.spawn(function()
    while true do
        local t = os.date("*t", os.time())
        timeLabel.Text = string.format("%02d:%02d", t.hour, t.min)
        task.wait(1)
    end
end)

local islandNotifying = false

local function islandMenuNotify(text)
    if islandNotifying then return end
    islandNotifying = true
    
    local dotColor = text == "Menu Closed" and C.red or C.green
    islandIcon.Visible = false
    waveContainer.Visible = false

    TweenService:Create(dynamicIsland, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 100, 0, 32),
        Position = UDim2.new(0.5, -50, 0, 6)
    }):Play()
    TweenService:Create(timeLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -117, 0, 6)
    }):Play()
    TweenService:Create(fpsLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 23, 0, 6)
    }):Play()

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 8, 0, 8)
    dot.Position = UDim2.new(0, 14, 0.5, -4)
    dot.BackgroundColor3 = dotColor
    dot.BorderSizePixel = 0
    dot.ZIndex = 5
    dot.Parent = dynamicIsland
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local menuLabel = Instance.new("TextLabel")
    menuLabel.Size = UDim2.new(1, -30, 1, 0)
    menuLabel.AnchorPoint = Vector2.new(0, 0.5)
    menuLabel.Position = UDim2.new(0, 24, 0.5, 0)
    menuLabel.BackgroundTransparency = 1
    menuLabel.Text = text
    menuLabel.TextColor3 = C.white
    menuLabel.TextSize = 12
    menuLabel.Font = Enum.Font.BuilderSans
    menuLabel.TextXAlignment = Enum.TextXAlignment.Center
    menuLabel.ZIndex = 5
    menuLabel.Parent = dynamicIsland

    task.delay(1.5, function()
        dot:Destroy()
        menuLabel:Destroy()
        islandIcon.Visible = true
        waveContainer.Visible = true
        TweenService:Create(dynamicIsland, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 158, 0, 32),
            Position = UDim2.new(0.5, -79, 0, 6)
        }):Play()
        TweenService:Create(timeLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, -145, 0, 6)
        }):Play()
        TweenService:Create(fpsLabel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 53, 0, 6)
        }):Play()
        islandNotifying = false
    end)
end

local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.new(0, 780, 0, 620)
window.BackgroundColor3 = C.black
window.BackgroundTransparency = 0.03
window.BorderSizePixel = 0
window.Active = true
window.Parent = screenGui
Instance.new("UICorner", window).CornerRadius = UDim.new(0, 14)

local windowScale = Instance.new("UIScale")
windowScale.Scale = 0.95
windowScale.Parent = window

window.BackgroundTransparency = 1
window.Size = UDim2.new(0, 780, 0, 620)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.new(0.5, 0, 0.5, 0)

local function launchWindow()
    window.Visible = true
    windowScale.Scale = 0.95
    window.BackgroundTransparency = 1
    TweenService:Create(windowScale, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Scale = 1
    }):Play()
    TweenService:Create(window, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.03
    }):Play()
end

launchWindow()

local globalFade = Instance.new("Frame")
globalFade.Name = "GlobalFade"
globalFade.Size = UDim2.new(1, -205, 0, 40)
globalFade.Position = UDim2.new(0, 205, 1, -40)
globalFade.BackgroundColor3 = C.black
globalFade.BackgroundTransparency = 0.3
globalFade.BorderSizePixel = 0
globalFade.ZIndex = 10
globalFade.ClipsDescendants = true
globalFade.Parent = window
Instance.new("UICorner", globalFade).CornerRadius = UDim.new(0, 14)

local globalFadeGrad = Instance.new("UIGradient")
globalFadeGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(1, 0)
})
globalFadeGrad.Rotation = 90
globalFadeGrad.Parent = globalFade

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.Position = UDim2.new(0, 0, 0, 0)
sidebar.Size = UDim2.new(0, 205, 1, 0)
sidebar.BackgroundColor3 = C.obsidian
sidebar.BackgroundTransparency = 0.6
sidebar.BorderSizePixel = 0
sidebar.Parent = window
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 14)

local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.new(1, -32, 0, 1)
divider.Position = UDim2.new(0, 16, 0, 60)
divider.BackgroundColor3 = C.steel
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel = 0
divider.Parent = sidebar

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundTransparency = 1
header.Parent = sidebar

local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.Size = UDim2.new(0, 36, 0, 36)
logo.Position = UDim2.new(0, 16, 0.5, -18)
logo.BackgroundTransparency = 1
logo.Image = "rbxassetid://123017704463941"
logo.Parent = header
Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0, 200, 0, 20)
title.Position = UDim2.new(0, 62, 0.5, -19)
title.BackgroundTransparency = 1
title.Text = "Linux"
title.TextColor3 = C.white
title.TextSize = 18
title.Font = Enum.Font.BuilderSansBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(0, 200, 0, 16)
subtitle.Position = UDim2.new(0, 62, 0.5, 1)
subtitle.BackgroundTransparency = 1
subtitle.Text = "by @Interface"
subtitle.TextColor3 = C.grey
subtitle.TextSize = 12
subtitle.Font = Enum.Font.BuilderSans
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local topbar = Instance.new("Frame")
topbar.Name = "Topbar"
topbar.Size = UDim2.new(1, -205, 0, 44)
topbar.Position = UDim2.new(0, 205, 0, 0)
topbar.BackgroundTransparency = 1
topbar.BorderSizePixel = 0
topbar.Parent = window

local topbarLayout = Instance.new("UIListLayout")
topbarLayout.FillDirection = Enum.FillDirection.Horizontal
topbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
topbarLayout.Padding = UDim.new(0, 6)
topbarLayout.Parent = topbar

local topbarPadding = Instance.new("UIPadding")
topbarPadding.PaddingLeft = UDim.new(0, 16)
topbarPadding.Parent = topbar

local topbarDivider = Instance.new("Frame")
topbarDivider.Size = UDim2.new(1, -229, 0, 1)
topbarDivider.Position = UDim2.new(0, 217, 0, 44)
topbarDivider.BackgroundColor3 = C.steel
topbarDivider.BackgroundTransparency = 0.5
topbarDivider.BorderSizePixel = 0
topbarDivider.Parent = window

local topbarIcon = Instance.new("ImageLabel")
topbarIcon.Name = "Icon"
topbarIcon.Size = UDim2.new(0, 16, 0, 16)
topbarIcon.BackgroundTransparency = 1
topbarIcon.ImageColor3 = C.grey
topbarIcon.Parent = topbar

local topbarMain = Instance.new("TextLabel")
topbarMain.Name = "Main"
topbarMain.Size = UDim2.new(0, 0, 1, 0)
topbarMain.AutomaticSize = Enum.AutomaticSize.X
topbarMain.BackgroundTransparency = 1
topbarMain.Text = ""
topbarMain.TextColor3 = C.grey
topbarMain.TextSize = 13
topbarMain.Font = Enum.Font.BuilderSans
topbarMain.TextXAlignment = Enum.TextXAlignment.Left
topbarMain.Parent = topbar

local topbarSep = Instance.new("TextLabel")
topbarSep.Name = "Sep"
topbarSep.Size = UDim2.new(0, 10, 1, 0)
topbarSep.BackgroundTransparency = 1
topbarSep.Text = "/"
topbarSep.TextColor3 = C.grey
topbarSep.TextSize = 13
topbarSep.Font = Enum.Font.BuilderSans
topbarSep.TextXAlignment = Enum.TextXAlignment.Center
topbarSep.Visible = false
topbarSep.Parent = topbar

local topbarSub = Instance.new("TextLabel")
topbarSub.Name = "Sub"
topbarSub.Size = UDim2.new(0, 0, 1, 0)
topbarSub.AutomaticSize = Enum.AutomaticSize.X
topbarSub.BackgroundTransparency = 1
topbarSub.Text = ""
topbarSub.TextColor3 = C.white
topbarSub.TextSize = 13
topbarSub.Font = Enum.Font.BuilderSansBold
topbarSub.TextXAlignment = Enum.TextXAlignment.Left
topbarSub.Visible = false
topbarSub.Parent = topbar

local searchBar = Instance.new("Frame")
searchBar.Name = "SearchBar"
searchBar.Size = UDim2.new(0, 180, 0, 30)
searchBar.Position = UDim2.new(1, -192, 0, 7)
searchBar.BackgroundColor3 = C.graphite
searchBar.BackgroundTransparency = 0.3
searchBar.BorderSizePixel = 0
searchBar.Parent = window
Instance.new("UICorner", searchBar).CornerRadius = UDim.new(0, 8)

local searchIcon = Instance.new("ImageLabel")
searchIcon.Size = UDim2.new(0, 14, 0, 14)
searchIcon.Position = UDim2.new(0, 10, 0.5, -7)
searchIcon.BackgroundTransparency = 1
searchIcon.Image = "rbxassetid://96045630034755"
searchIcon.ImageColor3 = C.grey
searchIcon.Parent = searchBar

local searchInput = Instance.new("TextBox")
searchInput.Name = "Input"
searchInput.Size = UDim2.new(1, -32, 1, 0)
searchInput.Position = UDim2.new(0, 28, 0, 0)
searchInput.BackgroundTransparency = 1
searchInput.Text = ""
searchInput.PlaceholderText = "Search..."
searchInput.PlaceholderColor3 = C.grey
searchInput.TextColor3 = C.white
searchInput.TextSize = 12
searchInput.Font = Enum.Font.BuilderSans
searchInput.TextXAlignment = Enum.TextXAlignment.Left
searchInput.ClearTextOnFocus = false
searchInput.Parent = searchBar

local searchHint = Instance.new("Frame")
searchHint.Size = UDim2.new(0, 32, 0, 20)
searchHint.Position = UDim2.new(1, -38, 0.5, -10)
searchHint.BackgroundColor3 = C.steel
searchHint.BackgroundTransparency = 0.5
searchHint.BorderSizePixel = 0
searchHint.Parent = searchBar
Instance.new("UICorner", searchHint).CornerRadius = UDim.new(0, 6)

local hintIcon = Instance.new("ImageLabel")
hintIcon.Size = UDim2.new(0, 12, 0, 12)
hintIcon.Position = UDim2.new(0, 6, 0.5, -6)
hintIcon.BackgroundTransparency = 1
hintIcon.Image = "rbxassetid://122538551810718"
hintIcon.ImageColor3 = C.white
hintIcon.Parent = searchHint

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(0, 14, 1, 0)
hintLabel.Position = UDim2.new(0, 22, 0, 0)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "F"
hintLabel.TextColor3 = C.white
hintLabel.TextSize = 11
hintLabel.Font = Enum.Font.BuilderSans
hintLabel.TextXAlignment = Enum.TextXAlignment.Left
hintLabel.Parent = searchHint

local searchTooltip = Instance.new("Frame")
searchTooltip.Size = UDim2.new(0, 58, 0, 22)
searchTooltip.Position = UDim2.new(1, -62, 1, 6)
searchTooltip.BackgroundColor3 = C.graphite
searchTooltip.BackgroundTransparency = 0.1
searchTooltip.BorderSizePixel = 0
searchTooltip.Visible = false
searchTooltip.ZIndex = 10
searchTooltip.Parent = searchBar
Instance.new("UICorner", searchTooltip).CornerRadius = UDim.new(1, 0)

local tooltipText = Instance.new("TextLabel")
tooltipText.Size = UDim2.new(1, 0, 1, 0)
tooltipText.BackgroundTransparency = 1
tooltipText.Text = "Ctrl + F"
tooltipText.TextColor3 = C.white
tooltipText.TextSize = 11
tooltipText.Font = Enum.Font.BuilderSans
tooltipText.ZIndex = 10
tooltipText.Parent = searchTooltip

searchHint.MouseEnter:Connect(function()
    searchTooltip.Visible = true
end)
searchHint.MouseLeave:Connect(function()
    searchTooltip.Visible = false
end)

searchInput.Focused:Connect(function()
    searchHint.Visible = false
    TweenService:Create(searchBar, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 220, 0, 30),
        Position = UDim2.new(1, -232, 0, 7),
        BackgroundTransparency = 0
    }):Play()
    TweenService:Create(searchIcon, TweenInfo.new(0.2), {ImageColor3 = C.white}):Play()
end)
searchInput.FocusLost:Connect(function()
    searchHint.Visible = true
    TweenService:Create(searchBar, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 180, 0, 30),
        Position = UDim2.new(1, -192, 0, 7),
        BackgroundTransparency = 0.3
    }):Play()
    TweenService:Create(searchIcon, TweenInfo.new(0.2), {ImageColor3 = C.grey}):Play()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F and
       (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
       or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
       or UserInputService:IsKeyDown(Enum.KeyCode.LeftSuper)) then
        searchInput:CaptureFocus()
    end
end)

local currentTab = nil
local tabs = {
    {name = "Player", icon = "rbxassetid://114518874508189", subtabs = {
        {name = "Movement", icon = "rbxassetid://108996706461959"},
        {name = "Combat",   icon = "rbxassetid://85263148845888"},
    }},
    {name = "Ragebot", icon = "rbxassetid://92899287223414"},
    {name = "Visual",  icon = "rbxassetid://82139990305722"},
    {name = "Effects", icon = "rbxassetid://102083890722557"},
}
local tabButtons = {}
local tabContents = {}
local firstLoad = true
local expandedStates = {}

local indicator = Instance.new("Frame")
indicator.Name = "Indicator"
indicator.Size = UDim2.new(1, -16, 0, 32)
indicator.Position = UDim2.new(0, 8, 0, 0)
indicator.BackgroundColor3 = C.graphite
indicator.BackgroundTransparency = 1
indicator.BorderSizePixel = 0
indicator.ZIndex = 1
indicator.Visible = false
indicator.Parent = sidebar
Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 8)

local sidebarContainer = Instance.new("ScrollingFrame")
sidebarContainer.Name = "SidebarContainer"
sidebarContainer.Position = UDim2.new(0, 0, 0, 68)
sidebarContainer.Size = UDim2.new(1, 0, 1, -68)
sidebarContainer.BackgroundTransparency = 1
sidebarContainer.BorderSizePixel = 0
sidebarContainer.ScrollBarThickness = 0
sidebarContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
sidebarContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebarContainer.Parent = sidebar

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 4)
sidebarLayout.Parent = sidebarContainer

local sidebarPadding = Instance.new("UIPadding")
sidebarPadding.PaddingLeft = UDim.new(0, 8)
sidebarPadding.PaddingRight = UDim.new(0, 8)
sidebarPadding.Parent = sidebarContainer

local function updateTopbar(tabName)
    topbarIcon.Visible = true
    topbarMain.TextSize = 13
    topbarMain.Font = Enum.Font.BuilderSans

    local isSubTab = tabName:find("_")
    if isSubTab then
        local parts = tabName:split("_")
        local mainName = parts[1]
        local subName = parts[2]
        for _, t in ipairs(tabs) do
            if t.name == mainName then
                topbarIcon.Image = t.icon
                break
            end
        end
        topbarMain.Text = mainName
        topbarMain.TextColor3 = C.grey
        topbarSep.Visible = true
        topbarSub.Visible = true
        topbarSub.Text = subName
    else
        for _, t in ipairs(tabs) do
            if t.name == tabName then
                topbarIcon.Image = t.icon
                break
            end
        end
        topbarMain.Text = tabName
        topbarMain.TextColor3 = C.white
        topbarSep.Visible = false
        topbarSub.Visible = false
    end
end

local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.Size = UDim2.new(1, -16, 0, 42)
bottomBar.Position = UDim2.new(0, 8, 1, -56)
bottomBar.BackgroundColor3 = C.coal
bottomBar.BackgroundTransparency = 0.03
bottomBar.BorderSizePixel = 0
bottomBar.Active = true
bottomBar.Parent = sidebar
Instance.new("UICorner", bottomBar).CornerRadius = UDim.new(0, 12)

local bottomStroke = Instance.new("UIStroke", bottomBar)
bottomStroke.Color = C.steel
bottomStroke.Thickness = 1.2
bottomStroke.Transparency = 0.6

local profileImg = Instance.new("ImageLabel")
profileImg.Name = "Profile"
profileImg.Size = UDim2.new(0, 28, 0, 28)
profileImg.Position = UDim2.new(0, 10, 0.5, -14)
profileImg.BackgroundTransparency = 1
profileImg.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
profileImg.Parent = bottomBar
Instance.new("UICorner", profileImg).CornerRadius = UDim.new(1, 0)

local profileName = Instance.new("TextLabel")
profileName.Size = UDim2.new(1, -80, 0, 16)
profileName.Position = UDim2.new(0, 46, 0.5, -14)
profileName.BackgroundTransparency = 1
profileName.Text = LocalPlayer.DisplayName
profileName.TextColor3 = C.white
profileName.TextSize = 13
profileName.Font = Enum.Font.BuilderSansBold
profileName.TextXAlignment = Enum.TextXAlignment.Left
profileName.Parent = bottomBar

local profileSub = Instance.new("TextLabel")
profileSub.Size = UDim2.new(1, -80, 0, 13)
profileSub.Position = UDim2.new(0, 46, 0.5, 1)
profileSub.BackgroundTransparency = 1
profileSub.Text = LocalPlayer.Name
profileSub.TextColor3 = C.grey
profileSub.TextSize = 11
profileSub.Font = Enum.Font.BuilderSans
profileSub.TextXAlignment = Enum.TextXAlignment.Left
profileSub.Parent = bottomBar

local bottomIcon = Instance.new("ImageLabel")
bottomIcon.Name = "BottomIcon"
bottomIcon.Size = UDim2.new(0, 20, 0, 20)
bottomIcon.Position = UDim2.new(1, -30, 0.5, -10)
bottomIcon.BackgroundTransparency = 1
bottomIcon.Image = "rbxassetid://72165523373713"
bottomIcon.ImageColor3 = C.grey
bottomIcon.Parent = bottomBar

local function getTabY(targetTabName, targetIsSub)
    local y = 68
    for _, tabData in ipairs(tabs) do
        local isExpanded = expandedStates[tabData.name]
        if tabData.name == targetTabName and not targetIsSub then
            return y
        end
        y = y + 36 + 4
        if tabData.subtabs and isExpanded then
            for si, sub in ipairs(tabData.subtabs) do
                local subKey = tabData.name .. "_" .. sub.name
                if subKey == targetTabName and targetIsSub then
                    return y
                end
                y = y + 38
            end
        end
    end
    return y
end

local function moveIndicator(btn, isSub)
    task.spawn(function()
        task.wait()
        indicator.Visible = true
        local targetY = getTabY(currentTab, isSub)
        local targetSize = isSub and UDim2.new(1, -28, 0, 28) or UDim2.new(1, -16, 0, 32)
        local targetPos = isSub and UDim2.new(0, 14, 0, targetY + 1) or UDim2.new(0, 8, 0, targetY + 2)
        if firstLoad then
            firstLoad = false
            indicator.Size = targetSize
            indicator.Position = targetPos
            TweenService:Create(indicator, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        else
            TweenService:Create(indicator, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = targetSize,
                Position = targetPos,
                BackgroundTransparency = 0
            }):Play()
        end
    end)
end

local function selectTab(tabName, isSub)
    searchBar.Visible = true
    topbarDivider.Visible = true
    TweenService:Create(indicator, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0
    }):Play()

    for name, frame in pairs(tabContents) do
        frame.Visible = false
    end
    for name, btn in pairs(tabButtons) do
        if btn:FindFirstChild("Icon") then btn.Icon.ImageColor3 = C.grey end
        if btn:FindFirstChild("Label") then btn.Label.TextColor3 = C.grey end
    end

    for _, tabData in ipairs(tabs) do
        if tabData.subtabs then
            local mainTabName = tabData.name
            if tabName ~= mainTabName and not tabName:find("^" .. mainTabName .. "_") then
                local wrapper = sidebarContainer:FindFirstChild(mainTabName .. "Wrapper")
                local tabBtnRef = wrapper and wrapper:FindFirstChild(mainTabName .. "Tab")
                local arrow = tabBtnRef and tabBtnRef:FindFirstChild("Arrow")
                if wrapper then
                    TweenService:Create(wrapper, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 0, 0, 36)
                    }):Play()
                end
                if arrow then
                    TweenService:Create(arrow, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                        Rotation = 0
                    }):Play()
                end
                expandedStates[mainTabName] = false
            end
        end
    end

    if tabContents[tabName] then
        local content = tabContents[tabName]
        content.Position = UDim2.new(0, 205, 0, 53)
        content.Visible = true
        TweenService:Create(content, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 205, 0, 45)
        }):Play()
    end

    local btn = tabButtons[tabName]
    if btn then
        if btn:FindFirstChild("Icon") then btn.Icon.ImageColor3 = C.white end
        if btn:FindFirstChild("Label") then btn.Label.TextColor3 = C.white end
        moveIndicator(btn, isSub)
    end

    updateTopbar(tabName)
    currentTab = tabName
end

local function createTabContent(name)
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = name .. "Content"
    contentFrame.Size = UDim2.new(1, -205, 1, -45)
    contentFrame.Position = UDim2.new(0, 205, 0, 45)
    contentFrame.BackgroundTransparency = 1
    contentFrame.BorderSizePixel = 0
    contentFrame.Visible = false
    contentFrame.Parent = window

    local leftScroll = Instance.new("ScrollingFrame")
    leftScroll.Name = "LeftScroll"
    leftScroll.Size = UDim2.new(0.5, -8, 1, 0)
    leftScroll.Position = UDim2.new(0, 6, 0, 0)
    leftScroll.BackgroundTransparency = 1
    leftScroll.BorderSizePixel = 0
    leftScroll.ScrollBarThickness = 0
    leftScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    leftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    leftScroll.Parent = contentFrame

    local leftLayout = Instance.new("UIListLayout")
    leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
    leftLayout.Padding = UDim.new(0, 5)
    leftLayout.Parent = leftScroll

    local leftPadding = Instance.new("UIPadding")
    leftPadding.PaddingTop = UDim.new(0, 12)
    leftPadding.PaddingLeft = UDim.new(0, 6)
    leftPadding.PaddingRight = UDim.new(0, 4)
    leftPadding.Parent = leftScroll

    local rightScroll = Instance.new("ScrollingFrame")
    rightScroll.Name = "RightScroll"
    rightScroll.Size = UDim2.new(0.5, -8, 1, 0)
    rightScroll.Position = UDim2.new(0.5, 2, 0, 0)
    rightScroll.BackgroundTransparency = 1
    rightScroll.BorderSizePixel = 0
    rightScroll.ScrollBarThickness = 0
    rightScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    rightScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    rightScroll.Parent = contentFrame

    local rightLayout = Instance.new("UIListLayout")
    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rightLayout.Padding = UDim.new(0, 5)
    rightLayout.Parent = rightScroll

    local rightPadding = Instance.new("UIPadding")
    rightPadding.PaddingTop = UDim.new(0, 12)
    rightPadding.PaddingLeft = UDim.new(0, 4)
    rightPadding.PaddingRight = UDim.new(0, 6)
    rightPadding.Parent = rightScroll

    return contentFrame
end

local function createGroup(parent, groupName, column)
    local targetScroll = column == "right"
        and parent:FindFirstChild("RightScroll")
        or parent:FindFirstChild("LeftScroll")

    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, 0, 0, 0)
    wrapper.AutomaticSize = Enum.AutomaticSize.Y
    wrapper.BackgroundTransparency = 1
    wrapper.LayoutOrder = #targetScroll:GetChildren()
    wrapper.Parent = targetScroll

    local wrapperLayout = Instance.new("UIListLayout")
    wrapperLayout.SortOrder = Enum.SortOrder.LayoutOrder
    wrapperLayout.Padding = UDim.new(0, 5)
    wrapperLayout.Parent = wrapper

    local groupLabel = Instance.new("TextLabel")
    groupLabel.Size = UDim2.new(1, 0, 0, 18)
    groupLabel.BackgroundTransparency = 1
    groupLabel.Text = groupName
    groupLabel.TextColor3 = C.grey
    groupLabel.Font = Enum.Font.BuilderSans
    groupLabel.TextSize = 13
    groupLabel.TextXAlignment = Enum.TextXAlignment.Left
    groupLabel.LayoutOrder = 1
    groupLabel.Parent = wrapper

    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = C.coal
    card.BackgroundTransparency = 0.5
    card.BorderSizePixel = 0
    card.LayoutOrder = 2
    card.ClipsDescendants = true
    card.Parent = wrapper
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local cardStroke = Instance.new("UIStroke", card)
    cardStroke.Color = C.steel
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.7
    
    local cardLayout = Instance.new("UIListLayout")
    cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cardLayout.Padding = UDim.new(0, 0)
    cardLayout.Parent = card

    local cardPadding = Instance.new("UIPadding")
    cardPadding.PaddingTop = UDim.new(0, 4)
    cardPadding.PaddingBottom = UDim.new(0, 4)
    cardPadding.Parent = card

    cardLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    local rows = {}
    for _, child in ipairs(card:GetChildren()) do
        if child:IsA("Frame") then
            table.insert(rows, child)
        end
    end
    table.sort(rows, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    
    for i, child in ipairs(rows) do
        local existing = child:FindFirstChild("Divider")
        if i < #rows then
            if not existing then
                local divider = Instance.new("Frame")
                divider.Name = "Divider"
                divider.Size = UDim2.new(1, -24, 0, 1)
                divider.Position = UDim2.new(0, 12, 1, -1)
                divider.BackgroundColor3 = C.steel
                divider.BackgroundTransparency = 0.7
                divider.BorderSizePixel = 0
                divider.Parent = child
            end
        else
            if existing then existing:Destroy() end
        end
    end
end)
    return card
end

local function createTab(tabData, layoutOrder)
    local tabName = tabData.name
    local tabIcon = tabData.icon
    local hasSubtabs = tabData.subtabs ~= nil

    local wrapper = Instance.new("Frame")
    wrapper.Name = tabName .. "Wrapper"
    wrapper.Size = UDim2.new(1, 0, 0, 36)
    wrapper.BackgroundTransparency = 1
    wrapper.BorderSizePixel = 0
    wrapper.LayoutOrder = layoutOrder
    wrapper.ClipsDescendants = true
    wrapper.Parent = sidebarContainer

    local wrapperLayout = Instance.new("UIListLayout")
    wrapperLayout.SortOrder = Enum.SortOrder.LayoutOrder
    wrapperLayout.Padding = UDim.new(0, 0)
    wrapperLayout.Parent = wrapper

    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName .. "Tab"
    tabBtn.Size = UDim2.new(1, 0, 0, 36)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = ""
    tabBtn.LayoutOrder = 1
    tabBtn.ZIndex = 3
    tabBtn.Parent = wrapper

    local iconLabel = Instance.new("ImageLabel")
    iconLabel.Name = "Icon"
    iconLabel.Size = UDim2.new(0, 16, 0, 16)
    iconLabel.Position = UDim2.new(0, 12, 0.5, -8)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Image = tabIcon
    iconLabel.ImageColor3 = C.grey
    iconLabel.ZIndex = 3
    iconLabel.Parent = tabBtn

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -38, 1, 0)
    label.Position = UDim2.new(0, 34, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tabName
    label.TextColor3 = C.grey
    label.Font = Enum.Font.BuilderSans
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.ZIndex = 3
    label.Parent = tabBtn

    tabButtons[tabName] = tabBtn

    if hasSubtabs then
        local arrow = Instance.new("ImageLabel")
        arrow.Name = "Arrow"
        arrow.Size = UDim2.new(0, 14, 0, 14)
        arrow.Position = UDim2.new(1, -22, 0.5, -7)
        arrow.BackgroundTransparency = 1
        arrow.Image = "rbxassetid://140136269072191"
        arrow.ImageColor3 = C.grey
        arrow.ZIndex = 3
        arrow.Parent = tabBtn

        expandedStates[tabName] = false

        for si, sub in ipairs(tabData.subtabs) do
            local subBtn = Instance.new("TextButton")
            subBtn.Name = sub.name .. "SubTab"
            subBtn.Size = UDim2.new(1, 0, 0, 38)
            subBtn.BackgroundTransparency = 1
            subBtn.Text = ""
            subBtn.LayoutOrder = si + 1
            subBtn.ZIndex = 3
            subBtn.Parent = wrapper

            local subIcon = Instance.new("ImageLabel")
            subIcon.Name = "Icon"
            subIcon.Size = UDim2.new(0, 14, 0, 14)
            subIcon.Position = UDim2.new(0, 22, 0.5, -7)
            subIcon.BackgroundTransparency = 1
            subIcon.Image = sub.icon
            subIcon.ImageColor3 = C.grey
            subIcon.ZIndex = 3
            subIcon.Parent = subBtn

            local subLabel = Instance.new("TextLabel")
            subLabel.Name = "Label"
            subLabel.Size = UDim2.new(1, -44, 1, 0)
            subLabel.Position = UDim2.new(0, 42, 0, 0)
            subLabel.BackgroundTransparency = 1
            subLabel.Text = sub.name
            subLabel.TextColor3 = C.grey
            subLabel.Font = Enum.Font.BuilderSans
            subLabel.TextSize = 12
            subLabel.TextXAlignment = Enum.TextXAlignment.Left
            subLabel.TextYAlignment = Enum.TextYAlignment.Center
            subLabel.ZIndex = 3
            subLabel.Parent = subBtn

            local subContent = createTabContent(tabName .. "_" .. sub.name)
            tabContents[tabName .. "_" .. sub.name] = subContent
            tabButtons[tabName .. "_" .. sub.name] = subBtn

            subBtn.MouseButton1Click:Connect(function()
                selectTab(tabName .. "_" .. sub.name, true)
            end)
        end

        tabBtn.MouseButton1Click:Connect(function()
            selectTab(tabName, false)
            expandedStates[tabName] = not expandedStates[tabName]
            local totalHeight = 36 + (expandedStates[tabName] and (#tabData.subtabs * 38 + 2) or 0)
            TweenService:Create(wrapper, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, totalHeight)
            }):Play()
            TweenService:Create(arrow, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Rotation = expandedStates[tabName] and 180 or 0
            }):Play()
        end)
    else
        local tabContent = createTabContent(tabName)
        tabContents[tabName] = tabContent

        tabBtn.MouseButton1Click:Connect(function()
            selectTab(tabName, false)
        end)
    end
end

for i, tabData in ipairs(tabs) do
    createTab(tabData, i)
end

selectTab(tabs[1].name, false)

local function createToggle(parent, label, default, callback, configKey)
    local savedVal = configKey and Config[configKey]
    local toggled = (savedVal ~= nil) and savedVal or (default or false)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    row.LayoutOrder = #parent:GetChildren()
    row.Parent = parent

    local rowLabel = Instance.new("TextLabel")
    rowLabel.Size = UDim2.new(1, -58, 1, 0)
    rowLabel.Position = UDim2.new(0, 14, 0, 0)
    rowLabel.BackgroundTransparency = 1
    rowLabel.Text = label
    rowLabel.TextColor3 = C.white
    rowLabel.TextTransparency = 0.35
    rowLabel.Font = Enum.Font.BuilderSans
    rowLabel.TextSize = 13
    rowLabel.TextXAlignment = Enum.TextXAlignment.Left
    rowLabel.TextYAlignment = Enum.TextYAlignment.Center
    rowLabel.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 30, 0, 16)
    track.Position = UDim2.new(1, -43, 0.5, -8)
    track.BackgroundColor3 = Color3.fromRGB(10, 13, 21)
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 12, 0, 12)
    thumb.AnchorPoint = Vector2.new(0, 0)
    thumb.Position = UDim2.new(0, 2, 0, 2)
    thumb.BackgroundColor3 = C.white
    thumb.BackgroundTransparency = 0.5
    thumb.BorderSizePixel = 0
    thumb.Parent = track
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ZIndex = 2
    btn.Parent = row

    local function updateToggle(state, animate)
        toggled = state
        local thumbPos = toggled and UDim2.new(0, 16, 0, 2) or UDim2.new(0, 2, 0, 2)
        local thumbTransp = toggled and 0 or 0.5
        local trackColor = toggled and C.mauve or Color3.fromRGB(10, 13, 21)
        local labelTransp = toggled and 0 or 0.35

        if animate then
            TweenService:Create(thumb, TweenInfo.new(0.175, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = thumbPos,
                BackgroundTransparency = thumbTransp
            }):Play()
            TweenService:Create(track, TweenInfo.new(0.175, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = trackColor
            }):Play()
            TweenService:Create(rowLabel, TweenInfo.new(0.175), {
                TextTransparency = labelTransp
            }):Play()
        else
            thumb.Position = thumbPos
            thumb.BackgroundTransparency = thumbTransp
            track.BackgroundColor3 = trackColor
            rowLabel.TextTransparency = labelTransp
        end

        if callback then callback(toggled) end
        if configKey then
            Config[configKey] = toggled
            task.spawn(SaveConfig)
        end
    end

    updateToggle(toggled, false)

    btn.MouseButton1Click:Connect(function()
        updateToggle(not toggled, true)
    end)

    return row
end

local function createSlider(parent, label, min, max, default, suffix, callback, configKey)
    local savedVal = configKey and Config[configKey]
    local value = (savedVal ~= nil) and savedVal or (default or min)
    local layoutOrder = #parent:GetChildren()

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    row.LayoutOrder = layoutOrder
    row.Parent = parent

    local rowLabel = Instance.new("TextLabel")
    rowLabel.Size = UDim2.new(0.4, 0, 1, 0)
    rowLabel.Position = UDim2.new(0, 14, 0, 0)
    rowLabel.BackgroundTransparency = 1
    rowLabel.Text = label
    rowLabel.TextColor3 = C.white
    rowLabel.TextTransparency = 0.35
    rowLabel.Font = Enum.Font.BuilderSans
    rowLabel.TextSize = 13
    rowLabel.TextXAlignment = Enum.TextXAlignment.Left
    rowLabel.TextYAlignment = Enum.TextYAlignment.Center
    rowLabel.Parent = row

    local valueLabel = Instance.new("TextBox")
    valueLabel.Size = UDim2.new(0, 40, 1, 0)
    valueLabel.Position = UDim2.new(1, -54, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(value) .. (suffix or "")
    valueLabel.TextColor3 = C.grey
    valueLabel.Font = Enum.Font.BuilderSans
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextYAlignment = Enum.TextYAlignment.Center
    valueLabel.ClearTextOnFocus = true
    valueLabel.ZIndex = 3
    valueLabel.Parent = row

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0, 120, 0, 4)
    sliderBg.Position = UDim2.new(0.4, 0, 0.5, -2)
    sliderBg.BackgroundColor3 = C.steel
    sliderBg.BackgroundTransparency = 0.3
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = row
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = C.mauve 
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 11, 0, 11)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
    thumb.BackgroundColor3 = C.silver
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 2
    thumb.Parent = sliderBg
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local function saveValue()
        if configKey then
            Config[configKey] = value
            task.spawn(SaveConfig)
        end
    end

    local function setSlider(newValue)
        value = math.clamp(math.floor(newValue), min, max)
        local delta = (value - min) / (max - min)
        valueLabel.Text = tostring(value) .. (suffix or "")
        TweenService:Create(sliderFill, TweenInfo.new(0.1), {Size = UDim2.new(delta, 0, 1, 0)}):Play()
        TweenService:Create(thumb, TweenInfo.new(0.1), {Position = UDim2.new(delta, 0, 0.5, 0)}):Play()
        if callback then callback(value) end
        saveValue()
    end

    valueLabel.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local input = tonumber(valueLabel.Text)
            if input then
                setSlider(input)
            else
                valueLabel.Text = tostring(value) .. (suffix or "")
            end
        else
            valueLabel.Text = tostring(value) .. (suffix or "")
        end
    end)

    local dragging = false
    local moveConn, releaseConn

    sliderBg.InputBegan:Connect(function(input)
        if dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            local isTouch = input.UserInputType == Enum.UserInputType.Touch
            dragging = true

            local function update()
                local inputX = isTouch and input.Position.X or UserInputService:GetMouseLocation().X
                local delta = math.clamp((inputX - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                local newValue = min + delta * (max - min)
                value = math.clamp(math.floor(newValue), min, max)
                valueLabel.Text = tostring(value) .. (suffix or "")
                TweenService:Create(sliderFill, TweenInfo.new(0.05), {Size = UDim2.new(delta, 0, 1, 0)}):Play()
                TweenService:Create(thumb, TweenInfo.new(0.05), {Position = UDim2.new(delta, 0, 0.5, 0)}):Play()
                if callback then callback(value) end
                saveValue()
            end

            update()
            moveConn = RunService.RenderStepped:Connect(update)
            releaseConn = UserInputService.InputEnded:Connect(function(endInput)
                if endInput == input then
                    if moveConn then moveConn:Disconnect() end
                    if releaseConn then releaseConn:Disconnect() end
                    dragging = false
                end
            end)
        end
    end)

    return row
end

local function createButton(parent, text, callback)
    local wrapper = Instance.new("Frame")
    wrapper.Size = UDim2.new(1, 0, 0, 44)
    wrapper.BackgroundTransparency = 1
    wrapper.LayoutOrder = #parent:GetChildren()
    wrapper.Name = "ButtonRow"
    wrapper.Parent = parent

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -24, 0, 28)
    row.AnchorPoint = Vector2.new(0.5, 0.5)
    row.Position = UDim2.new(0.5, 0, 0.5, 0)
    row.BackgroundTransparency = 0.4
    row.BackgroundColor3 = C.graphite
    row.ClipsDescendants = true
    row.Parent = wrapper
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local btnLabel = Instance.new("TextLabel")
    btnLabel.Size = UDim2.new(1, 0, 1, 0)
    btnLabel.BackgroundTransparency = 1
    btnLabel.Text = text
    btnLabel.TextColor3 = C.white
    btnLabel.Font = Enum.Font.BuilderSans
    btnLabel.TextSize = 12
    btnLabel.ZIndex = 2
    btnLabel.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ZIndex = 3
    btn.Parent = row

    btn.MouseEnter:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.2
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(row, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.4
        }):Play()
    end)
    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    return wrapper
end

local function createInput(parent, label, placeholder, callback, configKey)
    local savedVal = configKey and Config[configKey]
    local value = savedVal or ""

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    row.LayoutOrder = #parent:GetChildren()
    row.Parent = parent

    local rowLabel = Instance.new("TextLabel")
    rowLabel.Size = UDim2.new(0.45, 0, 1, 0)
    rowLabel.Position = UDim2.new(0, 14, 0, 0)
    rowLabel.BackgroundTransparency = 1
    rowLabel.Text = label
    rowLabel.TextColor3 = C.white
    rowLabel.TextTransparency = 0.35
    rowLabel.Font = Enum.Font.BuilderSans
    rowLabel.TextSize = 13
    rowLabel.TextXAlignment = Enum.TextXAlignment.Left
    rowLabel.TextYAlignment = Enum.TextYAlignment.Center
    rowLabel.Parent = row

    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(0.5, -14, 0, 22)
    inputFrame.Position = UDim2.new(0.5, 0, 0.5, -11)
    inputFrame.BackgroundColor3 = C.steel
    inputFrame.BackgroundTransparency = 0.7
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = row
    Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 6)

    local inputStroke = Instance.new("UIStroke", inputFrame)
    inputStroke.Color = C.steel
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.5

    local textbox = Instance.new("TextBox")
    textbox.Size = UDim2.new(1, -16, 1, 0)
    textbox.Position = UDim2.new(0, 8, 0, 0)
    textbox.BackgroundTransparency = 1
    textbox.Text = value
    textbox.PlaceholderText = placeholder or ""
    textbox.PlaceholderColor3 = C.grey
    textbox.TextColor3 = C.white
    textbox.TextSize = 12
    textbox.Font = Enum.Font.BuilderSans
    textbox.TextXAlignment = Enum.TextXAlignment.Left
    textbox.ClearTextOnFocus = false
    textbox.ZIndex = 2
    textbox.Parent = inputFrame

    textbox.Focused:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.2), {
            Color = C.mauve,
            Transparency = 0
        }):Play()
        TweenService:Create(inputFrame, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.5
        }):Play()
    end)

    textbox.FocusLost:Connect(function(enterPressed)
        value = textbox.Text
        TweenService:Create(inputStroke, TweenInfo.new(0.2), {
            Color = C.steel,
            Transparency = 0.5
        }):Play()
        TweenService:Create(inputFrame, TweenInfo.new(0.2), {
            BackgroundTransparency = 0.7
        }):Play()
        if callback then callback(value) end
        if configKey then
            Config[configKey] = value
            task.spawn(SaveConfig)
        end
    end)

    return row
end

local activeDropdown = nil

local function createDropdown(parent, label, options, callback, configKey)
    local savedVal = configKey and Config[configKey]
    local selected = savedVal or {}
    if type(selected) ~= "table" then selected = {} end

    local isOpen = false
    local panel = nil

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 36)
    row.BackgroundTransparency = 1
    row.LayoutOrder = #parent:GetChildren()
    row.Parent = parent

    local rowLabel = Instance.new("TextLabel")
    rowLabel.Size = UDim2.new(0.45, 0, 1, 0)
    rowLabel.Position = UDim2.new(0, 14, 0, 0)
    rowLabel.BackgroundTransparency = 1
    rowLabel.Text = label
    rowLabel.TextColor3 = C.white
    rowLabel.TextTransparency = 0.35
    rowLabel.Font = Enum.Font.BuilderSans
    rowLabel.TextSize = 13
    rowLabel.TextXAlignment = Enum.TextXAlignment.Left
    rowLabel.TextYAlignment = Enum.TextYAlignment.Center
    rowLabel.Parent = row

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.45, -30, 1, 0)
    valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = "..."
    valueLabel.TextColor3 = C.grey
    valueLabel.Font = Enum.Font.BuilderSans
    valueLabel.TextSize = 12
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextYAlignment = Enum.TextYAlignment.Center
    valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
    valueLabel.Parent = row

    local chevron = Instance.new("ImageLabel")
    chevron.Size = UDim2.new(0, 12, 0, 12)
    chevron.Position = UDim2.new(1, -22, 0.5, -6)
    chevron.BackgroundTransparency = 1
    chevron.Image = "rbxassetid://140136269072191"
    chevron.ImageColor3 = C.grey
    chevron.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ZIndex = 2
    btn.Parent = row

    local function getDisplayText()
        if #selected == 0 then return "..." end
        return table.concat(selected, ", ")
    end

    local function updateDisplay()
        valueLabel.Text = getDisplayText()
        valueLabel.TextColor3 = #selected > 0 and C.white or C.grey
    end

    local function saveValue()
        if configKey then
            Config[configKey] = selected
            task.spawn(SaveConfig)
        end
    end

    local function closeDropdown()
        if not panel then return end
        isOpen = false
        activeDropdown = nil
        TweenService:Create(chevron, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Rotation = 0
        }):Play()
        TweenService:Create(panel, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
            Size = UDim2.new(panel.Size.X.Scale, panel.Size.X.Offset, 0, panel.Size.Y.Offset * 0.85)
        }):Play()
        task.delay(0.2, function()
            if panel then panel:Destroy() panel = nil end
        end)
    end

    local function openDropdown()
        if activeDropdown and activeDropdown ~= closeDropdown then
            activeDropdown()
        end
        activeDropdown = closeDropdown
        isOpen = true

        TweenService:Create(chevron, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Rotation = 180
        }):Play()

        local absPos = row.AbsolutePosition
        local absSize = row.AbsoluteSize
        local itemHeight = 32
        local panelHeight = #options * itemHeight + 8

        panel = Instance.new("Frame")
        panel.Name = "DropdownPanel"
        panel.Size = UDim2.new(0, absSize.X - 28, 0, panelHeight * 0.85)
        panel.Position = UDim2.new(0, absPos.X + 14, 0, absPos.Y + absSize.Y + 4)
        panel.BackgroundColor3 = C.graphite
        panel.BackgroundTransparency = 1
        panel.BorderSizePixel = 0
        panel.ZIndex = 50
        panel.ClipsDescendants = true
        panel.Parent = screenGui
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

        local panelLayout = Instance.new("UIListLayout")
        panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
        panelLayout.Padding = UDim.new(0, 0)
        panelLayout.Parent = panel

        local panelPadding = Instance.new("UIPadding")
        panelPadding.PaddingTop = UDim.new(0, 4)
        panelPadding.PaddingBottom = UDim.new(0, 4)
        panelPadding.Parent = panel

        for i, option in ipairs(options) do
            local isSelected = table.find(selected, option) ~= nil

            local itemBtn = Instance.new("TextButton")
            itemBtn.Name = "Item_" .. i
            itemBtn.Size = UDim2.new(1, 0, 0, itemHeight)
            itemBtn.BackgroundTransparency = 1
            itemBtn.AutoButtonColor = false
            itemBtn.Text = ""
            itemBtn.LayoutOrder = i
            itemBtn.ZIndex = 51
            itemBtn.Parent = panel

            local indicator = Instance.new("Frame")
            indicator.Name = "Indicator"
            indicator.Size = UDim2.new(0, 2, 0, 14)
            indicator.Position = UDim2.new(0, 8, 0.5, -7)
            indicator.BackgroundColor3 = C.mauve
            indicator.BackgroundTransparency = isSelected and 0 or 1
            indicator.BorderSizePixel = 0
            indicator.ZIndex = 52
            indicator.Parent = itemBtn
            Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

            local itemLabel = Instance.new("TextLabel")
            itemLabel.Size = UDim2.new(1, -22, 1, 0)
            itemLabel.Position = UDim2.new(0, 18, 0, 0)
            itemLabel.BackgroundTransparency = 1
            itemLabel.Text = option
            itemLabel.TextColor3 = isSelected and C.white or C.grey
            itemLabel.Font = Enum.Font.BuilderSans
            itemLabel.TextSize = 12
            itemLabel.TextXAlignment = Enum.TextXAlignment.Left
            itemLabel.TextYAlignment = Enum.TextYAlignment.Center
            itemLabel.ZIndex = 52
            itemLabel.Parent = itemBtn

            itemBtn.MouseButton1Click:Connect(function()
                local idx = table.find(selected, option)
                if idx then
                    table.remove(selected, idx)
                    TweenService:Create(indicator, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
                    TweenService:Create(itemLabel, TweenInfo.new(0.15), {TextColor3 = C.grey}):Play()
                else
                    table.insert(selected, option)
                    TweenService:Create(indicator, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
                    TweenService:Create(itemLabel, TweenInfo.new(0.15), {TextColor3 = C.white}):Play()
                end
                updateDisplay()
                if callback then callback(selected) end
                saveValue()
            end)
        end

        TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.15,
            Size = UDim2.new(0, absSize.X - 28, 0, panelHeight)
        }):Play()
    end

    btn.MouseButton1Click:Connect(function()
        if isOpen then
            closeDropdown()
        else
            openDropdown()
        end
    end)

    -- close bila click luar
    UserInputService.InputBegan:Connect(function(input)
        if not isOpen then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local mp = UserInputService:GetMouseLocation()
        if panel then
            local pp = panel.AbsolutePosition
            local ps = panel.AbsoluteSize
            local rp = row.AbsolutePosition
            local rs = row.AbsoluteSize
            local inPanel = mp.X >= pp.X and mp.X <= pp.X + ps.X and mp.Y >= pp.Y and mp.Y <= pp.Y + ps.Y
            local inRow = mp.X >= rp.X and mp.X <= rp.X + rs.X and mp.Y >= rp.Y and mp.Y <= rp.Y + rs.Y
            if not inPanel and not inRow then
                closeDropdown()
            end
        end
    end)

    updateDisplay()
    return row
end

local function makeDraggable(gui)
    local dragging = false
    local dragStart
    local startPosition
    local inputChanged

    local function set(input)
        local delta = input.Position - dragStart
        TweenService:Create(gui, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        }):Play()
    end

    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = gui.Position
            if inputChanged then return end
            inputChanged = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    inputChanged:Disconnect()
                    inputChanged = nil
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                set(input)
            end
        end
    end)
end

makeDraggable(window)

local windowVisible = true

local function hideWindow()
    TweenService:Create(windowScale, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Scale = 0.95
    }):Play()
    TweenService:Create(window, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.25, function()
        window.Visible = false
    end)
    windowVisible = false
end

local function showWindow()
    launchWindow()
    windowVisible = true
end

dynamicIsland.Active = true
dynamicIsland.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        if islandNotifying then return end
        if windowVisible then
            hideWindow()
            islandMenuNotify("Menu Closed")
        else
            showWindow()
            islandMenuNotify("Menu Opened")
        end
    end
end)

local g1 = createGroup(tabContents["Player_Combat"], "Aimbot", "left")
createToggle(g1, "Silent Aim", false, function(state) print(state) end, "SilentAim")
createToggle(g1, "Auto Shoot", false, function(state) print(state) end, "AutoShoot")
createToggle(g1, "Team Check", true, function(state) print(state) end, "TeamCheck")
createSlider(g1, "FOV", 0, 360, 90, "°", function(v) print(v) end, "AimbotFOV")
createSlider(g1, "Smooth", 0, 100, 50, "%", function(v) print(v) end, "AimbotSmooth")
createButton(g1, "Im bout to nut", function() end)

local g2 = createGroup(tabContents["Player_Combat"], "Prediction", "right")
createToggle(g2, "Enabled", false, function(state) print(state) end, "PredictionEnabled")
createToggle(g2, "Auto Wall", false, function(state) print(state) end, "AutoWall")
createInput(g2, "Username", "Enter name...", function(v) print(v) end, "PlayerName")
createDropdown(g2, "Hit Part", {"Head", "Torso", "Arms", "Legs"}, function(v)
    print(table.concat(v, ", "))
end, "AimbotParts")

showNotification({message = "Connection failed", subtitle = "Could not reach the server", type = "Alert"})
showNotification({message = "Changes saved", subtitle = "Your settings have been updated", type = "Success"})
showNotification({message = "New update available", subtitle = "Version 2.0 is ready", type = "Info"})
