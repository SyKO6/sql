-- 🌅 ILUMINACIÓN REALISTA + EFECTOS VISUALES + BLUR DINÁMICO (VERSIÓN EXECUTOR)

-- Espera a que el juego esté completamente cargado
if not game:IsLoaded() then
    game.Loaded:Wait()
end
repeat task.wait() until workspace.CurrentCamera

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Limpieza del Lighting (sin borrar el Sky)
for _, child in ipairs(Lighting:GetChildren()) do
	if not child:IsA("Sky") then
		pcall(function() child:Destroy() end)
	end
end

-- Ajustes base
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

-- Crea los efectos visuales locales
local atmosphere = Instance.new("Atmosphere", Lighting)
atmosphere.Name = "RealisticAtmosphere"
atmosphere.Density = 0.48
atmosphere.Decay = Color3.fromRGB(185, 185, 185)
atmosphere.Glare = 0.8
atmosphere.Haze = 0.2

local cc = Instance.new("ColorCorrectionEffect", Lighting)
cc.Name = "RealisticColorCorrection"
cc.Brightness = -0.12
cc.Contrast = 0.45
cc.Saturation = 0.45
cc.TintColor = Color3.fromRGB(242, 255, 255)

local bloom = Instance.new("BloomEffect", Lighting)
bloom.Name = "RealisticBloom"
bloom.Intensity = 0.5
bloom.Size = 2000
bloom.Threshold = 1.0

local bloom2 = Instance.new("BloomEffect", Lighting)
bloom2.Name = "RealisticBloom2"
bloom2.Intensity = 0.2
bloom2.Size = 0.05
bloom2.Threshold = 5.0

local sunRays = Instance.new("SunRaysEffect", Lighting)
sunRays.Name = "RealisticSunRays"
sunRays.Intensity = 1.0
sunRays.Spread = 8.0

local sunLight = Instance.new("DirectionalLight", Lighting)
sunLight.Brightness = 5
sunLight.Color = Color3.fromRGB(255, 240, 200)
sunLight.Shadows = true
sunLight.ShadowSoftness = 1.0
sunLight.Orientation = Vector3.new(45, 45, 0)

local dof = Instance.new("DepthOfFieldEffect", Lighting)
dof.Name = "RealisticDepthOfField"
dof.FocusDistance = 60
dof.InFocusRadius = 20
dof.FarIntensity = 1.0
dof.NearIntensity = 1.0

-- 🔥 Blur principal
local blur = Instance.new("BlurEffect")
blur.Name = "RealisticBlur"
blur.Size = 0
blur.Parent = Lighting

-- Fade-in inicial (transición suave)
task.spawn(function()
	for i = 100, 0, -2 do
		blur.Size = i
		task.wait(0.06)
	end
end)

-- Skybox si no existe
if not Lighting:FindFirstChildOfClass("Sky") then
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

-- Variables principales
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid", 10)
local camera = workspace.CurrentCamera

-- Asegura que el efecto se vea (forzar render local)
task.wait(0.5)
blur.Enabled = true

local currentBlur = 0
local lastHealth = humanoid.Health

-- ===== BLUR POR MOVIMIENTO DE CÁMARA =====
local lastYaw, lastPitch, _ = camera.CFrame:ToOrientation()
local blurThreshold = 0.009 -- más sensible
local blurDecaySpeed = 2
local blurIncreaseSpeed = 8

RunService.RenderStepped:Connect(function(dt)
	local yaw, pitch, _ = camera.CFrame:ToOrientation()
	local rotationChange = math.abs(yaw - lastYaw) + math.abs(pitch - lastPitch)
	lastYaw, lastPitch = yaw, pitch

	local intensity = 0
	if rotationChange > blurThreshold then
		intensity = math.clamp((rotationChange - blurThreshold) * 4000, 0, 1)
	end

	if intensity > currentBlur then
		currentBlur += (intensity - currentBlur) * dt * blurIncreaseSpeed
	else
		currentBlur -= currentBlur * dt * blurDecaySpeed
	end

	blur.Size = math.clamp(currentBlur * 20, 0, 15)
end)

-- ===== BLUR POR DAÑO =====
humanoid.HealthChanged:Connect(function(hp)
	if hp < lastHealth then
		task.spawn(function()
			local peak = 10
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
	local lowHealthBlur = 0
	if percent < 0.25 then
		lowHealthBlur = math.clamp((0.25 - percent) * 60, 0, 10)
	end
	blur.Size = math.max(blur.Size, lowHealthBlur)
end)

print("✅ Iluminación + blur dinámico activado correctamente (modo executor)")