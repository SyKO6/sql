loadstring(game:HttpGet("https://raw.githubusercontent.com/SyKO6/sql/refs/heads/main/scripts/intro.lua"))()

-- 🌅 ILUMINACIÓN REALISTA + BLUR DINÁMICO + RTX + GOD RAYS + REFLEJO PBR DINÁMICO

-- ===== SERVICIOS =====
local Lighting        = game:GetService("Lighting")
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")

local player    = Players.LocalPlayer
local camera    = workspace.CurrentCamera

local character = player.Character or player.CharacterAdded:Wait()
local humanoid  = character:WaitForChild("Humanoid")

-- ===== LIMPIEZA DE LIGHTING =====
for _, child in ipairs(Lighting:GetChildren()) do
    if not child:IsA("Sky") then
        pcall(function() child:Destroy() end)
    end
end

-- ===== AJUSTES BASE =====
Lighting.ClockTime              = 14
Lighting.Brightness             = 5
Lighting.Ambient                = Color3.fromRGB(0, 0, 0)
Lighting.OutdoorAmbient         = Color3.fromRGB(0, 0, 0)
Lighting.FogStart               = 0
Lighting.FogEnd                 = 2800
Lighting.FogColor               = Color3.fromRGB(0, 0, 0)
Lighting.GlobalShadows          = true
Lighting.EnvironmentDiffuseScale= 2.0
Lighting.EnvironmentSpecularScale= 6.0
Lighting.Technology             = Enum.Technology.Future

-- ===== REALISTIC BLUR =====
local blur = Instance.new("BlurEffect")
blur.Name   = "RealisticBlur"
blur.Size   = 0
blur.Parent = Lighting

-- ===== ATMOSPHERE =====
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name    = "RealisticAtmosphere"
atmosphere.Density = 0.5
atmosphere.Offset  = 0.0
atmosphere.Color   = Color3.fromRGB(255, 255, 255)
atmosphere.Decay   = Color3.fromRGB(200, 200, 200)
atmosphere.Glare   = 0.0
atmosphere.Haze    = 0.0
atmosphere.Parent  = Lighting

-- ===== COLOR CORRECTION =====
local cc = Instance.new("ColorCorrectionEffect")
cc.Name       = "RealisticColorCorrection"
cc.Brightness = -0.15
cc.Contrast   = 0.5
cc.Saturation = 0.4
cc.TintColor  = Color3.fromRGB(242, 255, 255)
cc.Parent     = Lighting

-- ===== BLOOM =====
local bloom = Instance.new("BloomEffect")
bloom.Name      = "RealisticBloom"
bloom.Intensity = 0.26
bloom.Size      = 3000
bloom.Threshold = 1.0
bloom.Parent    = Lighting

local bloom2 = Instance.new("BloomEffect")
bloom2.Name      = "RealisticBloom2"
bloom2.Intensity = 0.001
bloom2.Size      = 0.01
bloom2.Threshold = 0.5
bloom2.Parent    = Lighting

-- ===== SUNRAYS =====
local sunRays = Instance.new("SunRaysEffect")
sunRays.Name      = "RealisticSunRays"
sunRays.Intensity = 0.2
sunRays.Spread    = 1.0
sunRays.Parent    = Lighting

-- ===== DEPTH OF FIELD =====
local dof = Instance.new("DepthOfFieldEffect")
dof.Name          = "RealisticDepthOfField"
dof.FocusDistance = 60
dof.InFocusRadius = 20
dof.FarIntensity  = 1.0
dof.NearIntensity = 1.0
dof.Parent        = Lighting

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
    sky.Name          = "RealisticSky"
    sky.SkyboxBk      = "rbxassetid://7018684000"
    sky.SkyboxDn      = "rbxassetid://7018684000"
    sky.SkyboxFt      = "rbxassetid://7018684000"
    sky.SkyboxLf      = "rbxassetid://7018684000"
    sky.SkyboxRt      = "rbxassetid://7018684000"
    sky.SkyboxUp      = "rbxassetid://7018684000"
    sky.SunAngularSize= 12
    sky.MoonAngularSize= 11
    sky.Parent        = Lighting
