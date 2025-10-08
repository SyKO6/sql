-- StarterPlayerScripts LocalScript
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Utilities
local function clamp(val, a, b) if val < a then return a end if val > b then return b end return val end

-- UI setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FloatingButtonGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.IgnoreGuiInset = true

local function makeFloatingButton(name, initialPos, size)
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.Size = UDim2.new(0, size or 60, 0, size or 60)
	btn.Position = initialPos or UDim2.new(0.85, 0, 0.8, 0)
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundTransparency = 1
	btn.AutoButtonColor = false
	btn.Image = "rbxassetid://112619174208625" -- user will set
	btn.ZIndex = 5
	btn.Parent = screenGui

	-- Circular mask
	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(1, 0)

	-- Shadow (subtle)
	local shadow = Instance.new("ImageLabel", btn)
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.new(0.5, 0.5, 0.5, 0)
	shadow.Size = UDim2.new(1, 12, 1, 12)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://112619174208625"
	shadow.ImageTransparency = 0.9
	shadow.ZIndex = 1

	return btn
end

-- Main floating button
local mainButton = makeFloatingButton("MainFloatingButton", UDim2.new(0.9,0,0.8,0), 64)

-- Secondary floating button placeholder
local secondButton = nil
local secondButtonEnabled = false

-- Menu
local menuFrame = Instance.new("Frame")
menuFrame.Name = "FloatingMenu"
menuFrame.Size = UDim2.new(0, 360, 0, 420)
menuFrame.Position = UDim2.new(0.5, -180, 0.5, -210)
menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
menuFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.ZIndex = 10
menuFrame.Parent = screenGui

local menuCorner = Instance.new("UICorner", menuFrame)
menuCorner.CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", menuFrame)
title.Size = UDim2.new(1, -20, 0, 36)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "Floating Controls"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(230,230,230)
title.Font = Enum.Font.GothamSemibold

-- Close button
local closeBtn = Instance.new("TextButton", menuFrame)
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -38, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(220,220,220)
closeBtn.Font = Enum.Font.GothamBold
local closeCorner = Instance.new("UICorner", closeBtn)
closeCorner.CornerRadius = UDim.new(0,6)

-- Helper for creating labeled toggle rows
local function createRow(y, labelText)
	local lbl = Instance.new("TextLabel", menuFrame)
	lbl.Size = UDim2.new(0.55, -20, 0, 28)
	lbl.Position = UDim2.new(0, 10, 0, y)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextSize = 15
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.Font = Enum.Font.Gotham

	local btn = Instance.new("TextButton", menuFrame)
	btn.Size = UDim2.new(0.35, 0, 0, 28)
	btn.Position = UDim2.new(0.6, 0, 0, y)
	btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	btn.Text = "Off"
	btn.TextColor3 = Color3.fromRGB(200,200,200)
	btn.Font = Enum.Font.GothamBold
	local corner = Instance.new("UICorner", btn)
	corner.CornerRadius = UDim.new(0,6)
	return btn
end

local rowY = 56
local sizeLabel = Instance.new("TextLabel", menuFrame)
sizeLabel.Size = UDim2.new(1, -20, 0, 20)
sizeLabel.Position = UDim2.new(0, 10, 0, rowY)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Text = "Botón — Tamaño:"
sizeLabel.TextColor3 = Color3.fromRGB(200,200,200)
sizeLabel.TextSize = 14
sizeLabel.Font = Enum.Font.Gotham

rowY = rowY + 26
local sizeSmall = Instance.new("TextButton", menuFrame)
sizeSmall.Parent = menuFrame
sizeSmall.Size = UDim2.new(0, 80, 0, 28)
sizeSmall.Position = UDim2.new(0.02, 0, 0, rowY)
sizeSmall.Text = "Pequeño"
sizeSmall.Font = Enum.Font.Gotham
sizeSmall.TextSize = 14
sizeSmall.BackgroundColor3 = Color3.fromRGB(55,55,55)
Instance.new("UICorner", sizeSmall).CornerRadius = UDim.new(0,6)

