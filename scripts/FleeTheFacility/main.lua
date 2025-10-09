loadstring(game:HttpGet("https://raw.githubusercontent.com/SyKO6/sql/refs/heads/main/scripts/intro.lua"))()

--// CONFIGURACIONES INICIALES
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// Variables
local normalSpeed = 18.8
local crawlSpeed = 10.8
local fov = 80

--// Aplicar configuración visual
camera.FieldOfView = fov
player.CameraMode = Enum.CameraMode.Classic
player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
player.CameraMaxZoomDistance = 1000

--// Corrección de iluminación (visión clara, sin tinte verde)
Lighting.GlobalShadows = false
Lighting.Atmosphere.Density = 0
Lighting.Brightness = 3
Lighting.FogEnd = 100000
Lighting.ExposureCompensation = 0.5

task.spawn(function()
	while true do
		task.wait(1)
		if Lighting.GlobalShadows then
			Lighting.GlobalShadows = false
		end
		if Lighting.Atmosphere and Lighting.Atmosphere.Density ~= 0 then
			Lighting.Atmosphere.Density = 0
		end
	end
end)

--// Sistema de velocidad dinámica
local function enforceWalkSpeed()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	local tempStats = player:FindFirstChild("TempPlayerStatsModule")
	if not tempStats then return end

	local isCrawling = tempStats:FindFirstChild("IsCrawling")
	local isBeast = tempStats:FindFirstChild("IsBeast")

	RunService.Heartbeat:Connect(function()
		if humanoid and isCrawling and isBeast then
			local crawling = isCrawling.Value
			local beast = isBeast.Value

			if not beast then
				if crawling then
					if humanoid.WalkSpeed ~= crawlSpeed then
						humanoid.WalkSpeed = crawlSpeed
					end
				else
					if humanoid.WalkSpeed ~= normalSpeed then
						humanoid.WalkSpeed = normalSpeed
					end
				end
			end
		end
	end)
end

if player.Character then
	enforceWalkSpeed()
end
player.CharacterAdded:Connect(enforceWalkSpeed)

--// Función para oscurecer color un % dado
local function darkenColor(color, percent)
	return Color3.new(
		color.R * (1 - percent),
		color.G * (1 - percent),
		color.B * (1 - percent)
	)
end

