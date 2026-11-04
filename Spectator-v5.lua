
-- SPECTATOR V5
-- Direct CameraSubject System
-- PREV / NEXT / STOP
-- Draggable UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Camera = workspace.CurrentCamera
local BIND_NAME = "SpectatorCameraV5"

local targets = {}
local currentTarget = nil
local targetIndex = 0
local spectating = false

-- Remove old GUI
local oldGui = PlayerGui:FindFirstChild("SpectatorV5")
if oldGui then
    oldGui:Destroy()
end

RunService:UnbindFromRenderStep(BIND_NAME)

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpectatorV5"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 280, 0, 155)
Main.Position = UDim2.new(0.5, -140, 0.72, -75)
Main.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
Main.BorderSizePixel = 0
Main.Active = true
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(75, 105, 160)
Stroke.Thickness = 1.5
Stroke.Parent = Main

-- Header
local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, -20, 0, 30)
Header.Position = UDim2.new(0, 10, 0, 5)
Header.BackgroundTransparency = 1
Header.Text = "SPECTATOR V5"
Header.TextColor3 = Color3.fromRGB(120, 170, 255)
Header.Font = Enum.Font.GothamBold
Header.TextSize = 15
Header.Parent = Main

-- Target name
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -20, 0, 28)
TargetLabel.Position = UDim2.new(0, 10, 0, 38)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "Belum memilih target"
TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextSize = 13
TargetLabel.TextTruncate = Enum.TextTruncate.AtEnd
TargetLabel.Parent = Main

-- Status
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 20)
Status.Position = UDim2.new(0, 10, 0, 65)
Status.BackgroundTransparency = 1
Status.Text = "Spectator tidak aktif"
Status.TextColor3 = Color3.fromRGB(160, 170, 185)
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.Parent = Main

-- Button function
local function createButton(name, text, position, size, color)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = color
    button.Text = text
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 12
    button.Parent = Main

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 7)
    corner.Parent = button

    return button
end

local PrevButton = createButton(
    "Previous", "◀ PREV",
    UDim2.new(0, 10, 0, 98),
    UDim2.new(0, 78, 0, 35),
    Color3.fromRGB(48, 65, 95)
)

local NextButton = createButton(
    "Next", "NEXT ▶",
    UDim2.new(0, 192, 0, 98),
    UDim2.new(0, 78, 0, 35),
    Color3.fromRGB(48, 65, 95)
)

local StopButton = createButton(
    "Stop", "STOP",
    UDim2.new(0, 96, 0, 98),
    UDim2.new(0, 88, 0, 35),
    Color3.fromRGB(155, 55, 65)
)

-- Toggle button
local Toggle = Instance.new("TextButton")
Toggle.Name = "Toggle"
Toggle.Size = UDim2.new(0, 110, 0, 35)
Toggle.Position = UDim2.new(0, 15, 0.5, 0)
Toggle.BackgroundColor3 = Color3.fromRGB(35, 65, 115)
Toggle.Text = "SPECTATE"
Toggle.TextColor3 = Color3.new(1, 1, 1)
Toggle.Font = Enum.Font.GothamBold
Toggle.TextSize = 12
Toggle.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = Toggle

-- Drag UI
local dragging = false
local dragStart
local startPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

-- Update player list
local function updateTargets()
    targets = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(targets, player)
        end
    end

    table.sort(targets, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)
end

-- Update UI
local function updateUI()
    if currentTarget then
        TargetLabel.Text = currentTarget.DisplayName ..
            "  (@" .. currentTarget.Name .. ")"

        Header.Text = "SPECTATOR V5  •  " ..
            targetIndex .. "/" .. #targets
    else
        TargetLabel.Text = "Belum memilih target"
        Header.Text = "SPECTATOR V5"
    end
end

-- Direct spectate
local function spectatePlayer(index)
    updateTargets()

    if #targets == 0 then
        currentTarget = nil
        targetIndex = 0
        Status.Text = "Tidak ada pemain lain"
        updateUI()
        return
    end

    if index > #targets then
        index = 1
    elseif index < 1 then
        index = #targets
    end

    targetIndex = index
    currentTarget = targets[targetIndex]
    spectating = true

    Camera = workspace.CurrentCamera

    local character = currentTarget.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    updateUI()

    if humanoid and humanoid.Health > 0 then
        Camera.CameraType = Enum.CameraType.Custom
        Camera.CameraSubject = humanoid
        Status.Text = "Mengikuti: " .. currentTarget.Name
    else
        Status.Text = "Karakter target belum tersedia"
    end
end

-- Keep camera subject updated
RunService:BindToRenderStep(
    BIND_NAME,
    Enum.RenderPriority.Camera.Value + 1,
    function()
        if not spectating or not currentTarget then
            return
        end

        local character = currentTarget.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if humanoid and humanoid.Health > 0 then
            Camera = workspace.CurrentCamera

            if Camera.CameraSubject ~= humanoid then
                Camera.CameraType = Enum.CameraType.Custom
                Camera.CameraSubject = humanoid
            end
        end
    end
)

-- Stop
local function stopSpectating()
    spectating = false
    currentTarget = nil
    targetIndex = 0

    Camera = workspace.CurrentCamera
    Camera.CameraType = Enum.CameraType.Custom

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        Camera.CameraSubject = humanoid
    end

    Status.Text = "Spectator tidak aktif"
    updateUI()
end

-- Buttons
PrevButton.MouseButton1Click:Connect(function()
    if spectating then
        spectatePlayer(targetIndex - 1)
    end
end)

NextButton.MouseButton1Click:Connect(function()
    if spectating then
        spectatePlayer(targetIndex + 1)
    end
end)

StopButton.MouseButton1Click:Connect(stopSpectating)

Toggle.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible

    if Main.Visible and not spectating then
        updateTargets()
        spectatePlayer(1)
    end
end)

-- Player events
Players.PlayerAdded:Connect(function()
    updateTargets()
    updateUI()
end)

Players.PlayerRemoving:Connect(function(player)
    if player == currentTarget then
        updateTargets()

        if #targets > 0 then
            spectatePlayer(math.min(targetIndex, #targets))
        else
            stopSpectating()
        end
    else
        updateTargets()
        updateUI()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3)

    if not spectating then
        stopSpectating()
    end
end)

updateTargets()
updateUI()

print("Spectator V5 loaded")
