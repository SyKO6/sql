local Lighting = game:GetService("Lighting")

-- LIMPIEZA
for _, child in ipairs(Lighting:GetChildren()) do
	if not child:IsA("Sky") then
		pcall(function()
			child:Destroy()
		end)
	end
end

-- AJUSTES BASE
pcall(function()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2
	Lighting.OutdoorAmbient = Color3.fromRGB(160, 170, 180)
	Lighting.FogStart = 0
	Lighting.FogEnd = 1000
	Lighting.FogColor = Color3.fromRGB(200, 210, 220)
	Lighting.GlobalShadows = true
end)

-- ATMOSPHERE
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "RealisticAtmosphere"
atmosphere.Density = 0.45
atmosphere.Offset = 0.0
atmosphere.Color = Color3.fromRGB(155, 180, 200)
atmosphere.Parent = Lighting

-- COLOR CORRECTION
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "RealisticColorCorrection"
cc.Brightness = 0.2
cc.Contrast = 0.3
cc.Saturation = 0.3
cc.TintColor = Color3.fromRGB(255, 250, 240)
cc.Parent = Lighting

-- BLOOM
local bloom = Instance.new("BloomEffect")
bloom.Name = "RealisticBloom"
bloom.Intensity = 10.0
bloom.Size = 24
bloom.Threshold = 0.8
bloom.Parent = Lighting

-- SUNRAYS
local sunRays = Instance.new("SunRaysEffect")
sunRays.Name = "RealisticSunRays"
sunRays.Intensity = 0.6
sunRays.Spread = 0.2
sunRays.Parent = Lighting

-- DEPTH OF FIELD
local dof = Instance.new("DepthOfFieldEffect")
dof.Name = "RealisticDepthOfField"
dof.FocusDistance = 60
dof.InFocusRadius = 20
dof.FarIntensity = 0.6
dof.NearIntensity = 0.0
dof.Parent = Lighting

-- BLUR
local blur = Instance.new("BlurEffect")
blur.Name = "RealisticBlur"
blur.Size = 4
blur.Parent = Lighting

-- SKY (si no hay uno existente)
local hasSky = false8
for _, c in ipairs(Lighting:GetChildren()) do
	if c:IsA("Sky") then
		hasSky = true
		break
	end
end

if not hasSky then
	local sky = Instance.new("Sky")
	sky.Name = "RealisticSky"
	sky.Parent = Lighting
end

print("Iluminación realista aplicada con reemplazo completo.")