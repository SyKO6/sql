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
local beastSpeed = 18.8
local fov = 80

--// Aplicar configuración visual
camera.FieldOfView = fov
player.CameraMode = Enum.CameraMode.Classic
player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
player.CameraMaxZoomDistance = 1000

--// Corrección de iluminación (visión clara)
Lighting.GlobalShadows = false
Lighting.Atmosphere.Density = 0
Lighting.Brightness = 3
Lighting.FogEnd = 100000
Lighting.ExposureCompensation = 0.5

task.spawn(function()
	while true do
		task.wait(1)
		if Lighting.GlobalShadows then Lighting.GlobalShadows = false end
		if Lighting.Atmosphere and Lighting.Atmosphere.Density ~= 0 then
			Lighting.Atmosphere.Density = 0
		end
	end
end)

--// Sistema de velocidad dinámica (Humano + Bestia)
--// Sistema de velocidad dinámica (Humano + Bestia)
local function enforceWalkSpeed()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	local tempStats = player:FindFirstChild("TempPlayerStatsModule")
	if not tempStats then return end

	local isCrawling = tempStats:FindFirstChild("IsCrawling")
	local isBeast = tempStats:FindFirstChild("IsBeast")

	-- bandera para evitar programar múltiples delays
	local beastSpeedPending = false

	RunService.Heartbeat:Connect(function()
		if humanoid and isCrawling and isBeast then
			local crawling = isCrawling.Value
			local beast = isBeast.Value

			-- 🧍‍♂️ Jugador normal
			if not beast then
				humanoid.WalkSpeed = crawling and crawlSpeed or normalSpeed
			else
				-- 🧟‍♂️ Bestia: si tiene velocidad menor a beastSpeed, esperar 1s y luego establecer
				if humanoid.WalkSpeed < beastSpeed then
					if not beastSpeedPending then
						beastSpeedPending = true
						task.delay(1, function()
							-- comprobar que el humanoide sigue existiendo y sigue con velocidad menor
							if humanoid and humanoid.Parent and humanoid.WalkSpeed < beastSpeed then
								humanoid.WalkSpeed = beastSpeed
							end
							beastSpeedPending = false
						end)
					end
				end
				-- Nota: ya no forzamos inmediatamente WalkSpeed = beastSpeed si es distinto.
			end
		end
	end)
end

if player.Character then enforceWalkSpeed() end
player.CharacterAdded:Connect(enforceWalkSpeed)

--// Función para oscurecer color
local function darkenColor(color, percent)
	return Color3.new(color.R * (1 - percent), color.G * (1 - percent), color.B * (1 - percent))
end

--// ESP avanzado con tracker 3D
local function createESP(target)
	if target == player then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESPHighlight"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- se ve a través de paredes
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

	-- 🧠 Tracker 3D (línea entre torsos)
	local playerTorso = player.Character:WaitForChild("HumanoidRootPart")
	local targetTorso = target.Character:WaitForChild("HumanoidRootPart")

	local trackerPart = Instance.new("Part")
	trackerPart.Name = "TorsoTrackerLine"
	trackerPart.Anchored = true
	trackerPart.CanCollide = false
	trackerPart.Material = Enum.Material.Neon
	trackerPart.Transparency = 0.35
	trackerPart.Size = Vector3.new(0.15, 0.15, 0.15)
	trackerPart.Color = Color3.fromRGB(255, 255, 255)
	trackerPart.Parent = workspace
	trackerPart.Locked = true
	trackerPart.CastShadow = false
	trackerPart:SetAttribute("NonInteractive", true)

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
		local ragdoll = tempStats and tempStats:FindFirstChild("Ragdoll")
		local currentAnim = tempStats and tempStats:FindFirstChild("CurrentAnimation")

		local beastValue = isBeast and isBeast.Value
		local capturedValue = captured and captured.Value
		local crawlingValue = crawling and crawling.Value
		local ragdollValue = ragdoll and ragdoll.Value
		local currentAnimValue = (currentAnim and currentAnim.Value) or ""

		-- 🔢 Sistema de prioridad de colores
		local finalColor = Color3.fromRGB(255, 255, 255)
		local priority = 1

		if currentAnimValue == "Typing" and priority < 2 then
			finalColor = Color3.fromRGB(0, 255, 0)
			priority = 2
		end
		if capturedValue and priority < 3 then
			finalColor = Color3.fromRGB(150, 220, 255)
			priority = 3
		end
		if ragdollValue and priority < 4 then
			finalColor = Color3.fromRGB(170, 0, 255)
			priority = 4
		end

		local beastNearby = false
		local beastPlayer
		for _, plr in pairs(Players:GetPlayers()) do
			local ts = plr:FindFirstChild("TempPlayerStatsModule")
			if ts and ts:FindFirstChild("IsBeast") and ts.IsBeast.Value then
				beastPlayer = plr
				break
			end
		end

		if beastPlayer and beastPlayer.Character and beastPlayer.Character:FindFirstChild("HumanoidRootPart") then
			local beastDist = (beastPlayer.Character.HumanoidRootPart.Position - targetTorso.Position).Magnitude
			if beastDist < 30 then
				beastNearby = true
				if ragdollValue then
					finalColor = Color3.fromRGB(220, 120, 255) -- púrpura claro (ragdoll + beast cerca)
					priority = 5
				elseif priority < 5 then
					finalColor = Color3.fromRGB(255, 180, 50) -- naranja
					priority = 5
				end
			end
		end

		if beastValue and priority < 10 then
			finalColor = Color3.fromRGB(255, 0, 0)
			priority = 10
		end

		-- Si está agachado (IsCrawling), aplicar siempre opaco sin importar prioridad
		if crawlingValue then
			local r, g, b = finalColor.R * 255, finalColor.G * 255, finalColor.B * 255
			finalColor = Color3.fromRGB(r * 0.7, g * 0.7, b * 0.7)
		end

		-- Actualizar visual
		highlight.OutlineColor = finalColor
		nameLabel.TextColor3 = finalColor
		nameLabel.Text = string.format("%s [%s (%.0f%%)] - %.1f",
			target.Name,
			beastValue and "Beast" or "Human",
			(target:FindFirstChild("SavedPlayerStatsModule")
				and target.SavedPlayerStatsModule:FindFirstChild("BeastChance")
				and target.SavedPlayerStatsModule.BeastChance.Value) or 0,
			dist
		)

		local midpoint = (playerTorso.Position + targetTorso.Position) / 2
		local direction = (targetTorso.Position - playerTorso.Position)
		local distance = direction.Magnitude

		trackerPart.Size = Vector3.new(0.04, 0.04, distance)
		trackerPart.CFrame = CFrame.lookAt(midpoint, targetTorso.Position)
		trackerPart.Color = finalColor
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
		if plr.Character then createESP(plr) end
	end
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(1)
		createESP(plr)
	end)
end)