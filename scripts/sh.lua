-- ShiftLock + ToastService (LocalScript) - Pegar en StarterPlayerScripts
-- Provee: .sh chat toggle, protección de cámara, toasts stack (max 2), BindableEvent para otras notifs

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- Config
local DESIRED_FOV = 75
local MIN_ZOOM = 0.5
local MAX_ZOOM = 1000
local TOAST_DURATION = 5
local TOAST_WIDTH = 360
local TOAST_HEIGHT = 84
local TOAST_MARGIN = 12
local MAX_STACK = 2
local PING_SOUND_ID = "rbxassetid://7149516992" -- puedes cambiar

-- Estado
local shiftLockEnabled = false
local mobileMode = UserInputService.TouchEnabled
local nextToastId = 0

-- Tabla de toasts activos (orden: 1 = más vieja inferior)
local activeToasts = {}

-- Crear contenedor de toasts en PlayerGui si no existe
local function ensureToastContainer()
	if not playerGui:FindFirstChild("ToastServiceGui") then
		local sg = Instance.new("ScreenGui")
		sg.Name = "ToastServiceGui"
		sg.ResetOnSpawn = false
		sg.IgnoreGuiInset = true
		sg.Parent = playerGui

		local holder = Instance.new("Frame")
		holder.Name = "ToastHolder"
		holder.AnchorPoint = Vector2.new(0, 1)
		holder.Position = UDim2.new(0, 20, 1, -20) -- bottom-left start
		holder.Size = UDim2.new(0, TOAST_WIDTH, 0, 0)
		holder.BackgroundTransparency = 1
		holder.Parent = sg
	end
	return playerGui.ToastServiceGui.ToastHolder
end

-- Mantener cámara/config cada frame
local function enforceCameraSettings()
	if not camera then camera = workspace.CurrentCamera end
	if not camera then return end

	-- FOV (solo si es menor)
	if camera.FieldOfView < DESIRED_FOV then camera.FieldOfView = DESIRED_FOV end

	-- camera mode
	if player.CameraMode ~= Enum.CameraMode.Classic then player.CameraMode = Enum.CameraMode.Classic end
	if player.DevCameraOcclusionMode ~= Enum.DevCameraOcclusionMode.Invisicam then
		player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
	end

	-- zoom
	if player.CameraMinZoomDistance ~= MIN_ZOOM then player.CameraMinZoomDistance = MIN_ZOOM end
	if player.CameraMaxZoomDistance ~= MAX_ZOOM then player.CameraMaxZoomDistance = MAX_ZOOM end
end

-- Helpers UI tween
local function tween(obj, props, time, style, dir)
	style = style or Enum.EasingStyle.Quad
	dir = dir or Enum.EasingDirection.Out
	return TweenService:Create(obj, TweenInfo.new(time, style, dir), props)
end

