-- 🌅 ILUMINACIÓN REALISTA + EFECTOS VISUALES + RASTRO DEL PERSONAJE

-- ===== SERVICIOS =====
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- ===== LIMPIEZA DE LIGHTING =====
for _, child in ipairs(Lighting:GetChildren()) do
	if not child:IsA("Sky") then
		pcall(function() child:Destroy() end)
	end
end

-- ===== AJUSTES BASE =====
pcall(function()
	Lighting.ClockTime = 14
	Lighting.Brightness = 1.2
	Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
	Lighting.FogStart = 0
	Lighting.FogEnd = 1500
	Lighting.FogColor = Color3.fromRGB(240, 240, 255)
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
atmosphere.Color = Color3.fromRGB(155, 180, 200)
atmosphere.Decay = Color3.fromRGB(120, 130, 150)
atmosphere.Glare = 0.3
atmosphere.Haze = 1.5
atmosphere.Parent = Lighting

-- ===== COLOR CORRECTION =====
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "RealisticColorCorrection"
cc.Brightness = 0.06
cc.Contrast = 0.2
cc.Saturation = 0.5
cc.TintColor = Color3.fromRGB(246, 246, 255)
cc.Parent = Lighting

-- ===== BLOOM =====
local bloom = Instance.new("BloomEffect")
bloom.Name = "RealisticBloom"
bloom.Intensity = 6.0
bloom.Size = 24
bloom.Threshold = 0.8
bloom.Parent = Lighting

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
dof.FarIntensity = 0.6
dof.NearIntensity = 0.0
dof.Parent = Lighting

-- ===== BLUR =====
local blur = Instance.new("BlurEffect")
blur.Name = "RealisticBlur"
blur.Size = 100
blur.Parent = Lighting

-- Suaviza el blur inicial
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

-- ===== BLUR DINÁMICO POR VIDA =====
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

humanoid.HealthChanged:Connect(function(hp)
	local max = humanoid.MaxHealth
	local percent = hp / max
	if percent < 0.15 then
		local intensity = math.clamp((0.15 - percent) * 100, 0, 15)
		blur.Size = intensity
	else
		blur.Size = 0
	end
end)

-- ===== RASTRO DEL PERSONAJE =====
character:WaitForChild("HumanoidRootPart")

local delayBetweenGhosts = 0.1
local ghostDuration = 0.5
local ghostTransparencyStep = 0.1
local ghostColor = Color3.fromRGB(255, 255, 255)

local function createGhost()
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local ghost = character:Clone()
	ghost.Name = "AfterImageGhost"

	for _, obj in ipairs(ghost:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") then
			obj:Destroy()
		elseif obj:IsA("BasePart") then
			obj.Anchored = true
			obj.CanCollide = false
			obj.Color = ghostColor
			obj.Material = Enum.Material.ForceField
			obj.Transparency = 0.4
		end
	end

	ghost.Parent = workspace

	task.spawn(function()
		for i = 1, 6 do
			for _, part in ipairs(ghost:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = part.Transparency + ghostTransparencyStep
				end
			end
			task.wait(ghostDuration / 6)
		end
		ghost:Destroy()
	end)
end

local lastPos = character.HumanoidRootPart.Position
RunService.RenderStepped:Connect(function()
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	local root = character.HumanoidRootPart
	local moved = (root.Position - lastPos).Magnitude > 0.2
	if moved then
		createGhost()
	end
	lastPos = root.Position
	task.wait(delayBetweenGhosts)
end)

print("🌄 Iluminación realista y efectos aplicados correctamente.")