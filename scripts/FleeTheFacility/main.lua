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

--// Iluminación clara (sin tinte verde)
if Lighting:FindFirstChildOfClass("Atmosphere") then
	Lighting.Atmosphere.Density = 0
end
Lighting.GlobalShadows = false
Lighting.Brightness = 3
Lighting.FogEnd = 100000
Lighting.ExposureCompensation = 0.5

task.spawn(function()
	while task.wait(1) do
		if Lighting.GlobalShadows then Lighting.GlobalShadows = false end
		if Lighting:FindFirstChildOfClass("Atmosphere") and Lighting.Atmosphere.Density ~= 0 then
			Lighting.Atmosphere.Density = 0
		end
	end
end)

--// Velocidad dinámica
local function enforceWalkSpeed()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	local tempStats = player:FindFirstChild("TempPlayerStatsModule")
	if not tempStats then return end

	local isCrawling = tempStats:FindFirstChild("IsCrawling")
	local isBeast = tempStats:FindFirstChild("IsBeast")

	RunService.Heartbeat:Connect(function()
		if humanoid and isCrawling and isBeast then
			if not isBeast.Value then
				humanoid.WalkSpeed = isCrawling.Value and crawlSpeed or normalSpeed
			end
		end
	end)
end

if player.Character then enforceWalkSpeed() end
player.CharacterAdded:Connect(enforceWalkSpeed)

--// Crear ESP + Tracker
local function createESPandTracker(target)
	if target == player then return end

	local function cleanup()
		if target.Character then
			for _, v in pairs(target.Character:GetChildren()) do
				if v.Name == "ESPHighlight" or v.Name == "NameTag" or v.Name == "TrackerBeam" then
					v:Destroy()
				end
			end
		end
	end
	cleanup()

	-- Highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESPHighlight"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.Parent = target.Character

	-- Nametag
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 230, 0, 16)
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

	-- Tracker 3D (línea estática)
	local beam = Instance.new("Beam")
	beam.Name = "TrackerBeam"
	beam.FaceCamera = true
	beam.LightInfluence = 0
	beam.Width0 = 0.05
	beam.Width1 = 0.05
	beam.Transparency = NumberSequence.new(0.2)
	beam.Parent = target.Character

	local attachA = Instance.new("Attachment", player.Character:WaitForChild("HumanoidRootPart"))
	local attachB = Instance.new("Attachment", target.Character:WaitForChild("HumanoidRootPart"))
	beam.Attachment0 = attachA
	beam.Attachment1 = attachB
	beam.Texture = ""
	beam.TextureSpeed = 0

	-- Actualización dinámica
	RunService.RenderStepped:Connect(function()
		if not (target.Character and player.Character) then return end
		local hrp1 = player.Character:FindFirstChild("HumanoidRootPart")
		local hrp2 = target.Character:FindFirstChild("HumanoidRootPart")
		if not (hrp1 and hrp2) then return end

		-- Distancia
		local dist = (hrp1.Position - hrp2.Position).Magnitude

		-- Estado del jugador
		local tempStats = target:FindFirstChild("TempPlayerStatsModule")
		local beast = tempStats and tempStats:FindFirstChild("IsBeast") and tempStats.IsBeast.Value
		local captured = tempStats and tempStats:FindFirstChild("Captured") and tempStats.Captured.Value
		local crawling = tempStats and tempStats:FindFirstChild("IsCrawling") and tempStats.IsCrawling.Value
		local chance = tempStats and tempStats:FindFirstChild("BeastChance") and math.floor(tempStats.BeastChance.Value * 100) or 0
		local currentAnim = tempStats and tempStats:FindFirstChild("CurrentAnimation") and tempStats.CurrentAnimation.Value or ""

		-- Color dinámico
		local color = Color3.fromRGB(255, 255, 255)
		if beast then
			color = Color3.fromRGB(255, 0, 0)
		elseif captured then
			color = Color3.fromRGB(150, 220, 255)
		elseif currentAnim == "Typing" then
			color = Color3.fromRGB(0, 255, 0)
		end
		if crawling then
			color = Color3.new(color.R * 0.7, color.G * 0.7, color.B * 0.7)
		end

		highlight.OutlineColor = color
		nameLabel.TextColor3 = color
		beam.Color = ColorSequence.new(color)

		-- Texto con % de bestia
		nameLabel.Text = string.format("%s [%s (%.0f%%)] - %.1f", target.Name, beast and "Beast" or "Human", chance, dist)
	end)
end

--// Aplicar ESP y Tracker a todos
for _, plr in pairs(Players:GetPlayers()) do
	if plr ~= player then
		plr.CharacterAdded:Connect(function()
			task.wait(1)
			createESPandTracker(plr)
		end)
		if plr.Character then
			createESPandTracker(plr)
		end
	end
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(1)
		createESPandTracker(plr)
	end)
end)