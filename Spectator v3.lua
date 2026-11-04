
--==================================================
-- SPECTATOR V3 - AUTO STREAM
-- Roblox Client / Executor
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer

-- CONFIGURATION
local CAMERA_HEIGHT = 6
local CAMERA_DISTANCE = 14
local STREAM_TIMEOUT = 8
local FOLLOW_SPEED = 10

-- STATE
local Targets = {}
local TargetIndex = 1
local CurrentTarget = nil
local Active = false
local Busy = false
local CameraConnection = nil
local SelectionID = 0

-- CLEAN OLD GUI
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("SpectatorExecutor")
    if old then old:Destroy() end
end)

pcall(function()
    local old = LP.PlayerGui:FindFirstChild("SpectatorExecutor")
    if old then old:Destroy() end
end)

-- GUI
local GUI = Instance.new("ScreenGui")
GUI.Name = "SpectatorExecutor"
GUI.ResetOnSpawn = false

local ok = pcall(function()
    GUI.Parent = game:GetService("CoreGui")
end)

if not ok or not GUI.Parent then
    GUI.Parent = LP:WaitForChild("PlayerGui")
end

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(290, 185)
Main.Position = UDim2.new(0.5, -145, 0.5, -92)
Main.BackgroundColor3 = Color3.fromRGB(17, 20, 32)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = GUI

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

local function CreateLabel(text, pos, size)
    local obj = Instance.new("TextLabel")
    obj.Position = pos
    obj.Size = size
    obj.BackgroundTransparency = 1
    obj.Text = text
    obj.TextColor3 = Color3.new(1,1,1)
    obj.Font = Enum.Font.GothamBold
    obj.TextSize = 13
    obj.Parent = Main
    return obj
end

local Title = CreateLabel(
    "SPECTATOR V3",
    UDim2.fromOffset(0, 5),
    UDim2.new(1, 0, 0, 28)
)
Title.TextSize = 17
Title.TextColor3 = Color3.fromRGB(160,130,255)

local Info = CreateLabel(
    "No Player Selected",
    UDim2.fromOffset(10, 38),
    UDim2.new(1, -20, 0, 45)
)
Info.BackgroundTransparency = 0
Info.BackgroundColor3 = Color3.fromRGB(30,35,52)

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 7)
InfoCorner.Parent = Info

local function CreateButton(name, text, x, width, color)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Position = UDim2.fromOffset(x, 94)
    b.Size = UDim2.fromOffset(width, 34)
    b.BackgroundColor3 = color or Color3.fromRGB(48,53,76)
    b.TextColor3 = Color3.new(1,1,1)
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    b.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,7)
    c.Parent = b

    return b
end

local Prev = CreateButton("Previous", "◀ PREV", 10, 78)
local Next = CreateButton("Next", "NEXT ▶", 94, 78)
local Refresh = CreateButton("Refresh", "↻", 178, 38)
local Stop = CreateButton(
    "Stop", "STOP", 222, 58,
    Color3.fromRGB(170,45,55)
)

local Status = CreateLabel(
    "READY",
    UDim2.fromOffset(5, 137),
    UDim2.new(1, -10, 0, 20)
)
Status.TextSize = 10
Status.TextColor3 = Color3.fromRGB(170,175,195)

local Count = CreateLabel(
    "Players: 0",
    UDim2.fromOffset(5, 158),
    UDim2.new(1, -10, 0, 18)
)
Count.TextSize = 10
Count.TextColor3 = Color3.fromRGB(150,155,175)

-- CAMERA
local function GetCamera()
    return workspace.CurrentCamera
end

local function UpdatePlayers()
    Targets = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            table.insert(Targets, p)
        end
    end

    Count.Text = "Players: " .. #Targets
end

local function StopCamera()
    Active = false
    Busy = false
    SelectionID += 1

    if CameraConnection then
        CameraConnection:Disconnect()
        CameraConnection = nil
    end

    CurrentTarget = nil

    local camera = GetCamera()
    local character = LP.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if camera then
        camera.CameraType = Enum.CameraType.Custom

        if humanoid then
            camera.CameraSubject = humanoid
        end
    end
end

-- FIND TARGET CHARACTER
local function WaitForTarget(target, requestID)
    local started = os.clock()

    while os.clock() - started < STREAM_TIMEOUT do
        if requestID ~= SelectionID then
            return nil
        end

        if not target.Parent then
            return nil
        end

        local character = target.Character

        if character then
            local root = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")

            if root and humanoid and humanoid.Health > 0 then
                return root, humanoid
            end
        end

        task.wait(0.2)
    end

    return nil
