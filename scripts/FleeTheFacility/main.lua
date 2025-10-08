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

--// Tracker con Beam
local function createTracker(fromPart, toPart, color)
	local att0 = Instance.new("Attachment", fromPart)
	local att1 = Instance.new("Attachment", toPart)

	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.FaceCamera = false
	beam.Color = ColorSequence.new(color)
	beam.Transparency = NumberSequence.new(0.6) -- semi-transparente
	beam.Width0 = 0.1
	beam.Width1 = 0.1
	beam.LightEmission = 0.5
	beam.Parent = fromPart

	return beam
end

--// ESP avanzado con Tracker
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

	local beam

	RunService.RenderStepped:Connect(function()
		if not (target.Character and target.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then
			if beam then beam:Destroy() end
			return
		end

		local color = Color3.fromRGB(255, 255, 255) -- Human base
		local tempStats = target:FindFirstChild("TempPlayerStatsModule")
		if tempStats then
			if tempStats:FindFirstChild("IsBeast") and tempStats.IsBeast.Value then color = Color3.fromRGB(255,0,0) end
			if tempStats:FindFirstChild("Captured") and tempStats.Captured.Value then color = Color3.fromRGB(150,220,255) end
			if tempStats:FindFirstChild("CurrentAnimation") and tempStats.CurrentAnimation.Value == "Typing" then color = Color3.fromRGB(0,255,0) end
		end

		highlight.OutlineColor = color
		nameLabel.TextColor3 = color

		if not beam then
			beam = createTracker(player.Character.HumanoidRootPart, target.Character.HumanoidRootPart, color)
		else
			beam.Color = ColorSequence.new(color)
		end
	end)
end

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