local sizeMedium = sizeSmall:Clone()
sizeMedium.Parent = menuFrame
sizeMedium.Position = UDim2.new(0.28, 0, 0, rowY)
sizeMedium.Text = "Medio"

local sizeLarge = sizeSmall:Clone()
sizeLarge.Parent = menuFrame
sizeLarge.Position = UDim2.new(0.54, 0, 0, rowY)
sizeLarge.Text = "Grande"

local sizeCustom = sizeSmall:Clone()
sizeCustom.Parent = menuFrame
sizeCustom.Position = UDim2.new(0.78, 0, 0, rowY)
sizeCustom.Text = "Custom"

rowY = rowY + 40
local previewLabel = Instance.new("TextLabel", menuFrame)
previewLabel.Size = UDim2.new(1, -20, 0, 18)
previewLabel.Position = UDim2.new(0, 10, 0, rowY)
previewLabel.BackgroundTransparency = 1
previewLabel.Text = "Vista previa:"
previewLabel.TextColor3 = Color3.fromRGB(200,200,200)
previewLabel.TextSize = 14
previewLabel.Font = Enum.Font.Gotham

rowY = rowY + 20
local previewFrame = Instance.new("Frame", menuFrame)
previewFrame.Size = UDim2.new(0, 320, 0, 70)
previewFrame.Position = UDim2.new(0, 20, 0, rowY)
previewFrame.BackgroundTransparency = 1

local previewButton = Instance.new("ImageLabel", previewFrame)
previewButton.Size = UDim2.new(0, 64, 0, 64)
previewButton.Position = UDim2.new(0, 0, 0, 3)
previewButton.BackgroundTransparency = 1
previewButton.Image = ""
Instance.new("UICorner", previewButton).CornerRadius = UDim.new(1,0)

local previewText = Instance.new("TextLabel", previewFrame)
previewText.Size = UDim2.new(1, -80, 1, 0)
previewText.Position = UDim2.new(0, 80, 0, 0)
previewText.BackgroundTransparency = 1
previewText.Text = "rbxassetid://112619174208625"
previewText.TextColor3 = Color3.fromRGB(200,200,200)
previewText.TextSize = 14
previewText.Font = Enum.Font.Gotham

rowY = rowY + 80
local imageLabel = Instance.new("TextLabel", menuFrame)
imageLabel.Size = UDim2.new(1, -20, 0, 18)
imageLabel.Position = UDim2.new(0, 10, 0, rowY)
imageLabel.BackgroundTransparency = 1
imageLabel.Text = "rbxassetid://112619174208625"
imageLabel.TextColor3 = Color3.fromRGB(200,200,200)
imageLabel.TextSize = 14
imageLabel.Font = Enum.Font.Gotham

rowY = rowY + 18
local imageInput = Instance.new("TextBox", menuFrame)
imageInput.Size = UDim2.new(1, -20, 0, 28)
imageInput.Position = UDim2.new(0, 10, 0, rowY)
imageInput.PlaceholderText = "rbxassetid://112619174208625"
imageInput.ClearTextOnFocus = false
imageInput.BackgroundColor3 = Color3.fromRGB(45,45,45)
imageInput.TextColor3 = Color3.fromRGB(220,220,220)
imageInput.Font = Enum.Font.Gotham
Instance.new("UICorner", imageInput).CornerRadius = UDim.new(0,6)

rowY = rowY + 38
local secondToggle = createRow(rowY, "Segundo botón flotante")
rowY = rowY + 44
local speedLabel = Instance.new("TextLabel", menuFrame)
speedLabel.Size = UDim2.new(0.55, -20, 0, 28)
speedLabel.Position = UDim2.new(0, 10, 0, rowY)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Velocidad asignada al 2º botón:"
speedLabel.TextColor3 = Color3.fromRGB(200,200,200)
speedLabel.TextSize = 14
speedLabel.Font = Enum.Font.Gotham

