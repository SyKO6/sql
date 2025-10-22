-- SHIFTLOCK + SISTEMA DE NOTIFICACIONES
-- Compatible con PC y Móvil
-- Hecho por tu botsito <3

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- ⚙️ Configuración de cámara
local desiredFOV = 75
local minZoom = 0.5
local maxZoom = 1000
local desiredCameraMode = Enum.CameraMode.Classic

-- 🔒 Shiftlock
local shiftLockEnabled = false
local cameraOffset = Vector3.new(1.75, 0, 0) -- Desplazamiento tipo Evade

-- 📢 Control de notificaciones
local activeNotifications = {}

local function showNotification(text, color)
	local playerGui = player:WaitForChild("PlayerGui")

	-- Elimina si hay más de 1 activa (máximo 2)
	if #activeNotifications >= 2 then
		local oldest = table.remove(activeNotifications, 1)
		if oldest and oldest.Parent then
			oldest:Destroy()
		end
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Notification_" .. tick()
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	table.insert(activeNotifications, screenGui)

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 340, 0, 75)
	frame.Position = UDim2.new(0, 30, 1, -150 - (#activeNotifications * 85))
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	frame.ClipsDescendants = true

	frame:TweenPosition(UDim2.new(0, 30, 1, -110 - ((#activeNotifications - 1) * 85)), "Out", "Quad", 0.3, true)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 0, 25)
	title.Position = UDim2.new(0, 10, 0, 6)
	title.BackgroundTransparency = 1
	title.Text = "NOTIFICACIÓN 🚨"
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = color
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.new(1, -20, 1, -35)
	msg.Position = UDim2.new(0, 10, 0, 28)
	msg.BackgroundTransparency = 1
	msg.Text = text
	msg.Font = Enum.Font.Gotham
	msg.TextColor3 = Color3.fromRGB(255, 255, 255)
	msg.TextSize = 18
	msg.TextXAlignment = Enum.TextXAlignment.Left
	msg.TextWrapped = true
	msg.Parent = frame

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 4)
	bar.Position = UDim2.new(0, 0, 1, -4)
	bar.BackgroundColor3 = color
	bar.BorderSizePixel = 0
	bar.Parent = frame

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 24, 0, 24)
	close.Position = UDim2.new(1, -28, 0, 4)
	close.BackgroundTransparency = 1
	close.Text = "✖"
	close.Font = Enum.Font.GothamBold
	close.TextColor3 = Color3.fromRGB(255, 255, 255)
	close.TextSize = 18
	close.Parent = frame

	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://7149516992"
	sound.Volume = 1
	sound.Parent = frame
	sound:Play()

	TweenService:Create(bar, TweenInfo.new(5), {Size = UDim2.new(0, 0, 0, 4)}):Play()

	close.MouseButton1Click:Connect(function()
		screenGui:Destroy()
	end)

	task.delay(5, function()
		if screenGui then
			screenGui:Destroy()
		end
	end)
end

-- 🧭 Mantener configuración de cámara
task.spawn(function()
	while task.wait(1) do
		player.CameraMode = desiredCameraMode
		player.CameraMinZoomDistance = minZoom
		player.CameraMaxZoomDistance = maxZoom
		camera.FieldOfView = desiredFOV
	end
end)

-- 🎯 Función principal de ShiftLock real
local function updateCamera()
	if shiftLockEnabled and character and humanoid then
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			camera.CameraSubject = humanoid
			camera.CFrame = CFrame.new(root.Position) * CFrame.new(cameraOffset)
		end
	end
end

RunService.RenderStepped:Connect(updateCamera)

local function toggleShiftLock()
	shiftLockEnabled = not shiftLockEnabled

	if shiftLockEnabled then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		showNotification("ShiftLock ACTIVADO", Color3.fromRGB(0, 255, 0))
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		showNotification("ShiftLock DESACTIVADO", Color3.fromRGB(255, 0, 0))
	end
end

-- 🗨️ Comando .sh
player.Chatted:Connect(function(msg)
	if msg:lower() == ".sh" then
		toggleShiftLock()
	end
end)