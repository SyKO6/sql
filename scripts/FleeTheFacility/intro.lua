-- ===== INTRO SCRIPT COMPLETO AJUSTADO =====
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Crear ScreenGui
local introGui = Instance.new("ScreenGui", playerGui)
introGui.Name = "IntroGUI"

-- Blur
local blur = Instance.new("BlurEffect", Lighting)
blur.Size = 0

-- ColorCorrection para "opacidad"
local colorCorrection = Instance.new("ColorCorrectionEffect", Lighting)
colorCorrection.Brightness = -0.8 -- Baja brillo 50%
colorCorrection.Contrast = 0
colorCorrection.Saturation = 0

-- Imagen redonda con sombra
local image = Instance.new("ImageLabel", introGui)
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
shadow.Image = "rbxassetid://124099167963073"
shadow.ZIndex = -1

-- Texto "Syk0 Script"
local label = Instance.new("TextLabel", introGui)
label.Size = UDim2.new(1, 0, 0, 50)
label.Position = UDim2.new(0, 0, 0.7, 0)
label.Text = "Syk0 Script"
label.Font = Enum.Font.SourceSansBold
label.TextSize = 36
label.TextColor3 = Color3.new(1, 1, 1)
label.TextStrokeTransparency = 0.5
label.BackgroundTransparency = 1

-- Animación cambio de color
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

-- Subir blur y brillo
TweenService:Create(blur, TweenInfo.new(2), {Size = 80}):Play()
TweenService:Create(colorCorrection, TweenInfo.new(2), {Brightness = 0}):Play()
wait(2.5)

-- Desaparece imagen y texto inicial
TweenService:Create(image, TweenInfo.new(1.5), {ImageTransparency = 1}):Play()
TweenService:Create(label, TweenInfo.new(1.5), {TextTransparency = 1}):Play()
wait(1.5)

-- Texto final
local finalGui = Instance.new("ScreenGui", playerGui)
finalGui.Name = "FinalIntro"

local title = Instance.new("TextLabel", finalGui)
title.Size = UDim2.new(1, 0, 0.2, 0)
title.Position = UDim2.new(0, 0, 0.35, 0) -- centrado verticalmente
title.Text = "— Syk0 —"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 48
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.TextStrokeTransparency = 0.5
title.TextScaled = true

local desc = Instance.new("TextLabel", finalGui)
desc.Size = UDim2.new(0.8, 0, 0.3, 0)
desc.Position = UDim2.new(0.1, 0, 0.55, 0)
desc.Text = ""
desc.Font = Enum.Font.SourceSans
desc.TextSize = 24
desc.TextColor3 = Color3.new(1, 1, 1)
desc.BackgroundTransparency = 1
desc.TextWrapped = true
desc.TextYAlignment = Enum.TextYAlignment.Top

local descriptionText = "Script creada por mí, modificación permitida."

spawn(function()
	for i = 1, #descriptionText do
		desc.Text = string.sub(descriptionText, 1, i)
		wait(0.03)
	end
end)

-- Esperar lectura
wait(3)

-- ===== FADE-OUT FINAL =====
local fadeFinal = TweenService:Create(title, TweenInfo.new(1.5), {TextTransparency = 1})
fadeFinal:Play()
TweenService:Create(desc, TweenInfo.new(1.5), {TextTransparency = 1}):Play()
TweenService:Create(blur, TweenInfo.new(1.5), {Size = 0}):Play()
TweenService:Create(colorCorrection, TweenInfo.new(1.5), {Brightness = -0.5}):Play()

wait(1.5)
finalGui:Destroy()
blur:Destroy()
colorCorrection:Destroy()