-- Map Explorer V2 | Delta-friendly | Mobile + PC
-- Read-only explorer for client-visible Roblox instances.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GUI_NAME = "MapExplorerV2"
local MAX_ROWS = 1000
local ROOT_NAMES = {
    "Workspace", "ReplicatedStorage", "Lighting", "Players",
    "StarterGui", "StarterPack", "SoundService"
}

-- Remove an older copy before creating the new interface.
pcall(function()
    local old = playerGui:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end
end)

local state = {
    root = workspace,
    rootName = "Workspace",
    expanded = {},
    selected = nil,
    filter = "",
    highlight = nil,
    dirty = true,
    minimized = false,
    alive = true,
}

local COLORS = {
    panel = Color3.fromRGB(22, 25, 34),
    header = Color3.fromRGB(31, 36, 49),
    surface = Color3.fromRGB(15, 18, 26),
    button = Color3.fromRGB(48, 56, 73),
    accent = Color3.fromRGB(91, 133, 220),
    text = Color3.fromRGB(235, 238, 245),
    muted = Color3.fromRGB(155, 165, 183),
    selected = Color3.fromRGB(48, 75, 120),
    red = Color3.fromRGB(165, 65, 72),
}

local function create(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local gui = create("ScreenGui", {
    Name = GUI_NAME,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 9999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local main = create("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.52),
    Size = UDim2.new(0, 410, 0, 500),
    BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)
create("UICorner", {CornerRadius = UDim.new(0, 10)}, main)
create("UIStroke", {Color = Color3.fromRGB(65, 76, 99), Transparency = 0.35, Thickness = 1}, main)

local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = COLORS.header,
    BorderSizePixel = 0,
}, main)
create("UICorner", {CornerRadius = UDim.new(0, 10)}, header)

local title = create("TextLabel", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(12, 0),
    Size = UDim2.new(1, -112, 1, 0),
    Font = Enum.Font.GothamBold,
    Text = "MAP EXPLORER  V2",
    TextColor3 = COLORS.text,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local function makeButton(parent, text, size, position, color)
    local b = create("TextButton", {
        Size = size,
        Position = position,
        BackgroundColor3 = color or COLORS.button,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Font = Enum.Font.GothamSemibold,
        Text = text,
        TextColor3 = COLORS.text,
        TextSize = 12,
    }, parent)
    create("UICorner", {CornerRadius = UDim.new(0, 6)}, b)
    return b
end

local minimizeBtn = makeButton(header, "—", UDim2.fromOffset(30, 26), UDim2.new(1, -70, 0, 6))
local closeBtn = makeButton(header, "×", UDim2.fromOffset(30, 26), UDim2.new(1, -36, 0, 6), COLORS.red)

local controls = create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(8, 46),
    Size = UDim2.new(1, -16, 0, 30),
}, main)

local rootBtn = makeButton(controls, "Workspace  ▾", UDim2.new(0, 124, 1, 0), UDim2.fromOffset(0, 0))
local search = create("TextBox", {
    Position = UDim2.fromOffset(132, 0),
    Size = UDim2.new(1, -222, 1, 0),
    BackgroundColor3 = COLORS.surface,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Font = Enum.Font.Gotham,
    PlaceholderText = "Cari nama objek...",
    PlaceholderColor3 = COLORS.muted,
    Text = "",
    TextColor3 = COLORS.text,
    TextSize = 12,
}, controls)
create("UICorner", {CornerRadius = UDim.new(0, 6)}, search)

local refreshBtn = makeButton(controls, "↻", UDim2.fromOffset(38, 30), UDim2.new(1, -82, 0, 0))
local collapseBtn = makeButton(controls, "Reset", UDim2.fromOffset(38, 30), UDim2.new(1, -40, 0, 0))

local tree = create("ScrollingFrame", {
    Name = "Tree",
    Position = UDim2.fromOffset(8, 84),
    Size = UDim2.new(1, -16, 1, -224),
    BackgroundColor3 = COLORS.surface,
    BorderSizePixel = 0,
    ScrollBarThickness = 5,
    ScrollBarImageColor3 = COLORS.muted,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)
create("UICorner", {CornerRadius = UDim.new(0, 7)}, tree)
local listLayout = create("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 1),
}, tree)

local detail = create("TextLabel", {
    Name = "Details",
    Position = UDim2.new(0, 8, 1, -130),
    Size = UDim2.new(1, -16, 0, 86),
    BackgroundColor3 = COLORS.surface,
    BorderSizePixel = 0,
    Font = Enum.Font.Code,
    Text = "Pilih objek untuk melihat detail.",
    TextColor3 = COLORS.muted,
    TextSize = 11,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
}, main)
create("UIPadding", {
    PaddingTop = UDim.new(0, 7),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 6),
}, detail)
create("UICorner", {CornerRadius = UDim.new(0, 7)}, detail)

