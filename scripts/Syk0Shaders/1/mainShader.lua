loadstring(game:HttpGet("https://raw.githubusercontent.com/SyKO6/sql/refs/heads/main/scripts/intro.lua"))()

-- 🌅 ILUMINACIÓN REALISTA + EFECTOS VISUALES + BLUR DINÁMICO + SOMBRAS + REFLEJOS

-- ===== SERVICIOS =====
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- ===== LIMPIEZA DE LIGHTING =====
for _, child in ipairs(Lighting:GetChildren()) do
	if not child:IsA("Sky") then
		pcall(function() child:Destroy() end)
	end
end

-- ===== AJUSTES BASE =====
pcall(function()
	Lighting.ClockTime = 14 -- Hora del día para sol alto
	Lighting.Brightness = 5
	Lighting.Ambient = Color3.fromRGB(0, 0, 0)
	Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
	Lighting.FogStart = 0
	Lighting.FogEnd = 2800
	Lighting.FogColor = Color3.fromRGB(0, 0, 0)
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 1.5
	Lighting.EnvironmentSpecularScale = 1.5
	Lighting.Technology = Enum.Technology.Future
end)

-- ===== REALISTIC BLUR =====
local blur = Instance.new("BlurEffect")
blur.Name = "RealisticBlur"
blur.Size = 0
blur.Parent = Lighting

local blur2 = Instance.new("BlurEffect")
blur2.Name = "RealisticBlur2"
blur2.Size = 2
blur2.Parent = Lighting

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

blur = ensureRealisticBlur()

Lighting.ChildRemoved:Connect(function(child)
	if child.Name == "RealisticBlur" then
		task.wait(0.1)
		blur = ensureRealisticBlur()
	end
end)

-- ===== BLUR DINÁMICO =====
local currentBlur = 0
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

-- ===== REFLEJOS Y SOMBRAS AUTOMÁTICOS =====
for _, obj in pairs(workspace:GetDescendants()) do
	if obj:IsA("BasePart") then
		if obj.Reflectance == 0 then
			obj.Reflectance = 0.2
		end
		obj.CastShadow = true
	end
end

-- ===== AJUSTE DINÁMICO DEL SOL =====
RunService.RenderStepped:Connect(function()
	Lighting.ClockTime = 14 -- ajustar hora del día
	if Lighting:FindFirstChild("RealisticSky") then
		Lighting.RealisticSky.SunAngularSize = 12
	end
end)

-- ===== REFLEJO TIPO METAL (USANDO SMOOTHPLASTIC) =====

-- ✨ Reflejo suave metálico sin quemar los colores ni perder textura
local function applySmoothMetal(obj)
	if not obj:IsA("BasePart") then return end

	local originalColor = obj.Color

	-- Cambiar material a SmoothPlastic (para reflejos limpios)
	obj.Material = Enum.Material.SmoothPlastic

	-- Ajustar reflectancia y color original
	obj.Reflectance = 0.25
	obj.Color = originalColor
	obj.CastShadow = true

	-- Si tiene SurfaceAppearance o Textura, conservarla sin alterarla
	local sa = obj:FindFirstChildOfClass("SurfaceAppearance")
	if sa then
		sa.Metalness = 0.4
		sa.Roughness = 0.2
		sa.Specular = Color3.fromRGB(255, 255, 255)
	end
end

-- 🌍 Aplicar a todo el mundo existente
for _, v in ipairs(workspace:GetDescendants()) do
	applySmoothMetal(v)
end

-- 🔁 Aplicar automáticamente a nuevos objetos
workspace.DescendantAdded:Connect(function(obj)
	task.wait(0.05)
	applySmoothMetal(obj)
end)

-- 🧍 Aplicar a los personajes
local function applyToCharacter(character)
	for _, obj in ipairs(character:GetDescendants()) do
		applySmoothMetal(obj)
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr.Character then applyToCharacter(plr.Character) end
	plr.CharacterAdded:Connect(applyToCharacter)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(applyToCharacter)
end)

-- 💡 Ajustes globales de iluminación para reflejo más natural
Lighting.EnvironmentSpecularScale = 4.5
Lighting.EnvironmentDiffuseScale  = 3.0

print("🌇 Iluminación realista con rayos, sombras y reflejos aplicada correctamente.")