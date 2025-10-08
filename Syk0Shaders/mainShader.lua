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
	Lighting.ClockTime = 14
	Lighting.Brightness = 4
	Lighting.Ambient = Color3.fromRGB(0, 0, 0)
	Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
	Lighting.FogStart = 0
	Lighting.FogEnd = 1200
	Lighting.FogColor = Color3.fromRGB(0, 0, 0)
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 1.0
	Lighting.EnvironmentSpecularScale = 1.0
	Lighting.Technology = Enum.Technology.Future
end)

-- ===== ATMOSPHERE =====
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "RealisticAtmosphere"
atmosphere.Density = 0.45
atmosphere.Offset = 0.0
atmosphere.Color = Color3.fromRGB(255, 255, 255)
atmosphere.Decay = Color3.fromRGB(255, 255, 255)
atmosphere.Glare = 0.3
atmosphere.Haze = 1.5
atmosphere.Parent = Lighting

-- ===== COLOR CORRECTION =====
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "RealisticColorCorrection"
cc.Brightness = 0.2
cc.Contrast = 0.12
cc.Saturation = 0.2
cc.TintColor = Color3.fromRGB(230, 230, 255)
cc.Parent = Lighting

-- ===== BLOOM =====
local bloom = Instance.new("BloomEffect")
bloom.Name = "RealisticBloom"
bloom.Intensity = 10.0
bloom.Size = 50
bloom.Threshold = 2.0
bloom.Parent = Lighting

-- ===== SUNRAYS =====
local sunRays = Instance.new("SunRaysEffect")
sunRays.Name = "RealisticSunRays"
sunRays.Intensity = 2.0
sunRays.Spread = 2.0
sunRays.Parent = Lighting

-- ===== DEPTH OF FIELD =====
local dof = Instance.new("DepthOfFieldEffect")
dof.Name = "RealisticDepthOfField"
dof.FocusDistance = 60
dof.InFocusRadius = 20
dof.FarIntensity = 0.6
dof.NearIntensity = 0.2
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

-- ===== BLUR POR MOVIMIENTO DE CÁMARA (SUAVE Y REALISTA) =====
local lastLookVector = camera.CFrame.LookVector
local blurDecaySpeed = 3  -- qué tan rápido se desvanece el blur
local blurIncreaseSpeed = 10 -- qué tan rápido aparece

RunService.RenderStepped:Connect(function(dt)
	local currentLookVector = camera.CFrame.LookVector
	local rotationChange = (currentLookVector - lastLookVector).Magnitude
	lastLookVector = currentLookVector

	-- Detectar solo giros bruscos (ej: más de 80° o movimientos fuertes)
	local intensity = math.clamp(rotationChange * 250, 0, 1)

	-- Si el giro es muy leve, ignorarlo completamente
	if intensity < 0.25 then
		intensity = 0
	end

	-- Si hay movimiento fuerte, aumentar blur suavemente
	if intensity > currentBlur then
		currentBlur = currentBlur + (intensity - currentBlur) * dt * blurIncreaseSpeed
	else
		-- De lo contrario, desvanecer blur suavemente
		currentBlur = currentBlur - currentBlur * dt * blurDecaySpeed
	end

	blur.Size = math.clamp(currentBlur * 15, 0, 15)
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