end

-- ===== BLUR DINÁMICO =====
local currentBlur     = 0
local lastLookVector  = camera.CFrame.LookVector
local blurDecaySpeed  = 2
local blurIncreaseSpeed= 8
local blurThreshold   = 0.22

local function ensureRealisticBlur()
    local b = Lighting:FindFirstChild("RealisticBlur")
    if not b then
        b = Instance.new("BlurEffect")
        b.Name   = "RealisticBlur"
        b.Size   = 0
        b.Parent = Lighting
    end
    return b
end

blur = ensureRealisticBlur()

Lighting.ChildRemoved:Connect(function(child)
    if child.Name == "RealisticBlur" then
        task.wait(0.1)
        blur = ensureRealisticBlur()
    end
end)

RunService.RenderStepped:Connect(function(dt)
    local currentLookVector = camera.CFrame.LookVector
    local rotChange = (currentLookVector - lastLookVector).Magnitude
    lastLookVector   = currentLookVector

    local intensity = 0
    if rotChange > blurThreshold then
        intensity = math.clamp((rotChange - blurThreshold) * 1200, 0, 1)
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
    local pct = hp / humanoid.MaxHealth
    if pct < 0.15 then
        local extra = math.clamp((0.15 - pct) * 100, 0, 15)
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

-- ===== REFLEJO PBR DINÁMICO TOTAL =====

-- ✨ Reflejo metálico sin perder color o textura original
local function applyMetalReflection(obj)
	if not obj:IsA("BasePart") then return end

	-- Mantener material original, pero mejorar reflejo global
	obj.Reflectance = 0.35
	obj.Material = obj.Material -- mantener material actual
	obj.CastShadow = true

	-- Ajustar color ligeramente hacia tonos fríos (reflejo metálico)
	local originalColor = obj.Color
	obj.Color = Color3.new(
		math.clamp(originalColor.R * 1.05, 0, 1),
		math.clamp(originalColor.G * 1.05, 0, 1),
		math.clamp(originalColor.B * 1.05, 0, 1)
	)

	-- Añadir SurfaceAppearance si no tiene
	local sa = obj:FindFirstChildOfClass("SurfaceAppearance")
	if not sa then
		sa = Instance.new("SurfaceAppearance")
		sa.Name = "MetalReflection"
		sa.Parent = obj
	end

	-- Parámetros PBR tipo metal pulido
	sa.Metalness = 0.85
	sa.Roughness = 0.08
	sa.Specular = Color3.fromRGB(255, 255, 255)
end

-- 🌌 Aplicar reflejo a todo el mapa
for _, v in ipairs(workspace:GetDescendants()) do
	applyMetalReflection(v)
end

-- 🌠 Mantener reflejo en nuevos objetos
workspace.DescendantAdded:Connect(function(obj)
	task.wait(0.05)
	applyMetalReflection(obj)
end)

-- 🧍 Aplicar reflejo metálico a los jugadores
local function applyToCharacter(character)
	for _, obj in ipairs(character:GetDescendants()) do
		applyMetalReflection(obj)
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr.Character then applyToCharacter(plr.Character) end
	plr.CharacterAdded:Connect(applyToCharacter)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(applyToCharacter)
end)

-- 🌞 Aumentar brillo ambiental para reflejar mejor la luz metálica
Lighting.EnvironmentSpecularScale = 8
Lighting.EnvironmentDiffuseScale  = 3.2
Lighting.Brightness = 6
Lighting.Ambient = Color3.fromRGB(50, 50, 50)
Lighting.OutdoorAmbient = Color3.fromRGB(60, 60, 60)

print("💫 Reflejo metálico PBR aplicado a todos los objetos sin perder textura ni color.")