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

--// ESP avanzado con Beam (tracker 3D dinámico y seguro)
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

	-- === NUEVO TRACKER 3D (Beam con color dinámico) ===
	local camPart = Instance.new("Part")
	camPart.Anchored = true
	camPart.CanCollide = false
	camPart.Transparency = 1
	camPart.Size = Vector3.new(0.1, 0.1, 0.1)
	camPart.Parent = workspace

	local cameraAttachment = Instance.new("Attachment")
	cameraAttachment.Name = "CameraAttachment"
	cameraAttachment.Parent = camPart

	local targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = "TargetAttachment"
	targetAttachment.Parent = target.Character:WaitForChild("HumanoidRootPart")

	local beam = Instance.new("Beam")
	beam.Name = "ESPBeam"
	beam.Attachment0 = cameraAttachment
	beam.Attachment1 = targetAttachment
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Width0 = 0.1
	beam.Width1 = 0.1
	beam.Transparency = NumberSequence.new(0.15)
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	beam.Parent = workspace

	RunService.RenderStepped:Connect(function()
		if not (target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then
			beam.Enabled = false
			return
		end

		-- Actualizar posición de cámara y objetivo
		camPart.CFrame = camera.CFrame
		targetAttachment.WorldPosition = target.Character.HumanoidRootPart.Position

		local root = target.Character.HumanoidRootPart
		local dist = (player.Character.HumanoidRootPart.Position - root.Position).Magnitude
		local tempStats = target:FindFirstChild("TempPlayerStatsModule")

		local isBeast = tempStats and tempStats:FindFirstChild("IsBeast")
		local captured = tempStats and tempStats:FindFirstChild("Captured")
		local crawling = tempStats and tempStats:FindFirstChild("IsCrawling")
		local currentAnim = tempStats and tempStats:FindFirstChild("CurrentAnimation")

		local beastValue = isBeast and isBeast.Value
		local capturedValue = captured and captured.Value
		local crawlingValue = crawling and crawling.Value
		local currentAnimValue = (currentAnim and currentAnim.Value) or ""

		-- === CÁLCULO DE COLOR DINÁMICO ===
		local color = Color3.fromRGB(255, 255, 255) -- por defecto humano

		if beastValue then
			color = Color3.fromRGB(255, 0, 0) -- Beast
		elseif capturedValue then
			color = Color3.fromRGB(150, 220, 255) -- Capturado (azul hielo)
		elseif currentAnimValue == "Typing" then
			color = Color3.fromRGB(0, 255, 0) -- Escribiendo
		end

		-- Detectar si hay una bestia cerca
		local beast = nil
		for _, plr in pairs(Players:GetPlayers()) do
			local ts = plr:FindFirstChild("TempPlayerStatsModule")
			if ts and ts:FindFirstChild("IsBeast") and ts.IsBeast.Value then
				beast = plr
				break
			end
		end

		if beast and beast.Character and beast.Character:FindFirstChild("HumanoidRootPart") then
			local beastDist = (beast.Character.HumanoidRootPart.Position - root.Position).Magnitude
			if beastDist < 30 and not beastValue then
				color = Color3.fromRGB(255, 180, 50) -- Amarillo-naranja si hay bestia cerca
			end
		end

		-- Si está agachado (IsCrawling), oscurecer 30%
		if crawlingValue then
			color = Color3.new(color.R * 0.7, color.G * 0.7, color.B * 0.7)
		end

		-- === APLICAR COLOR Y DATOS ===
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

		beam.Color = ColorSequence.new(color)
		beam.Enabled = true
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