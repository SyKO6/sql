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
	billboard.Size = UDim2.new(0, 260, 0, 20)
	billboard.AlwaysOnTop = true
	billboard.ExtentsOffset = Vector3.new(0, 3, 0)
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

	RunService.RenderStepped:Connect(function()
		if not (target.Character and target.Character:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then 
			return 
		end

		local dist = (player.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude

		local tempStats = target:FindFirstChild("TempPlayerStatsModule")
		local savedStats = target:FindFirstChild("SavedPlayerStatsModule")

		local isBeast = tempStats and tempStats:FindFirstChild("IsBeast")
		local isCrawling = tempStats and tempStats:FindFirstChild("IsCrawling")
		local isCaptured = tempStats and tempStats:FindFirstChild("Captured")

		local beastValue = (isBeast and isBeast.Value) or false
		local crawlValue = (isCrawling and isCrawling.Value) or false
		local capturedValue = (isCaptured and isCaptured.Value) or false

		local beastChance = savedStats and savedStats:FindFirstChild("BeastChance")
		local chanceValue = (beastChance and beastChance.Value) or 0

		-- Buscar si hay bestia para medir distancia
		local nearestBeastDist = math.huge
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= target then
				local stats = plr:FindFirstChild("TempPlayerStatsModule")
				local isB = stats and stats:FindFirstChild("IsBeast")
				if isB and isB.Value and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					local d = (target.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
					if d < nearestBeastDist then
						nearestBeastDist = d
					end
				end
			end
		end

		-- Colores base
		local textColor = Color3.fromRGB(255, 255, 255)
		local outlineColor = Color3.fromRGB(255, 255, 255)

		-- Prioridad de color
		if beastValue then
			textColor = Color3.fromRGB(255, 0, 0)
			outlineColor = Color3.fromRGB(255, 0, 0)
		elseif capturedValue then
			textColor = Color3.fromRGB(80, 200, 255)
			outlineColor = Color3.fromRGB(80, 200, 255)
		elseif crawlValue then
			textColor = Color3.fromRGB(56, 140, 179)
			outlineColor = Color3.fromRGB(56, 140, 179)
		elseif nearestBeastDist < 20 then
			textColor = Color3.fromRGB(255, 170, 0)
			outlineColor = Color3.fromRGB(255, 140, 0)
		end

		nameLabel.TextColor3 = textColor
		highlight.OutlineColor = outlineColor

		-- Mostrar formato: Nombre [Beast / Human (Chance%)] - Studs
		local role = beastValue and "Beast" or "Human"
		nameLabel.Text = string.format("%s [%s (%d%%)] - %.1f", target.Name, role, chanceValue, dist)
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