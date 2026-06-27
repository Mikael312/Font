local cloneref = (cloneref or clonereference or function(instance) return instance end)
local gethui = gethui or function() return game:GetService("CoreGui") end
local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local LocalPlayer = Players.LocalPlayer

local c = {
    coal = Color3.fromRGB(18, 18, 18),
    black = Color3.new(0, 0, 0),
    white = Color3.new(1, 1, 1),
    blue = Color3.fromRGB(147, 197, 253),
    graphite = Color3.fromRGB(28, 28, 28),
    steel = Color3.fromRGB(40, 40, 40),
    grey = Color3.fromRGB(100, 100, 100),
    ivory = Color3.fromRGB(255, 255, 240),
}

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({ _tasks = {} }, Maid)
end

function Maid:GiveTask(task)
    local class = typeof(task)
    if class ~= "Instance" and class ~= "RBXScriptConnection" and (class ~= "table" or not task.Disconnect) then return end
    self._tasks[task] = true
end

function Maid:RemoveTask(task)
    self._tasks[task] = nil
end

function Maid:Destroy()
    local task, _ = next(self._tasks)
    while task do
        self._tasks[task] = nil
        if typeof(task) == "Instance" then
            task:Destroy()
        else
            task:Disconnect()
        end
        task, _ = next(self._tasks)
    end
end

Maid.DoCleaning = Maid.Destroy
Maid.Disconnect = Maid.Destroy
Maid.CleanUp = Maid.Destroy

local maid = Maid.new()

local heartbeat = RunService.Heartbeat
local sqrt, sin, halfpi, tau = math.sqrt, math.sin, math.pi / 2, math.pi * 2
local s, p = 1.70158, 0.3
local e = 1 / p

local styles = {
    linear = function(delta) return delta end,
    sine = function(delta) return sin(halfpi * delta - halfpi) + 1 end,
    back = function(delta) return delta^2 * (delta * (s + 1) - s) end,
    quad = function(delta) return delta^2 end,
    quart = function(delta) return delta^4 end,
    quint = function(delta) return delta^5 end,
    elastic = function(delta) return -2^(10 * (delta - 1)) * sin(tau * (delta - 1 - p * 0.25) * e) end,
    exponential = function(delta) return 2^(10 * delta - 10) - 0.001 end,
    circular = function(delta) return -sqrt(1 - delta^2) + 1 end,
    cubic = function(delta) return delta^3 end
}

local tween = {}
tween.__index = tween

function tween:create(object, info, properties)
    return setmetatable({
        object = object,
        time = info.time or info[1],
        style = info.style or info[2] or "quad",
        direction = info.direction or info[3] or "out",
        properties = properties,
        elapsed = 0,
        starts = {},
    }, self)
end

function tween:play(_REVERSE)
    if _REVERSE then
        self.reversed = true
    else
        for property in self.properties do
            self.starts[property] = self.object[property]
        end
    end

    coroutine.wrap(function()
        while (if _REVERSE then self.elapsed >= 0 else self.elapsed <= self.time) and not self.cancelled and (if _REVERSE then true else not self.reversed) do
            if self.paused then heartbeat:Wait() continue end
            self.elapsed += if _REVERSE then -heartbeat:Wait() else heartbeat:Wait()
            self.delta = self.elapsed / self.time

            local alpha
            if self.direction == "in" then
                alpha = styles[self.style](self.delta)
            elseif self.direction == "in_out" then
                if self.delta <= 0.5 then
                    alpha = 0.5 * styles[self.style](2 * self.delta)
                else
                    alpha = 0.5 * (1 - styles[self.style](-2 * self.delta + 2)) + 0.5
                end
            else
                alpha = 1 - styles[self.style](-self.delta + 1)
            end

            for property, value in self.properties do
                if typeof(value) == "number" then
                    self.object[property] = self.starts[property] + ((value - self.starts[property]) * alpha)
                else
                    self.object[property] = self.starts[property]:lerp(value, alpha)
                end
            end
        end

        if not self.cancelled and (if _REVERSE then true else not self.reversed) then
            for property, value in self.properties do
                self.object[property] = if _REVERSE then self.starts[property] else value
            end
        end

        if self.callback and not self.cancelled and not self.reversed then
            self.callback()
        end
    end)()
end

function tween:reverse() self:play(true) end
function tween:pause() self.paused = true end
function tween:resume() self.paused = false end
function tween:cancel() self.cancelled = true end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Mirin"
screenGui.ResetOnSpawn = false
screenGui.Parent = gethui()

