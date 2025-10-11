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

--// Corrección de iluminación
Lighting.GlobalShadows = false
Lighting.Atmosphere.Density = 0
Lighting.Brightness = 1
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

--// SISTEMA DE VELOCIDAD DINÁMICA
local function enforceWalkSpeed()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")

	local tempStats = player:WaitForChild("TempPlayerStatsModule", 5)
	if not tempStats then return end

	local isCrawling = tempStats:WaitForChild("IsCrawling", 5)
	local isBeast = tempStats:WaitForChild("IsBeast", 5)
	local beastSpeedPending = false

	RunService.Heartbeat:Connect(function()
		if humanoid and isCrawling and isBeast then
			local crawling = isCrawling.Value
			local beast = isBeast.Value

			if not beast then
				humanoid.WalkSpeed = crawling and crawlSpeed or normalSpeed
			else
				if humanoid.WalkSpeed < beastSpeed then
					if not beastSpeedPending then
						beastSpeedPending = true
						task.delay(1, function()
							if humanoid and humanoid.Parent and humanoid.WalkSpeed < beastSpeed then
								humanoid.WalkSpeed = beastSpeed
							end
							beastSpeedPending = false
						end)
					end
				end
			end
		end
	end)
end

if player.Character then enforceWalkSpeed() end
player.CharacterAdded:Connect(enforceWalkSpeed)

--// ESP Y TRACKER
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
	nameLabel.TextTransparency = 0.15
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = billboard

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

	RunService.RenderStepped:Connect(function()
		if not (target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then
			trackerPart.Transparency = 1
			return
		end

		local dist = (playerTorso.Position - targetTorso.Position).Magnitude
		local tempStats = target:FindFirstChild("TempPlayerStatsModule")
		local beast = tempStats and tempStats:FindFirstChild("IsBeast") and tempStats.IsBeast.Value
		local color = beast and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)

		highlight.OutlineColor = color
		nameLabel.TextColor3 = color
		nameLabel.Text = string.format("%s [%s] - %.1f", target.Name, beast and "Beast" or "Human", dist)

		local midpoint = (playerTorso.Position + targetTorso.Position) / 2
		local direction = (targetTorso.Position - playerTorso.Position)
		local distance = direction.Magnitude
		trackerPart.Size = Vector3.new(0.04, 0.04, distance)
		trackerPart.CFrame = CFrame.lookAt(midpoint, targetTorso.Position)
		trackerPart.Color = color
	end)
end

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

-- 🧿 SISTEMA DE TEMMIE Y TABLE ESP
local TEMMIE_IMAGE_ID = "rbxassetid://90866842257772"
local OFFSET_Y = -1
local TEMMIE_SIZE = UDim2.new(0, 68, 0, 68)
local CONTOUR_COLOR = Color3.fromRGB(0, 255, 0)
local activeTables = {}
local lastColorState = {}
local DISABLE_COLOR = Color3.fromRGB(40, 127, 71)

-- Crear el Temmie
local function createTemmie(screen)
	if screen:FindFirstChild("BillboardGuiTemmie") then return end
	local temmie = Instance.new("BillboardGui")
	temmie.Name = "BillboardGuiTemmie"
	temmie.Size = TEMMIE_SIZE
	temmie.AlwaysOnTop = true
	temmie.MaxDistance = math.huge
	temmie.Parent = screen

	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.new(1, 0, 1, 0)
	img.Image = TEMMIE_IMAGE_ID
	img.ImageTransparency = 0.35
	img.Parent = temmie
end

-- Crear contorno
local function createContour(tbl)
	if tbl:FindFirstChild("TableESP") then return end
	local hl = Instance.new("Highlight")
	hl.Name = "TableESP"
	hl.Adornee = tbl
	hl.FillTransparency = 1
	hl.OutlineTransparency = 1
	hl.OutlineColor = CONTOUR_COLOR
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = tbl
	activeTables[tbl] = {alpha = 0}
end

-- Actualizar visual de color
local function updateVisuals(screen, temmie, esp)
	local color = screen.Color
	local isDisabled =
		math.floor(color.R * 255) == 40 and
		math.floor(color.G * 255) == 127 and
		math.floor(color.B * 255) == 71

	if lastColorState[screen] == isDisabled then return end
	lastColorState[screen] = isDisabled

	if temmie then temmie.Enabled = not isDisabled end
	if esp then esp.Enabled = not isDisabled end
end

-- Conectar cambios de color en cada mesa
local function connectTable(tbl)
	local screen = tbl:FindFirstChild("Screen")
	if not screen then return end
	createTemmie(screen)
	createContour(tbl)

	local temmie = screen:FindFirstChild("BillboardGuiTemmie")
	local esp = tbl:FindFirstChild("TableESP")

	screen:GetPropertyChangedSignal("Color"):Connect(function()
		updateVisuals(screen, temmie, esp)
	end)

	updateVisuals(screen, temmie, esp)
end

-- Inicializar mesas existentes
for _, obj in ipairs(workspace:GetDescendants()) do
	if obj.Name == "ComputerTable" then
		connectTable(obj)
	end
end

workspace.DescendantAdded:Connect(function(obj)
	if obj.Name == "ComputerTable" then
		task.spawn(function()
			obj:WaitForChild("Screen")
			connectTable(obj)
		end)
	end
end)

-- 🔁 Revisión periódica ultra ligera (1 loop global)
task.spawn(function()
	while task.wait(1) do
		for tbl in pairs(activeTables) do
			if tbl and tbl.Parent then
				local screen = tbl:FindFirstChild("Screen")
				if screen then
					local temmie = screen:FindFirstChild("BillboardGuiTemmie")
					local esp = tbl:FindFirstChild("TableESP")
					updateVisuals(screen, temmie, esp)
				end
			else
				activeTables[tbl] = nil
			end
		end
	end
end)

-- 💎 GEMSTONE TEXTURE (LOCAL PLAYER)
local TARGET_TEXTURE = "rbxassetid://136402852592541"

task.spawn(function()
	while task.wait(2) do
		local char = workspace:FindFirstChild(player.Name)
		if char then
			local gemstone = char:FindFirstChild("PackedGemstone")
			local handle = gemstone and gemstone:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") and handle.TextureID ~= TARGET_TEXTURE then
				handle.TextureID = TARGET_TEXTURE
			end
		end
	end
end)