local copyBtn = makeButton(main, "Salin Path", UDim2.new(0.5, -12, 0, 28), UDim2.new(0, 8, 1, -36))
local highlightBtn = makeButton(main, "Highlight", UDim2.new(0.5, -12, 0, 28), UDim2.new(0.5, 4, 1, -36))

-- Small reopen button remains available after minimizing or closing the panel.
local reopenBtn = makeButton(gui, "OPEN EXPLORER", UDim2.fromOffset(124, 34), UDim2.new(0, 12, 0.5, 0), COLORS.accent)
reopenBtn.Visible = false

local function safeGetChildren(inst)
    local ok, result = pcall(function()
        return inst:GetChildren()
    end)
    return ok and result or {}
end

local function escapePathName(name)
    return string.format("[%q]", name)
end

local function getPath(inst)
    local parts = {}
    local current = inst
    while current and current ~= game do
        local name = current.Name
        if name:match("^[%a_][%w_]*$") then
            table.insert(parts, 1, "." .. name)
        else
            table.insert(parts, 1, escapePathName(name))
        end
        current = current.Parent
    end
    return "game" .. table.concat(parts)
end

local function describe(inst)
    local children = safeGetChildren(inst)
    local lines = {
        "Name  : " .. inst.Name,
        "Class : " .. inst.ClassName,
        "Anak  : " .. tostring(#children),
    }

    pcall(function()
        if inst:IsA("BasePart") then
            local p, s = inst.Position, inst.Size
            table.insert(lines, string.format("Pos   : %.1f, %.1f, %.1f", p.X, p.Y, p.Z))
            table.insert(lines, string.format("Size  : %.1f, %.1f, %.1f", s.X, s.Y, s.Z))
        elseif inst:IsA("Model") then
            local p = inst:GetPivot().Position
            table.insert(lines, string.format("Pivot : %.1f, %.1f, %.1f", p.X, p.Y, p.Z))
        end
    end)

    return table.concat(lines, "\n") .. "\n\n" .. getPath(inst)
end

local function classColor(inst)
    if inst:IsA("BasePart") then return Color3.fromRGB(125, 195, 255) end
    if inst:IsA("Model") then return Color3.fromRGB(255, 205, 125) end
    if inst:IsA("Folder") then return Color3.fromRGB(185, 185, 200) end
    if inst:IsA("LuaSourceContainer") then return Color3.fromRGB(145, 225, 155) end
    return COLORS.text
end

local rowCount = 0
local function addRow(inst, depth)
    if rowCount >= MAX_ROWS then return end
    rowCount += 1

    local children = safeGetChildren(inst)
    local hasChildren = #children > 0
    local isExpanded = state.expanded[inst] == true

    local row = create("Frame", {
        Size = UDim2.new(1, -2, 0, 25),
        BackgroundColor3 = state.selected == inst and COLORS.selected or COLORS.surface,
        BorderSizePixel = 0,
        LayoutOrder = rowCount,
    }, tree)

    local indent = math.min(depth * 13, 180)
    if hasChildren and state.filter == "" then
        local arrow = makeButton(row, isExpanded and "▼" or "▶",
            UDim2.fromOffset(22, 23), UDim2.fromOffset(indent, 1))
        arrow.BackgroundTransparency = 1
        arrow.TextColor3 = COLORS.muted
        arrow.TextSize = 10
        arrow.MouseButton1Click:Connect(function()
            state.expanded[inst] = not isExpanded
            state.dirty = true
        end)
    end

    local selectBtn = create("TextButton", {
        Position = UDim2.fromOffset(indent + 23, 0),
        Size = UDim2.new(1, -(indent + 27), 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        Text = inst.Name .. "  [" .. inst.ClassName .. "]",
        TextColor3 = classColor(inst),
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    selectBtn.MouseButton1Click:Connect(function()
        state.selected = inst
        detail.Text = describe(inst)
        if state.highlight then
            pcall(function() state.highlight.Adornee = inst end)
        end
        state.dirty = true
    end)
end

local function addTree(inst, depth)
    if rowCount >= MAX_ROWS then return end
    addRow(inst, depth)

    if state.expanded[inst] then
        for _, child in ipairs(safeGetChildren(inst)) do
            if rowCount >= MAX_ROWS then break end
            addTree(child, depth + 1)
        end
    end
end

local function rebuild()
    for _, child in ipairs(tree:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    rowCount = 0
    if not state.root or not state.root.Parent and state.root ~= game then
        detail.Text = "Root tidak tersedia. Tekan Refresh."
        return
    end

    if state.filter ~= "" then
        local query = state.filter:lower()
        local ok, descendants = pcall(function()
            return state.root:GetDescendants()
        end)
        if ok then
            for _, inst in ipairs(descendants) do
                if rowCount >= MAX_ROWS then break end
                if inst.Name:lower():find(query, 1, true) then
                    addRow(inst, 0)
                end
            end
        end
    else
        addTree(state.root, 0)
    end

    if rowCount >= MAX_ROWS then
        detail.Text = "Batas tampilan " .. MAX_ROWS .. " baris tercapai. Gunakan pencarian untuk mempersempit hasil."
    end
end

local rootIndex = 1
rootBtn.MouseButton1Click:Connect(function()
    rootIndex = rootIndex % #ROOT_NAMES + 1
    local name = ROOT_NAMES[rootIndex]
    local ok, service = pcall(function()
        return game:GetService(name)
    end)
    if ok and service then
        state.root = service
        state.rootName = name
        state.expanded = {[service] = true}
        rootBtn.Text = name .. "  ▾"
        tree.CanvasPosition = Vector2.zero
        state.dirty = true
    end
end)

local searchToken = 0
search:GetPropertyChangedSignal("Text"):Connect(function()
    state.filter = search.Text
    searchToken += 1
    local token = searchToken
    task.delay(0.25, function()
        if state.alive and token == searchToken then
            state.dirty = true
        end
    end)
end)

refreshBtn.MouseButton1Click:Connect(function()
    state.dirty = true
end)

collapseBtn.MouseButton1Click:Connect(function()
    state.expanded = {[state.root] = true}
    tree.CanvasPosition = Vector2.zero
    state.dirty = true
end)

copyBtn.MouseButton1Click:Connect(function()
    if not state.selected then
        copyBtn.Text = "Pilih objek dulu"
        task.delay(1.2, function()
            if copyBtn.Parent then copyBtn.Text = "Salin Path" end
        end)
        return
    end

    local path = getPath(state.selected)
    local copied = false

    -- Executors expose different clipboard function names.
    for _, name in ipairs({"setclipboard", "toclipboard", "setrbxclipboard"}) do
        local fn = nil
        pcall(function() fn = getfenv and getfenv()[name] end)
        if type(fn) == "function" then
            copied = pcall(fn, path)
            if copied then break end
        end
    end

    if copied then
        copyBtn.Text = "Tersalin ✓"
    else
        copyBtn.Text = "Path di Output"
        print("[Map Explorer] " .. path)
    end
    task.delay(1.4, function()
        if copyBtn.Parent then copyBtn.Text = "Salin Path" end
    end)
end)

highlightBtn.MouseButton1Click:Connect(function()
    if state.highlight then
        pcall(function() state.highlight:Destroy() end)
        state.highlight = nil
        highlightBtn.Text = "Highlight"
        return
    end

    if not state.selected then
        highlightBtn.Text = "Pilih objek dulu"
        task.delay(1.2, function()
            if highlightBtn.Parent then highlightBtn.Text = "Highlight" end
        end)
        return
    end

    local ok, h = pcall(function()
        local item = Instance.new("Highlight")
        item.Name = "MapExplorerHighlight"
        item.FillColor = Color3.fromRGB(255, 190, 55)
        item.OutlineColor = Color3.fromRGB(255, 235, 160)
        item.FillTransparency = 0.65
        item.OutlineTransparency = 0
        item.Adornee = state.selected
        item.Parent = workspace
        return item
    end)

    if ok then
        state.highlight = h
        highlightBtn.Text = "Matikan Highlight"
    else
        highlightBtn.Text = "Tidak didukung"
        task.delay(1.3, function()
            if highlightBtn.Parent then highlightBtn.Text = "Highlight" end
        end)
    end
end)

local function setMinimized(value)
    state.minimized = value
    main.Visible = not value
    reopenBtn.Visible = value
end

minimizeBtn.MouseButton1Click:Connect(function()
    setMinimized(true)
end)

closeBtn.MouseButton1Click:Connect(function()
    setMinimized(true)
end)

reopenBtn.MouseButton1Click:Connect(function()
    setMinimized(false)
    state.dirty = true
end)

-- Drag window with mouse or touch. Dragging starts only from the title area.
do
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPosition = nil

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
            dragInput = input

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end)
end

-- Responsive sizing for narrow phone screens.
local function updateSize()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local width = math.max(290, math.min(410, viewport.X - 20))
    local height = math.max(330, math.min(500, viewport.Y - 30))
    main.Size = UDim2.fromOffset(width, height)
end

updateSize()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)
end

-- Refresh only when needed; debounce repeated instance changes.
task.spawn(function()
    while state.alive and gui.Parent do
        if state.dirty and main.Visible then
            state.dirty = false
            local ok, err = pcall(rebuild)
            if not ok then
                warn("[Map Explorer V2] " .. tostring(err))
                detail.Text = "Gagal memuat tree. Tekan Refresh."
            end
        end
        task.wait(0.15)
    end
end)

-- Workspace changes mark the tree dirty without forcing an immediate rebuild.
pcall(function()
    workspace.DescendantAdded:Connect(function()
        state.dirty = true
    end)
    workspace.DescendantRemoving:Connect(function()
        state.dirty = true
    end)
end)

state.expanded[workspace] = true
state.dirty = true

print("[Map Explorer V2] Loaded successfully.")
