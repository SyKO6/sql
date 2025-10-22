-- ShiftLock final (PC + Móvil) + ToastService (stack max 2)
-- Pegar en StarterPlayerScripts (LocalScript)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local camera = workspace.CurrentCamera

-- ===== CONFIG =====
local DESIRED_FOV = 75
local MIN_ZOOM = 0.5
local MAX_ZOOM = 1000
local TOAST_DURATION = 5
local TOAST_WIDTH = 380
local TOAST_HEIGHT = 88
local TOAST_MARGIN = 12
local MAX_STACK = 2
local PING_SOUND_ID = "rbxassetid://7149516992"

-- SHIFTLOCK / CAMERA
local shiftLockEnabled = false
local mobileMode = UserInputService.TouchEnabled
local shoulderOffset = Vector3.new(1.1, 1.5, -2.4) -- posición de cámara relativa al HRP (ajusta si quieres)
local camDistance = 6.0 -- distancia inicial (se usa para zoom)
local minDistance = 1.5
local maxDistance = 12.0
local mouseSensitivityPC = 0.18
local touchSensitivity = 0.6

-- TOASTS
local nextToastId = 0
local activeToasts = {}

-- ===== HELPERS =====
local function clamp(n, a, b) if n < a then return a elseif n > b then return b else return n end end

local function ensureToastHolder()
	if not playerGui:FindFirstChild("ToastServiceGui") then
		local sg = Instance.new("ScreenGui")
		sg.Name = "ToastServiceGui"
		sg.ResetOnSpawn = false
		sg.IgnoreGuiInset = true
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.Parent = playerGui

		local holder = Instance.new("Frame")
		holder.Name = "ToastHolder"
		holder.AnchorPoint = Vector2.new(0, 1)
		-- posición: inferior izquierda, un poco hacia arriba para no tapar UI móvil
		holder.Position = UDim2.new(0, 20, 1, -110)
		holder.Size = UDim2.new(0, TOAST_WIDTH, 0, 0)
		holder.BackgroundTransparency = 1
		holder.ZIndex = 50
		holder.Parent = sg
	end
	return playerGui.ToastServiceGui.ToastHolder
end

local function tween(obj, props, time)
	return TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

