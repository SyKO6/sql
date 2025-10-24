-- Mey Companion Script (Siempre R6)
-- LocalScript para StarterPlayerScripts

-- =========================================================
-- CONFIGURACIÓN
-- =========================================================
local CONFIG = {
	UserIdToClone = 7139360318,           -- Usuario base
	NameDisplay = "Mey ♥",
	SpawnOffset = Vector3.new(2, 0, 0),
	FollowDistance = 5,
	FollowStartDistance = 10,
	TeleportDistance = 80,
	PathRecomputeInterval = 0.5,
	SpeechMinDelay = 6,
	SpeechMaxDelay = 18,
	SpeechBubbleDuration = 4,
	LookAtDistance = 8,
	LookChance = 0.35,
	LookCheckInterval = 2.2,
	CollisionGroupName = "CompanionNoPlayer",
}

local PHRASES = {
	"¡Hola! 💕",
	"No te vayas muy lejos 😳",
	"Jeje, te sigo~ 🐾",
	"Estás haciendo un buen trabajo 😌",
	"Me gusta estar contigo 💖",
	"No corras tan rápido 😅",
	"Eres genial, ¿sabías? 💫",
	"Siempre contigo~ 🌸",
	"¿Jugamos? 😊",
	"Te cuido 😉",
}

-- =========================================================
-- SERVICIOS
-- =========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local PhysicsService = game:GetService("PhysicsService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	return warn("Debe ir en StarterPlayerScripts")
end

-- =========================================================
-- FUNCIONES AUXILIARES
-- =========================================================
local function safeWaitForChild(parent, name)
	local child = parent:FindFirstChild(name)
	while not child do
		child = parent:WaitForChild(name)
	end
	return child
end

local function createSpeechBubble(text)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.new(0, 180, 0, 50)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 0.35
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -8, 1, -8)
	label.Position = UDim2.new(0, 4, 0, 4)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(40, 40, 40)
	label.Font = Enum.Font.Gotham
	label.TextSize = 18
	label.TextWrapped = true
	label.Parent = frame

	return gui
end

local function createNameTag(nameText)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 120, 0, 25)
	billboard.StudsOffset = Vector3.new(0, 2.25, 0)
	billboard.AlwaysOnTop = false

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = nameText
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 16
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.7
	textLabel.Parent = billboard

	return billboard
end

