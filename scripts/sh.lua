-- ShiftLock + ToastService (final) - Pegar en StarterPlayerScripts
-- Features:
--  - .sh toggles Shift Lock (PC real + mobile simulated)
--  - camera shoulder Scriptable while shift lock active
--  - protects FOV (>=75), Invisicam, zoom [0.5,1000]
--  - toast notifications bottom-left, stack max 2, ping sound once per toast
--  - ToastServiceEvent BindableEvent in PlayerGui to fire toasts from other scripts

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

-- shift lock / camera config
local shiftLockEnabled = false
local mobileMode = UserInputService.TouchEnabled
local nextToastId = 0
local activeToasts = {} -- ordered list, oldest first

-- shoulder camera offsets & sensitivities
local shoulderOffset = Vector3.new(1.0, 1.4, -2.2) -- tweakable
local mouseSensitivityPC = 0.18
local touchSensitivity = 0.6

-- ===== HELPERS =====
local function clamp(n, a, b) if n < a then return a elseif n > b then return b else return n end end

local function enforceCameraSettings()
    if not camera then camera = workspace.CurrentCamera end
    if not camera then return end

    -- FOV: only set if less than desired
    if camera.FieldOfView < DESIRED_FOV then camera.FieldOfView = DESIRED_FOV end

    if player.CameraMode ~= Enum.CameraMode.Classic then player.CameraMode = Enum.CameraMode.Classic end
    if player.DevCameraOcclusionMode ~= Enum.DevCameraOcclusionMode.Invisicam then
        player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
    end

    if player.CameraMinZoomDistance ~= MIN_ZOOM then player.CameraMinZoomDistance = MIN_ZOOM end
    if player.CameraMaxZoomDistance ~= MAX_ZOOM then player.CameraMaxZoomDistance = MAX_ZOOM end
end

local function tween(obj, props, time)
    return TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

-- ===== TOAST SERVICE =====
local function ensureToastHolder()
    if not playerGui:FindFirstChild("ToastServiceGui") then
        local sg = Instance.new("ScreenGui")
        sg.Name = "ToastServiceGui"
        sg.ResetOnSpawn = false
        sg.IgnoreGuiInset = true
        sg.Parent = playerGui

        local holder = Instance.new("Frame")
        holder.Name = "ToastHolder"
        holder.AnchorPoint = Vector2.new(0, 1)
        holder.Position = UDim2.new(0, 20, 1, -20) -- bottom-left
        holder.Size = UDim2.new(0, TOAST_WIDTH, 0, 0)
        holder.BackgroundTransparency = 1
        holder.Parent = sg
    end
    return playerGui.ToastServiceGui.ToastHolder
end

