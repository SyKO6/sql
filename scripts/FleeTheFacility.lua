-- 🌙 VISIÓN CLARA Y CONTROL AUTOMÁTICO DE ENTORNO (SEGURO)
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- === CONFIGURACIÓN INICIAL ===
local function aplicarEfectos()
	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid")

	-- === CÁMARA ===
	camera.FieldOfView = 80
	camera.CameraType = Enum.CameraType.Custom
	player.CameraMode = Enum.CameraMode.Classic
	player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
	player.CameraMaxZoomDistance = 1000
	player.CameraMinZoomDistance = 0.5

	-- === MOVIMIENTO BASE ===
	humanoid.WalkSpeed = 18.8

	-- === ILUMINACIÓN BASE ===
	pcall(function()
		Lighting.Brightness = 5
		Lighting.ClockTime = 0
		Lighting.Ambient = Color3.fromRGB(210, 220, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(210, 220, 255)
	end)

	-- === ATMÓSFERA LIMPIA ===
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0
	atmosphere.Haze = 0
	atmosphere.Glare = 0
	atmosphere.Color = Color3.fromRGB(255, 255, 255)
	atmosphere.Decay = Color3.fromRGB(255, 255, 255)

	-- === VISIÓN CLARA SIN TINTE VERDE ===
	local cc = Lighting:FindFirstChild("VisionClara")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "VisionClara"
		cc.Brightness = 0.4
		cc.Contrast = 0.1
		cc.Saturation = 0.05
		cc.TintColor = Color3.fromRGB(255, 255, 255)
		cc.Parent = Lighting
	else
		cc.Brightness = 0.4
		cc.Contrast = 0.1
		cc.Saturation = 0.05
		cc.TintColor = Color3.fromRGB(255, 255, 255)
	end
end

-- === MONITOREO PERMANENTE ===
task.spawn(function()
	while true do
		task.wait(0.5)
		pcall(function()
			if Lighting.GlobalShadows == true then
				Lighting.GlobalShadows = false
			end
			local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
			if atmosphere and atmosphere.Density ~= 0 then
				atmosphere.Density = 0
			end
		end)
	end
end)

-- === CONTROL DE VELOCIDAD SEGÚN ESTADO ===
task.spawn(function()
	while true do
		task.wait(0.25)
		local char = player.Character
		if char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local statsModule = player:FindFirstChild("TempPlayerStatsModule")
				if statsModule then
					local isCrawling = statsModule:FindFirstChild("isCrawling")
					local isBeast = statsModule:FindFirstChild("isBeast")

					if isBeast and isBeast.Value == true then
						-- No modificar velocidad si es Beast
						continue
					end

					if (not isCrawling) or (isCrawling.Value == false) then
						if humanoid.WalkSpeed ~= 18.8 then
							humanoid.WalkSpeed = 18.8
						end
					end
				else
					if humanoid.WalkSpeed ~= 18.8 then
						humanoid.WalkSpeed = 18.8
					end
				end
			end
		end
	end
end)

-- === EJECUCIÓN INICIAL ===
task.spawn(aplicarEfectos)

print("✅ Efectos aplicados correctamente y monitoreo activo.")