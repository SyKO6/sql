loadstring(game:HttpGet("https://raw.githubusercontent.com/SyKO6/sql/refs/heads/main/scripts/intro.lua"))()

-- 🌅 ILUMINACIÓN REALISTA + EFECTOS VISUALES + BLUR DINÁMICO

-- ===== SERVICIOS =====
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

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
atmosphere.Density = 0.6
atmosphere.Offset = 0.0
atmosphere.Color = Color3.fromRGB(255, 255, 255)
atmosphere.Decay = Color3.fromRGB(185, 185, 185)
atmosphere.Glare = 0.0
atmosphere.Haze = 0.0
atmosphere.Parent = Lighting

-- ===== COLOR CORRECTION =====
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "RealisticColorCorrection"
cc.Brightness = -0.12
cc.Contrast = 0.45
cc.Saturation = 0.2
cc.TintColor = Color3.fromRGB(242, 255, 255)
cc.Parent = Lighting

-- ===== BLOOM =====
local bloom = Instance.new("BloomEffect")
bloom.Name = "RealisticBloom"
bloom.Intensity = 0.2
bloom.Size = 2800
bloom.Threshold = 1.0
bloom.Parent = Lighting

local bloom2 = Instance.new("BloomEffect")
bloom2.Name = "RealisticBloom2"
bloom2.Intensity = 0.001
bloom2.Size = 0.01
bloom2.Threshold = 0.5
bloom2.Parent = Lighting

-- ===== SUNRAYS =====
local sunRays = Instance.new("SunRaysEffect")
sunRays.Name = "RealisticSunRays"
sunRays.Intensity = 1.0
sunRays.Spread = 1.0
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

-- ===== ASEGURAR QUE EXISTA RealisticBlur =====
local function ensureRealisticBlur()
	local blur = Lighting:FindFirstChild("RealisticBlur")
	if not blur then
		blur = Instance.new("BlurEffect")
		blur.Name = "RealisticBlur"
		blur.Size = 0
		blur.Parent = Lighting
	end
	return blur
end

local blur = ensureRealisticBlur()

-- Monitor para recrear blur si se borra
Lighting.ChildRemoved:Connect(function(child)
	if child.Name == "RealisticBlur" then
		task.wait(0.1)
		blur = ensureRealisticBlur()
	end
end)

-- ===== SUAVIZADO DEL BLUR =====
local currentBlur = 0
local blurTarget = 0

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

-- ===== BLUR DINÁMICO =====
local lastLookVector = camera.CFrame.LookVector
local blurDecaySpeed = 2
local blurIncreaseSpeed = 8
local blurThreshold = 0.22

RunService.RenderStepped:Connect(function(dt)
	local currentLookVector = camera.CFrame.LookVector
	local rotationChange = (currentLookVector - lastLookVector).Magnitude
	lastLookVector = currentLookVector

	local intensity = 0
	if rotationChange > blurThreshold then
		intensity = math.clamp((rotationChange - blurThreshold) * 1200, 0, 1)
	end

	if intensity > currentBlur then
		currentBlur += (intensity - currentBlur) * dt * blurIncreaseSpeed
	else
		currentBlur -= currentBlur * dt * blurDecaySpeed
	end

	blur.Size = math.clamp(currentBlur * 20, 0, 15)
end)

-- ===== BLUR POR DAÑO =====
local lastHealth = humanoid.Health
humanoid.HealthChanged:Connect(function(hp)
	if hp < lastHealth then
		task.spawn(function()
			local peak = 10
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

-- ===== BLUR SUAVIZADO INICIAL =====
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

print("🌇 Iluminación realista + blur dinámico aplicado correctamente.")