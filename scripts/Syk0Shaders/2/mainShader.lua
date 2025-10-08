-- 🌅 ILUMINACIÓN ULTRA REALISTA + SOMBRAS + REFLEJOS + BRILLO

-- ===== SERVICIOS =====
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ===== LIMPIEZA DE LIGHTING =====
for _, child in ipairs(Lighting:GetChildren()) do
	if not child:IsA("Sky") then
		pcall(function() child:Destroy() end)
	end
end

-- ===== AJUSTES BASE =====
Lighting.ClockTime = 14.2
Lighting.Brightness = 6.5
Lighting.Ambient = Color3.fromRGB(45, 45, 45)
Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 1.0
Lighting.EnvironmentSpecularScale = 1.5
Lighting.Technology = Enum.Technology.Future

-- ===== CIELO =====
local sky = Instance.new("Sky")
sky.SkyboxBk = "rbxassetid://7018684000"
sky.SkyboxDn = "rbxassetid://7018684000"
sky.SkyboxFt = "rbxassetid://7018684000"
sky.SkyboxLf = "rbxassetid://7018684000"
sky.SkyboxRt = "rbxassetid://7018684000"
sky.SkyboxUp = "rbxassetid://7018684000"
sky.SunAngularSize = 12
sky.MoonAngularSize = 11
sky.Parent = Lighting

-- ===== ATMOSFERA REALISTA =====
local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.4
atmosphere.Offset = 0.02
atmosphere.Color = Color3.fromRGB(255, 255, 255)
atmosphere.Decay = Color3.fromRGB(255, 255, 255)
atmosphere.Glare = 0.25
atmosphere.Haze = 1
atmosphere.Parent = Lighting

-- ===== COLOR CORRECTION =====
local cc = Instance.new("ColorCorrectionEffect")
cc.Brightness = 0.02
cc.Contrast = 0.5
cc.Saturation = 0.45
cc.TintColor = Color3.fromRGB(255, 245, 235)
cc.Parent = Lighting

-- ===== BLOOM =====
local bloom = Instance.new("BloomEffect")
bloom.Intensity = 2.6
bloom.Size = 60
bloom.Threshold = 1.1
bloom.Parent = Lighting

-- ===== SUNRAYS =====
local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.4
sunRays.Spread = 0.8
sunRays.Parent = Lighting

-- ===== DEPTH OF FIELD =====
local dof = Instance.new("DepthOfFieldEffect")
dof.FocusDistance = 50
dof.InFocusRadius = 25
dof.FarIntensity = 0.4
dof.NearIntensity = 0.8
dof.Parent = Lighting

-- ===== BLUR SUAVE =====
local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = Lighting

-- ===== LUZ SOLAR REALISTA =====
local sun = Instance.new("SunRaysEffect")
sun.Intensity = 0.5
sun.Spread = 1
sun.Parent = Lighting

-- ===== ILUMINACIÓN ADICIONAL =====
local sunLight = Instance.new("DirectionalLight")
sunLight.Brightness = 5
sunLight.Color = Color3.fromRGB(255, 240, 200)
sunLight.Shadows = true
sunLight.ShadowSoftness = 0.25
sunLight.Orientation = Vector3.new(45, 45, 0)
sunLight.Parent = Lighting

-- ===== REFLEJOS DE LUZ EN OBJETOS =====
task.spawn(function()
	while task.wait(1) do
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") then
				-- Materiales más reflectivos
				if obj.Material ~= Enum.Material.Glass and obj.Material ~= Enum.Material.Neon then
					obj.Reflectance = math.clamp((obj.Reflectance or 0) + 0.15, 0, 0.25)
				end
				obj.CastShadow = true
			end
		end
	end
end)

-- ===== LUZ DE REFLEXIÓN EN PERSONAJES =====
local player = Players.LocalPlayer
player.CharacterAdded:Connect(function(char)
	task.wait(1)
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Reflectance = 0.1
			part.Material = Enum.Material.SmoothPlastic
		end
	end
end)

-- ===== BLUR DINÁMICO (MISMO SISTEMA ORIGINAL) =====
local camera = workspace.CurrentCamera
local lastLookVector = camera.CFrame.LookVector
local currentBlur = 0
local blurThreshold = 0.34
local blurDecaySpeed = 2
local blurIncreaseSpeed = 8

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

-- ===== BRILLO GLOBAL SUAVE (LENTE) =====
local glare = Instance.new("BloomEffect")
glare.Name = "LensGlow"
glare.Intensity = 1.4
glare.Size = 120
glare.Threshold = 0.9
glare.Parent = Lighting

print("☀️ Iluminación ultra realista con reflejos, sombras suaves y materiales reactivos aplicada.")