local window = Instance.new("Frame")
window.Name = "Window"
window.Size = UDim2.fromOffset(580, 560)
window.Position = UDim2.fromScale(0.5, 0.5)
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.BackgroundColor3 = c.black
window.BackgroundTransparency = 1
window.BorderSizePixel = 0
window.Active = true
window.Visible = false
window.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 9)
corner.Parent = window

local stroke = Instance.new("UIStroke")
stroke.Color = c.coal
stroke.Thickness = 1.2
stroke.Transparency = 0.5
stroke.Parent = window

local windowScale = Instance.new("UIScale")
windowScale.Scale = 0.95
windowScale.Parent = window

local function launchWindow()
    window.Visible = true
    windowScale.Scale = 0.95
    window.BackgroundTransparency = 1

    tween:create(windowScale, {time = 0.35, style = "quart", direction = "out"}, {
        Scale = 1
    }):play()

    tween:create(window, {time = 0.35, style = "quart", direction = "out"}, {
        BackgroundTransparency = 0.02
    }):play()
end

launchWindow()

local topbar = Instance.new("Frame")
topbar.Name = "Topbar"
topbar.Size = UDim2.new(1, 0, 0, 44)
topbar.Position = UDim2.new(0, 0, 0, 0)
topbar.BackgroundTransparency = 1
topbar.BorderSizePixel = 0
topbar.Parent = window

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0, 200, 0, 20)
title.Position = UDim2.new(0, 12, 0.5, -10)
title.BackgroundTransparency = 1
title.Text = "Mirin"
title.TextColor3 = c.white
title.TextSize = 16
title.Font = Enum.Font.BuilderSans
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topbar

local searchBar = Instance.new("Frame")
searchBar.Name = "SearchBar"
searchBar.Size = UDim2.new(0, 160, 0, 26)
searchBar.Position = UDim2.new(1, -168, 0.5, -13)
searchBar.BackgroundColor3 = c.graphite
searchBar.BackgroundTransparency = 0.3
searchBar.BorderSizePixel = 0
searchBar.Parent = topbar
Instance.new("UICorner", searchBar).CornerRadius = UDim.new(1, 0)

local searchIcon = Instance.new("ImageLabel")
searchIcon.Size = UDim2.new(0, 13, 0, 13)
searchIcon.Position = UDim2.new(0, 9, 0.5, -6)
searchIcon.BackgroundTransparency = 1
searchIcon.Image = "rbxassetid://96045630034755"
searchIcon.ImageColor3 = c.ivory
searchIcon.Parent = searchBar

local searchInput = Instance.new("TextBox")
searchInput.Name = "Input"
searchInput.Size = UDim2.new(1, -28, 1, 0)
searchInput.Position = UDim2.new(0, 26, 0, 0)
searchInput.BackgroundTransparency = 1
searchInput.Text = ""
searchInput.PlaceholderText = "Search..."
searchInput.PlaceholderColor3 = c.grey
searchInput.TextColor3 = c.white
searchInput.TextSize = 12
searchInput.Font = Enum.Font.BuilderSans
searchInput.TextXAlignment = Enum.TextXAlignment.Left
searchInput.ClearTextOnFocus = false
searchInput.Parent = searchBar

local searchHint = Instance.new("Frame")
searchHint.Size = UDim2.new(0, 32, 0, 18)
searchHint.Position = UDim2.new(1, -36, 0.5, -9)
searchHint.BackgroundColor3 = c.steel
searchHint.BackgroundTransparency = 0.5
searchHint.BorderSizePixel = 0
searchHint.Parent = searchBar
Instance.new("UICorner", searchHint).CornerRadius = UDim.new(1, 0)

local hintIcon = Instance.new("ImageLabel")
hintIcon.Size = UDim2.new(0, 11, 0, 11)
hintIcon.Position = UDim2.new(0, 6, 0.5, -5)
hintIcon.BackgroundTransparency = 1
hintIcon.Image = "rbxassetid://122538551810718"
hintIcon.ImageColor3 = c.ivory
hintIcon.Parent = searchHint

local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(0, 14, 1, 0)
hintLabel.Position = UDim2.new(0, 21, 0, 0)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "F"
hintLabel.TextColor3 = c.ivory
hintLabel.TextSize = 11
hintLabel.Font = Enum.Font.BuilderSans
hintLabel.TextXAlignment = Enum.TextXAlignment.Left
hintLabel.Parent = searchHint

