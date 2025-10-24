-- Mey Companion - Sincroniza Animaciones del Jugador
-- Forza R6 y copia animaciones del jugador automáticamente

------------------------------------------------------
-- CONFIGURACIÓN
------------------------------------------------------
local TARGET_USER_ID = 7139360318
local NAME = "Mey ♥"
local FOLLOW_DISTANCE = 4
local SMOOTH_SPEED = 8

------------------------------------------------------
-- SERVICIOS
------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function waitForCharacter()
	local char = LocalPlayer.Character
	while not char or not char:FindFirstChild("HumanoidRootPart") do
		char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		task.wait()
	end
	return char
end

------------------------------------------------------
-- CREAR R6 BASE
------------------------------------------------------
local function createR6Rig()
	local model = Instance.new("Model")
	model.Name = NAME

	local function makePart(name, size)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Anchored = false
		p.CanCollide = false
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end

	local torso = makePart("Torso", Vector3.new(2,2,1))
	local head = makePart("Head", Vector3.new(2,1,1))
	local larm = makePart("Left Arm", Vector3.new(1,2,1))
	local rarm = makePart("Right Arm", Vector3.new(1,2,1))
	local lleg = makePart("Left Leg", Vector3.new(1,2,1))
	local rleg = makePart("Right Leg", Vector3.new(1,2,1))
	local root = makePart("HumanoidRootPart", Vector3.new(2,2,1))
	root.Transparency = 1
	model.PrimaryPart = root

	local function weld(a,b,name)
		local w = Instance.new("Motor6D")
		w.Name = name
		w.Part0 = a
		w.Part1 = b
		w.C0 = CFrame.new()
		w.C1 = CFrame.new()
		w.Parent = a
		return w
	end

	weld(root, torso, "RootJoint")
	weld(torso, head, "Neck")
	weld(torso, larm, "Left Shoulder")
	weld(torso, rarm, "Right Shoulder")
	weld(torso, lleg, "Left Hip")
	weld(torso, rleg, "Right Hip")

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.Parent = model

	model.Parent = workspace
	return model, humanoid
end

------------------------------------------------------
-- COPIAR ANIMACIONES DEL JUGADOR
------------------------------------------------------
local function copyAnimations(fromHum, toHum)
	local animate = fromHum.Parent:FindFirstChild("Animate")
	if not animate then return false end

	local newAnimate = Instance.new("Folder")
	newAnimate.Name = "Animate"

	for _, obj in ipairs(animate:GetDescendants()) do
		if obj:IsA("Animation") then
			local clone = Instance.new("Animation")
			clone.Name = obj.Name
			clone.AnimationId = obj.AnimationId
			clone.Parent = newAnimate
		end
	end

	local scriptClone = Instance.new("Script")
	scriptClone.Name = "Animate"
	scriptClone.Source = [[
		local char = script.Parent
		local hum = char:WaitForChild("Humanoid")
		local animFolder = char:WaitForChild("Animate")

		local function loadAnim(name)
			local animObj = animFolder:FindFirstChild(name)
			if not animObj then return end
			local a = Instance.new("Animation")
			a.AnimationId = animObj.AnimationId
			return hum:LoadAnimation(a)
		end

		local idle = loadAnim("idle") or loadAnim("Idle") 
		local walk = loadAnim("walk") or loadAnim("Walk")
		local jump = loadAnim("jump") or loadAnim("Jump")
		local fall = loadAnim("fall") or loadAnim("Fall")

		if idle then idle:Play() end

		hum.Running:Connect(function(speed)
			if speed > 1 then
				if walk and not walk.IsPlaying then
					if idle then idle:Stop() end
					walk:Play()
				end
			else
				if walk and walk.IsPlaying then
					walk:Stop()
					if idle then idle:Play() end
				end
			end
		end)

		hum.Jumping:Connect(function()
			if jump then
				if idle then idle:Stop() end
				if walk then walk:Stop() end
				jump:Play()
			end
		end)

		hum.FreeFalling:Connect(function()
			if fall then
				if idle then idle:Stop() end
				if walk then walk:Stop() end
				fall:Play()
			end
		end)
	]]
	scriptClone.Parent = toHum.Parent
	newAnimate.Parent = toHum.Parent

	return true
end

------------------------------------------------------
-- CREAR COMPAÑERO
------------------------------------------------------
local function createCompanion()
	local dummy, hum = createR6Rig()

	-- Apariencia
	local ok, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(TARGET_USER_ID)
	end)
	if ok and desc then
		hum:ApplyDescription(desc)
	end

	-- Nombre visible como jugador
	local head = dummy:FindFirstChild("Head")
	if head then
		local tag = Instance.new("BillboardGui")
		tag.Size = UDim2.new(0,120,0,25)
		tag.StudsOffset = Vector3.new(0,2.3,0)
		tag.AlwaysOnTop = false
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1,0,1,0)
		label.BackgroundTransparency = 1
		label.Text = NAME
		label.Font = Enum.Font.GothamBold
		label.TextSize = 16
		label.TextColor3 = Color3.new(1,1,1)
		label.TextStrokeTransparency = 0.6
		label.Parent = tag
		tag.Parent = head
	end

	return dummy, hum
end

------------------------------------------------------
-- FOLLOW SYSTEM
------------------------------------------------------
local char = waitForCharacter()
local playerHum = char:WaitForChild("Humanoid")
local playerRoot = char:WaitForChild("HumanoidRootPart")

local companion, companionHum = createCompanion()
local root = companion.PrimaryPart

-- Copiar animaciones del jugador
if not copyAnimations(playerHum, companionHum) then
	warn("⚠️ No se pudieron copiar animaciones, usando base R6.")
end

root.CFrame = playerRoot.CFrame * CFrame.new(2,0,0)

RunService.Heartbeat:Connect(function(dt)
	if not playerRoot or not root then return end

	companionHum.WalkSpeed = playerHum.WalkSpeed
	companionHum.JumpPower = playerHum.JumpPower

	local dist = (playerRoot.Position - root.Position).Magnitude
	if dist > FOLLOW_DISTANCE then
		local dir = (playerRoot.Position - root.Position).Unit
		local move = dir * SMOOTH_SPEED * dt
		root.CFrame = CFrame.new(root.Position + move, playerRoot.Position)
	end
end)

print("✅ Mey Companion R6 listo y sincronizado con tus animaciones.")