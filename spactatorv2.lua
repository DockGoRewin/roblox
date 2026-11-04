-- SPECTATOR SYSTEM (FIXED)
-- Roblox LocalScript

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

local currentTarget = nil
local targets = {}
local currentIndex = 0
local spectating = false

local function getCamera()
    return workspace.CurrentCamera
end

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "SpectatorGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Tombol toggle (untuk HP)
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 110, 0, 36)
toggleButton.Position = UDim2.new(0, 10, 0.5, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Text = "👁 Spectate"
toggleButton.TextSize = 14
toggleButton.Font = Enum.Font.GothamBold
toggleButton.BorderSizePixel = 0
toggleButton.Parent = gui
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 8)

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 115)
frame.Position = UDim2.new(0.5, -140, 0.85, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Visible = false
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, 0, 0, 35)
nameLabel.Position = UDim2.new(0, 0, 0, 5)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = "Spectating: None"
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.TextSize = 16
nameLabel.Font = Enum.Font.GothamBold
nameLabel.Parent = frame

local function createButton(name, text, position, size)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(40, 50, 75)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Text = text
    button.TextSize = 14
    button.Font = Enum.Font.GothamBold
    button.BorderSizePixel = 0
    button.Parent = frame
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    return button
end

local previousButton = createButton("Previous", "◀ Previous", UDim2.new(0, 10, 0, 48), UDim2.new(0, 95, 0, 35))
local nextButton = createButton("Next", "Next ▶", UDim2.new(0, 175, 0, 48), UDim2.new(0, 95, 0, 35))
local exitButton = createButton("Exit", "EXIT", UDim2.new(0.5, -35, 0, 88), UDim2.new(0, 70, 0, 22))
exitButton.BackgroundColor3 = Color3.fromRGB(170, 45, 55)

-- Ambil daftar target yang hidup
local function updateTargets()
    targets = {}
    for _, target in ipairs(Players:GetPlayers()) do
        if target ~= player then
            local character = target.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                table.insert(targets, target)
            end
        end
    end
end

-- Pilih target (kamera diatur oleh loop di bawah)
local function spectatePlayer(index)
    updateTargets()

    if #targets == 0 then
        nameLabel.Text = "No players available"
        currentTarget = nil
        return
    end

    if index > #targets then
        index = 1
    elseif index < 1 then
        index = #targets
    end

    currentIndex = index
    currentTarget = targets[currentIndex]
    nameLabel.Text = "Spectating: " .. currentTarget.DisplayName

    -- Pastikan area target ter-stream (kalau StreamingEnabled)
    local char = currentTarget.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        pcall(function()
            player:RequestStreamAroundAsync(root.Position)
        end)
    end
end

-- Paksa kamera ke target tiap frame (menimpa script kamera bawaan)
RunService:BindToRenderStep("SpectatorCamera", Enum.RenderPriority.Camera.Value + 1, function()
    if not spectating then return end

    local camera = getCamera()
    if not camera then return end

    if not currentTarget or not currentTarget.Parent then
        -- target keluar game, cari target baru
        spectatePlayer(1)
        return
    end

    local character = currentTarget.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoid then
        if humanoid.Health <= 0 then
            spectatePlayer(currentIndex + 1)
            return
        end
        if camera.CameraType ~= Enum.CameraType.Custom then
            camera.CameraType = Enum.CameraType.Custom
        end
        if camera.CameraSubject ~= humanoid then
            camera.CameraSubject = humanoid
        end
    end
end)

local function stopSpectating()
    spectating = false
    currentTarget = nil
    frame.Visible = false
    toggleButton.Text = "👁 Spectate"

    local camera = getCamera()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    camera.CameraType = Enum.CameraType.Custom
    if humanoid then
        camera.CameraSubject = humanoid
    end
end

local function startSpectating()
    spectating = true
    frame.Visible = true
    toggleButton.Text = "Stop"
    spectatePlayer(1)
end

local function toggleSpectating()
    if spectating then
        stopSpectating()
    else
        startSpectating()
    end
end

-- Tombol
nextButton.MouseButton1Click:Connect(function()
    if spectating then spectatePlayer(currentIndex + 1) end
end)

previousButton.MouseButton1Click:Connect(function()
    if spectating then spectatePlayer(currentIndex - 1) end
end)

exitButton.MouseButton1Click:Connect(stopSpectating)
toggleButton.MouseButton1Click:Connect(toggleSpectating)

-- Shortcut keyboard
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.P then
        toggleSpectating()
    end
end)

-- Pemain keluar
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if spectating and leavingPlayer == currentTarget then
        task.wait(0.2)
        spectatePlayer(1)
    end
end)

-- Respawn avatar sendiri: JANGAN reset kamera kalau lagi spectate
player.CharacterAdded:Connect(function()
    if not spectating then
        task.wait(0.5)
        stopSpectating()
    end
end)

print("Spectator System Loaded!")