local speedDisplay = Instance.new("TextBox", menuFrame)
speedDisplay.Size = UDim2.new(0.35, 0, 0, 28)
speedDisplay.Position = UDim2.new(0.6, 0, 0, rowY)
speedDisplay.BackgroundColor3 = Color3.fromRGB(50,50,50)
speedDisplay.ClearTextOnFocus = false
speedDisplay.Text = "18.8"
speedDisplay.TextColor3 = Color3.fromRGB(200,200,200)
speedDisplay.Font = Enum.Font.Gotham
Instance.new("UICorner", speedDisplay).CornerRadius = UDim.new(0,6)

rowY = rowY + 44
local clearArtifactsBtn = Instance.new("TextButton", menuFrame)
clearArtifactsBtn.Size = UDim2.new(0.96, 0, 0, 34)
clearArtifactsBtn.Position = UDim2.new(0.02, 0, 0, rowY)
clearArtifactsBtn.Text = "ClearArtifacts"
clearArtifactsBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
clearArtifactsBtn.Font = Enum.Font.GothamBold
clearArtifactsBtn.TextColor3 = Color3.fromRGB(240,240,240)
Instance.new("UICorner", clearArtifactsBtn).CornerRadius = UDim.new(0,8)

rowY = rowY + 44
local fovLabel = Instance.new("TextLabel", menuFrame)
fovLabel.Size = UDim2.new(0.55, -20, 0, 28)
fovLabel.Position = UDim2.new(0, 10, 0, rowY)
fovLabel.BackgroundTransparency = 1
fovLabel.Text = "FOV (50-120):"
fovLabel.TextColor3 = Color3.fromRGB(200,200,200)
fovLabel.TextSize = 14
fovLabel.Font = Enum.Font.Gotham

local fovInput = Instance.new("TextBox", menuFrame)
fovInput.Size = UDim2.new(0.35, 0, 0, 28)
fovInput.Position = UDim2.new(0.6, 0, 0, rowY)
fovInput.BackgroundColor3 = Color3.fromRGB(50,50,50)
fovInput.ClearTextOnFocus = false
fovInput.Text = "70"
fovInput.TextColor3 = Color3.fromRGB(200,200,200)
fovInput.Font = Enum.Font.Gotham
Instance.new("UICorner", fovInput).CornerRadius = UDim.new(0,6)

rowY = rowY + 44
local espToggle = createRow(rowY, "ESP (mostrar hitboxes)")
rowY = rowY + 44
local noclipToggle = createRow(rowY, "Noclip")
rowY = rowY + 44

-- State
local dragging = false
local dragObject = nil
local dragStart = nil
local dragStartPos = nil

local lastClickTime = 0
local dblClickThreshold = 0.28

local function makeDraggable(btn)
	local draggingLocal = false
	local inputConn, moveConn, upConn

	local function startDrag(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingLocal = true
			dragObject = btn
			dragStart = input.Position
			dragStartPos = btn.Position
			inputConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					draggingLocal = false
					dragObject = nil
					if moveConn then moveConn:Disconnect() moveConn = nil end
					if upConn then upConn:Disconnect() upConn = nil end
				end
			end)
			moveConn = UserInputService.InputChanged:Connect(function(inp)
				if draggingLocal and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
					local delta = inp.Position - dragStart
					local newPos = UDim2.new(
						0, clamp(dragStartPos.X.Offset + delta.X, 0, math.max(0, workspace.CurrentCamera.ViewportSize.X - btn.AbsoluteSize.X)),
						0, clamp(dragStartPos.Y.Offset + delta.Y, 0, math.max(0, workspace.CurrentCamera.ViewportSize.Y - btn.AbsoluteSize.Y))
					)
					btn.Position = newPos
				end
			end)
		end
	end

	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local now = tick()
			if now - (btn._lastClick or 0) <= dblClickThreshold then
				-- double click
				btn._lastClick = 0
				btn:Fire("DoubleClick")
			else
				btn._lastClick = now
				-- start drag after short delay if not a double click
				startDrag(input)
			end
		end
	end)

	-- touch/mouse move handled above by InputChanged
end

