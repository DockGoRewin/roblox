-- Explorer Editor V3 - Studio Lite helper (client-side)
-- Features: hierarchy, search, properties, rename, delete, duplicate, insert.
-- IMPORTANT: Client-side Instance edits may be local-only and may not be saved by Studio Lite.
-- Use only in a place/project you own or are authorized to edit.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then
    warn("[Explorer V3] LocalPlayer tidak ditemukan.")
    return
end

local playerGui = player:WaitForChild("PlayerGui", 10)
if not playerGui then
    warn("[Explorer V3] PlayerGui tidak ditemukan.")
    return
end

local GUI_NAME = "StudioLiteExplorerV3"
local MAX_ROWS = 700

pcall(function()
    local old = playerGui:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end
end)

local C = {
    bg = Color3.fromRGB(19, 22, 30),
    panel = Color3.fromRGB(27, 31, 42),
    panel2 = Color3.fromRGB(35, 40, 53),
    field = Color3.fromRGB(15, 18, 25),
    line = Color3.fromRGB(58, 66, 84),
    accent = Color3.fromRGB(75, 125, 220),
    text = Color3.fromRGB(235, 239, 247),
    muted = Color3.fromRGB(155, 165, 182),
    danger = Color3.fromRGB(160, 58, 65),
    green = Color3.fromRGB(65, 145, 105),
    selected = Color3.fromRGB(49, 76, 119),
}

local state = {
    root = workspace,
    selected = nil,
    expanded = {},
    query = "",
    properties = {},
    alive = true,
    rebuilding = false,
}

local function new(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        local ok, err = pcall(function() obj[k] = v end)
        if not ok then warn("[Explorer V3] Property " .. tostring(k) .. ": " .. tostring(err)) end
    end
    obj.Parent = parent
    return obj
end

local function corner(obj, radius)
    new("UICorner", {CornerRadius = UDim.new(0, radius or 6)}, obj)
end

local function button(parent, text, pos, size, color)
    local b = new("TextButton", {
        Position = pos, Size = size, BackgroundColor3 = color or C.panel2,
        BorderSizePixel = 0, AutoButtonColor = true, Text = text,
        TextColor3 = C.text, Font = Enum.Font.GothamSemibold, TextSize = 11,
    }, parent)
    corner(b, 6)
    return b
end

local gui = new("ScreenGui", {
    Name = GUI_NAME, ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 10000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local main = new("Frame", {
    Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(520, 570),
    BackgroundColor3 = C.bg, BorderSizePixel = 0, ClipsDescendants = true,
}, gui)
corner(main, 9)
new("UIStroke", {Color = C.line, Transparency = 0.15, Thickness = 1}, main)

local header = new("Frame", {
    Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, main)
corner(header, 9)

new("TextLabel", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(11, 0),
    Size = UDim2.new(1, -100, 1, 0), Text = "STUDIO LITE  /  EXPLORER V3",
    TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local minBtn = button(header, "—", UDim2.new(1, -68, 0, 6), UDim2.fromOffset(28, 26))
local closeBtn = button(header, "×", UDim2.new(1, -35, 0, 6), UDim2.fromOffset(28, 26), C.danger)

local toolbar = new("Frame", {
    BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 45),
    Size = UDim2.new(1, -16, 0, 32),
}, main)

local searchBox = new("TextBox", {
    Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, -150, 1, 0),
    BackgroundColor3 = C.field, BorderSizePixel = 0, ClearTextOnFocus = false,
    PlaceholderText = "Cari Instance...", PlaceholderColor3 = C.muted,
    Text = "", TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 12,
}, toolbar)
corner(searchBox, 6)

local refreshBtn = button(toolbar, "Refresh", UDim2.new(1, -144, 0, 0), UDim2.fromOffset(62, 32))
local collapseBtn = button(toolbar, "Tutup Tree", UDim2.new(1, -77, 0, 0), UDim2.fromOffset(77, 32))

local leftTitle = new("TextLabel", {
    Position = UDim2.fromOffset(8, 83), Size = UDim2.new(0.48, -10, 0, 22),
    BackgroundTransparency = 1, Text = "EXPLORER", TextColor3 = C.muted,
    Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
}, main)

local rightTitle = new("TextLabel", {
    Position = UDim2.new(0.52, 2, 0, 83), Size = UDim2.new(0.48, -10, 0, 22),
    BackgroundTransparency = 1, Text = "PROPERTIES", TextColor3 = C.muted,
    Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
}, main)

local tree = new("ScrollingFrame", {
    Position = UDim2.fromOffset(8, 106), Size = UDim2.new(0.52, -12, 1, -213),
    BackgroundColor3 = C.field, BorderSizePixel = 0, ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.muted, CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)
corner(tree, 6)
new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 1)}, tree)

local props = new("ScrollingFrame", {
    Position = UDim2.new(0.52, 2, 0, 106), Size = UDim2.new(0.48, -10, 1, -213),
    BackgroundColor3 = C.field, BorderSizePixel = 0, ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.muted, CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)
corner(props, 6)
new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)}, props)
new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6)}, props)