-- =========================================================
-- CREAR R6 SIEMPRE
-- =========================================================
local function createR6Dummy()
	local model = Instance.new("Model")
	model.Name = CONFIG.NameDisplay

	local function part(name, size, color)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.BrickColor = BrickColor.new(color or "Really black")
		p.Anchored = false
		p.CanCollide = false
		p.Parent = model
		return p
	end

	local torso = part("Torso", Vector3.new(2, 2, 1))
	local head = part("Head", Vector3.new(2, 1, 1))
	head.Position = torso.Position + Vector3.new(0, 1.5, 0)
	local la = part("Left Arm", Vector3.new(1, 2, 1))
	local ra = part("Right Arm", Vector3.new(1, 2, 1))
	local ll = part("Left Leg", Vector3.new(1, 2, 1))
	local rl = part("Right Leg", Vector3.new(1, 2, 1))

	local hum = Instance.new("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6
	hum.Parent = model

	local hrp = part("HumanoidRootPart", Vector3.new(2, 2, 1))
	hrp.Transparency = 1

	local function weld(p0, p1, cf)
		local m = Instance.new("Motor6D")
		m.Part0 = p0
		m.Part1 = p1
		m.C0 = cf
		m.Parent = p0
	end

	weld(torso, head, CFrame.new(0, 1.5, 0))
	weld(torso, la, CFrame.new(-1.5, 0.5, 0))
	weld(torso, ra, CFrame.new(1.5, 0.5, 0))
	weld(torso, ll, CFrame.new(-0.5, -1, 0))
	weld(torso, rl, CFrame.new(0.5, -1, 0))

	local rootJoint = Instance.new("Motor6D")
	rootJoint.Part0 = hrp
	rootJoint.Part1 = torso
	rootJoint.Parent = hrp

	createNameTag(CONFIG.NameDisplay).Parent = head

	model.PrimaryPart = hrp
	return model, hum, hrp
end

-- =========================================================
-- CREAR COMPAÑERO
-- =========================================================
local function createCompanion()
	local success, model = pcall(function()
		return Players:GetCharacterAppearanceAsync(CONFIG.UserIdToClone)
	end)

	local r6Model, hum, root

	if success and model and model:FindFirstChildOfClass("Humanoid") then
		-- Si el modelo existe, forzar a R6
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		humanoid.RigType = Enum.HumanoidRigType.R6
		model.Name = CONFIG.NameDisplay
		root = model:FindFirstChild("HumanoidRootPart")
		if not root then
			root = Instance.new("Part")
			root.Name = "HumanoidRootPart"
			root.Size = Vector3.new(2, 2, 1)
			root.Anchored = false
			root.CanCollide = false
			root.Parent = model
			model.PrimaryPart = root
		end
		hum = humanoid
		r6Model = model
	else
		warn("Fallo al obtener avatar, usando dummy R6.")
		r6Model, hum, root = createR6Dummy()
	end

	local playerChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local playerRoot = safeWaitForChild(playerChar, "HumanoidRootPart")
	r6Model.Parent = workspace
	root.CFrame = playerRoot.CFrame * CFrame.new(CONFIG.SpawnOffset)

	return r6Model, hum, root
end

-- =========================================================
-- LÓGICA PRINCIPAL
-- =========================================================
local companion, humanoid, hrp = createCompanion()
local lastPathTime = 0
local nextSpeech = tick() + math.random(CONFIG.SpeechMinDelay, CONFIG.SpeechMaxDelay)
local nextLook = tick() + CONFIG.LookCheckInterval
local path = nil

RunService.Heartbeat:Connect(function()
	local playerChar = LocalPlayer.Character
	if not playerChar then return end
	local playerHRP = playerChar:FindFirstChild("HumanoidRootPart")
	if not playerHRP or not hrp or not humanoid then return end

	local dist = (playerHRP.Position - hrp.Position).Magnitude
	if dist >= CONFIG.TeleportDistance then
		hrp.CFrame = playerHRP.CFrame * CFrame.new(CONFIG.SpawnOffset)
		return
	end

	if dist > CONFIG.FollowStartDistance then
		if tick() - lastPathTime > CONFIG.PathRecomputeInterval then
			local newPath = PathfindingService:CreatePath()
			newPath:ComputeAsync(hrp.Position, playerHRP.Position)
			path = newPath
			lastPathTime = tick()
		end
		if path and path.Status == Enum.PathStatus.Success then
			for _, waypoint in ipairs(path:GetWaypoints()) do
				humanoid:MoveTo(waypoint.Position)
				humanoid.MoveToFinished:Wait(1)
			end
		end
	end

	if tick() >= nextSpeech then
		nextSpeech = tick() + math.random(CONFIG.SpeechMinDelay, CONFIG.SpeechMaxDelay)
		local phrase = PHRASES[math.random(1, #PHRASES)]
		local bubble = createSpeechBubble(phrase)
		local head = companion:FindFirstChild("Head")
		if head then
			bubble.Parent = head
			Debris:AddItem(bubble, CONFIG.SpeechBubbleDuration)
		end
	end

	if dist < CONFIG.LookAtDistance and tick() >= nextLook then
		nextLook = tick() + CONFIG.LookCheckInterval
		if math.random() < CONFIG.LookChance then
			hrp.CFrame = CFrame.new(hrp.Position, playerHRP.Position)
		end
	end
end)

print("✅ Mey ♥ (R6) activo y siguiéndote.")