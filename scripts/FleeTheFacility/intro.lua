-- ===== INTRO SCRIPT COMPLETO CON FADE-OUT FINAL =====
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Crear ScreenGui
local introGui = Instance.new("ScreenGui", playerGui)
introGui.Name = "IntroGUI"

-- Fondo semi-opaco con blur
local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 0

local overlay = Instance.new("Frame", introGui)
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.2

-- Imagen redonda con sombra
local image = Instance.new("ImageLabel", overlay)
image.Size = UDim2.new(0, 200, 0, 200)
image.Position = UDim2.new(0.5, -100, 0.5, -100)
image.BackgroundTransparency = 1
image.Image = "rbxassetid://124099167963073"
image.ScaleType = Enum.ScaleType.Fit
image.ClipsDescendants = true

local uicorner = Instance.new("UICorner", image)
uicorner.CornerRadius = UDim.new(1, 0)

local shadow = Instance.new("ImageLabel", image)
shadow.Size = UDim2.new(1.2, 0, 1.2, 0)
shadow.Position = UDim2.new(-0.1, 0, -0.1, 0)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://131604521"
shadow.ZIndex = -1

-- Texto "Syk0 Script"
local label = Instance.new("TextLabel", overlay)
label.Size = UDim2.new(1, 0, 0, 50)
label.Position = UDim2.new(0, 0, 0.7, 0)
label.Text = "Syk0 Script"
label.Font = Enum.Font.SourceSansBold
label.TextSize = 36
label.TextColor3 = Color3.new(1, 1, 1)
label.TextStrokeTransparency = 0.5
label.BackgroundTransparency = 1

-- Animación de cambio de color
spawn(function()
	while true do
		for i = 0, 1, 0.01 do
			label.TextColor3 = Color3.fromRGB(255, math.floor(255 - (25 * i)), math.floor(255 - (25 * i)))
			wait(0.03)
		end
		for i = 1, 0, -0.01 do
			label.TextColor3 = Color3.fromRGB(255, math.floor(255 - (25 * i)), math.floor(255 - (25 * i)))
			wait(0.03)
		end
	end
end)

-- Subida de imagen
local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tween = TweenService:Create(image, tweenInfo, {Position = UDim2.new(0.5, -100, 0.4, -100)})
tween:Play()

-- Subir blur
TweenService:Create(blur, TweenInfo.new(2), {Size = 80}):Play()
wait(2.5)

-- Fade-out overlay inicial
local fadeTween = TweenService:Create(overlay, TweenInfo.new(1.5), {BackgroundTransparency = 1})
fadeTween:Play()
wait(1.5)
overlay:Destroy()

-- Mostrar título final con efecto typing
local finalGui = Instance.new("ScreenGui", playerGui)
finalGui.Name = "FinalIntro"

local title = Instance.new("TextLabel", finalGui)
title.Size = UDim2.new(1, 0, 0.2, 0)
title.Position = UDim2.new(0, 0, 0.3, 0)
title.Text = "— Syk0 —"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 48
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1

local desc = Instance.new("TextLabel", finalGui)
desc.Size = UDim2.new(1, 0, 0.3, 0)
desc.Position = UDim2.new(0, 0, 0.5, 0)
desc.Text = ""
desc.Font = Enum.Font.SourceSans
desc.TextSize = 24
desc.TextColor3 = Color3.new(1, 1, 1)
desc.BackgroundTransparency = 1
desc.TextWrapped = true
desc.TextYAlignment = Enum.TextYAlignment.Top

local descriptionText = "Script creada por mí. Modificación permitida.\nEste script mejora la experiencia visual.\nColores del ESP:\n- Verde: Amigo\n- Rojo: Enemigo\n- Azul: Neutro"

spawn(function()
	for i = 1, #descriptionText do
		desc.Text = string.sub(descriptionText, 1, i)
		wait(0.03)
	end
end)

-- Esperar lectura
wait(3) -- Tiempo que el texto final permanece visible

-- ===== FADE-OUT FINAL =====
local fadeFinal = TweenService:Create(finalGui, TweenInfo.new(1.5), {BackgroundTransparency = 1})
fadeFinal:Play()

-- Desvanecer título y descripción
for _, obj in pairs(finalGui:GetChildren()) do
	if obj:IsA("TextLabel") then
		TweenService:Create(obj, TweenInfo.new(1.5), {TextTransparency = 1}):Play()
	end
end

wait(1.5)
finalGui:Destroy()
blur:Destroy()