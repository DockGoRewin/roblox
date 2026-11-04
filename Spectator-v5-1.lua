-- SPECTATOR V5.1 (fixed)
-- Direct CameraSubject System | PREV / NEXT / STOP | Draggable UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local BIND_NAME = "SpectatorCameraV5"

local targets = {}
local currentTarget = nil
local targetIndex = 0
local spectating = false

-- Bersihkan instance lama (GUI + koneksi)
if _G.SpectatorV5Cleanup then
    pcall(_G.SpectatorV5Cleanup)
end

local connections = {}
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end

local oldGui = PlayerGui:FindFirstChild("SpectatorV5")
if oldGui then oldGui:Destroy() end
pcall(function() RunService:UnbindFromRenderStep(BIND_NAME) end)

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

-- Header (area drag, dibuat lebih tinggi)
local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.Position = UDim2.new(0, 0, 0, 0)
Header.BackgroundTransparency = 1
Header.Text = "SPECTATOR V5"
Header.TextColor3 = Color3.fromRGB(120, 170, 255)
Header.Font = Enum.Font.GothamBold
Header.TextSize = 15
Header.Parent = Main

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -20, 0, 28)
TargetLabel.Position = UDim2.new(0, 10, 0, 42)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "Belum memilih target"
TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextSize = 13
TargetLabel.TextTruncate = Enum.TextTruncate.AtEnd
TargetLabel.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 20)
Status.Position = UDim2.new(0, 10, 0, 68)
Status.BackgroundTransparency = 1
Status.Text = "Spectator tidak aktif"
Status.TextColor3 = Color3.fromRGB(160, 170, 185)
Status.Font = Enum.Font.Gotham
Status.TextSize = 11
Status.Parent = Main

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

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = button
    return button
end

local PrevButton = createButton("Previous", "◀ PREV",
    UDim2.new(0, 10, 0, 105), UDim2.new(0, 78, 0, 35), Color3.fromRGB(48, 65, 95))
local StopButton = createButton("Stop", "STOP",
    UDim2.new(0, 96, 0, 105), UDim2.new(0, 88, 0, 35), Color3.fromRGB(155, 55, 65))
local NextButton = createButton("Next", "NEXT ▶",
    UDim2.new(0, 192, 0, 105), UDim2.new(0, 78, 0, 35), Color3.fromRGB(48, 65, 95))

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
local dragStart, startPosition

connect(Header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

        local changedConn
        changedConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                changedConn:Disconnect()
            end
        end)
    end
end)

connect(UserInputService.InputChanged, function(input)
    if dragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)

-- Helpers
local function setStatus(text)
    if Status.Text ~= text then
        Status.Text = text
    end
end

local function getHumanoid(player)
    local character = player and player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function updateUI()
    if currentTarget and targetIndex > 0 then
        TargetLabel.Text = currentTarget.DisplayName .. "  (@" .. currentTarget.Name .. ")"
        Header.Text = "SPECTATOR V5  •  " .. targetIndex .. "/" .. #targets
    else
        TargetLabel.Text = "Belum memilih target"
        Header.Text = "SPECTATOR V5"
    end
end

-- Bangun ulang list target; targetIndex dihitung ulang dari currentTarget
local function refreshTargets(exclude)
    targets = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player ~= exclude then
            table.insert(targets, player)
        end
    end

    table.sort(targets, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    targetIndex = (currentTarget and table.find(targets, currentTarget)) or 0
end

local function stopSpectating()
    spectating = false
    currentTarget = nil
    targetIndex = 0

    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Custom

    local humanoid = getHumanoid(LocalPlayer)
    if humanoid then
        camera.CameraSubject = humanoid
    end

    setStatus("Spectator tidak aktif")
    updateUI()
end

-- Pilih target berdasarkan index (tanpa refresh)
local function selectIndex(index)
    if #targets == 0 then
        currentTarget = nil
        targetIndex = 0
        spectating = false
        setStatus("Tidak ada pemain lain")
        updateUI()
        return
    end

    if index > #targets then
        index = 1
    elseif index < 1 then
        index = #targets
    end

    targetIndex = index
    currentTarget = targets[index]
    spectating = true

    local humanoid = getHumanoid(currentTarget)
    if humanoid and humanoid.Health > 0 then
        local camera = workspace.CurrentCamera
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = humanoid
        setStatus("Mengikuti: " .. currentTarget.Name)
    else
        setStatus("Menunggu karakter target...")
    end

    updateUI()
end

-- Pindah target (dir = +1 next, -1 prev)
local function moveTarget(dir)
    refreshTargets()
    if #targets == 0 then
        stopSpectating()
        setStatus("Tidak ada pemain lain")
        return
    end
    local base = targetIndex > 0 and targetIndex or (dir > 0 and 0 or 1)
    selectIndex(base + dir)
end

-- Jaga CameraSubject tetap di target + update status
RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function()
    if not spectating or not currentTarget then return end

    local humanoid = getHumanoid(currentTarget)
    if humanoid and humanoid.Health > 0 then
        local camera = workspace.CurrentCamera
        if camera.CameraSubject ~= humanoid then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = humanoid
        end
        setStatus("Mengikuti: " .. currentTarget.Name)
    else
        setStatus("Menunggu karakter target...")
    end
end)

-- Tombol
connect(PrevButton.MouseButton1Click, function()
    if spectating then moveTarget(-1) end
end)

connect(NextButton.MouseButton1Click, function()
    if spectating then moveTarget(1) end
end)

connect(StopButton.MouseButton1Click, stopSpectating)

connect(Toggle.MouseButton1Click, function()
    Main.Visible = not Main.Visible

    if Main.Visible and not spectating then
        refreshTargets()
        selectIndex(1)
    end
end)

-- Event pemain
connect(Players.PlayerAdded, function()
    refreshTargets()
    updateUI()
end)

connect(Players.PlayerRemoving, function(player)
    if player == currentTarget then
        local oldIndex = targetIndex
        currentTarget = nil
        refreshTargets(player) -- pemain yang keluar tidak ikut dihitung

        if #targets > 0 then
            selectIndex(math.clamp(oldIndex, 1, #targets))
        else
            stopSpectating()
            setStatus("Tidak ada pemain lain")
        end
    else
        refreshTargets(player)
        updateUI()
    end
end)

-- Cleanup kalau script dijalankan ulang
_G.SpectatorV5Cleanup = function()
    for _, c in ipairs(connections) do
        c:Disconnect()
    end
    pcall(function() RunService:UnbindFromRenderStep(BIND_NAME) end)
    if ScreenGui then ScreenGui:Destroy() end
end

refreshTargets()
updateUI()

print("Spectator V5.1 loaded")
