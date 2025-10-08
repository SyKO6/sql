-- 🌌 VISIÓN CLARA + AJUSTES DE CÁMARA Y MOVIMIENTO
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Esperar a que el personaje cargue
player.CharacterAdded:Connect(function(char)
	local humanoid = char:WaitForChild("Humanoid")

	-- ===== AJUSTES DE CÁMARA =====
	camera.FieldOfView = 80
	camera.CameraType = Enum.CameraType.Custom
	player.CameraMode = Enum.CameraMode.Classic -- “Inviscam”, modo libre sin zoom
	player.CameraMaxZoomDistance = 1000
	player.CameraMinZoomDistance = 0.5

	-- ===== AJUSTES DE MOVIMIENTO =====
	humanoid.WalkSpeed = 18.8

	-- ===== AJUSTES DE ILUMINACIÓN =====
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.Brightness = 5
		Lighting.ClockTime = 0  -- noche simulada
		Lighting.Ambient = Color3.fromRGB(180, 220, 255)
		Lighting.OutdoorAmbient = Color3.fromRGB(180, 220, 255)
	end)

	-- ===== ATMÓSFERA (ELIMINAR NEBLINA Y DENSIDAD) =====
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density = 0
		atmosphere.Haze = 0
		atmosphere.Glare = 0
	else
		-- Si no hay atmósfera, crear una limpia
		local newAtmo = Instance.new("Atmosphere")
		newAtmo.Density = 0
		newAtmo.Haze = 0
		newAtmo.Glare = 0
		newAtmo.Color = Color3.fromRGB(255, 255, 255)
		newAtmo.Decay = Color3.fromRGB(255, 255, 255)
		newAtmo.Parent = Lighting
	end

	-- ===== EFECTO DE VISIÓN NOCTURNA SUAVE =====
	local cc = Lighting:FindFirstChild("VisionNocturna")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "VisionNocturna"
		cc.Brightness = 0.25  -- un poco más claro
		cc.Contrast = 0.15
		cc.Saturation = 0.05
		cc.TintColor = Color3.fromRGB(200, 255, 200) -- tono verdoso suave
		cc.Parent = Lighting
	end

	print("🌙 Vision clara aplicada al jugador con éxito.")
end)