-- params: {title=, text=, color=Color3, duration=}
local function createToast(params)
	params = params or {}
	local title = params.title or "Notification"
	local text = params.text or ""
	local color = params.color or Color3.fromRGB(0,200,255)
	local duration = params.duration or TOAST_DURATION

	local holder = ensureToastHolder()

	-- si hay máximo, eliminar la más vieja
	if #activeToasts >= MAX_STACK then
		local oldest = table.remove(activeToasts, 1)
		if oldest and oldest.gui and oldest.gui.Parent then
			tween(oldest.gui, {Position = UDim2.new(0, -TOAST_WIDTH - 50, 0, 0), BackgroundTransparency = 1}, 0.25):Play()
			task.delay(0.28, function() if oldest.gui and oldest.gui.Parent then oldest.gui.Parent:Destroy() end end)
		end
	end

	-- crear GUI
	local guiFrame = Instance.new("Frame")
	guiFrame.Name = "Toast_" .. tostring(nextToastId + 1)
	guiFrame.Size = UDim2.new(0, TOAST_WIDTH, 0, TOAST_HEIGHT)
	guiFrame.Position = UDim2.new(0, -TOAST_WIDTH - 50, 0, 0)
	guiFrame.BackgroundColor3 = Color3.fromRGB(255,255,255)
	guiFrame.BorderSizePixel = 0
	guiFrame.ClipsDescendants = true
	guiFrame.Parent = holder

	local corner = Instance.new("UICorner", guiFrame)
	corner.CornerRadius = UDim.new(0, 14)

	local strip = Instance.new("Frame", guiFrame)
	strip.Size = UDim2.new(0, 12, 1, 0)
	strip.Position = UDim2.new(0, 0, 0, 0)
	strip.BackgroundColor3 = color
	strip.BorderSizePixel = 0
	local stripCorner = Instance.new("UICorner", strip)
	stripCorner.CornerRadius = UDim.new(0, 14)

	local header = Instance.new("TextLabel", guiFrame)
	header.BackgroundTransparency = 1
	header.Position = UDim2.new(0, 18, 0, 6)
	header.Size = UDim2.new(1, -56, 0, 20)
	header.Font = Enum.Font.GothamBold
	header.TextSize = 14
	header.Text = "NOTIFICACIÓN 🚨"
	header.TextColor3 = color
	header.TextXAlignment = Enum.TextXAlignment.Left

	local titleLabel = Instance.new("TextLabel", guiFrame)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.new(0, 18, 0, 26)
	titleLabel.Size = UDim2.new(1, -64, 0, 36)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 20
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(20,20,20)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left

	if text ~= "" then
		local sub = Instance.new("TextLabel", guiFrame)
		sub.BackgroundTransparency = 1
		sub.Position = UDim2.new(0, 18, 0, 56)
		sub.Size = UDim2.new(1, -64, 0, 18)
		sub.Font = Enum.Font.Gotham
		sub.TextSize = 14
		sub.Text = text
		sub.TextColor3 = Color3.fromRGB(100,100,100)
		sub.TextXAlignment = Enum.TextXAlignment.Left
	end

	local closeBtn = Instance.new("TextButton", guiFrame)
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -46, 0, 12)
	closeBtn.Text = "✕"
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 20
	closeBtn.TextColor3 = Color3.new(1,1,1)
	closeBtn.BackgroundTransparency = 1

	local progress = Instance.new("Frame", guiFrame)
	progress.Name = "Progress"
	progress.Size = UDim2.new(1, -28, 0, 6)
	progress.Position = UDim2.new(0, 14, 1, -12)
	progress.BackgroundTransparency = 0.25
	progress.BackgroundColor3 = Color3.fromRGB(255,255,255)
	progress.BorderSizePixel = 0
	local pCorner = Instance.new("UICorner", progress)
	pCorner.CornerRadius = UDim.new(0, 4)

	local inner = Instance.new("Frame", progress)
	inner.Name = "Inner"
	inner.Size = UDim2.new(1,0,1,0)
	inner.Position = UDim2.new(0,0,0,0)
	inner.BackgroundColor3 = color
	inner.BorderSizePixel = 0
	local innerCorner = Instance.new("UICorner", inner)
	innerCorner.CornerRadius = UDim.new(0, 4)

	-- ping sound (one per toast)
	if PING_SOUND_ID and PING_SOUND_ID ~= "" then
		local s = Instance.new("Sound", guiFrame)
		s.SoundId = PING_SOUND_ID
		s.Volume = 0.6
		s:Play()
		task.delay(1.2, function() pcall(function() s:Destroy() end) end)
	end

	-- anim in
	guiFrame.BackgroundTransparency = 1
	titleLabel.TextTransparency = 1
	local tIn = tween(guiFrame, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}, 0.36)
	local tTitle = tween(titleLabel, {TextTransparency = 0}, 0.36)
	tIn:Play(); tTitle:Play()

	-- push existing toasts up visually
	for i = 1, #activeToasts do
		local entry = activeToasts[i]
		if entry and entry.gui then
			local targetY = (TOAST_HEIGHT + TOAST_MARGIN) * i
			entry.gui:TweenPosition(UDim2.new(0, 0, 0, targetY), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
		end
	end

	nextToastId = nextToastId + 1
	local thisId = nextToastId
	table.insert(activeToasts, {id = thisId, gui = guiFrame})

	-- progress loop & auto remove
	local start = tick()
	local alive = true
	closeBtn.MouseButton1Click:Connect(function() alive = false end)

	task.spawn(function()
		while alive and tick() - start < duration do
			local t = 1 - ((tick() - start) / duration)
			inner.Size = UDim2.new(t, 0, 1, 0)
			task.wait(0.03)
		end
		alive = false
		-- animate out & destroy
		tween(guiFrame, {Position = UDim2.new(0, -TOAST_WIDTH - 50, 0, 0), BackgroundTransparency = 1}, 0.28):Play()
		task.wait(0.32)
		for i, v in ipairs(activeToasts) do
			if v.id == thisId then
				table.remove(activeToasts, i)
				break
			end
		end
		if guiFrame and guiFrame.Parent then guiFrame.Parent:Destroy() end
		-- restack remaining
		for i = 1, #activeToasts do
			local entry = activeToasts[i]
			if entry and entry.gui then
				local targetY = (TOAST_HEIGHT + TOAST_MARGIN) * (i - 1)
				entry.gui:TweenPosition(UDim2.new(0, 0, 0, targetY), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.22, true)
			end
		end
	end)

	return thisId
end

-- BindableEvent API
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
toastEvent.Event:Connect(function(tbl)
	if type(tbl) == "table" then
		createToast(tbl)
	end
end)

-- ===== CAMERA / SHIFTLOCK CORE =====
-- track touches for pinch zoom
local activeTouches = {}

UserInputService.TouchStarted:Connect(function(t)
	activeTouches[t] = t.Position
end)
UserInputService.TouchEnded:Connect(function(t)
	activeTouches[t] = nil
end)

UserInputService.TouchMoved:Connect(function(t)
	-- update stored pos for pinch calculations
	activeTouches[t] = t.Position
end)

-- pinch zoom handling (mobile)
local function handlePinchZoom()
	local keys = {}
	for k,v in pairs(activeTouches) do table.insert(keys, {id=k, pos=v}) end
	if #keys >= 2 then
		-- take first two touches
		local a = keys[1].pos
		local b = keys[2].pos
		local curDist = (a - b).Magnitude
		return curDist
	end
	return nil
end

local lastPinchDist = nil

-- rotate HRP on input
UserInputService.InputChanged:Connect(function(input, gp)
	if not shiftLockEnabled then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement and not mobileMode then
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = player.Character.HumanoidRootPart
			local dx = input.Delta.X
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, -math.rad(dx * mouseSensitivityPC), 0)
		end
	elseif input.UserInputType == Enum.UserInputType.Touch and mobileMode then
		-- single finger rotation handled via TouchMoved above by updating activeTouches and using delta:
		-- For simplicity, we rotate using TouchMoved deltas in TouchMoved (see below)
	end
end)