end

-- REQUEST STREAMING
local function RequestTargetStream(target, requestID)
    Status.Text = "SEARCHING TARGET..."

    local root, humanoid = WaitForTarget(target, requestID)

    if not root then
        return false
    end

    Status.Text = "REQUESTING STREAM..."

    local camera = GetCamera()

    -- Request area around target
    pcall(function()
        LP:RequestStreamAroundAsync(
            root.Position,
            5
        )
    end)

    if requestID ~= SelectionID then
        return false
    end

    -- Recheck character after streaming
    root, humanoid = WaitForTarget(target, requestID)

    if not root then
        return false
    end

    camera = GetCamera()

    if not camera then
        return false
    end

    CurrentTarget = target
    Active = true

    camera.CameraType = Enum.CameraType.Scriptable

    local currentCFrame = camera.CFrame

    if CameraConnection then
        CameraConnection:Disconnect()
    end

    CameraConnection = RunService.RenderStepped:Connect(function(dt)
        if not Active or CurrentTarget ~= target then
            return
        end

        camera = GetCamera()

        if not camera then return end

        local character = target.Character
        local targetRoot = character and
            character:FindFirstChild("HumanoidRootPart")

        local targetHumanoid = character and
            character:FindFirstChildOfClass("Humanoid")

        if not targetRoot or not targetHumanoid then
            return
        end

        if camera.CameraType ~= Enum.CameraType.Scriptable then
            camera.CameraType = Enum.CameraType.Scriptable
        end

        local offset = targetRoot.CFrame:VectorToWorldSpace(
            Vector3.new(0, CAMERA_HEIGHT, CAMERA_DISTANCE)
        )

        local position = targetRoot.Position + offset
        local lookAt = targetRoot.Position + Vector3.new(0,2,0)

        local desired = CFrame.lookAt(position, lookAt)

        local alpha = 1 - math.exp(-FOLLOW_SPEED * dt)

        currentCFrame = currentCFrame:Lerp(desired, alpha)

        camera.CFrame = currentCFrame
        camera.Focus = CFrame.new(lookAt)
    end)

    return true
end

-- SELECT PLAYER
local function Spectate(index)
    UpdatePlayers()

    if #Targets == 0 then
        Status.Text = "NO PLAYERS"
        Info.Text = "No Other Players"
        return
    end

    TargetIndex = ((index - 1) % #Targets) + 1

    local target = Targets[TargetIndex]

    SelectionID += 1
    local requestID = SelectionID

    if CameraConnection then
        CameraConnection:Disconnect()
        CameraConnection = nil
    end

    Active = false
    Busy = true
    CurrentTarget = target

    Info.Text = target.DisplayName .. "\n@" .. target.Name
    Status.Text = "LOADING TARGET..."

    task.spawn(function()
        local success = RequestTargetStream(target, requestID)

        if requestID ~= SelectionID then
            return
        end

        Busy = false

        if success then
            Status.Text = "FOLLOWING " ..
                TargetIndex .. "/" .. #Targets
        else
            Status.Text = "TARGET NOT STREAMED"
        end
    end)
end

-- BUTTONS
Prev.MouseButton1Click:Connect(function()
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
    StopCamera()
    Info.Text = "Spectating Stopped"
    Status.Text = "CAMERA RESTORED"
end)

-- PLAYER EVENTS
Players.PlayerRemoving:Connect(function(p)
    if p == CurrentTarget then
        task.wait(0.3)
        Spectate(TargetIndex)
    else
        UpdatePlayers()
    end
end)

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    UpdatePlayers()
end)

-- TARGET RESPAWN
local function ConnectPlayer(p)
    p.CharacterAdded:Connect(function()
        if p == CurrentTarget then
            task.wait(1)
            Spectate(TargetIndex)
        end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    ConnectPlayer(p)
end

-- LOCAL RESPAWN
LP.CharacterAdded:Connect(function()
    task.wait(0.5)

    if not Active and not Busy then
        StopCamera()
    end
end)

-- INITIALIZE
UpdatePlayers()

if #Targets > 0 then
    Spectate(1)
else
    Status.Text = "WAITING FOR PLAYERS"
end

print("[Spectator V3] Loaded successfully")
