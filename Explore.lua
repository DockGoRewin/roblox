-- MapExplorer.lua (LocalScript)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local MAX_ROWS = 1500
local ROOT_NAMES = {"Workspace","ReplicatedStorage","Lighting","Players","StarterGui","StarterPack","SoundService"}

local state = {
	root = workspace,
	expanded = {},
	selected = nil,
	filter = "",
	highlight = nil,
	dirty = false,
}

-- ============ GUI ============
local gui = Instance.new("ScreenGui")
gui.Name = "MapExplorer"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(380, 460)
main.Position = UDim2.new(0, 20, 0.5, -230)
main.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
main.BorderSizePixel = 0
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local function label(parent, text, size, pos, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.Size = size
	l.Position = pos
	l.TextColor3 = Color3.fromRGB(230, 230, 235)
	l.Font = font or Enum.Font.Gotham
	l.TextSize = 13
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

local function button(parent, text, size, pos, color)
	local b = Instance.new("TextButton")
	b.Text = text
	b.Size = size
	b.Position = pos
	b.BackgroundColor3 = color or Color3.fromRGB(55, 55, 66)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 12
	b.AutoButtonColor = true
	b.BorderSizePixel = 0
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
	return b
end

-- Title bar (drag)
local title = Instance.new("Frame")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(42, 42, 52)
title.BorderSizePixel = 0
title.Parent = main
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)
label(title, "  🗺️ Map Explorer", UDim2.new(1, -40, 1, 0), UDim2.new(0, 0, 0, 0), Enum.Font.GothamBold)
local closeBtn = button(title, "X", UDim2.fromOffset(24, 22), UDim2.new(1, -30, 0, 4), Color3.fromRGB(170, 55, 55))

-- Root selector
local rootBtn = button(main, "Root: Workspace", UDim2.new(0, 130, 0, 24), UDim2.new(0, 8, 0, 36))
local search = Instance.new("TextBox")
search.PlaceholderText = "Cari nama..."
search.Text = ""
search.ClearTextOnFocus = false
search.Size = UDim2.new(1, -240, 0, 24)
search.Position = UDim2.new(0, 144, 0, 36)
search.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
search.TextColor3 = Color3.new(1, 1, 1)
search.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
search.Font = Enum.Font.Gotham
search.TextSize = 12
search.BorderSizePixel = 0
search.Parent = main
Instance.new("UICorner", search).CornerRadius = UDim.new(0, 5)
local refreshBtn = button(main, "⟳", UDim2.fromOffset(40, 24), UDim2.new(1, -92, 0, 36))
local collapseBtn = button(main, "▲ All", UDim2.fromOffset(44, 24), UDim2.new(1, -48, 0, 36))

-- Tree
local tree = Instance.new("ScrollingFrame")
tree.Size = UDim2.new(1, -16, 1, -210)
tree.Position = UDim2.new(0, 8, 0, 66)
tree.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
tree.BorderSizePixel = 0
tree.ScrollBarThickness = 6
tree.CanvasSize = UDim2.new()
tree.AutomaticCanvasSize = Enum.AutomaticSize.Y
tree.Parent = main
Instance.new("UIListLayout", tree).SortOrder = Enum.SortOrder.LayoutOrder

-- Detail panel
local detail = Instance.new("TextLabel")
detail.Size = UDim2.new(1, -16, 0, 100)
detail.Position = UDim2.new(0, 8, 1, -138)
detail.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
detail.BorderSizePixel = 0
detail.TextColor3 = Color3.fromRGB(200, 200, 210)
detail.Font = Enum.Font.Code
detail.TextSize = 12
detail.TextXAlignment = Enum.TextXAlignment.Left
detail.TextYAlignment = Enum.TextYAlignment.Top
detail.TextWrapped = true
detail.Text = "Pilih objek untuk melihat detail."
detail.Parent = main

local copyBtn = button(main, "Salin Path", UDim2.new(0.5, -12, 0, 26), UDim2.new(0, 8, 1, -32))
local hlBtn = button(main, "Highlight", UDim2.new(0.5, -12, 0, 26), UDim2.new(0.5, 4, 1, -32))

-- ============ Helpers ============
local function getPath(inst)
	local parts = {}
	local cur = inst
	while cur and cur ~= game do
		local n = cur.Name
		if n:match("^[%a_][%w_]*$") then
			table.insert(parts, 1, "." .. n)
		else
			table.insert(parts, 1, '["' .. n .. '"]')
		end
		cur = cur.Parent
	end
	return "game" .. table.concat(parts)
end

local function describe(inst)
	local lines = {
		"Name : " .. inst.Name,
		"Class: " .. inst.ClassName,
		"Anak : " .. #inst:GetChildren(),
	}
	if inst:IsA("BasePart") then
		local p = inst.Position
		table.insert(lines, string.format("Pos  : %.1f, %.1f, %.1f", p.X, p.Y, p.Z))
		table.insert(lines, string.format("Size : %.1f, %.1f, %.1f", inst.Size.X, inst.Size.Y, inst.Size.Z))
	elseif inst:IsA("Model") then
		local ok, pv = pcall(function() return inst:GetPivot().Position end)
		if ok then table.insert(lines, string.format("Pivot: %.1f, %.1f, %.1f", pv.X, pv.Y, pv.Z)) end
	end
	return table.concat(lines, "\n")
end

