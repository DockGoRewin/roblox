-- SPECTATOR V5.2
-- Direct CameraSubject | PREV / NEXT / STOP | Player List | Draggable UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local BIND_NAME = "SpectatorCameraV5"
local SKIP_AFTER = 5 -- detik sebelum auto-skip target yang belum ke-load

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

-- ========== GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpectatorV5"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 280, 0, 320)
Main.Position = UDim2.new(0.5, -140, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(20, 23, 32)
Main.BorderSizePixel = 0
Main.Active = true
Main.Visible = false
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(75, 105, 160)
Stroke.Thickness = 1.5
Stroke.Parent = Main

local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundTransparency = 1
Header.Text = "SPECTATOR V5"
Header.TextColor3 = Color3.fromRGB(120, 170, 255)
Header.Font = Enum.Font.GothamBold
Header.TextSize = 15
Header.Parent = Main

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, -20, 0, 26)
TargetLabel.Position = UDim2.new(0, 10, 0, 40)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "Belum memilih target"
TargetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.TextSize = 13
TargetLabel.TextTruncate = Enum.TextTruncate.AtEnd
TargetLabel.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 20)
Status.Position = UDim2.new(0, 10, 0, 64)
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
    UDim2.new(0, 10, 0, 90), UDim2.new(0, 78, 0, 35), Color3.fromRGB(48, 65, 95))
local StopButton = createButton("Stop", "STOP",
    UDim2.new(0, 96, 0, 90), UDim2.new(0, 88, 0, 35), Color3.fromRGB(155, 55, 65))
local NextButton = createButton("Next", "NEXT ▶",
    UDim2.new(0, 192, 0, 90), UDim2.new(0, 78, 0, 35), Color3.fromRGB(48, 65, 95))

-- Daftar pemain
local List = Instance.new("ScrollingFrame")
List.Name = "PlayerList"
List.Size = UDim2.new(1, -20, 0, 175)
List.Position = UDim2.new(0, 10, 0, 135)
List.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
List.BorderSizePixel = 0
List.ScrollBarThickness = 4
List.CanvasSize = UDim2.new(0, 0, 0, 0)
List.AutomaticCanvasSize = Enum.AutomaticSize.Y
List.Parent = Main

local ListCorner = Instance.new("UICorner")
ListCorner.CornerRadius = UDim.new(0, 8)
ListCorner.Parent = List

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 4)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = List

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop = UDim.new(0, 4)
ListPadding.PaddingBottom = UDim.new(0, 4)
ListPadding.PaddingLeft = UDim.new(0, 4)
ListPadding.PaddingRight = UDim.new(0, 4)
ListPadding.Parent = List

local EmptyLabel = Instance.new("TextLabel")
EmptyLabel.Size = UDim2.new(1, 0, 0, 30)
EmptyLabel.BackgroundTransparency = 1
EmptyLabel.Text = "Tidak ada pemain lain"
EmptyLabel.TextColor3 = Color3.fromRGB(160, 170, 185)
EmptyLabel.Font = Enum.Font.Gotham
EmptyLabel.TextSize = 12
EmptyLabel.Visible = false
EmptyLabel.Parent = List

-- Tombol toggle di luar panel
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

-- ========== DRAG ==========
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

-- ========== LOGIKA ==========
local selectIndex -- forward declaration

local function setStatus(text)
    if Status.Text ~= text then
        Status.Text = text
    end
end

local function getHumanoid(player)
    local character = player and player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function rebuildList()
    for _, child in ipairs(List:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    EmptyLabel.Visible = (#targets == 0)

    for i, player in ipairs(targets) do
        local isCurrent = (player == currentTarget)

        local item = Instance.new("TextButton")
        item.Name = "Target_" .. player.Name
        item.LayoutOrder = i
        item.Size = UDim2.new(1, 0, 0, 30)
        item.BackgroundColor3 = isCurrent
            and Color3.fromRGB(45, 90, 160)
            or Color3.fromRGB(40, 46, 62)
        item.Text = player.DisplayName .. "  (@" .. player.Name .. ")"
        item.TextColor3 = Color3.new(1, 1, 1)
        item.Font = Enum.Font.Gotham
        item.TextSize = 12
        item.TextTruncate = Enum.TextTruncate.AtEnd
        item.Parent = List

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = item

        item.MouseButton1Click:Connect(function()
            local idx = table.find(targets, player)
            if idx then
                selectIndex(idx)
            end
        end)
    end
end

local function updateUI()
    if currentTarget and targetIndex > 0 then
        TargetLabel.Text = currentTarget.DisplayName .. "  (@" .. currentTarget.Name .. ")"
        Header.Text = "SPECTATOR V5  •  " .. targetIndex .. "/" .. #targets
    else
        TargetLabel.Text = "Belum memilih target"
        Header.Text = "SPECTATOR V5"
    end
    rebuildList()
end

-- Bangun ulang daftar target; targetIndex dihitung ulang dari currentTarget
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

selectIndex = function(index)
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

-- dir = +1 (next) / -1 (prev)
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

-- Jaga CameraSubject tetap di target + auto-skip kalau tidak ke-load
local waitStart = nil

RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function()
    if not spectating or not currentTarget then
        waitStart = nil
        return
    end

    local humanoid = getHumanoid(currentTarget)
    if humanoid and humanoid.Health > 0 then
        waitStart = nil
        local camera = workspace.CurrentCamera
        if camera.CameraSubject ~= humanoid then
            camera.CameraType = Enum.CameraType.Custom
            camera.CameraSubject = humanoid
        end
        setStatus("Mengikuti: " .. currentTarget.Name)
    else
        waitStart = waitStart or os.clock()
        local waited = os.clock() - waitStart
        setStatus(string.format("Menunggu karakter target... (%ds)", waited))

        if waited > SKIP_AFTER and #targets > 1 then
            waitStart = nil
            moveTarget(1)
        end
    end
end)

-- ========== TOMBOL ==========
connect(PrevButton.MouseButton1Click, function()
    moveTarget(-1)
end)

connect(NextButton.MouseButton1Click, function()
    moveTarget(1)
end)

connect(StopButton.MouseButton1Click, stopSpectating)

connect(Toggle.MouseButton1Click, function()
    Main.Visible = not Main.Visible

    if Main.Visible then
        refreshTargets()
        if spectating then
            updateUI()
        else
            selectIndex(1)
        end
    end
end)

-- ========== EVENT PEMAIN ==========
connect(Players.PlayerAdded, function()
    refreshTargets()
    updateUI()
end)

connect(Players.PlayerRemoving, function(player)
    if player == currentTarget then
        local oldIndex = targetIndex
        currentTarget = nil
        refreshTargets(player)

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

print("Spectator V5.2 loaded")