-- Simple custom event connection helper
local function bindableClick(btn)
	btn.MouseButton1Click:Connect(function()
		-- single click default handled by drag handler; this event is for normal clicks
	end)
	btn.MouseButton1Down:Connect(function() end)
	-- create a custom method for double click
	btn:DefineFast = function() end
	btn.Fire = function(_, ev)
		-- ev is "DoubleClick" -> call ._doubleClick if exists
		if ev == "DoubleClick" and btn._doubleClick then
			btn._doubleClick()
		end
	end
	btn.OnDoubleClick = function(f)
		btn._doubleClick = f
	end
end

-- Create connections for mainButton
bindableClick(mainButton)
makeDraggable(mainButton)

mainButton.OnDoubleClick(function()
	-- toggle menu
	menuFrame.Visible = not menuFrame.Visible
end)

-- single-tap should begin drag (already included)
-- allow opening menu via double-tap anywhere on button (done)

-- Image input handling
imageInput.FocusLost:Connect(function(enter)
	local txt = imageInput.Text
	if txt and txt ~= "" then
		mainButton.Image = txt
		previewButton.Image = txt
		if secondButton then secondButton.Image = txt end
	end
end)

-- Size options
local function setMainButtonSize(px)
	mainButton.Size = UDim2.new(0, px, 0, px)
	previewButton.Size = UDim2.new(0, px, 0, px)
	previewButton.Position = UDim2.new(0, 0, 0, (70 - px)/2)
end

sizeSmall.MouseButton1Click:Connect(function() setMainButtonSize(40) end)
sizeMedium.MouseButton1Click:Connect(function() setMainButtonSize(64) end)
sizeLarge.MouseButton1Click:Connect(function() setMainButtonSize(88) end)
sizeCustom.MouseButton1Click:Connect(function()
	-- open a quick prompt
	local ok = Instance.new("TextBox", menuFrame)
	ok.Size = UDim2.new(0, 120, 0, 28)
	ok.Position = UDim2.new(0.5, -60, 0, 86)
	ok.PlaceholderText = "px (30-200)"
	ok.Text = ""
	ok.BackgroundColor3 = Color3.fromRGB(50,50,50)
	ok.TextColor3 = Color3.fromRGB(220,220,220)
	ok.Font = Enum.Font.Gotham
	Instance.new("UICorner", ok).CornerRadius = UDim.new(0,6)
	ok:CaptureFocus()
	local conn
	conn = ok.FocusLost:Connect(function(enterPressed)
		local n = tonumber(ok.Text)
		n = clamp(n or 64, 30, 200)
		setMainButtonSize(n)
		conn:Disconnect()
		ok:Destroy()
	end)
end)

-- Close button
closeBtn.MouseButton1Click:Connect(function()
	menuFrame.Visible = false
end)

-- Second button toggling
local function createSecondButton()
	if secondButton then secondButton:Destroy() end
	secondButton = makeFloatingButton("SecondFloatingButton", UDim2.new(0.8,0,0.9,0), 56)
	secondButtonEnabled = true
	bindableClick(secondButton)
	makeDraggable(secondButton)
	secondButton.OnDoubleClick(function()
		-- set player speed to configured
		local speed = tonumber(speedDisplay.Text) or 18.8
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = speed
			end
		end
	end)
end

local function removeSecondButton()
	if secondButton then secondButton:Destroy() secondButton = nil end
	secondButtonEnabled = false
end

secondToggle.MouseButton1Click:Connect(function()
	secondButtonEnabled = not secondButtonEnabled
	if secondButtonEnabled then
		secondToggle.Text = "On"
		createSecondButton()
	else
		secondToggle.Text = "Off"
		removeSecondButton()
	end
end)

