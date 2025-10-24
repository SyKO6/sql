-- Mey Companion R6 - Versión limpia y funcional
-- Ejecuta esto dentro de StarterPlayerScripts (solo Studio)
-- Crea un personaje R6 que copia la apariencia del UserId indicado y te sigue

-- CONFIGURACIÓN
local TARGET_USER_ID = 7139360318  -- Cambia a tu UserId
local NAME = "Mey ♥"

-- SERVICIOS
local Players = game:GetService("Players")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local function waitForChar()
	local char = LocalPlayer.Character
	while not char or not char:FindFirstChild("HumanoidRootPart") do
		char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		task.wait()
	end
	return char
end

-- FUNCIÓN PRINCIPAL: crear el companion
local function createCompanion()
	-- Crear rig R6 base
	local asset = InsertService:LoadAsset(1664543044) -- Dummy R6 clásico
	local dummy = asset:FindFirstChildOfClass("Model") or asset
	dummy.Name = NAME
	dummy.Parent = workspace

	-- Asegurar humanoide y tipo R6
	local hum = dummy:FindFirstChildOfClass("Humanoid") or Instance.new("Humanoid", dummy)
	hum.RigType = Enum.HumanoidRigType.R6
	hum.DisplayName = ""

	-- Aplicar apariencia de usuario
	local success, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(TARGET_USER_ID)
	end)
	if success and desc then
		hum:ApplyDescription(desc)
	end

	-- Animaciones R6 por defecto
	local animate = Instance.new("Script")
	animate.Name = "Animate"
	animate.Source = [[
		wait(1)
		local char = script.Parent
		local hum = char:WaitForChild("Humanoid")
		local function loadAnim(name, id)
			local anim = Instance.new("Animation")
			anim.Name = name
			anim.AnimationId = "rbxassetid://"..id
			return hum:LoadAnimation(anim)
		end

		local idle = loadAnim("Idle", 180435571)
		local walk = loadAnim("Walk", 180426354)
		local run = loadAnim("Run", 180426354)
		local jump = loadAnim("Jump", 125750702)
		local fall = loadAnim("Fall", 180436148)

		idle:Play()

		hum.Running:Connect(function(speed)
			if speed > 0 then
				if not walk.IsPlaying then walk:Play() end
			else
				if walk.IsPlaying then walk:Stop() end
				if not idle.IsPlaying then idle:Play() end
			end
		end)

		hum.Jumping:Connect(function(active)
			if active then
				idle:Stop()
				walk:Stop()
				jump:Play()
			end
		end)

		hum.FreeFalling:Connect(function(active)
			if active then
				idle:Stop()
				walk:Stop()
				fall:Play()
			end
		end)
	]]
	animate.Parent = dummy

	-- Posición inicial cerca del jugador
	local playerChar = waitForChar()
	local playerRoot = playerChar:WaitForChild("HumanoidRootPart")
	dummy:SetPrimaryPartCFrame(playerRoot.CFrame * CFrame.new(2, 0, 0))

	-- Nombre sobre la cabeza
	local head = dummy:WaitForChild("Head")
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.new(0, 120, 0, 25)
	tag.StudsOffset = Vector3.new(0, 2.3, 0)
	tag.AlwaysOnTop = false
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = NAME
	label.TextColor3 = Color3.fromRGB(255,255,255)
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.6
	label.TextSize = 16
	label.Parent = tag
	tag.Parent = head

	return dummy, hum
end

-- CREAR Y DAR VIDA
local companion, hum = createCompanion()
local root = companion.PrimaryPart
local playerChar = waitForChar()
local playerRoot = playerChar:WaitForChild("HumanoidRootPart")

local FOLLOW_DISTANCE = 4
local SPEED = 6

RunService.Heartbeat:Connect(function(dt)
	if not playerRoot or not root then return end
	local dist = (playerRoot.Position - root.Position).Magnitude
	if dist > FOLLOW_DISTANCE then
		local dir = (playerRoot.Position - root.Position).Unit
		local target = root.Position + dir * SPEED * dt
		root.CFrame = CFrame.new(target, playerRoot.Position)
	end
end)

print("✅ Mey Companion (R6 + Animaciones + Follow) activo.")