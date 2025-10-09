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

	-- === TRACKER 3D (GARANTIZADO FUNCIONAL) ===
    local camPart = Instance.new("Part")
    camPart.Name = "CamPart_" .. target.Name
    camPart.Anchored = true
    camPart.CanCollide = false
    camPart.Transparency = 1
    camPart.Size = Vector3.new(0.2, 0.2, 0.2)
    camPart.Parent = workspace
    
    local camAttach = Instance.new("Attachment")
    camAttach.Name = "CameraAttach"
    camAttach.Parent = camPart
    
    local root = target.Character:WaitForChild("HumanoidRootPart")
    
    local targetAttach = Instance.new("Attachment")
    targetAttach.Name = "TargetAttach"
    targetAttach.Parent = root
    
    local beam = Instance.new("Beam")
    beam.Attachment0 = camAttach
    beam.Attachment1 = targetAttach
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.Width0 = 0.1
    beam.Width1 = 0.1
    beam.Transparency = NumberSequence.new(0.15)
    beam.Segments = 1
    beam.Parent = workspace
    beam.Enabled = true
    
    -- Color base del jugador
    local function getColor(plr)
    	local tempStats = plr:FindFirstChild("TempPlayerStatsModule")
    	if not tempStats then return Color3.fromRGB(255, 255, 255) end
    	if tempStats:FindFirstChild("IsBeast") and tempStats.IsBeast.Value then
    		return Color3.fromRGB(255, 0, 0)
    	elseif tempStats:FindFirstChild("Captured") and tempStats.Captured.Value then
    		return Color3.fromRGB(150, 220, 255)
    	elseif tempStats:FindFirstChild("CurrentAnimation") and tempStats.CurrentAnimation.Value == "Typing" then
    		return Color3.fromRGB(0, 255, 0)
    	else
    		return Color3.fromRGB(255, 255, 255)
    	end
    end
    
    RunService.RenderStepped:Connect(function()
    	if not (target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then
    		beam.Enabled = false
    		return
    	end
    
    	-- Mantener la posición del punto de la cámara
    	camPart.CFrame = CFrame.new(camera.CFrame.Position)
    
    	-- Actualizar color dinámico
    	local col = getColor(target)
    
    	-- Cambiar color si hay bestia cerca
    	for _, plr in pairs(Players:GetPlayers()) do
    		local stats = plr:FindFirstChild("TempPlayerStatsModule")
    		if stats and stats:FindFirstChild("IsBeast") and stats.IsBeast.Value and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
    			local dist = (plr.Character.HumanoidRootPart.Position - root.Position).Magnitude
    			if dist < 30 and not (stats.IsBeast.Value and plr == target) then
    				col = Color3.fromRGB(255, 180, 50)
    				break
    			end
    		end
    	end
    
    	beam.Color = ColorSequence.new(col)
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