-- ClearArtifacts implementation
clearArtifactsBtn.MouseButton1Click:Connect(function()
	-- Global shadows off
	Lighting.GlobalShadows = false
	-- Reduce atmosphere density
	local atm = Lighting:FindFirstChildOfClass("Atmosphere")
	if atm then
		atm.Density = 0
	end
	-- adjust effects: disable bloom, blur, color correction intensity
	for _, eff in pairs(Lighting:GetChildren()) do
		if eff:IsA("BloomEffect") or eff:IsA("BlurEffect") or eff:IsA("ColorCorrectionEffect") or eff:IsA("SunRaysEffect") then
			-- try to disable or reduce
			if eff:IsA("BloomEffect") then
				eff.Intensity = 0
			elseif eff:IsA("BlurEffect") then
				eff.Size = 0
			elseif eff:IsA("ColorCorrectionEffect") then
				eff.Saturation = 0
			elseif eff:IsA("SunRaysEffect") then
				eff.Intensity = 0
			end
		end
	end
	-- camera max zoom to 1000 and try to set camera type to Custom (non-zoom style)
	camera.MaxZoomDistance = 1000
	-- "invscam" interpreted as using Scriptable camera control off-screen; we'll set CameraType to Custom and leave FOV adjustable
	camera.CameraType = Enum.CameraType.Custom
	-- slight ambient adjustment for visibility without extreme brightness
	Lighting.Ambient = Color3.fromRGB(120,120,120)
	Lighting.OutdoorAmbient = Color3.fromRGB(120,120,120)
end)

-- FOV input handling
fovInput.FocusLost:Connect(function()
	local v = tonumber(fovInput.Text) or 70
	v = clamp(v, 50, 120)
	camera.FieldOfView = v
	fovInput.Text = tostring(v)
end)

-- ESP implementation
local espEnabled = false
local espData = {}

local function createESPForCharacter(char)
	if not char then return end
	local parts = {}
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			local box = Instance.new("BoxHandleAdornment")
			box.Name = "ESPBox_" .. part.Name
			box.Adornee = part
			box.AlwaysOnTop = true
			box.ZIndex = 10
			box.Transparency = 0.6
			box.Size = part.Size
			box.Color3 = Color3.fromRGB(0, 255, 0)
			box.Parent = player.PlayerGui -- parent to playergui works for client-only adornments
			table.insert(parts, box)
		end
	end
	-- Billboard for name and distance
	local head = char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart")
	local billboard
	if head then
		billboard = Instance.new("BillboardGui", player.PlayerGui)
		billboard.Size = UDim2.new(0, 120, 0, 36)
		billboard.AlwaysOnTop = true
		local label = Instance.new("TextLabel", billboard)
		label.Size = UDim2.new(1,0,1,0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255,255,255)
		label.Font = Enum.Font.Gotham
		label.TextSize = 14
		label.Text = char.Name
		billboard.Adornee = head
	end
	return {boxes = parts, nameGui = billboard}
end

local function removeESPForChar(playerChar)
	if not playerChar then return end
	for _, v in pairs(espData[playerChar]) do
		if type(v) == "table" then
			for _, obj in pairs(v) do
				if obj and obj.Parent then pcall(function() obj:Destroy() end) end
			end
		elseif v and v.Parent then
			pcall(function() v:Destroy() end)
		end
	end
	espData[playerChar] = nil
end

local function updateESP()
	for pl, data in pairs(espData) do
		if pl.Character and pl.Character.Parent then
			local head = pl.Character:FindFirstChild("Head") or pl.Character:FindFirstChildWhichIsA("BasePart")
			if data.nameGui and head then
				local label = data.nameGui:FindFirstChildWhichIsA("TextLabel")
				if label then
					local dist = math.floor((player.Character and player.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart.Position - head.Position).Magnitude) or 0)
					label.Text = pl.Name .. " - " .. tostring(dist) .. " studs"
				end
			end
		else
			removeESPForChar(pl)
		end
	end
end

espToggle.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	if espEnabled then
		espToggle.Text = "On"
		-- create for all other players
		for _, pl in pairs(Players:GetPlayers()) do
			if pl ~= player and pl.Character then
				espData[pl] = createESPForCharacter(pl.Character)
			end
		end
		Players.PlayerAdded:Connect(function(pl)
			if pl ~= player then
				pl.CharacterAdded:Connect(function(char)
					if espEnabled then
						espData[pl] = createESPForCharacter(char)
					end
				end)
			end
		end)
		for _, pl in pairs(Players:GetPlayers()) do
			if pl ~= player then
				pl.CharacterAdded:Connect(function(char)
					if espEnabled then
						espData[pl] = createESPForCharacter(char)
					end
				end)
			end
		end
	else
		espToggle.Text = "Off"
		for pl, _ in pairs(espData) do
			removeESPForChar(pl)
		end
	end
