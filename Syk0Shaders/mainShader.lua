local PERMANENT_DELETE = false

local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local backupName = ("LightingBackup_%s"):format(HttpService:GenerateGUID(false):gsub("%-", ""):sub(1,8))
local backupFolder = Instance.new("Folder")
backupFolder.Name = backupName
backupFolder.Parent = ServerStorage

for _, child in ipairs(Lighting:GetChildren()) do
    if not child:IsA("Sky") then
        local ok, err = pcall(function()
            child.Parent = backupFolder
        end)
        if not ok then
            warn("No se pudo mover ", child, " a ServerStorage:", err)
        end
    end
end

if PERMANENT_DELETE then
    for _, item in ipairs(backupFolder:GetChildren()) do
        pcall(function() item:Destroy() end)
    end
    warn("Se han eliminado permanentemente los antiguos objetos de Lighting.")
else
    warn(("Backup de Lighting guardado en ServerStorage/%s — no eliminado permanentemente."):format(backupName))
end

local function safeSet(obj, propName, value)
    pcall(function()
        obj[propName] = value
    end)
end

pcall(function()
    Lighting.ClockTime = 14            -- hora del día (0-24)
    Lighting.Brightness = 2           -- brillo general
    Lighting.OutdoorAmbient = Color3.fromRGB(160, 170, 180) -- luz ambiente
    Lighting.FogStart = 0
    Lighting.FogEnd = 1000
    Lighting.FogColor = Color3.fromRGB(200, 210, 220)
    Lighting.GlobalShadows = true
end)

-- Crea Atmosphere
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "RealisticAtmosphere"
safeSet(atmosphere, "Density", 0.5)    -- intento: densidad
safeSet(atmosphere, "Offset", 0.0)
safeSet(atmosphere, "Color", Color3.fromRGB(155, 180, 200))
atmosphere.Parent = Lighting

-- Crea ColorCorrectionEffect
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "RealisticColorCorrection"
safeSet(cc, "Brightness", 0.05)
safeSet(cc, "Contrast", 0.06)
safeSet(cc, "Saturation", -0.02)
safeSet(cc, "TintColor", Color3.fromRGB(255, 250, 240))
cc.Parent = Lighting

-- Crea BloomEffect
local bloom = Instance.new("BloomEffect")
bloom.Name = "RealisticBloom"
safeSet(bloom, "Intensity", 1.0)
safeSet(bloom, "Size", 24)
safeSet(bloom, "Threshold", 0.8)
bloom.Parent = Lighting

-- Crea SunRaysEffect
local sunRays = Instance.new("SunRaysEffect")
sunRays.Name = "RealisticSunRays"
safeSet(sunRays, "Intensity", 0.6)
safeSet(sunRays, "Spread", 0.2)
sunRays.Parent = Lighting

-- Crea DepthOfFieldEffect (suaviza el fondo, útil para cámaras cinemáticas)
local dof = Instance.new("DepthOfFieldEffect")
dof.Name = "RealisticDepthOfField"
safeSet(dof, "FocusDistance", 60)
safeSet(dof, "InFocusRadius", 20)
safeSet(dof, "FarIntensity", 0.6)
safeSet(dof, "NearIntensity", 0.0)
dof.Parent = Lighting

-- Opcional: crear un Sky nuevo si no existe (si existe, se preservó)
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
    -- Si quieres, puedes asignar las URLs de skyboxes aquí:
    -- sky.SkyboxBk = "rbxassetid://<id>"
    -- sky.SkyboxDn = ...
    -- Pero dejar en blanco utiliza el sky por defecto de Roblox
    sky.Parent = Lighting
end

-- Agrupar los assets creados en una carpeta para organización
local assetsFolder = Instance.new("Folder")
assetsFolder.Name = "RealisticLightingAssets"
assetsFolder.Parent = Lighting
for _, obj in ipairs(Lighting:GetChildren()) do
    if obj.Name:match("^Realistic") or obj == dof or obj:IsA("Sky") and obj.Name == "RealisticSky" then
        -- si es uno de los objetos que acabamos de crear, muévelo a la carpeta (salvo Sky existente)
        if obj ~= assetsFolder then
            pcall(function() obj.Parent = assetsFolder end)
        end
    end
end

print("Configuración de iluminación realista aplicada. Backup en ServerStorage/" .. backupName .. (PERMANENT_DELETE and " (eliminado permanentemente)" or " (preservado)"))