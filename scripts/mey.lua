--// Mey Companion Script R6 - Versión 2 //
-- Ejecuta esto localmente (en tu Baseplate, plugin, etc.)

local userId = 7139360318 -- Tu ID (apariencia del NPC)
local npcName = "Mey ♥"
local maxDistance = 80
local followDistance = 5

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local humanoid = char:WaitForChild("Humanoid")

--// Eliminar si ya existe una Mey
local old = workspace:FindFirstChild(npcName)
if old then old:Destroy() end

--// Cargar modelo de usuario
local success, npcModel = pcall(function()
	return Players:GetCharacterAppearanceAsync(userId)
end)

if not success or not npcModel then
	warn("No se pudo cargar el modelo del usuario.")
	return
end

npcModel.Parent = workspace
npcModel.Name = npcName
npcModel:MoveTo(hrp.Position + Vector3.new(2,0,2))

-- Forzar R6 si no lo es
local npcHumanoid = npcModel:FindFirstChildOfClass("Humanoid") or Instance.new("Humanoid", npcModel)
npcHumanoid.RigType = Enum.HumanoidRigType.R6
npcHumanoid.DisplayName = npcName
npcHumanoid.NameDisplayDistance = 15

-- Hacerlo atravesable por el jugador
for _, part in ipairs(npcModel:GetDescendants()) do
	if part:IsA("BasePart") then
		part.CanCollide = true
		part.Massless = false
		part.CollisionGroup = "Default"
	end
end

-- Animaciones básicas R6
if npcModel:FindFirstChild("Animate") then npcModel.Animate:Destroy() end
local animate = Instance.new("Folder", npcModel)
animate.Name = "Animate"

local function addAnim(name, id)
	local s = Instance.new("StringValue")
	s.Name = name
	s.Value = "rbxassetid://"..id
	s.Parent = animate
end

addAnim("idle", 180435571)
addAnim("walk", 180426354)
addAnim("run", 180426354)
addAnim("jump", 125750702)

-- Frases de compañía 💬
-- Frases de compañía 💬
local frases = {
	"Te quiero mucho ♡",
	"Siempre a tu lado~",
	"Eres mi persona favorita~",
	"No te me pierdas uwu",
	"Love u <3",
}

local ChatService = game:GetService("Chat")

task.spawn(function()
	while task.wait(math.random(12, 20)) do
		if math.random() < 0.6 and npcModel and npcModel:FindFirstChild("Head") then
			local frase = frases[math.random(1, #frases)]
			ChatService:Chat(npcModel.Head, frase, Enum.ChatColor.White)
		end
	end
end)

-- Movimiento natural 🧠
task.spawn(function()
	while task.wait(0.2) do
		if not npcModel or not npcModel.Parent then break end
		local npcHRP = npcModel:FindFirstChild("HumanoidRootPart")
		if not npcHRP then continue end

		local dist = (hrp.Position - npcHRP.Position).Magnitude

		if dist > maxDistance then
			npcModel:MoveTo(hrp.Position + Vector3.new(2,0,2))
		elseif dist > followDistance then
			local offset = Vector3.new(math.random(-2,2),0,math.random(-2,2))
			local targetPos = hrp.Position - hrp.CFrame.LookVector * 3 + offset
			npcModel:MoveTo(targetPos)
		end

		-- Mirada suave (rotación lenta hacia el jugador)
		if dist < 10 and math.random() < 0.25 then
			local lookCF = CFrame.lookAt(npcHRP.Position, hrp.Position)
			local tween = TweenService:Create(npcHRP, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				CFrame = npcHRP.CFrame:Lerp(lookCF, 0.5)
			})
			tween:Play()
		end

		-- Sincronizar velocidad
		npcHumanoid.WalkSpeed = humanoid.WalkSpeed
	end
end)

-- Salto con delay de 1s
task.spawn(function()
	while task.wait(0.1) do
		if humanoid.Jump then
			task.wait(1)
			if npcHumanoid then npcHumanoid.Jump = true end
		end
	end
end)