end)

-- Noclip implementation
local noclipEnabled = false
local noclipConn

noclipToggle.MouseButton1Click:Connect(function()
	noclipEnabled = not noclipEnabled
	if noclipEnabled then
		noclipToggle.Text = "On"
		noclipConn = RunService.Stepped:Connect(function()
			local char = player.Character
			if char then
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		noclipToggle.Text = "Off"
		if noclipConn then noclipConn:Disconnect() noclipConn = nil end
		-- restore collisions on respawn
		local char = player.Character
		if char then
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
					part.CanCollide = true
				end
			end
		end
	end
end)

-- Keep preview/button images synced on start
previewButton.Image = mainButton.Image

-- Keep ESP distances updating
RunService.RenderStepped:Connect(function()
	if espEnabled then updateESP() end
end)

-- When player character spawns, ensure camera settings and default values
local function onCharacterAdded(char)
	-- ensure humanoid root exists
	local humanoid = char:WaitForChild("Humanoid", 5)
	-- ensure default WalkSpeed not to break
	if humanoid then
		if humanoid.WalkSpeed == 0 then humanoid.WalkSpeed = 16 end
	end
	-- reset collision if noclip off
	if not noclipEnabled then
		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = true
			end
		end
	end
	-- attach ESP if enabled
	if espEnabled then
		espData[player] = espData[player] or {}
		-- attach for others already handled by PlayerAdded/CharacterAdded above
	end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

-- ensure main button drag works across viewport resizing
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	-- clamp position to screen
	local pos = mainButton.Position
	local size = mainButton.AbsoluteSize
	local vx, vy = workspace.CurrentCamera.ViewportSize.X, workspace.CurrentCamera.ViewportSize.Y
	local nx = clamp(pos.X.Offset, 0, math.max(0, vx - size.X))
	local ny = clamp(pos.Y.Offset, 0, math.max(0, vy - size.Y))
	mainButton.Position = UDim2.new(0, nx, 0, ny)
	if secondButton then
		local pos2 = secondButton.Position
		local s2 = secondButton.AbsoluteSize
		local nx2 = clamp(pos2.X.Offset, 0, math.max(0, vx - s2.X))
		local ny2 = clamp(pos2.Y.Offset, 0, math.max(0, vy - s2.Y))
		secondButton.Position = UDim2.new(0, nx2, 0, ny2)
	end
end)

-- Make sure main button click-drag vs double-click separation works for touches
-- We'll simulate double-click by checking last click time on InputBegan
mainButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local now = tick()
		if now - lastClickTime <= dblClickThreshold then
			-- double click
			lastClickTime = 0
			menuFrame.Visible = not menuFrame.Visible
		else
			lastClickTime = now
			-- start dragging handled in makeDraggable
		end
	end
end)

-- secondButton creation via menu toggle persists across runs; load toggles initial state
secondToggle.Text = secondButtonEnabled and "On" or "Off"
espToggle.Text = espEnabled and "On" or "Off"
noclipToggle.Text = noclipEnabled and "On" or "Off"
secondToggle.Text = secondButtonEnabled and "On" or "Off"

-- Ensure second button can also be double-clicked to set speed (if created externally)
if secondButton then
	secondButton.OnDoubleClick(function()
		local speed = tonumber(speedDisplay.Text) or 18.8
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = speed
			end
		end
	end)
end

-- Final notes (silent): initial values
camera.FieldOfView = tonumber(fovInput.Text) or 70
camera.MaxZoomDistance = 1000

-- Ensure preview shows current main button image continuously
RunService.Heartbeat:Connect(function()
	if previewButton.Image ~= mainButton.Image then
		previewButton.Image = mainButton.Image
	end
end)