local function classColor(inst)
	if inst:IsA("BasePart") then return Color3.fromRGB(120, 200, 255) end
	if inst:IsA("Model") then return Color3.fromRGB(255, 210, 120) end
	if inst:IsA("Folder") then return Color3.fromRGB(180, 180, 190) end
	if inst:IsA("LuaSourceContainer") then return Color3.fromRGB(140, 230, 140) end
	return Color3.fromRGB(225, 225, 230)
end

-- ============ Tree build ============
local rowCount

local function addRow(inst, depth)
	if rowCount >= MAX_ROWS then return end
	rowCount += 1

	local hasKids = #inst:GetChildren() > 0
	local row = Instance.new("TextButton")
	row.Size = UDim2.new(1, 0, 0, 20)
	row.BackgroundColor3 = (state.selected == inst) and Color3.fromRGB(60, 90, 150) or Color3.fromRGB(20, 20, 26)
	row.BorderSizePixel = 0
	row.AutoButtonColor = false
	row.Text = ""
	row.LayoutOrder = rowCount
	row.Parent = tree

	local indent = depth * 14
	if hasKids and state.filter == "" then
		local arrow = Instance.new("TextButton")
		arrow.BackgroundTransparency = 1
		arrow.Size = UDim2.fromOffset(16, 20)
		arrow.Position = UDim2.fromOffset(indent, 0)
		arrow.Text = state.expanded[inst] and "▼" or "▶"
		arrow.TextColor3 = Color3.fromRGB(170, 170, 180)
		arrow.TextSize = 10
		arrow.Font = Enum.Font.Gotham
		arrow.Parent = row
		arrow.MouseButton1Click:Connect(function()
			state.expanded[inst] = not state.expanded[inst] or nil
			state.dirty = true
		end)
	end

	local txt = label(row, inst.Name .. "  [" .. inst.ClassName .. "]",
		UDim2.new(1, -indent - 20, 1, 0), UDim2.fromOffset(indent + 18, 0))
	txt.TextColor3 = classColor(inst)
	txt.TextTruncate = Enum.TextTruncate.AtEnd

	row.MouseButton1Click:Connect(function()
		state.selected = inst
		detail.Text = describe(inst) .. "\n" .. getPath(inst)
		if state.highlight then state.highlight.Adornee = inst end
		state.dirty = true
	end)
end

local function addTree(inst, depth)
	addRow(inst, depth)
	if state.expanded[inst] then
		for _, c in ipairs(inst:GetChildren()) do
			if rowCount >= MAX_ROWS then return end
			addTree(c, depth + 1)
		end
	end
end

local function rebuild()
	for _, c in ipairs(tree:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	rowCount = 0

	if state.filter ~= "" then
		local q = state.filter:lower()
		for _, d in ipairs(state.root:GetDescendants()) do
			if rowCount >= MAX_ROWS then break end
			if d.Name:lower():find(q, 1, true) then addRow(d, 0) end
		end
	else
		addTree(state.root, 0)
	end
end

-- ============ Events ============
local rootIndex = 1
rootBtn.MouseButton1Click:Connect(function()
	for _ = 1, #ROOT_NAMES do
		rootIndex = rootIndex % #ROOT_NAMES + 1
		local ok, svc = pcall(game.GetService, game, ROOT_NAMES[rootIndex])
		if ok and svc then
			state.root = svc
			state.expanded = { [svc] = true }
			rootBtn.Text = "Root: " .. ROOT_NAMES[rootIndex]
			state.dirty = true
			return
		end
	end
end)

search:GetPropertyChangedSignal("Text"):Connect(function()
	state.filter = search.Text
	state.dirty = true
end)

refreshBtn.MouseButton1Click:Connect(function() state.dirty = true end)
collapseBtn.MouseButton1Click:Connect(function()
	state.expanded = { [state.root] = true }
	state.dirty = true
end)

copyBtn.MouseButton1Click:Connect(function()
	if not state.selected then return end
	local path = getPath(state.selected)
	local ok = pcall(function() setclipboard(path) end)
	copyBtn.Text = ok and "Tersalin ✓" or "Lihat Output"
	if not ok then print(path) end
	task.delay(1.2, function() copyBtn.Text = "Salin Path" end)
end)

hlBtn.MouseButton1Click:Connect(function()
	if state.highlight then
		state.highlight:Destroy()
		state.highlight = nil
		hlBtn.Text = "Highlight"
	elseif state.selected then
		local h = Instance.new("Highlight")
		h.FillColor = Color3.fromRGB(255, 200, 0)
		h.FillTransparency = 0.6
		h.Adornee = state.selected
		h.Parent = gui
		state.highlight = h
		hlBtn.Text = "Matikan Highlight"
	end
end)

closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)
UIS.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == Enum.KeyCode.RightControl then
		main.Visible = not main.Visible
	end
end)

-- Drag
do
	local dragging, startPos, startInput
	title.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, startInput, startPos = true, i.Position, main.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - startInput
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

-- Loop render (debounce)
task.spawn(function()
	while gui.Parent do
		if state.dirty and main.Visible then
			state.dirty = false
			rebuild()
		end
		task.wait(0.1)
	end
end)

-- Auto-refresh saat map berubah
local function watch(root)
	root.DescendantAdded:Connect(function() state.dirty = true end)
	root.DescendantRemoving:Connect(function() state.dirty = true end)
end
watch(workspace)

state.expanded[state.root] = true
state.dirty = true
