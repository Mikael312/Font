local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local gethui = gethui or function() return game:GetService("CoreGui") end

local C = {
    white    = Color3.fromRGB(255, 255, 255),
    black    = Color3.fromRGB(0, 0, 0),
    coal     = Color3.fromRGB(18, 18, 20),
    graphite = Color3.fromRGB(28, 28, 30),
    steel    = Color3.fromRGB(43, 43, 43),
    grey     = Color3.fromRGB(99, 99, 102),
    mauve    = Color3.fromRGB(117, 98, 101),
    green    = Color3.fromRGB(80, 200, 120),
    ivory    = Color3.fromRGB(255, 255, 240),
}

local keyGui = Instance.new("ScreenGui")
keyGui.Name = "KeySystem"
keyGui.ResetOnSpawn = false
keyGui.IgnoreGuiInset = true
keyGui.Parent = gethui()

local card = Instance.new("Frame")
card.Name = "Card"
card.Size = UDim2.new(0, 340, 0, 260)
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.new(0.5, 0, 0.5, 0)
card.BackgroundColor3 = C.coal
card.BackgroundTransparency = 0
card.BorderSizePixel = 0
card.Parent = keyGui
Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

local dragging, dragStart, startPos, inputChanged

card.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = card.Position
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
            TweenService:Create(card, TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            }):Play()
        end
    end
end)
