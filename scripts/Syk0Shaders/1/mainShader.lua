loadstring(game:HttpGet("https://raw.githubusercontent.com/SyKO6/sql/refs/heads/main/scripts/intro.lua"))()

-- 🌅 ILUMINACIÓN REALISTA + EFECTOS VISUALES + BLUR DINÁMICO

-- ===== SERVICIOS =====
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- ===== LIMPIEZA DE LIGHTING =====
for _, child in ipairs(Lighting:GetChildren()) do
	if not child:IsA("Sky") then
		pcall(function() child:Destroy() end)
	end
end

-- ===== AJUSTES BASE =====
pcall(function()
	Lighting.ClockTime = 13.2
	Lighting.Brightness = 5
	Lighting.Ambient = Color3.fromRGB(0, 0, 0)
	Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
	Lighting.FogStart = 0
	Lighting.FogEnd = 2800
	Lighting.FogColor = Color3.fromRGB(0, 0, 0)
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 1.0
	Lighting.EnvironmentSpecularScale = 1.0
	Lighting.Technology = Enum.Technology.Future
end)

-- ===== ATMOSPHERE =====
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "RealisticAtmosphere"
atmosphere.Density = 0.48
atmosphere.Offset = 0.0
atmosphere.Color = Color3.fromRGB(255, 255, 255)
atmosphere.Decay = Color3.fromRGB(185, 185, 185)
atmosphere.Glare = 0.8
atmosphere.Haze = 0.2
atmosphere.Parent = Lighting

-- ===== COLOR CORRECTION =====
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "RealisticColorCorrection"
cc.Brightness = -0.12
cc.Contrast = 0.45
cc.Saturation = 0.45
cc.TintColor = Color3.fromRGB(242, 255, 255)
cc.Parent = Lighting

-- ===== BLOOM =====
local bloom = Instance.new("BloomEffect")
bloom.Name = "RealisticBloom"
bloom.Intensity = 0.5
bloom.Size = 2000
bloom.Threshold = 1.0
bloom.Parent = Lighting

local bloom2 = Instance.new("BloomEffect")
bloom2.Name = "RealisticBloom2"
bloom2.Intensity = 0.2
bloom2.Size = 0.05
bloom2.Threshold = 5.0
bloom2.Parent = Lighting

-- ===== SUNRAYS =====
local sunRays = Instance.new("SunRaysEffect")
sunRays.Name = "RealisticSunRays"
sunRays.Intensity = 1.0
sunRays.Spread = 8.0
sunRays.Parent = Lighting

local sunLight = Instance.new("DirectionalLight")
sunLight.Brightness = 5
sunLight.Color = Color3.fromRGB(255, 240, 200)
sunLight.Shadows = true
sunLight.ShadowSoftness = 1.0
sunLight.Orientation = Vector3.new(45, 45, 0)
sunLight.Parent = Lighting

-- ===== DEPTH OF FIELD =====
local dof = Instance.new("DepthOfFieldEffect")
dof.Name = "RealisticDepthOfField"
dof.FocusDistance = 60
dof.InFocusRadius = 20
dof.FarIntensity = 1.0
dof.NearIntensity = 1.0
dof.Parent = Lighting

-- ===== BLUR =====
local blur = Instance.new("BlurEffect")
blur.Name = "RealisticBlur"
blur.Size = 100
blur.Parent = Lighting

-- Suaviza el blur inicial (fade-in de entrada)
task.spawn(function()
	for i = 100, 0, -2 do
		blur.Size = i
		task.wait(0.06)
	end
end)

-- ===== SKY =====
local hasSky = false
for _, c in ipairs(Lighting:GetChildren()) do
	if c:IsA("Sky") then
		hasSky = true
		break
	end
end

if not hasSky then
	local sky = Instance.new("Sky")
	sky.Name = "RealisticSky"
	sky.SkyboxBk = "rbxassetid://7018684000"
	sky.SkyboxDn = "rbxassetid://7018684000"
	sky.SkyboxFt = "rbxassetid://7018684000"
	sky.SkyboxLf = "rbxassetid://7018684000"
	sky.SkyboxRt = "rbxassetid://7018684000"
	sky.SkyboxUp = "rbxassetid://7018684000"
	sky.SunAngularSize = 12
	sky.MoonAngularSize = 11
	sky.Parent = Lighting
end

-- ===== VARIABLES =====
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

local currentBlur = 0
local blurTarget = 0

-- ===== FUNCIÓN SUAVIZADO =====
local function tweenBlur(target, speed)
	task.spawn(function()
		local step = (target - currentBlur) / (speed * 30)
		for i = 1, math.abs(speed * 30) do
			currentBlur += step
			blur.Size = math.clamp(currentBlur, 0, 15)
			task.wait(1/30)
		end
	end)
end

-- ===== BLUR POR MOVIMIENTO DE CÁMARA (SOLO GIROS EXTREMADAMENTE BRUSCOS) =====
local lastLookVector = camera.CFrame.LookVector
local blurDecaySpeed = 2   -- qué tan rápido se desvanece el blur
local blurIncreaseSpeed = 8 -- qué tan rápido aparece
local blurThreshold = 0.22   -- 🔥 sensibilidad MUY alta (debe ser un giro rapidísimo para activar)

RunService.RenderStepped:Connect(function(dt)
	local currentLookVector = camera.CFrame.LookVector
	local rotationChange = (currentLookVector - lastLookVector).Magnitude
	lastLookVector = currentLookVector

	local intensity = 0
	if rotationChange > blurThreshold then
		-- se activa solo si el movimiento supera muchísimo el umbral
		intensity = math.clamp((rotationChange - blurThreshold) * 1200, 0, 1)
	end

	if intensity > currentBlur then
		currentBlur += (intensity - currentBlur) * dt * blurIncreaseSpeed
	else
		currentBlur -= currentBlur * dt * blurDecaySpeed
	end

	blur.Size = math.clamp(currentBlur * 20, 0, 15)
end)

-- ===== BLUR RÁPIDO POR DAÑO =====
local lastHealth = humanoid.Health
humanoid.HealthChanged:Connect(function(hp)
	if hp < lastHealth then
		-- Efecto "shot" de blur al recibir daño
		task.spawn(function()
			local peak = 10  -- intensidad del golpe visual
			blur.Size = peak
			for i = peak, 0, -1 do
				blur.Size = i
				task.wait(0.02)
			end
		end)
	end
	lastHealth = hp
end)

-- ===== BLUR POR BAJA VIDA =====
humanoid.HealthChanged:Connect(function(hp)
	local percent = hp / humanoid.MaxHealth
	if percent < 0.15 then
		local extra = math.clamp((0.15 - percent) * 100, 0, 15)
		blur.Size = math.max(blur.Size, extra)
	end
end)

print("🌇 Iluminación realista + blur dinámico aplicado correctamente.")