-- Crear y mostrar toast; devuelve id
local function createToast(params)
	-- params: {title = string, color = Color3, duration = number (optional)}
	local title = params.title or "Notificación"
	local color = params.color or Color3.fromRGB(0, 200, 255)
	local duration = params.duration or TOAST_DURATION

	local holder = ensureToastContainer()

	-- Si ya hay MAX_STACK toasts, eliminar la más vieja (index 1)
	if #activeToasts >= MAX_STACK then
		local oldest = table.remove(activeToasts, 1)
		if oldest and oldest.gui then
			-- anim out then destroy
			tween(oldest.gui, {Position = UDim2.new(0, -TOAST_WIDTH - 50, 0, 0), BackgroundTransparency = 1}, 0.25):Play()
			task.delay(0.28, function() if oldest.gui and oldest.gui.Parent then oldest.gui.Parent:Destroy() end end)
		end
	end

	-- crear frame principal
	local toastGui = Instance.new("Frame")
	toastGui.Name = "Toast_" .. tostring(nextToastId)
	toastGui.Size = UDim2.new(0, TOAST_WIDTH, 0, TOAST_HEIGHT)
	toastGui.BackgroundColor3 = color
	toastGui.BackgroundTransparency = 1 -- start hidden
	toastGui.BorderSizePixel = 0
	toastGui.Position = UDim2.new(0, -TOAST_WIDTH - 50, 0, 0) -- start off-screen (holder local coords)
	toastGui.AnchorPoint = Vector2.new(0, 0)
	toastGui.Parent = holder
	toastGui.ClipsDescendants = true

	-- rounded corners
	local corner = Instance.new("UICorner", toastGui)
	corner.CornerRadius = UDim.new(0, 14)

	-- title label (big)
	local titleLabel = Instance.new("TextLabel", toastGui)
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, 18, 0, 12)
	titleLabel.Size = UDim2.new(1, -56, 0, 36)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 24
	titleLabel.TextColor3 = Color3.new(1,1,1)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Top
	titleLabel.Text = title

	-- progress bar container (thin)
	local progress = Instance.new("Frame", toastGui)
	progress.Name = "Progress"
	progress.Size = UDim2.new(1, -28, 0, 6)
	progress.Position = UDim2.new(0, 14, 1, -12)
	progress.BackgroundTransparency = 0.25
	progress.BackgroundColor3 = Color3.fromRGB(255,255,255)
	progress.BorderSizePixel = 0
	local progressCorner = Instance.new("UICorner", progress)
	progressCorner.CornerRadius = UDim.new(0, 4)

	-- inner bar
	local inner = Instance.new("Frame", progress)
	inner.Name = "Inner"
	inner.Size = UDim2.new(1, 0, 1, 0)
	inner.Position = UDim2.new(0, 0, 0, 0)
	inner.BackgroundColor3 = Color3.fromRGB(255,255,255)
	inner.BorderSizePixel = 0
	local innerCorner = Instance.new("UICorner", inner)
	innerCorner.CornerRadius = UDim.new(0, 4)

	-- close button
	local closeBtn = Instance.new("TextButton", toastGui)
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -46, 0, 12)
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 20
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.BackgroundTransparency = 1

	-- sound ping
	if PING_SOUND_ID and PING_SOUND_ID ~= "" then
		local s = Instance.new("Sound", toastGui)
		s.SoundId = PING_SOUND_ID
		s.Volume = 0.35
		s:Play()
		task.delay(0.8, function() if s then s:Destroy() end end)
	end

	-- tween in (slide + fade)
	toastGui.BackgroundTransparency = 1
	titleLabel.TextTransparency = 1
	inner.Size = UDim2.new(1,0,1,0)

	local tIn = tween(toastGui, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}, 0.35)
	local tTitle = tween(titleLabel, {TextTransparency = 0}, 0.35)
	tIn:Play(); tTitle:Play()

	-- push existing toasts up
	for i = 1, #activeToasts do
		local entry = activeToasts[i]
		if entry and entry.gui then
			local targetY = (TOAST_HEIGHT + TOAST_MARGIN) * i
			entry.gui:TweenPosition(UDim2.new(0, 0, 0, targetY), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
		end
	end

	-- add to activeToasts at end
	nextToastId = nextToastId + 1
	local thisId = nextToastId
	table.insert(activeToasts, {id = thisId, gui = toastGui})

	-- progress coroutine & auto-remove
	local start = tick()
	local alive = true

	-- close handling
	closeBtn.MouseButton1Click:Connect(function()
		alive = false
	end)

	task.spawn(function()
		while alive and tick() - start < duration do
			local t = 1 - ((tick() - start) / duration)
			inner.Size = UDim2.new(t, 0, 1, 0)
			task.wait(0.03)
		end

		-- remove this toast
		alive = false
		-- animate out
		tween(toastGui, {Position = UDim2.new(0, -TOAST_WIDTH - 50, 0, 0), BackgroundTransparency = 1}, 0.28):Play()
		task.wait(0.3)
		-- destroy and remove from activeToasts
		for i, v in ipairs(activeToasts) do
			if v.id == thisId then
				table.remove(activeToasts, i)
				break
			end
		end
		if toastGui and toastGui.Parent then toastGui:Destroy() end

		-- re-stack remaining toasts (slide down)
		for i = 1, #activeToasts do
			local entry = activeToasts[i]
			if entry and entry.gui then
				local targetY = (TOAST_HEIGHT + TOAST_MARGIN) * (i - 1)
				entry.gui:TweenPosition(UDim2.new(0, 0, 0, targetY), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.22, true)
			end
		end
	end)

	-- return id so other scripts can reference
	return thisId
end

-- Public API via BindableEvent: other local scripts can fire notifications
-- Create BindableEvent in PlayerGui if not exists
local function ensureBindable()
	local bindName = "ToastServiceEvent"
	local be = playerGui:FindFirstChild(bindName)
	if not be then
		be = Instance.new("BindableEvent")
		be.Name = bindName
		be.Parent = playerGui
	end
	return be
end
local toastEvent = ensureBindable()

-- When event fired, params should be table {title=, color=Color3, duration=number}
toastEvent.Event:Connect(function(tbl)
	if type(tbl) == "table" then
		createToast(tbl)
	end
end)

-- SHIFT LOCK implementation
-- PC: use MouseBehavior + DevEnableMouseLock
-- Mobile: simulate by locking camera to humanoid attach + basic touch rotate (rotate HRP yaw with drag)
local function setShiftLock(state)
	shiftLockEnabled = state and true or false
	if not camera then camera = workspace.CurrentCamera end

	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
		-- try again later
		return
	end

	-- PC
	if not UserInputService.TouchEnabled then
		-- ensure DevEnableMouseLock true then set MouseBehavior
		player.DevEnableMouseLock = true
		UserInputService.MouseBehavior = state and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
	else
		-- Mobile: simulate
		if state then
			-- attach camera to humanoid (attach behaves like shoulder/center)
			camera.CameraType = Enum.CameraType.Attach
			camera.CameraSubject = player.Character:FindFirstChild("Humanoid") or camera.CameraSubject
			-- we'll allow rotating HRP with touch drags (see below)
		else
			camera.CameraType = Enum.CameraType.Custom
		end
	end

	-- show toast with lime color if activated
	if state then
		createToast({title = "Shift Lock Activado", color = Color3.fromRGB(181, 255, 0), duration = TOAST_DURATION})
	else
		createToast({title = "Shift Lock Desactivado", color = Color3.fromRGB(255, 100, 100), duration = TOAST_DURATION})
	end
end

-- Chat command .sh
player.Chatted:Connect(function(msg)
	if type(msg) ~= "string" then return end
	if msg:lower():match("^%.sh$") then
		setShiftLock(not shiftLockEnabled)
	end
end)

-- Mobile rotation handling (simple)
local dragging = false
local lastPos = nil
local sensitivity = 0.5 -- tune rotation speed for mobile

UserInputService.TouchMoved:Connect(function(input, gameProcessed)
	if not shiftLockEnabled then return end
	if not UserInputService.TouchEnabled then return end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

	if input.UserInputType == Enum.UserInputType.Touch then
		-- single touch drag rotates character yaw
		if input.Position and input.Delta then
			local deltaX = input.Delta.X
			local hrp = player.Character.HumanoidRootPart
			local yaw = CFrame.Angles(0, -math.rad(deltaX * sensitivity), 0)
			hrp.CFrame = CFrame.new(hrp.Position) * yaw
		end
	end
end)

-- PC mouse movement rotating character when shiftLockEnabled
UserInputService.InputChanged:Connect(function(input, gp)
	if not shiftLockEnabled then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement and not UserInputService.TouchEnabled then
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local dx = input.Delta.X
			local hrp = player.Character.HumanoidRootPart
			local yaw = CFrame.Angles(0, -math.rad(dx * 0.18), 0) -- adjust sensitivity
			hrp.CFrame = CFrame.new(hrp.Position) * yaw
		end
	end
end)

-- Auto-protect every frame: enforce camera settings and keep shift lock active if enabled
RunService.RenderStepped:Connect(function()
	enforceCameraSettings()
	-- if shiftLock supposed to be active, keep forcing relevant flags
	if shiftLockEnabled then
		if not UserInputService.TouchEnabled then
			player.DevEnableMouseLock = true
			if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			end
		else
			-- mobile: keep camera attached
			if camera.CameraType ~= Enum.CameraType.Attach then
				camera.CameraType = Enum.CameraType.Attach
			end
		end
	end
end)

-- Expose simple API to other local scripts (table in PlayerGui)
-- You can call this from another LocalScript:
-- local be = player.PlayerGui:FindFirstChild("ToastServiceEvent"); if be then be:Fire({title="Hello", color=Color3.new(1,0,0), duration=4}) end
-- (that will stack with our toasts)

-- initial apply (no shift lock by default)
enforceCameraSettings()