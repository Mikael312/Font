local cloneref = (cloneref or clonereference or function(instance) return instance end)
local gethui = gethui or function() return game:GetService("CoreGui") end

local Players = cloneref(game:GetService("Players"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local LocalPlayer = Players.LocalPlayer

local c = {
    coal = Color3.fromRGB(18, 18, 18),
    black = Color3.new(0, 0, 0),
}

local heartbeat = RunService.Heartbeat
local sqrt, sin, pi, halfpi, tau = math.sqrt, math.sin, math.pi, math.pi / 2, math.pi * 2
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

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Mirin"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = gethui()

local Window = Instance.new("Frame")
Window.Name = "Window"
Window.Size = UDim2.fromOffset(580, 560)
Window.Position = UDim2.fromScale(0.5, 0.5)
Window.AnchorPoint = Vector2.new(0.5, 0.5)
Window.BackgroundColor3 = c.black
Window.BackgroundTransparency = 1
Window.BorderSizePixel = 0
Window.Visible = false
Window.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 9)
Corner.Parent = Window

local Stroke = Instance.new("UIStroke")
Stroke.Color = c.coal
Stroke.Thickness = 1.2
Stroke.Transparency = 0.5
Stroke.Parent = Window

local WindowScale = Instance.new("UIScale")
WindowScale.Scale = 0.95
WindowScale.Parent = Window

local function launchWindow()
    Window.Visible = true
    WindowScale.Scale = 0.95
    Window.BackgroundTransparency = 1

    tween:create(WindowScale, {time = 0.35, style = "quart", direction = "out"}, {
        Scale = 1
    }):play()

    tween:create(Window, {time = 0.35, style = "quart", direction = "out"}, {
        BackgroundTransparency = 0.01
    }):play()
end

launchWindow()

local dragging, dragStart, startPos, inputChanged, activeTween

Window.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Window.Position
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
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        if dragging then
            local delta = input.Position - dragStart
            if activeTween then activeTween:cancel() end
            activeTween = tween:create(Window, {time = 0.7, style = "quart", direction = "out"}, {
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
end)