--// ESP avanzado
local function createESP(target)
	if target == player then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESPHighlight"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.Parent = target.Character

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 220, 0, 18)
	billboard.AlwaysOnTop = true
	billboard.Adornee = target.Character:WaitForChild("Head")
	billboard.Parent = target.Character

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = billboard

	-- 🧠 Tracker 3D entre torsos
	local playerTorso = player.Character:WaitForChild("HumanoidRootPart")
	local targetTorso = target.Character:WaitForChild("HumanoidRootPart")

	local trackerPart = Instance.new("Part")
	trackerPart.Name = "TorsoTrackerLine"
	trackerPart.Anchored = true
	trackerPart.CanCollide = false
	trackerPart.CanTouch = false
	trackerPart.CanQuery = false
	trackerPart.Material = Enum.Material.Neon
	trackerPart.Transparency = 0.35
	trackerPart.Size = Vector3.new(0.15, 0.15, 0.15)
	trackerPart.Color = Color3.fromRGB(255, 255, 255)
	trackerPart.Parent = workspace
	trackerPart.CastShadow = false
	trackerPart.Locked = true
	trackerPart:SetAttribute("NonInteractive", true)

	-- ❗ Permitir ver a través de paredes (No se corta)
	trackerPart.LocalTransparencyModifier = 0
	trackerPart.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	RunService.RenderStepped:Connect(function()
		if not (target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then
			if trackerPart then trackerPart.Transparency = 1 end
			return
		end

		local dist = (playerTorso.Position - targetTorso.Position).Magnitude

		local tempStats = target:FindFirstChild("TempPlayerStatsModule")
		local isBeast = tempStats and tempStats:FindFirstChild("IsBeast")
		local captured = tempStats and tempStats:FindFirstChild("Captured")
		local crawling = tempStats and tempStats:FindFirstChild("IsCrawling")
		local currentAnim = tempStats and tempStats:FindFirstChild("CurrentAnimation")
		local ragdoll = tempStats and tempStats:FindFirstChild("Ragdoll")

		local beastValue = (isBeast and isBeast.Value)
		local capturedValue = (captured and captured.Value)
		local crawlingValue = (crawling and crawling.Value)
		local currentAnimValue = (currentAnim and currentAnim.Value) or ""
		local ragdollValue = (ragdoll and ragdoll.Value)

		-- 🟩 Sistema de color por prioridad
		local color = Color3.fromRGB(255, 255, 255)
		local priority = 1

		-- Verde (Typing) prioridad 2
		if currentAnimValue == "Typing" and priority < 2 then
			color = Color3.fromRGB(0, 255, 0)
			priority = 2
		end

		-- Azul (capturado) prioridad 3
		if capturedValue and priority < 3 then
			color = Color3.fromRGB(150, 220, 255)
			priority = 3
		end

		-- Morado (ragdoll) prioridad 4
		if ragdollValue and priority < 4 then
			color = Color3.fromRGB(180, 0, 255)
			priority = 4
		end

		-- Naranja (beast cerca) prioridad 5
		local beast = nil
		for _, plr in pairs(Players:GetPlayers()) do
			local ts = plr:FindFirstChild("TempPlayerStatsModule")
			if ts and ts:FindFirstChild("IsBeast") and ts.IsBeast.Value then
				beast = plr
				break
			end
		end
		local beastDist = math.huge
		if beast and beast.Character and beast.Character:FindFirstChild("HumanoidRootPart") then
			beastDist = (beast.Character.HumanoidRootPart.Position - targetTorso.Position).Magnitude
			if beastDist < 30 and not beastValue and priority < 5 then
				color = Color3.fromRGB(255, 180, 50)
				priority = 5
			end
		end

		-- 🔮 Si está en ragdoll y cerca de la bestia → púrpura claro
		if ragdollValue and beastDist < 30 then
			color = Color3.fromRGB(200, 120, 255)
			priority = 6
		end

		-- Rojo (es bestia) prioridad 10
		if beastValue and priority < 10 then
			color = Color3.fromRGB(255, 0, 0)
			priority = 10
		end

		-- Opaco por IsCrawling (máxima prioridad)
		if crawlingValue then
			local r, g, b = color.R * 255, color.G * 255, color.B * 255
			color = Color3.fromRGB(r * 0.7, g * 0.7, b * 0.7)
			priority = 999
		end

		-- Aplicar colores actualizados
		highlight.OutlineColor = color
		nameLabel.TextColor3 = color
		nameLabel.Text = string.format("%s [%s (%.0f%%)] - %.1f",
			target.Name,
			beastValue and "Beast" or "Human",
			(target:FindFirstChild("SavedPlayerStatsModule")
				and target.SavedPlayerStatsModule:FindFirstChild("BeastChance")
				and target.SavedPlayerStatsModule.BeastChance.Value) or 0,
			dist
		)

		-- 🟪 Tracker 3D visual
		local midpoint = (playerTorso.Position + targetTorso.Position) / 2
		local direction = (targetTorso.Position - playerTorso.Position)
		local distance = direction.Magnitude

		trackerPart.Size = Vector3.new(0.15, 0.15, distance)
		trackerPart.CFrame = CFrame.lookAt(midpoint, targetTorso.Position)
		trackerPart.Color = color
		trackerPart.Transparency = 0.35
	end)
end

--// Aplicar ESP a todos los jugadores
for _, plr in pairs(Players:GetPlayers()) do
	if plr ~= player then
		plr.CharacterAdded:Connect(function()
			task.wait(1)
			createESP(plr)
		end)
		if plr.Character then
			createESP(plr)
		end
	end
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(1)
		createESP(plr)
	end)
end)