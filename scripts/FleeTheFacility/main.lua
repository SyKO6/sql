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

--// Corrección de iluminación
Lighting.GlobalShadows = false
if Lighting:FindFirstChildOfClass("Atmosphere") then
	Lighting:FindFirstChildOfClass("Atmosphere").Density = 0
end
Lighting.Brightness = 3
Lighting.FogEnd = 100000
Lighting.ExposureCompensation = 0.5

task.spawn(function()
	while true do
		task.wait(1)
		if Lighting.GlobalShadows then
			Lighting.GlobalShadows = false
		end
		local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmos and atmos.Density ~= 0 then
			atmos.Density = 0
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
				humanoid.WalkSpeed = crawling and crawlSpeed or normalSpeed
			end
		end
	end)
end

if player.Character then
	enforceWalkSpeed()
end
player.CharacterAdded:Connect(enforceWalkSpeed)

--// ESP AVANZADO
local function createESP(target)
	if target == player then return end
	repeat task.wait() until target.Character and target.Character:FindFirstChild("HumanoidRootPart") and target.Character:FindFirstChild("Head")

	-- Highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESPHighlight"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.Adornee = target.Character
	highlight.Parent = target.Character

	-- Nombre flotante
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

	-- Beam (línea de cámara)
	local camPart = Instance.new("Part")
	camPart.Anchored = true
	camPart.CanCollide = false
	camPart.Transparency = 1
	camPart.Size = Vector3.new(0.1, 0.1, 0.1)
	camPart.Parent = workspace

	local cameraAttachment = Instance.new("Attachment")
	cameraAttachment.Parent = camPart

	local targetAttachment = Instance.new("Attachment")
	targetAttachment.Parent = target.Character:WaitForChild("HumanoidRootPart")

	local beam = Instance.new("Beam")
	beam.Attachment0 = cameraAttachment
	beam.Attachment1 = targetAttachment
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Width0 = 0.1
	beam.Width1 = 0.1
	beam.Transparency = NumberSequence.new(0.15)
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	beam.Parent = cameraAttachment -- <- esto es importante

	-- Render loop
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not (target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then
			beam.Enabled = false
			if conn then conn:Disconnect() end
			return
		end

		camPart.CFrame = camera.CFrame

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

		-- Color dinámico
		local color = Color3.fromRGB(255, 255, 255)
		if beastValue then
			color = Color3.fromRGB(255, 0, 0)
		elseif capturedValue then
			color = Color3.fromRGB(150, 220, 255)
		elseif currentAnimValue == "Typing" then
			color = Color3.fromRGB(0, 255, 0)
		end

		-- Detectar bestia cercana
		for _, plr in pairs(Players:GetPlayers()) do
			local ts = plr:FindFirstChild("TempPlayerStatsModule")
			if ts and ts:FindFirstChild("IsBeast") and ts.IsBeast.Value and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local beastDist = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
				if beastDist < 30 and not beastValue then
					color = Color3.fromRGB(255, 180, 50)
					break
				end
			end
		end

		if crawlingValue then
			color = Color3.new(color.R * 0.7, color.G * 0.7, color.B * 0.7)
		end

		-- Aplicar color
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

-- Aplicar ESP a todos los jugadores
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