-- params: {title=string, text=string (optional), color=Color3, duration=number (optional)}
local function createToast(params)
    params = params or {}
    local title = params.title or "Notification"
    local text = params.text or ""
    local color = params.color or Color3.fromRGB(0,200,255)
    local duration = params.duration or TOAST_DURATION

    local holder = ensureToastHolder()

    -- if full, remove oldest
    if #activeToasts >= MAX_STACK then
        local oldest = table.remove(activeToasts, 1)
        if oldest and oldest.gui and oldest.gui.Parent then
            -- animate out then destroy
            oldest.gui:TweenPosition(UDim2.new(0, -TOAST_WIDTH - 50, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.25, true)
            task.delay(0.28, function()
                if oldest.gui and oldest.gui.Parent then oldest.gui.Parent:Destroy() end
            end)
        end
    end

    -- main frame (white with left colored strip)
    local guiFrame = Instance.new("Frame")
    guiFrame.Name = "Toast_" .. tostring(nextToastId + 1)
    guiFrame.Size = UDim2.new(0, TOAST_WIDTH, 0, TOAST_HEIGHT)
    guiFrame.Position = UDim2.new(0, -TOAST_WIDTH - 50, 0, 0) -- start off holder
    guiFrame.BackgroundColor3 = Color3.fromRGB(255,255,255)
    guiFrame.BorderSizePixel = 0
    guiFrame.Parent = holder
    guiFrame.ClipsDescendants = true

    -- rounded corners
    local corner = Instance.new("UICorner", guiFrame)
    corner.CornerRadius = UDim.new(0, 14)

    -- left colored strip
    local strip = Instance.new("Frame", guiFrame)
    strip.Size = UDim2.new(0, 14, 1, 0)
    strip.Position = UDim2.new(0, 0, 0, 0)
    strip.BackgroundColor3 = color
    strip.BorderSizePixel = 0
    local sCorner = Instance.new("UICorner", strip)
    sCorner.CornerRadius = UDim.new(0, 14)

    -- header label
    local header = Instance.new("TextLabel", guiFrame)
    header.BackgroundTransparency = 1
    header.Position = UDim2.new(0, 28, 0, 6)
    header.Size = UDim2.new(1, -56, 0, 20)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 14
    header.Text = "NOTIFICATION"
    header.TextColor3 = Color3.fromRGB(40,40,40)
    header.TextXAlignment = Enum.TextXAlignment.Left

    -- title area
    local titleLabel = Instance.new("TextLabel", guiFrame)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 28, 0, 26)
    titleLabel.Size = UDim2.new(1, -64, 0, 36)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 20
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(20,20,20)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- optional subtext
    if text and text ~= "" then
        local sub = Instance.new("TextLabel", guiFrame)
        sub.BackgroundTransparency = 1
        sub.Position = UDim2.new(0, 28, 0, 56)
        sub.Size = UDim2.new(1, -64, 0, 18)
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 14
        sub.Text = text
        sub.TextColor3 = Color3.fromRGB(100,100,100)
        sub.TextXAlignment = Enum.TextXAlignment.Left
    end

    -- close button
    local closeBtn = Instance.new("TextButton", guiFrame)
    closeBtn.Size = UDim2.new(0, 36, 0, 36)
    closeBtn.Position = UDim2.new(1, -46, 0, 10)
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.TextColor3 = Color3.fromRGB(80,80,80)
    closeBtn.BackgroundTransparency = 1

    -- progress bar background + fill
    local progressBg = Instance.new("Frame", guiFrame)
    progressBg.Size = UDim2.new(1, -32, 0, 6)
    progressBg.Position = UDim2.new(0, 16, 1, -12)
    progressBg.BackgroundColor3 = Color3.fromRGB(230,230,230)
    progressBg.BorderSizePixel = 0
    local pbCorner = Instance.new("UICorner", progressBg)
    pbCorner.CornerRadius = UDim.new(0, 4)

    local progressFill = Instance.new("Frame", progressBg)
    progressFill.Size = UDim2.new(1, 0, 1, 0)
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.BackgroundColor3 = color
    progressFill.BorderSizePixel = 0
    local pfCorner = Instance.new("UICorner", progressFill)
    pfCorner.CornerRadius = UDim.new(0, 4)

    -- play ping only once per toast
    if PING_SOUND_ID and PING_SOUND_ID ~= "" then
        local s = Instance.new("Sound", guiFrame)
        s.SoundId = PING_SOUND_ID
        s.Volume = 0.6
        s:Play()
        task.delay(1.2, function() pcall(function() s:Destroy() end) end)
    end

    -- animate in
    local tIn = tween(guiFrame, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}, 0.36)
    tIn:Play()

    -- push existing toasts upward (stack)
    for i = 1, #activeToasts do
        local ent = activeToasts[i]
        if ent and ent.gui then
            local targetY = (TOAST_HEIGHT + TOAST_MARGIN) * i
            ent.gui:TweenPosition(UDim2.new(0, 0, 0, targetY), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.24, true)
        end
    end

    -- register
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
            progressFill.Size = UDim2.new(t, 0, 1, 0)
            task.wait(0.03)
        end
        alive = false
        -- animate out
        tween(guiFrame, {Position = UDim2.new(0, -TOAST_WIDTH - 50, 0, 0), BackgroundTransparency = 1}, 0.28):Play()
        task.wait(0.32)
        -- remove from activeToasts
        for i = 1, #activeToasts do
            if activeToasts[i] and activeToasts[i].id == thisId then
                table.remove(activeToasts, i)
                break
            end
        end
        if guiFrame.Parent then guiFrame.Parent:Destroy() end
        -- re-stack remaining toasts (slide down)
        for i = 1, #activeToasts do
            local ent = activeToasts[i]
            if ent and ent.gui then
                local targetY = (TOAST_HEIGHT + TOAST_MARGIN) * (i - 1)
                ent.gui:TweenPosition(UDim2.new(0, 0, 0, targetY), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.22, true)
            end
        end
    end)

    return thisId
