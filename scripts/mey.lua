--[[ 
    🩷 Mey Companion (R6 Only) 🩷
    - Compañera que sigue al jugador con comportamiento humano y frases dulces.
    - Ejecutar como LocalScript en Roblox Studio.
--]]

----------------------------------------------------
-- CONFIGURACIÓN
----------------------------------------------------
local CONFIG = {
	UserIdToClone = 7139360318,      -- Tu ID (apariencia base R6)
	NameDisplay = "Mey ♥",
	FollowDistance = 6,              -- distancia donde deja de avanzar
	StartFollowDistance = 10,        -- cuando empieza a seguirte
	TeleportDistance = 80,           -- si se aleja demasiado
	PathRefresh = 0.5,               -- cada cuanto actualiza el camino
	JumpDelay = 1,                   -- segundos después de que tú saltes
	LookDistance = 8,                -- distancia para girar el torso
	LookChance = 0.3,                -- probabilidad de mirarte al estar cerca
}

----------------------------------------------------
-- SERVICIOS
----------------------------------------------------
local Players = game:GetService("Players")
local ChatService = game:GetService("Chat")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then return end

----------------------------------------------------
-- FUNCIONES AUXILIARES
----------------------------------------------------
local function say(humanoid, text)
	pcall(function()
		ChatService:Chat(humanoid.Parent.Head, text, Enum.ChatColor.White)
	end)
end

local function getDefaultR6Animations()
	local animate = Instance.new("LocalScript")
	animate.Name = "Animate"

	local function new(name, id)
		local val = Instance.new("StringValue")
		val.Name = name
		val.Value = id
		return val
	end

	local walk = Instance.new("StringValue")
	walk.Name = "walk"
	walk.Value = "rbxassetid://180426354" -- walk
	local run = new("run", "rbxassetid://180426354")
	local idle = Instance.new("Folder")
	idle.Name = "idle"
	local anim1 = new("Animation1", "rbxassetid://180435571")
	local anim2 = new("Animation2", "rbxassetid://180435792")
	idle:AddChild(anim1)
	idle:AddChild(anim2)

	local jump = new("jump", "rbxassetid://125750702")
	local fall = new("fall", "rbxassetid://180436148")

	walk.Parent = animate
	run.Parent = animate
	idle.Parent = animate
	jump.Parent = animate
	fall.Parent = animate

	return animate
end

----------------------------------------------------
-- CREAR NPC
----------------------------------------------------
local function createMey()
	local desc = Players:GetHumanoidDescriptionFromUserId(CONFIG.UserIdToClone)
	local npc = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
	npc.Name = CONFIG.NameDisplay
	npc.Parent = workspace

	local hrp = npc:WaitForChild("HumanoidRootPart")
	local hum = npc:WaitForChild("Humanoid")
	hum.DisplayName = CONFIG.NameDisplay
	hum.NameDisplayDistance = 20

	-- posición inicial (cerca del jugador)
	local char = player.Character or player.CharacterAdded:Wait()
	local root = char:WaitForChild("HumanoidRootPart")
	npc:SetPrimaryPartCFrame(root.CFrame * CFrame.new(2, 0, 0))

	-- animaciones
	local plrAnimate = char:FindFirstChild("Animate")
	if plrAnimate and player.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R6 then
		plrAnimate:Clone().Parent = npc
	else
		getDefaultR6Animations().Parent = npc
	end

	say(hum, "¡Hola! Prometo no perderme esta vez 💕")
	return npc, hum, hrp
end

----------------------------------------------------
-- LÓGICA PRINCIPAL
----------------------------------------------------
local npc, hum, hrp = createMey()
local path
local lastPath = 0
local nextLook = 0
local canFollow = true

local char = player.Character or player.CharacterAdded:Wait()
local myHum = char:WaitForChild("Humanoid")
local myRoot = char:WaitForChild("HumanoidRootPart")

-- seguir
RunService.Heartbeat:Connect(function()
	if not npc or not hrp or not hum or not myRoot then return end

	-- adaptar velocidad
	hum.WalkSpeed = myHum.WalkSpeed

	local dist = (myRoot.Position - hrp.Position).Magnitude

	-- teletransporte
	if dist > CONFIG.TeleportDistance then
		hrp.CFrame = myRoot.CFrame * CFrame.new(2, 0, 0)
		say(hum, "Ups, me adelanté un poco 😅")
		return
	end

	-- seguir
	if dist > CONFIG.StartFollowDistance then
		if tick() - lastPath > CONFIG.PathRefresh then
			local pathNew = PathfindingService:CreatePath()
			pathNew:ComputeAsync(hrp.Position, myRoot.Position)
			path = pathNew
			lastPath = tick()
		end

		if path and path.Status == Enum.PathStatus.Success then
			local points = path:GetWaypoints()
			for _, p in ipairs(points) do
				if (myRoot.Position - hrp.Position).Magnitude <= CONFIG.FollowDistance then
					break
				end
				hum:MoveTo(p.Position + Vector3.new(math.random(-1,1)*0.5, 0, math.random(-1,1)*0.5))
				hum.MoveToFinished:Wait(0.2)
			end
		else
			hum:MoveTo(myRoot.Position)
		end
	elseif dist < CONFIG.LookDistance and tick() >= nextLook then
		nextLook = tick() + 2 + math.random()
		if math.random() < CONFIG.LookChance then
			hrp.CFrame = CFrame.new(hrp.Position, myRoot.Position)
		end
	end
end)

-- salto sincronizado
myHum.Jumping:Connect(function(active)
	if active then
		task.wait(CONFIG.JumpDelay)
		hum.Jump = true
	end
end)

-- frases cercanas
RunService.Stepped:Connect(function()
	if (myRoot.Position - hrp.Position).Magnitude < CONFIG.FollowDistance then
		if math.random() < 0.003 then
			say(hum, "Jeje... aquí estoy 🫶")
		end
	end
end)

print("🩷 Companion 'Mey ♥' activada correctamente.")