--// SHIFT LOCK MANAGER + TOAST NOTIFICATION UI
-- Pega este script en StarterPlayerScripts o ejecútalo como LocalScript

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- CONFIG
local FOV = 75
local MIN_ZOOM = 0.5
local MAX_ZOOM = 1000
local TOAST_DURATION = 5

-- // == FUNCIONES BASE == //
local function fixCamera()
	local cam = workspace.CurrentCamera
	if not cam then return end
	if cam.FieldOfView < FOV then cam.FieldOfView = FOV end
	player.CameraMode = Enum.CameraMode.Classic
	player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
	player.CameraMinZoomDistance = MIN_ZOOM
	player.CameraMaxZoomDistance = MAX_ZOOM
	player.DevEnableMouseLock = true
end

-- shiftlock state
local shiftLockEnabled = player.DevEnableMouseLock and UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter

local function setShiftLock(state)
	player.DevEnableMouseLock = true
	UserInputService.MouseBehavior = state and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
end

--// == NOTIFICACIÓN == //
local function showToast(title, color)
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "ToastUI"
	ScreenGui.Parent = playerGui

	local Frame = Instance.new("Frame")
	Frame.AnchorPoint = Vector2.new(0, 1)
	Frame.Position = UDim2.new(0, 20, 1, -20)
	Frame.Size = UDim2.new(0, 280, 0, 60)
	Frame.BackgroundColor3 = color
	Frame.BackgroundTransparency = 0.1
	Frame.BorderSizePixel = 0
	Frame.Visible = false
	Frame.Parent = ScreenGui
	Frame.ClipsDescendants = true

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 10)
	Corner.Parent = Frame

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -40, 1, -15)
	Label.Position = UDim2.new(0, 10, 0, 5)
	Label.BackgroundTransparency = 1
	Label.Font = Enum.Font.GothamBold
	Label.TextScaled = true
	Label.TextColor3 = Color3.fromRGB(255, 255, 255)
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Text = title
	Label.Parent = Frame

	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Size = UDim2.new(0, 25, 0, 25)
	CloseBtn.Position = UDim2.new(1, -30, 0, 5)
	CloseBtn.Text = "✕"
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextScaled = true
	CloseBtn.BackgroundTransparency = 1
	CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	CloseBtn.Parent = Frame

	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.new(1, 0, 0, 4)
	Bar.Position = UDim2.new(0, 0, 1, -4)
	Bar.BackgroundColor3 = Color3.fromRGB(255,255,255)
	Bar.BorderSizePixel = 0
	Bar.Parent = Frame

	local Corner2 = Instance.new("UICorner")
	Corner2.CornerRadius = UDim.new(0, 4)
	Corner2.Parent = Bar

	-- ping sound
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9118823102"
	sound.Volume = 0.3
	sound.PlayOnRemove = true
	sound.Parent = ScreenGui
	sound:Destroy()

	-- animation
	Frame.Position = UDim2.new(0, -300, 1, -20)
	Frame.Visible = true
	Frame:TweenPosition(UDim2.new(0, 20, 1, -20), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.35, true)

	local start = tick()
	local running = true

	CloseBtn.MouseButton1Click:Connect(function()
		running = false
	end)

	task.spawn(function()
		while running and tick() - start < TOAST_DURATION do
			local t = 1 - ((tick() - start) / TOAST_DURATION)
			Bar.Size = UDim2.new(t, 0, 0, 4)
			task.wait(0.05)
		end
		Frame:TweenPosition(UDim2.new(0, -300, 1, -20), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
		task.wait(0.3)
		ScreenGui:Destroy()
	end)
end

--// == COMANDO CHAT == //
player.Chatted:Connect(function(msg)
	msg = msg:lower()
	if msg == ".sh" then
		shiftLockEnabled = not shiftLockEnabled
		setShiftLock(shiftLockEnabled)
		showToast(
			shiftLockEnabled and "Shift Lock Activado" or "Shift Lock Desactivado",
			shiftLockEnabled and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(255, 100, 100)
		)
	end
end)

--// == PROTECCIÓN CONTINUA == //
RunService.Heartbeat:Connect(function()
	fixCamera()
	if player.DevEnableMouseLock ~= true then
		player.DevEnableMouseLock = true
	end
	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter and shiftLockEnabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end)

fixCamera()