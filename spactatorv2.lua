-- SPECTATOR V2
-- Executor / Client Side
-- Scriptable Camera Follow

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Cleanup previous GUI
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("SpectatorExecutor"):Destroy()
end)

local Targets = {}
local TargetIndex = 1
local CurrentTarget = nil
local Active = false
local CameraConnection = nil

local CameraOffset = Vector3.new(0, 5, 12)

-- GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "SpectatorExecutor"
GUI.ResetOnSpawn = false

local success = pcall(function()
    GUI.Parent = game:GetService("CoreGui")
end)

if not success then
    GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(280, 165)
Main.Position = UDim2.new(0.5, -140, 0.5, -82)
Main.BackgroundColor3 = Color3.fromRGB(17, 20, 32)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = Main

local function Label(text, position, size)
    local obj = Instance.new("TextLabel")
    obj.Position = position
    obj.Size = size
    obj.BackgroundTransparency = 1
    obj.Text = text
    obj.TextColor3 = Color3.new(1, 1, 1)
    obj.Font = Enum.Font.GothamBold
    obj.TextSize = 13
    obj.Parent = Main
    return obj
end

local Title = Label(
    "SPECTATOR V2",
    UDim2.fromOffset(0, 5),
    UDim2.new(1, 0, 0, 25)
)

Title.TextColor3 = Color3.fromRGB(160, 130, 255)
Title.TextSize = 17

local Info = Label(
    "No Player Selected",
    UDim2.fromOffset(10, 38),
    UDim2.new(1, -20, 0, 43)
)

Info.BackgroundColor3 = Color3.fromRGB(30, 35, 52)
Info.BackgroundTransparency = 0
Info.TextWrapped = true

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 7)
infoCorner.Parent = Info

local function Button(name, text, x, width, color)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Position = UDim2.fromOffset(x, 92)
    b.Size = UDim2.fromOffset(width, 32)
    b.BackgroundColor3 = color or Color3.fromRGB(48, 53, 76)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    b.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = b

    return b
end

local Prev = Button("Previous", "◀ PREV", 10, 75)
local Next = Button("Next", "NEXT ▶", 92, 75)
local Refresh = Button("Refresh", "↻", 174, 35)
local Stop = Button("Stop", "STOP", 215, 55, Color3.fromRGB(170, 45, 55))

local Status = Label(
    "READY",
    UDim2.fromOffset(0, 132),
    UDim2.new(1, 0, 0, 22)
)

Status.TextColor3 = Color3.fromRGB(170, 175, 195)
Status.TextSize = 10

-- Camera
local function GetCamera()
    return workspace.CurrentCamera
end

local function RestoreCamera()
    Active = false
    CurrentTarget = nil

    if CameraConnection then
        CameraConnection:Disconnect()
        CameraConnection = nil
    end

    local camera = GetCamera()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if camera then
        camera.CameraType = Enum.CameraType.Custom

        if humanoid then
            camera.CameraSubject = humanoid
        end
    end

    Info.Text = "Spectating Stopped"
    Status.Text = "CAMERA RESTORED"
end

-- Player list
local function UpdatePlayers()
    Targets = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local character = p.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")

            if humanoid and root and humanoid.Health > 0 then
                table.insert(Targets, p)
            end
        end
    end
end

-- Start camera follow
local function StartCamera(target)
    if CameraConnection then
        CameraConnection:Disconnect()
        CameraConnection = nil
    end

    local character = target.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    if not root then
        Status.Text = "WAITING FOR CHARACTER"
        return false
    end

    CurrentTarget = target
    Active = true

    local camera = GetCamera()
    camera.CameraType = Enum.CameraType.Scriptable

    local currentCFrame = camera.CFrame

    CameraConnection = RunService.RenderStepped:Connect(function(dt)
        if not Active or CurrentTarget ~= target then
            return
        end

        -- Refresh camera reference
        camera = GetCamera()

        if not camera then return end

        -- Check target character
        local char = target.Character
        local targetRoot = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")

        if not targetRoot or not humanoid or humanoid.Health <= 0 then
            Status.Text = "TARGET UNAVAILABLE"
            return
        end

        -- Force Scriptable mode
        if camera.CameraType ~= Enum.CameraType.Scriptable then
            camera.CameraType = Enum.CameraType.Scriptable
        end

        -- Camera behind target
        local offset = targetRoot.CFrame:VectorToWorldSpace(CameraOffset)

        local cameraPosition = targetRoot.Position + offset
        local lookPosition = targetRoot.Position + Vector3.new(0, 2, 0)

        local desiredCFrame = CFrame.lookAt(
            cameraPosition,
            lookPosition
        )

        -- Smooth camera movement
        local alpha = 1 - math.exp(-8 * dt)
        currentCFrame = currentCFrame:Lerp(desiredCFrame, alpha)

        camera.CFrame = currentCFrame
        camera.Focus = CFrame.new(lookPosition)
    end)

    return true
end

-- Spectate
local function Spectate(index)
    UpdatePlayers()

    if #Targets == 0 then
        CurrentTarget = nil
        Info.Text = "No Players Available"
        Status.Text = "NO TARGET"
        return
    end

    TargetIndex = ((index - 1) % #Targets) + 1

    local target = Targets[TargetIndex]

    Info.Text = target.DisplayName .. "\n@" .. target.Name

    if StartCamera(target) then
        Status.Text = "SPECTATING " .. TargetIndex .. "/" .. #Targets
    end
end

-- Buttons
Prev.MouseButton1Click:Connect(function()
    Spectate(TargetIndex - 1)
end)

Next.MouseButton1Click:Connect(function()
    Spectate(TargetIndex + 1)
end)

Refresh.MouseButton1Click:Connect(function()
    Spectate(1)
end)

Stop.MouseButton1Click:Connect(function()
    RestoreCamera()
end)

-- Player leaves
Players.PlayerRemoving:Connect(function(p)
    if p == CurrentTarget and Active then
        task.wait(0.2)
        Spectate(TargetIndex)
    end
end)

-- Target respawn
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if p == CurrentTarget and Active then
            task.wait(1)
            Spectate(TargetIndex)
        end
    end)
end)

-- Existing players respawn
for _, p in ipairs(Players:GetPlayers()) do
    p.CharacterAdded:Connect(function()
        if p == CurrentTarget and Active then
            task.wait(1)
            Spectate(TargetIndex)
        end
    end)
end

-- Local respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)

    if not Active then
        RestoreCamera()
    end
end)

-- Initial
UpdatePlayers()

if #Targets > 0 then
    Spectate(1)
else
    Status.Text = "WAITING FOR PLAYERS"
end

print("[Spectator V2] Loaded!")
