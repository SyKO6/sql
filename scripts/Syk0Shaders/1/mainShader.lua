-- ===== ILUMINACIÓN REALISTA + BLUR DINÁMICO =====
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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

-- ===== CREAR O ASEGURAR RealisticBlur =====
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

-- Asegurar que siempre exista
Lighting.ChildRemoved:Connect(function(child)
	if child.Name == "RealisticBlur" then
		task.wait(0.1)
		blur = ensureRealisticBlur()
	end
end)

-- ===== BLUR DINÁMICO =====
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

print("🌇 Iluminación + Blur dinámico cargado correctamente.")