-- TouchMoved rotation & pinch combine
UserInputService.TouchMoved:Connect(function(touch, gp)
	if not shiftLockEnabled then return end
	-- if single touch -> rotate
	local cnt = 0
	for _ in pairs(activeTouches) do cnt = cnt + 1 end
	if cnt == 1 then
		-- single touch rotate
		local delta = touch.Delta
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = player.Character.HumanoidRootPart
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, -math.rad(delta.X * touchSensitivity), 0)
		end
	else
		-- pinch zoom
		local dist = handlePinchZoom()
		if dist then
			if lastPinchDist then
				local diff = dist - lastPinchDist
				camDistance = clamp(camDistance - diff * 0.02, minDistance, maxDistance)
			end
			lastPinchDist = dist
		end
	end
end)

UserInputService.TouchEnded:Connect(function(touch, gp)
	-- reset pinch distance when touches end
	local cnt = 0
	for _ in pairs(activeTouches) do cnt = cnt + 1 end
	if cnt < 2 then lastPinchDist = nil end
end)

-- mouse wheel zoom (PC)
UserInputService.InputBegan:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		-- MouseWheelDelta works in InputChanged not InputBegan in some clients; listen InputChanged below
	end
end)
UserInputService.InputChanged:Connect(function(input, gp)
	if input.UserInputType == Enum.UserInputType.MouseWheel and not mobileMode then
		camDistance = clamp(camDistance - input.Position.Z * 0.6, minDistance, maxDistance)
	end
end)

-- apply camera each frame when shiftLockEnabled
RunService:BindToRenderStep("ShiftLockCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	-- enforce camera settings
	if camera and player then
		-- FOV: only set if smaller than desired
		if camera.FieldOfView < DESIRED_FOV then camera.FieldOfView = DESIRED_FOV end
	end
	if player.CameraMode ~= Enum.CameraMode.Classic then player.CameraMode = Enum.CameraMode.Classic end
	if player.DevCameraOcclusionMode ~= Enum.DevCameraOcclusionMode.Invisicam then player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam end
	if player.CameraMinZoomDistance ~= MIN_ZOOM then player.CameraMinZoomDistance = MIN_ZOOM end
	if player.CameraMaxZoomDistance ~= MAX_ZOOM then player.CameraMaxZoomDistance = MAX_ZOOM end

	if not shiftLockEnabled then return end
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

	local hrp = player.Character.HumanoidRootPart
	-- target lookAt point (slightly above root)
	local lookAt = hrp.Position + Vector3.new(0, 1.4, 0)
	-- compute shoulder point in world space, keeping facing direction
	local worldShoulder = (hrp.CFrame * CFrame.new(shoulderOffset)).p
	-- apply distance backwards along look vector (so camDistance matters)
	local dir = (lookAt - worldShoulder).Unit
	local camPos = lookAt - dir * camDistance
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(camPos, lookAt)
end)

-- toggle shiftlock
local function applyShiftLock(state)
	shiftLockEnabled = state and true or false
	-- show toast
	if shiftLockEnabled then
		createToast({title = "Shift Lock Activado", text = "", color = Color3.fromRGB(181,255,0), duration = TOAST_DURATION})
		-- on PC try to set official lock center
		if not mobileMode then
			pcall(function() player.DevEnableMouseLock = true end)
			pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter end)
			UserInputService.MouseIconEnabled = false
		end
	else
		createToast({title = "Shift Lock Desactivado", text = "", color = Color3.fromRGB(255,100,100), duration = TOAST_DURATION})
		if not mobileMode then
			pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
			UserInputService.MouseIconEnabled = true
		end
		-- restore camera to engine
		if camera then camera.CameraType = Enum.CameraType.Custom end
	end
end

-- chat command .sh
player.Chatted:Connect(function(msg)
	if type(msg) ~= "string" then return end
	if msg:lower():match("^%.sh$") then
		applyShiftLock(not shiftLockEnabled)
	end
end)

-- ensure initial camera state
applyShiftLock(false)

-- cleanup on leave (optional)
player.AncestryChanged:Connect(function(_, parent)
	if not parent then
		-- nothing special here; GUI will be GC'd
	end
end)