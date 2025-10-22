--// SHIFT LOCK CONTROLLER + CAMERA FIX + TOAST ANIMADO

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Config deseada
local DESIRED_FOV = 75
local MAX_ZOOM = 1000
local MIN_ZOOM = 0.5

-- Estado persistente de Shift Lock
local forceShiftLock = false

-- Mantener configuraciones
local function enforceCameraSettings()
	-- Cámara clásica y libre
	if player.CameraMode ~= Enum.CameraMode.Classic then
		player.CameraMode = Enum.CameraMode.Classic
	end

	-- Invisicam
	if player.DevCameraOcclusionMode ~= Enum.DevCameraOcclusionMode.Invisicam then
		player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
	end

	-- Zoom libre
	if player.CameraMaxZoomDistance ~= MAX_ZOOM then
		player.CameraMaxZoomDistance = MAX_ZOOM
	end
	if player.CameraMinZoomDistance ~= MIN_ZOOM then
		player.CameraMinZoomDistance = MIN_ZOOM
	end

	-- FOV mínimo 75
	if camera.FieldOfView < DESIRED_FOV then
		camera.FieldOfView = DESIRED_FOV
	end

	-- Sin bloqueo en primera persona
	if player.DevComputerCameraMovementMode == Enum.DevComputerCameraMovementMode.FirstPerson then
		player.DevComputerCameraMovementMode = Enum.DevComputerCameraMovementMode.Classic
	end

	-- Si el ShiftLock debe estar activo y algo lo cambió → reactivar
	if forceShiftLock and not player.DevEnableMouseLock then
		player.DevEnableMouseLock = true
	end
end

-- Crear GUI de notificación si no existe
local function createToastGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ToastGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")
	return screenGui
end

local toastGui = player:WaitForChild("PlayerGui"):FindFirstChild("ToastGui") or createToastGui()

-- Mostrar notificación animada
local function showToast(title, message, color)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 270, 0, 65)
	frame.Position = UDim2.new(0, -300, 1, -100)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = toastGui
	frame.ClipsDescendants = true
	frame.ZIndex = 10
	frame.AnchorPoint = Vector2.new(0, 1)

	local corner = Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0, 10)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -10, 0, 25)
	titleLabel.Position = UDim2.new(0, 10, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 20
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = title
	titleLabel.Parent = frame

	local messageLabel = Instance.new("TextLabel")
	messageLabel.Size = UDim2.new(1, -10, 0, 25)
	messageLabel.Position = UDim2.new(0, 10, 0, 30)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextSize = 16
	messageLabel.TextColor3 = Color3.new(1, 1, 1)
	messageLabel.TextXAlignment = Enum.TextXAlignment.Left
	messageLabel.Text = message
	messageLabel.Parent = frame

	frame.BackgroundTransparency = 1
	titleLabel.TextTransparency = 1
	messageLabel.TextTransparency = 1

	-- Animación entrada
	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 20, 1, -20),
		BackgroundTransparency = 0.1
	})
	local fadeInTitle = TweenService:Create(titleLabel, TweenInfo.new(0.5), {TextTransparency = 0})
	local fadeInMsg = TweenService:Create(messageLabel, TweenInfo.new(0.5), {TextTransparency = 0})

	tweenIn:Play()
	fadeInTitle:Play()
	fadeInMsg:Play()

	task.wait(3)

	-- Animación salida
	local tweenOut = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Position = UDim2.new(0, -300, 1, -20),
		BackgroundTransparency = 1
	})
	local fadeOutTitle = TweenService:Create(titleLabel, TweenInfo.new(0.5), {TextTransparency = 1})
	local fadeOutMsg = TweenService:Create(messageLabel, TweenInfo.new(0.5), {TextTransparency = 1})

	tweenOut:Play()
	fadeOutTitle:Play()
	fadeOutMsg:Play()

	tweenOut.Completed:Wait()
	frame:Destroy()
end

-- Cambiar Shift Lock manualmente
local function toggleShiftLock()
	forceShiftLock = not forceShiftLock
	player.DevEnableMouseLock = forceShiftLock

	if forceShiftLock then
		showToast("✅ Shift Lock", "Activado permanentemente.", Color3.fromRGB(46, 204, 113))
	else
		showToast("❌ Shift Lock", "Desactivado permanentemente.", Color3.fromRGB(231, 76, 60))
	end
end

-- Detectar comando en el chat
player.Chatted:Connect(function(msg)
	if msg:lower() == ".sh" then
		toggleShiftLock()
	end
end)

-- Mantener cámara y ShiftLock estables
RunService.Heartbeat:Connect(enforceCameraSettings)
enforceCameraSettings()