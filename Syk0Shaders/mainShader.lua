-- ⚡ Script de iluminación + efecto "motion ghost" al mover la cámara
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera
local player = Players.LocalPlayer or Players:GetPlayers()[1]

-- LIMPIEZA DE ILUMINACIÓN
for _, child in ipairs(Lighting:GetChildren()) do
	if not child:IsA("Sky") then
		pcall(function()
			child:Destroy()
		end)
	end
end

-- EFECTOS BASE
Lighting.ClockTime = 14
Lighting.Brightness = 2
Lighting.OutdoorAmbient = Color3.fromRGB(160, 170, 180)
Lighting.FogStart = 0
Lighting.FogEnd = 1000
Lighting.FogColor = Color3.fromRGB(200, 210, 220)
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 1.5
Lighting.EnvironmentSpecularScale = 1.5

local atmosphere = Instance.new("Atmosphere")
atmosphere.Density = 0.45
atmosphere.Color = Color3.fromRGB(155, 180, 200)
atmosphere.Decay = Color3.fromRGB(80, 85, 100)
atmosphere.Parent = Lighting

local cc = Instance.new("ColorCorrectionEffect")
cc.Contrast = 0.4
cc.Saturation = 0.6
cc.Brightness = 0.25
cc.TintColor = Color3.fromRGB(255, 240, 230)
cc.Parent = Lighting

local bloom = Instance.new("BloomEffect")
bloom.Intensity = 8
bloom.Size = 40
bloom.Threshold = 0.8
bloom.Parent = Lighting

local sunRays = Instance.new("SunRaysEffect")
sunRays.Intensity = 0.6
sunRays.Spread = 0.25
sunRays.Parent = Lighting

local dof = Instance.new("DepthOfFieldEffect")
dof.FocusDistance = 60
dof.InFocusRadius = 20
dof.FarIntensity = 0.6
dof.Parent = Lighting

-- UI para simular efecto de frame repeat
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MotionGhostEffect"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 999999
screenGui.Parent = player:WaitForChild("PlayerGui")

local ghostFrame = Instance.new("ImageLabel")
ghostFrame.BackgroundTransparency = 1
ghostFrame.Size = UDim2.new(1, 0, 1, 0)
ghostFrame.ImageTransparency = 1
ghostFrame.ZIndex = 0
ghostFrame.Parent = screenGui

-- Captura dinámica del frame
local lastCFrame = camera.CFrame
local lastUpdate = 0
local fadeSpeed = 0.1
local transparency = 1

RunService.RenderStepped:Connect(function(dt)
	local movement = (camera.CFrame.Position - lastCFrame.Position).Magnitude
	if movement > 1 then
		-- Tomar un snapshot del frame actual
		local colorFrame = Instance.new("ImageLabel")
		colorFrame.Size = UDim2.new(1, 0, 1, 0)
		colorFrame.BackgroundColor3 = Color3.new(1, 1, 1)
		colorFrame.BackgroundTransparency = 0.95
		colorFrame.BorderSizePixel = 0
		colorFrame.ZIndex = 1
		colorFrame.Parent = screenGui
		
		-- Efecto de “fade out” de los rastros
		task.spawn(function(f)
			for i = 1, 10 do
				f.BackgroundTransparency = f.BackgroundTransparency + 0.05
				task.wait(0.03)
			end
			f:Destroy()
		end, colorFrame)
	end
	
	lastCFrame = camera.CFrame
end)

-- EFECTO INICIAL (desvanecido de entrada)
task.spawn(function()
	local black = Instance.new("Frame")
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.Size = UDim2.new(1, 0, 1, 0)
	black.BackgroundTransparency = 1
	black.Parent = screenGui
	for i = 1, 30 do
		black.BackgroundTransparency = 1 - (i / 30)
		task.wait(0.03)
	end
	for i = 1, 60 do
		black.BackgroundTransparency = i / 60
		task.wait(0.03)
	end
	black:Destroy()
end)

-- EFECTO DE VIDA BAJA
task.spawn(function()
	while task.wait(0.1) do
		local humanoid = player and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local hp = humanoid.Health / humanoid.MaxHealth
			if hp < 0.15 then
				local shade = Instance.new("Frame")
				shade.BackgroundColor3 = Color3.new(1, 0, 0)
				shade.Size = UDim2.new(1, 0, 1, 0)
				shade.BackgroundTransparency = 0.9 + hp * 0.5
				shade.ZIndex = 2
				shade.Parent = screenGui
				task.spawn(function(s)
					for i = 1, 15 do
						s.BackgroundTransparency = s.BackgroundTransparency + 0.05
						task.wait(0.03)
					end
					s:Destroy()
				end, shade)
			end
		end
	end
end)

print("Iluminación realista + efecto motion ghost activado.")