end

-- BindableEvent public API for other LocalScripts
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

-- ===== SHIFT LOCK (PC real + mobile simulated) =====
local function applyShiftLock(state)
    shiftLockEnabled = state and true or false
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        -- will be enforced in RenderStepped once character exists
        return
    end

    if shiftLockEnabled then
        -- Use Scriptable camera to control exact shoulder position
        camera.CameraType = Enum.CameraType.Scriptable
        -- attempt to keep DevEnableMouseLock on PC for consistency
        pcall(function() player.DevEnableMouseLock = true end)
    else
        -- restore default camera behavior
        camera.CameraType = Enum.CameraType.Custom
        if not UserInputService.TouchEnabled then
            pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.Default end)
        end
    end

    -- show toast (lime for activate, red for deactivate)
    if shiftLockEnabled then
        createToast({title = "Shift Lock Activado", color = Color3.fromRGB(181,255,0), duration = TOAST_DURATION})
    else
        createToast({title = "Shift Lock Desactivado", color = Color3.fromRGB(255,100,100), duration = TOAST_DURATION})
    end
end

-- rotate HRP with mouse/touch while shift lock enabled
UserInputService.InputChanged:Connect(function(input)
    if not shiftLockEnabled then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement and not UserInputService.TouchEnabled then
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dx = input.Delta.X
            local hrp = player.Character.HumanoidRootPart
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, -math.rad(dx * mouseSensitivityPC), 0)
        end
    end
end)

UserInputService.TouchMoved:Connect(function(touch, gp)
    if not shiftLockEnabled then return end
    if not UserInputService.TouchEnabled then return end
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        local dx = touch.Delta.X
        hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, -math.rad(dx * touchSensitivity), 0)
    end
end)

-- camera update on render: place camera at shoulder and look at head
RunService:BindToRenderStep("ShiftLockCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
    enforceCameraSettings()

    if not shiftLockEnabled then return end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

    local hrp = player.Character.HumanoidRootPart
    -- compute world shoulder position
    local worldOffset = (hrp.CFrame * CFrame.new(shoulderOffset)).p
    local lookAt = hrp.Position + Vector3.new(0, 1.4, 0)
    camera.CFrame = CFrame.lookAt(worldOffset, lookAt)
end)

-- chat command
player.Chatted:Connect(function(msg)
    if type(msg) ~= "string" then return end
    if msg:lower():match("^%.sh$") then
        applyShiftLock(not shiftLockEnabled)
    end
end)

-- protect / reapply settings frequently
RunService.RenderStepped:Connect(function()
    enforceCameraSettings()
    if shiftLockEnabled then
        -- enforce flags on PC if possible
        if not UserInputService.TouchEnabled then
            pcall(function() player.DevEnableMouseLock = true end)
            if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
                pcall(function() UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter end)
            end
        else
            -- mobile: ensure camera remains Scriptable
            if camera.CameraType ~= Enum.CameraType.Scriptable then camera.CameraType = Enum.CameraType.Scriptable end
        end
    end
end)

-- initial apply
enforceCameraSettings()