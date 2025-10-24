-- Mey ♥ Companion (Always R6, LocalScript)
-- Seguro para usar dentro de Roblox Studio

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local LocalPlayer = Players.LocalPlayer
local MeyUserId = 7139360318  -- ID del avatar de Mey
local NameDisplay = "Mey ♥"

-- ==========================================
-- Crear personaje R6 con apariencia de Mey
-- ==========================================
local function createMey()
	-- Cargar modelo R6 base
	local model = InsertService:LoadAsset(1664543044) -- R6 Dummy Asset
	local char = model:FindFirstChildWhichIsA("Model") or model
	char.Name = NameDisplay
	char.Parent = workspace

	-- Forzar rig R6
	local hum = char:FindFirstChildOfClass("Humanoid")
	hum.RigType = Enum.HumanoidRigType.R6

	-- Aplicar apariencia de Mey
	local success, desc = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(MeyUserId)
	end)
	if success and desc then
		hum:ApplyDescription(desc)
	end

	-- Posicionar cerca del jugador
	local playerChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local root = playerChar:WaitForChild("HumanoidRootPart")
	char:SetPrimaryPartCFrame(root.CFrame * CFrame.new(2, 0, 0))

	-- Eliminar DisplayName duplicado
	hum.DisplayName = ""

	-- Crear nombre flotante (solo visible cerca)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MeyName"
	billboard.Size = UDim2.new(0, 120, 0, 25)
	billboard.StudsOffset = Vector3.new(0, 2.25, 0)
	billboard.AlwaysOnTop = false

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = NameDisplay
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.6
	label.Parent = billboard

	local head = char:WaitForChild("Head", 5)
	if head then
		billboard.Parent = head
	end

	return char, hum
end

-- ==========================================
-- Seguir al jugador suavemente
-- ==========================================
local companion, humanoid = createMey()
local meyRoot = companion:WaitForChild("HumanoidRootPart")

local followDistance = 5
local speed = 6

RunService.Heartbeat:Connect(function(dt)
	local playerChar = LocalPlayer.Character
	if not playerChar then return end
	local playerRoot = playerChar:FindFirstChild("HumanoidRootPart")
	if not playerRoot then return end

	local dist = (playerRoot.Position - meyRoot.Position).Magnitude
	if dist > followDistance then
		local targetPos = playerRoot.Position - playerRoot.CFrame.LookVector * 2
		local moveDir = (targetPos - meyRoot.Position).Unit
		meyRoot.CFrame = meyRoot.CFrame:Lerp(CFrame.new(meyRoot.Position + moveDir * speed * dt, playerRoot.Position), 0.2)
	end

	-- Mirar al jugador si está cerca
	if dist < 8 then
		meyRoot.CFrame = CFrame.new(meyRoot.Position, playerRoot.Position)
	end
end)

-- ==========================================
-- Burbuja de texto (parece chat real)
-- ==========================================
local phrases = {
	"Hola~ 💕", "No te vayas muy lejos 😳", "Jeje, te sigo 🐾",
	"Me gusta estar contigo 💖", "Eres genial 🌸", "Te cuido 😉"
}

task.spawn(function()
	while task.wait(math.random(6, 15)) do
		local head = companion:FindFirstChild("Head")
		if head and humanoid then
			local msg = phrases[math.random(1, #phrases)]
			humanoid:Chat(msg)
		end
	end
end)

print("🌸 Companion 'Mey ♥' actvo (R6 forzado, seguimiento suave)")