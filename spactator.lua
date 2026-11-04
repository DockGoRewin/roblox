--[[
    ROBLOX SPECTATOR GUI
    Client-side Spectator
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local TargetIndex = 1
local Targets = {}
local CurrentTarget = nil

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpectatorExecutor"
ScreenGui.ResetOnSpawn = false

pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- Main GUI
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 270, 0, 155)
Main.Position = UDim2.new(0.5, -135, 0.5, -77)
Main.BackgroundColor3 = Color3.fromRGB(17, 20, 32)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "SPECTATOR"
Title.TextColor3 = Color3.fromRGB(160, 130, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 17
Title.Parent = Main

-- Player Info
local Info = Instance.new("TextLabel")
Info.Position = UDim2.new(0, 10, 0, 40)
Info.Size = UDim2.new(1, -20, 0, 40)
Info.BackgroundColor3 = Color3.fromRGB(28, 32, 48)
Info.TextColor3 = Color3.new(1, 1, 1)
Info.Text = "No Player Selected"
Info.Font = Enum.Font.Gotham
Info.TextSize = 12
Info.Parent = Main

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 7)
InfoCorner.Parent = Info

local function Button(name, text, pos, size)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Position = pos
    b.Size = size
    b.BackgroundColor3 = Color3.fromRGB(48, 53, 76)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = b

    return b
end

local Previous = Button(
    "Previous",
    "◀ PREV",
    UDim2.new(0, 10, 0, 90),
    UDim2.new(0, 75, 0, 30)
)

local Next = Button(
    "Next",
    "NEXT ▶",
    UDim2.new(0, 95, 0, 90),
    UDim2.new(0, 75, 0, 30)
)

local Refresh = Button(
    "Refresh",
    "↻",
    UDim2.new(0, 180, 0, 90),
    UDim2.new(0, 35, 0, 30)
)

local Stop = Button(
    "Stop",
    "STOP",
    UDim2.new(0, 225, 0, 90),
    UDim2.new(0, 35, 0, 30)
)

Stop.BackgroundColor3 = Color3.fromRGB(170, 45, 55)

local Status = Instance.new("TextLabel")
Status.Position = UDim2.new(0, 0, 0, 128)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.BackgroundTransparency = 1
Status.Text = "Ready"
Status.TextColor3 = Color3.fromRGB(150, 155, 175)
Status.TextSize = 10
Status.Font = Enum.Font.Gotham
Status.Parent = Main

-- Update player list
local function UpdatePlayers()
    Targets = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local char = p.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if hum and hum.Health > 0 then
                table.insert(Targets, p)
            end
        end
    end
end

-- Spectate
local function Spectate(index)
    UpdatePlayers()

    if #Targets == 0 then
        CurrentTarget = nil
        Info.Text = "No players available"
        Status.Text = "No target"
        return
    end

    TargetIndex = ((index - 1) % #Targets) + 1

    local target = Targets[TargetIndex]
    local character = target.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if not humanoid or humanoid.Health <= 0 then
        Status.Text = "Target unavailable"
        return
    end

    CurrentTarget = target

    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = humanoid

    Info.Text = target.DisplayName .. "\n@" .. target.Name
    Status.Text = "Spectating " .. TargetIndex .. "/" .. #Targets
end

-- Buttons
Previous.MouseButton1Click:Connect(function()
    Spectate(TargetIndex - 1)
end)

Next.MouseButton1Click:Connect(function()
    Spectate(TargetIndex + 1)
end)

Refresh.MouseButton1Click:Connect(function()
    UpdatePlayers()
    Spectate(1)
end)

Stop.MouseButton1Click:Connect(function()
    CurrentTarget = nil

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        Camera.CameraType = Enum.CameraType.Custom
        Camera.CameraSubject = humanoid
    end

    Info.Text = "Spectating Stopped"
    Status.Text = "Camera Restored"
end)

-- Target respawn
Players.PlayerAdded:Connect(function()
    task.wait(1)
    UpdatePlayers()
end)

Players.PlayerRemoving:Connect(function(p)
    if p == CurrentTarget then
        task.wait(0.2)
        UpdatePlayers()
        Spectate(TargetIndex)
    else
        UpdatePlayers()
    end
end)

-- Restore camera after own respawn
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)

    if not CurrentTarget then
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then
            Camera.CameraSubject = hum
        end
    end
end)

UpdatePlayers()

if #Targets > 0 then
    Spectate(1)
end

print("[Spectator] Loaded successfully!")