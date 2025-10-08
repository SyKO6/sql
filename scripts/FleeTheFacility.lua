-- 🌌 VISIÓN CLARA + AJUSTES DE CÁMARA Y MOVIMIENTO (COMPATIBLE CON INYECCIÓN DIRECTA)
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Limpieza ligera de efectos previos (por si reinyectas varias veces)
pcall(function()
	local old = Lighting:FindFirstChild("VisionNocturna")
	if old then old:Destroy() end
end)

-- ===== FUNCIÓN PRINCIPAL =====
local function aplicarEfectos()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	-- === CÁMARA ===
	camera.FieldOfView = 80
	camera.CameraType = Enum.CameraType.Custom
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMaxZoomDistance = 1000
	player.CameraMinZoomDistance = 0.5

	-- === MOVIMIENTO ===
	if humanoid then
		humanoid.WalkSpeed = 18.8
	end

	-- === ILUMINACIÓN ===
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.Brightness = 5
		Lighting.ClockTime = 0
		Lighting.Ambient = Color3.fromRGB(180, 220, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(180, 220, 255)
	end)

	-- === ATMÓSFERA ===
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

	-- === EFECTO DE VISIÓN NOCTURNA ===
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "VisionNocturna"
	cc.Brightness = 0.25
	cc.Contrast = 0.15
	cc.Saturation = 0.05
	cc.TintColor = Color3.fromRGB(200, 255, 200)
	cc.Parent = Lighting

	print("🌙 Efectos visuales aplicados exitosamente (inyección detectada).")
end

-- Ejecutar inmediatamente
task.spawn(aplicarEfectos)

-- Si el script es ejecutado más de una vez, se vuelve a aplicar sin errores
RunService.RenderStepped:Connect(function()
	if camera.FieldOfView ~= 80 then
		aplicarEfectos()
	end
end)