local actionBar = new("Frame", {
    Position = UDim2.new(0, 8, 1, -98), Size = UDim2.new(1, -16, 0, 38),
    BackgroundTransparency = 1,
}, main)

local renameBtn = button(actionBar, "Rename", UDim2.fromOffset(0, 0), UDim2.new(0.25, -4, 1, 0), C.accent)
local duplicateBtn = button(actionBar, "Duplicate", UDim2.new(0.25, 2, 0, 0), UDim2.new(0.25, -4, 1, 0))
local deleteBtn = button(actionBar, "Delete", UDim2.new(0.5, 4, 0, 0), UDim2.new(0.25, -4, 1, 0), C.danger)
local insertBtn = button(actionBar, "+ Part", UDim2.new(0.75, 6, 0, 0), UDim2.new(0.25, -6, 1, 0), C.green)

local status = new("TextLabel", {
    Position = UDim2.new(0, 8, 1, -54), Size = UDim2.new(1, -16, 0, 18),
    BackgroundTransparency = 1, Text = "Siap. Pilih Instance di Explorer.",
    TextColor3 = C.muted, Font = Enum.Font.Gotham, TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, main)

local warning = new("TextLabel", {
    Position = UDim2.new(0, 8, 1, -34), Size = UDim2.new(1, -16, 0, 26),
    BackgroundColor3 = C.panel, BorderSizePixel = 0,
    Text = "Perubahan dari client mungkin tidak tersimpan ke project Studio Lite.",
    TextColor3 = Color3.fromRGB(255, 205, 130), Font = Enum.Font.Gotham,
    TextSize = 9, TextWrapped = true,
}, main)
corner(warning, 5)

local reopen = button(gui, "OPEN EXPLORER", UDim2.new(0, 12, 0.5, 0), UDim2.fromOffset(125, 34), C.accent)
reopen.Visible = false

local function setStatus(message)
    status.Text = tostring(message)
end

local function childrenOf(inst)
    local ok, list = pcall(function() return inst:GetChildren() end)
    return ok and list or {}
end

local function safeName(inst)
    local ok, value = pcall(function() return inst.Name end)
    return ok and value or "?"
end

local function clearGui(container)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
end

local function clearProperties()
    clearGui(props)
end

local function propertyRow(label, value, order)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 43), BackgroundColor3 = C.panel,
        BorderSizePixel = 0, LayoutOrder = order or 1,
    }, props)
    corner(row, 5)

    new("TextLabel", {
        Position = UDim2.fromOffset(6, 2), Size = UDim2.new(1, -12, 0, 14),
        BackgroundTransparency = 1, Text = label, TextColor3 = C.muted,
        Font = Enum.Font.GothamSemibold, TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local box = new("TextBox", {
        Position = UDim2.fromOffset(5, 17), Size = UDim2.new(1, -10, 0, 22),
        BackgroundColor3 = C.field, BorderSizePixel = 0,
        Text = tostring(value), TextColor3 = C.text,
        Font = Enum.Font.Gotham, TextSize = 10,
        ClearTextOnFocus = false,
    }, row)
    corner(box, 4)
    return box
end

local function parseVector3(text)
    local x, y, z = text:match("^%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*$")
    if not x then return nil end
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return nil end
    return Vector3.new(x, y, z)
end

local function parseColor3(text)
    local r, g, b = text:match("^%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*$")
    if not r then return nil end
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if r > 255 or g > 255 or b > 255 then return nil end
    return Color3.fromRGB(r, g, b)
end

local function addEditableProperty(inst, label, getter, setter, formatter, parser)
    local ok, value = pcall(getter, inst)
    if not ok then return end
    local box = propertyRow(label, formatter and formatter(value) or value, #props:GetChildren() + 1)
    local committing = false
    local function commit()
        if committing then return end
        committing = true
        local parsed, result = pcall(parser or function(v) return v end, box.Text)
        if parsed and result ~= nil then
            local success, err = pcall(setter, inst, result)
            if success then
                box.TextColor3 = C.text
                setStatus(label .. " diperbarui.")
            else
                box.TextColor3 = Color3.fromRGB(255, 120, 120)
                setStatus("Gagal mengubah " .. label .. ": " .. tostring(err))
            end
        else
            box.TextColor3 = Color3.fromRGB(255, 120, 120)
            setStatus("Format " .. label .. " tidak valid.")
        end
        committing = false
    end
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then commit() end
    end)
end

local function addBooleanProperty(inst, label, getter, setter)
    local ok, value = pcall(getter, inst)
    if not ok then return end
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.panel,
        BorderSizePixel = 0, LayoutOrder = #props:GetChildren() + 1,
    }, props)
    corner(row, 5)
    new("TextLabel", {
        Position = UDim2.fromOffset(6, 0), Size = UDim2.new(1, -58, 1, 0),
        BackgroundTransparency = 1, Text = label, TextColor3 = C.text,
        Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local b = button(row, value and "ON" or "OFF", UDim2.new(1, -48, 0, 3), UDim2.fromOffset(42, 24), value and C.green or C.danger)
    b.MouseButton1Click:Connect(function()
        local currentOk, current = pcall(getter, inst)
        if not currentOk then return end
        local success = pcall(setter, inst, not current)
        if success then
            b.Text = not current and "ON" or "OFF"
            b.BackgroundColor3 = not current and C.green or C.danger
            setStatus(label .. " diubah.")
        end
    end)
end

local function addEnumProperty(inst, label, enumType, getter, setter, allowed)
    local ok, value = pcall(getter, inst)
    if not ok then return end
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 43), BackgroundColor3 = C.panel,
        BorderSizePixel = 0, LayoutOrder = #props:GetChildren() + 1,
    }, props)
    corner(row, 5)
    new("TextLabel", {
        Position = UDim2.fromOffset(6, 2), Size = UDim2.new(1, -12, 0, 14),
        BackgroundTransparency = 1, Text = label .. " (ketik nama enum)",
        TextColor3 = C.muted, Font = Enum.Font.GothamSemibold, TextSize = 8,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local box = new("TextBox", {
        Position = UDim2.fromOffset(5, 17), Size = UDim2.new(1, -10, 0, 22),
        BackgroundColor3 = C.field, BorderSizePixel = 0,
        Text = tostring(value):gsub("^Enum%.[^%.]+%.", ""),
        TextColor3 = C.text, Font = Enum.Font.Gotham, TextSize = 10,
        ClearTextOnFocus = false,
    }, row)
    corner(box, 4)
    box.FocusLost:Connect(function(enter)
        if not enter then return end
        local name = box.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if allowed and not allowed[name] then
            setStatus("Nilai " .. label .. " tidak didukung.")
            return
        end
        local enumItem
        pcall(function() enumItem = enumType[name] end)
        if enumItem then
            local success = pcall(setter, inst, enumItem)
            setStatus(success and (label .. " diperbarui.") or ("Gagal mengubah " .. label))
        else
            setStatus("Nama enum tidak valid: " .. name)
        end
    end)
end

local function showProperties(inst)
    clearProperties()
    if not inst then
        propertyRow("Selection", "Pilih Instance di panel Explorer.", 1)
        return
    end

    addEditableProperty(inst, "Name", function(o) return o.Name end,
        function(o, v) o.Name = v end, nil,
        function(v) if v == "" then return nil end return v end)

    propertyRow("ClassName", inst.ClassName, 2)

    if inst:IsA("BasePart") then
        addBooleanProperty(inst, "Anchored", function(o) return o.Anchored end, function(o, v) o.Anchored = v end)
        addBooleanProperty(inst, "CanCollide", function(o) return o.CanCollide end, function(o, v) o.CanCollide = v end)
        addBooleanProperty(inst, "CanTouch", function(o) return o.CanTouch end, function(o, v) o.CanTouch = v end)
        addEditableProperty(inst, "Transparency", function(o) return o.Transparency end,
            function(o, v) o.Transparency = math.clamp(v, 0, 1) end, nil, tonumber)
        addEditableProperty(inst, "Size (X, Y, Z)", function(o) return o.Size end,
            function(o, v) o.Size = v end,
            function(v) return string.format("%.2f, %.2f, %.2f", v.X, v.Y, v.Z) end, parseVector3)
        addEditableProperty(inst, "Position (X, Y, Z)", function(o) return o.Position end,
            function(o, v) o.Position = v end,
            function(v) return string.format("%.2f, %.2f, %.2f", v.X, v.Y, v.Z) end, parseVector3)
        addEditableProperty(inst, "Color RGB (0-255)", function(o) return o.Color end,
            function(o, v) o.Color = v end,
            function(v) return string.format("%d, %d, %d", math.floor(v.R*255), math.floor(v.G*255), math.floor(v.B*255)) end, parseColor3)
        addEnumProperty(inst, "Material", Enum.Material, function(o) return o.Material end,
            function(o, v) o.Material = v end, {
                Plastic=true, SmoothPlastic=true, Neon=true, Wood=true, WoodPlanks=true,
                Concrete=true, Brick=true, Slate=true, Grass=true, Sand=true,
                Metal=true, DiamondPlate=true, Foil=true, Glass=true, Ice=true,
                Marble=true, Granite=true, Pebble=true, Fabric=true, CorrodedMetal=true,
                Rust=true, Ground=true, Mud=true, Rock=true, Snow=true, Asphalt=true,
            })
    elseif inst:IsA("Model") then
        local ok, pivot = pcall(function() return inst:GetPivot().Position end)
        if ok then
            propertyRow("Pivot Position", string.format("%.2f, %.2f, %.2f", pivot.X, pivot.Y, pivot.Z), 3)
        end
    end

    if inst:IsA("Decal") or inst:IsA("Texture") then
        addEditableProperty(inst, "Transparency", function(o) return o.Transparency end,
            function(o, v) o.Transparency = math.clamp(v, 0, 1) end, nil, tonumber)
        addEditableProperty(inst, "Texture", function(o) return o.Texture end,
            function(o, v) o.Texture = v end)
    end

    if inst:IsA("PointLight") or inst:IsA("SpotLight") or inst:IsA("SurfaceLight") then
        addBooleanProperty(inst, "Enabled", function(o) return o.Enabled end, function(o, v) o.Enabled = v end)
        addEditableProperty(inst, "Brightness", function(o) return o.Brightness end,
            function(o, v) o.Brightness = v end, nil, tonumber)
        addEditableProperty(inst, "Range", function(o) return o.Range end,
            function(o, v) o.Range = v end, nil, tonumber)
    end
end

local function selectInstance(inst)
    if not inst then return end
    state.selected = inst
    showProperties(inst)
    setStatus("Dipilih: " .. inst:GetFullName())
end

local function addTreeRow(inst, depth, order)
    local row = new("Frame", {
        Size = UDim2.new(1, -2, 0, 25),
        BackgroundColor3 = state.selected == inst and C.selected or C.field,
        BorderSizePixel = 0, LayoutOrder = order,
    }, tree)

    local indent = math.min(depth * 11, 120)
    local kids = childrenOf(inst)
    if #kids > 0 and state.query == "" then
        local expand = button(row, state.expanded[inst] and "v" or ">", UDim2.fromOffset(indent, 1), UDim2.fromOffset(18, 23))
        expand.BackgroundTransparency = 1
        expand.TextColor3 = C.muted
        expand.MouseButton1Click:Connect(function()
            state.expanded[inst] = not state.expanded[inst]
            state.rebuild = true
        end)
    end

    local label = inst.Name .. "  [" .. inst.ClassName .. "]"
    local select = new("TextButton", {
        Position = UDim2.fromOffset(indent + 20, 0),
        Size = UDim2.new(1, -(indent + 22), 1, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Text = label, TextColor3 = inst:IsA("BasePart") and Color3.fromRGB(130, 195, 255) or C.text,
        Font = Enum.Font.Gotham, TextSize = 9, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    select.MouseButton1Click:Connect(function()
        selectInstance(inst)
        state.rebuild = true
    end)
end

local function rebuildTree()
    if state.rebuilding then return end
    state.rebuilding = true
    clearGui(tree)
    local order, count = 0, 0
    local query = state.query:lower()

    local function add(inst, depth)
        if count >= MAX_ROWS then return end
        if query == "" or safeName(inst):lower():find(query, 1, true) then
            count += 1
            order += 1
            addTreeRow(inst, depth, order)
        end
        if state.expanded[inst] and query == "" then
            for _, child in ipairs(childrenOf(inst)) do
                if count >= MAX_ROWS then break end
                add(child, depth + 1)
            end
        end
    end

    if query == "" then
        add(state.root, 0)
    else
        local ok, descendants = pcall(function() return state.root:GetDescendants() end)
        if ok then
            for _, inst in ipairs(descendants) do
                if count >= MAX_ROWS then break end
                if safeName(inst):lower():find(query, 1, true) then
                    count += 1
                    order += 1
                    addTreeRow(inst, 0, order)
                end
            end
        end
    end

    if count >= MAX_ROWS then setStatus("Batas " .. MAX_ROWS .. " baris tercapai. Persempit pencarian.") end
    state.rebuilding = false
end

local function refresh()
    rebuildTree()
    if state.selected and state.selected.Parent then
        showProperties(state.selected)
    elseif state.selected then
        state.selected = nil
        showProperties(nil)
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    state.query = searchBox.Text
    task.delay(0.2, function()
        if state.alive then rebuildTree() end
    end)
end)

refreshBtn.MouseButton1Click:Connect(refresh)
collapseBtn.MouseButton1Click:Connect(function()
    state.expanded = {[state.root] = true}
    tree.CanvasPosition = Vector2.zero
    refresh()
end)

local function askText(titleText, initial)
    -- Small in-GUI prompt; avoids relying on executor-specific input APIs.
    local overlay = new("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 50,
    }, main)
    local boxFrame = new("Frame", {
        AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(0.5,0.5),
        Size = UDim2.new(0.82,0,0,120), BackgroundColor3 = C.panel,
        BorderSizePixel = 0, ZIndex = 51,
    }, overlay)
    corner(boxFrame, 8)
    new("TextLabel", {
        Position = UDim2.fromOffset(10,7), Size = UDim2.new(1,-20,0,22),
        BackgroundTransparency = 1, Text = titleText, TextColor3 = C.text,
        Font = Enum.Font.GothamBold, TextSize = 12, ZIndex = 52,
    }, boxFrame)
    local input = new("TextBox", {
        Position = UDim2.fromOffset(10,34), Size = UDim2.new(1,-20,0,30),
        BackgroundColor3 = C.field, BorderSizePixel = 0,
        Text = initial or "", TextColor3 = C.text, PlaceholderText = "Masukkan nama...",
        Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false, ZIndex = 52,
    }, boxFrame)
    corner(input, 5)
    local result
    local okBtn = button(boxFrame, "OK", UDim2.new(0,10,1,-39), UDim2.new(0.5,-15,0,29), C.accent)
    okBtn.ZIndex = 52
    local cancelBtn = button(boxFrame, "Batal", UDim2.new(0.5,5,1,-39), UDim2.new(0.5,-15,0,29))
    cancelBtn.ZIndex = 52
    okBtn.MouseButton1Click:Connect(function()
        result = input.Text
        overlay:Destroy()
    end)
    cancelBtn.MouseButton1Click:Connect(function()
        overlay:Destroy()
    end)
    input:CaptureFocus()
    local finished = false
    local connection
    connection = overlay.AncestryChanged:Connect(function(_, parent)
        if not parent then finished = true end
    end)
    repeat task.wait() until finished or not gui.Parent
    if connection then connection:Disconnect() end
    return result
end

renameBtn.MouseButton1Click:Connect(function()
    local inst = state.selected
    if not inst then setStatus("Pilih Instance terlebih dahulu."); return end
    local name = askText("Rename Instance", inst.Name)
    if name and name ~= "" then
        local ok, err = pcall(function() inst.Name = name end)
        setStatus(ok and "Nama berhasil diubah." or ("Rename gagal: " .. tostring(err)))
        refresh()
    end
end)

deleteBtn.MouseButton1Click:Connect(function()
    local inst = state.selected
    if not inst then setStatus("Pilih Instance terlebih dahulu."); return end
    if inst == game or inst == workspace then
        setStatus("Instance root tidak boleh dihapus.")
        return
    end
    local ok, err = pcall(function() inst:Destroy() end)
    if ok then
        state.selected = nil
        showProperties(nil)
        setStatus("Instance dihapus dari client.")
    else
        setStatus("Delete gagal: " .. tostring(err))
    end
    refresh()
end)

duplicateBtn.MouseButton1Click:Connect(function()
    local inst = state.selected
    if not inst then setStatus("Pilih Instance terlebih dahulu."); return end
    local ok, clone = pcall(function() return inst:Clone() end)
    if not ok or not clone then
        setStatus("Duplicate gagal. Instance mungkin tidak Archivable.")
        return
    end
    local parent = inst.Parent
    local success, err = pcall(function()
        clone.Name = inst.Name .. "_Copy"
        clone.Parent = parent
        if clone:IsA("BasePart") and inst:IsA("BasePart") then
            clone.CFrame = inst.CFrame * CFrame.new(3, 0, 0)
        end
    end)
    if success then
        state.expanded[parent] = true
        selectInstance(clone)
        setStatus("Duplikat dibuat di client.")
    else
        pcall(function() clone:Destroy() end)
        setStatus("Duplicate gagal: " .. tostring(err))
    end
    refresh()
end)

insertBtn.MouseButton1Click:Connect(function()
    local parent = state.selected
    if not parent then parent = workspace end
    local ok, part = pcall(function()
        local p = Instance.new("Part")
        p.Name = "Part"
        p.Size = Vector3.new(4, 1, 4)
        p.Anchored = true
        p.Position = Vector3.new(0, 5, 0)
        p.Parent = parent
        return p
    end)
    if ok then
        state.expanded[parent] = true
        selectInstance(part)
        setStatus("Part baru dibuat di client.")
        refresh()
    else
        setStatus("Insert gagal: " .. tostring(part))
    end
end)

local function minimize(value)
    main.Visible = not value
    reopen.Visible = value
end
minBtn.MouseButton1Click:Connect(function() minimize(true) end)
closeBtn.MouseButton1Click:Connect(function() minimize(true) end)
reopen.MouseButton1Click:Connect(function() minimize(false); refresh() end)

-- Drag support for both touch and mouse.
do
    local dragging, startInput, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function fit()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local v = camera.ViewportSize
    main.Size = UDim2.fromOffset(math.max(310, math.min(650, v.X - 16)),
        math.max(390, math.min(620, v.Y - 20)))
end
fit()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
end

state.expanded[workspace] = true
refresh()

-- Watch for hierarchy changes, with a small debounce.
local lastChange = 0
local function markDirty()
    lastChange = os.clock()
end
pcall(function()
    workspace.DescendantAdded:Connect(markDirty)
    workspace.DescendantRemoving:Connect(markDirty)
end)

task.spawn(function()
    while state.alive and gui.Parent do
        if lastChange > 0 and os.clock() - lastChange > 0.45 then
            lastChange = 0
            refresh()
        end
        task.wait(0.2)
    end
end)

print("[Studio Lite Explorer V3] Loaded.")
setStatus("V3 siap. Perubahan mungkin hanya lokal pada client.")