local searchTooltip = Instance.new("Frame")
searchTooltip.Size = UDim2.new(0, 58, 0, 22)
searchTooltip.Position = UDim2.new(1, -62, 1, 6)
searchTooltip.BackgroundColor3 = c.graphite
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
tooltipText.TextColor3 = c.white
tooltipText.TextSize = 11
tooltipText.Font = Enum.Font.BuilderSans
tooltipText.ZIndex = 10
tooltipText.Parent = searchTooltip

maid:GiveTask(searchHint.MouseEnter:Connect(function()
    searchTooltip.Visible = true
end))

maid:GiveTask(searchHint.MouseLeave:Connect(function()
    searchTooltip.Visible = false
end))

maid:GiveTask(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F and
       (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
       or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
       or UserInputService:IsKeyDown(Enum.KeyCode.LeftSuper)) then
        searchInput:CaptureFocus()
    end
end))

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -24, 0, 32)
tabBar.Position = UDim2.new(0, 12, 0, 44)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
tabBar.ClipsDescendants = true
tabBar.Parent = window

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Padding = UDim.new(0, 4)
tabList.Parent = tabBar

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Name = "TabScroll"
tabScroll.Size = UDim2.new(1, 0, 1, 0)
tabScroll.BackgroundTransparency = 1
tabScroll.BorderSizePixel = 0
tabScroll.ScrollBarThickness = 0
tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
tabScroll.Parent = tabBar

local tabInner = Instance.new("Frame")
tabInner.Name = "TabInner"
tabInner.Size = UDim2.new(1, 0, 1, 0)
tabInner.BackgroundTransparency = 1
tabInner.BorderSizePixel = 0
tabInner.AutomaticSize = Enum.AutomaticSize.X
tabInner.Parent = tabScroll

local tabInnerList = Instance.new("UIListLayout")
tabInnerList.FillDirection = Enum.FillDirection.Horizontal
tabInnerList.SortOrder = Enum.SortOrder.LayoutOrder
tabInnerList.Padding = UDim.new(0, 4)
tabInnerList.Parent = tabInner

local indicator = Instance.new("Frame")
indicator.Name = "Indicator"
indicator.Size = UDim2.new(0, 60, 1, 0)
indicator.Position = UDim2.new(0, 0, 0, 0)
indicator.BackgroundColor3 = c.steel
indicator.BorderSizePixel = 0
indicator.ZIndex = 0
indicator.Parent = tabScroll
Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

local tabs = {"Player", "Aimbot"}
local tabButtons = {}
local activeTab = nil

local function selectTab(tab, button)
    activeTab = tab
    tween:create(indicator, {time = 0.25, style = "quart", direction = "out"}, {
        Position = UDim2.new(0, button.AbsolutePosition.X - tabScroll.AbsolutePosition.X, 0, 0),
        Size = UDim2.new(0, button.AbsoluteSize.X, 1, 0)
    }):play()
    for _, btn in tabButtons do
        tween:create(btn, {time = 0.2, style = "quad", direction = "out"}, {
            TextColor3 = btn == button and c.white or c.grey
        }):play()
    end
end

for i, name in tabs do
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 0, 1, 0)
    btn.AutomaticSize = Enum.AutomaticSize.X
    btn.BackgroundTransparency = 1
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = c.grey
    btn.TextSize = 13
    btn.Font = Enum.Font.BuilderSans
    btn.AutoButtonColor = false
    btn.LayoutOrder = i
    btn.ZIndex = 1
    btn.Parent = tabInner

    local btnPad = Instance.new("UIPadding")
    btnPad.PaddingLeft = UDim.new(0, 12)
    btnPad.PaddingRight = UDim.new(0, 12)
    btnPad.Parent = btn

    tabButtons[i] = btn

    maid:GiveTask(btn.MouseButton1Click:Connect(function()
        selectTab(name, btn)
    end))
end

task.defer(function()
    selectTab(tabs[1], tabButtons[1])
end)
                    
local dragging, dragStart, startPos, inputChanged, activeTween

maid:GiveTask(window.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = window.Position
        inputChanged = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                inputChanged:Disconnect()
                inputChanged = nil
            end
        end)
    end
end))

maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            if activeTween then activeTween:cancel() end
            activeTween = tween:create(window, {time = 0.7, style = "quart", direction = "out"}, {
                Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            })
            activeTween:play()
        end
    end
end))
