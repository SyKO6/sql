loadstring(game:HttpGet("https://raw.githubusercontent.com/SyKO6/sql/refs/heads/main/scripts/intro.lua"))()  
  
-- SCRIPT OPTIMIZADO (mantiene la funcionalidad original)
-- Pegar en LocalScript del cliente

--// CONFIGURACIONES INICIALES
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = workspace

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Velocidades / FOV
local normalSpeed = 18.8
local crawlSpeed = 10.8
local beastSpeed = 18.8
local fov = 75

camera.FieldOfView = fov
player.CameraMode = Enum.CameraMode.Classic
player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
player.CameraMaxZoomDistance = 1000

-- Lighting: aplicar una vez y conectar señales si existen
Lighting.GlobalShadows = false
if Lighting:FindFirstChild("Atmosphere") then
    Lighting.Atmosphere.Density = 0
end
Lighting.Brightness = 1
Lighting.FogEnd = 100000
Lighting.ExposureCompensation = 0.5

-- Conectar señales para mantener valores (evita while true)
if Lighting:GetAttribute("ConnectedToFixes") ~= true then
    Lighting:SetAttribute("ConnectedToFixes", true)
    Lighting:GetPropertyChangedSignal("GlobalShadows"):Connect(function()
        if Lighting.GlobalShadows then Lighting.GlobalShadows = false end
    end)
    if Lighting:FindFirstChild("Atmosphere") then
        Lighting.Atmosphere:GetPropertyChangedSignal("Density"):Connect(function()
            if Lighting.Atmosphere.Density ~= 0 then Lighting.Atmosphere.Density = 0 end
        end)
    end
end

-- UTIL: conexiones y limpieza por character
local playerCleanup = {} -- player -> list of connections / objects to clean

local function addCleanup(p, obj)
    if not p then return end
    playerCleanup[p] = playerCleanup[p] or {}
    table.insert(playerCleanup[p], obj)
end

local function runCleanup(p)
    if not p then return end
    local list = playerCleanup[p]
    if list then
        for _, v in ipairs(list) do
            pcall(function()
                if typeof(v) == "RBXScriptConnection" then v:Disconnect()
                elseif typeof(v) == "Instance" and v.Destroy then v:Destroy()
                end
            end)
        end
    end
    playerCleanup[p] = nil
end

-- ===========
-- WALK SPEED (una conexión por character, bien limpiada)
-- ===========
local function enforceWalkSpeedForCharacter(char)
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local tempStats = player:FindFirstChild("TempPlayerStatsModule")
    if not tempStats then return end

    local isCrawling = tempStats:FindFirstChild("IsCrawling")
    local isBeast = tempStats:FindFirstChild("IsBeast")

    -- conexion heartbeat por personaje (guardada para limpieza)
    local hbConn
    hbConn = RunService.Heartbeat:Connect(function()
        if not humanoid or not humanoid.Parent then
            if hbConn then hbConn:Disconnect() end
            return
        end
        -- si no existen las flags, no tocar
        if not isCrawling or not isBeast then return end

        local crawling = isCrawling.Value
        local beast = isBeast.Value

        if not beast then
            humanoid.WalkSpeed = crawling and crawlSpeed or normalSpeed
        else
            -- lógica original: si walkspeed menor, espera 1s y luego asigna
            if humanoid.WalkSpeed < beastSpeed then
                -- delay seguro (no crear muchos delays simultáneos por personaje)
                task.delay(1, function()
                    if humanoid and humanoid.Parent and humanoid.WalkSpeed < beastSpeed then
                        humanoid.WalkSpeed = beastSpeed
                    end
                end)
            end
        end
    end)

    -- limpiar cuando muera o se elimine el personaje
    local ancConn
    ancConn = char.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if hbConn then hbConn:Disconnect() end
            if ancConn then ancConn:Disconnect() end
        end
    end)

    addCleanup(player, hbConn)
    addCleanup(player, ancConn)
end

-- Conectar para cada respawn
if player.Character then
    enforceWalkSpeedForCharacter(player.Character)
end
player.CharacterAdded:Connect(enforceWalkSpeedForCharacter)

-- ===========
-- ESP / TRACKERS (estructura: registrar ESPs y un solo RenderStepped global)
-- ===========
local activeESPs = {} -- targetPlayer -> {highlight, billboard, nameLabel, trackerPart, targetTorso}

local function destroyESPForTarget(target)
    local data = activeESPs[target]
    if not data then return end
    if data.highlight and data.highlight.Parent then pcall(function() data.highlight:Destroy() end) end
    if data.billboard and data.billboard.Parent then pcall(function() data.billboard:Destroy() end) end
    if data.trackerPart and data.trackerPart.Parent then pcall(function() data.trackerPart:Destroy() end) end
    activeESPs[target] = nil
end

local function createESP(target)
    if not target or target == player then return end
    if activeESPs[target] then return end

    local c = target.Character
    if not c or not c:FindFirstChild("Head") or not c:FindFirstChild("HumanoidRootPart") then
        -- esperar a que el character esté listo (pero no crear mil listeners)
        local conn
        conn = target.CharacterAdded:Connect(function()
            if conn then conn:Disconnect() end
            createESP(target)
        end)
        addCleanup(player, conn)
        return
    end

    -- evitar duplicados marcando al player
    if target:GetAttribute("ESPAdded") then return end
    target:SetAttribute("ESPAdded", true)

    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESPHighlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 1
    highlight.OutlineTransparency = 0
    highlight.Parent = c

    -- Billboard + label
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "NameTag"
    billboard.Size = UDim2.new(0, 220, 0, 18)
    billboard.AlwaysOnTop = true
    billboard.Adornee = c:FindFirstChild("Head")
    billboard.Parent = c

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextTransparency = 0.15
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextScaled = true
    nameLabel.Parent = billboard

    -- Tracker part (pequeño parte que se estira entre ambos torsos)
    local trackerPart = Instance.new("Part")
    trackerPart.Name = "TorsoTrackerLine"
    trackerPart.Anchored = true
    trackerPart.CanCollide = false
    trackerPart.Material = Enum.Material.Neon
    trackerPart.Transparency = 0.35
    trackerPart.Size = Vector3.new(0.04, 0.04, 0.04)
    trackerPart.Color = Color3.fromRGB(255,255,255)
    trackerPart.Parent = Workspace
    trackerPart.Locked = true
    trackerPart.CastShadow = false

    activeESPs[target] = {
        highlight = highlight,
        billboard = billboard,
        nameLabel = nameLabel,
        trackerPart = trackerPart,
        targetTorso = c:FindFirstChild("HumanoidRootPart"),
    }

    -- limpiar si el player sale o muere
    local function onRemove()
        destroyESPForTarget(target)
        target:SetAttribute("ESPAdded", nil)
    end

    local ancConn = target.AncestryChanged:Connect(function(_, parent)
        if not parent then onRemove() end
    end)
    addCleanup(player, ancConn)
end

-- Aplicar ESP a todos los players actuales (excepto local)
for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= player then
        plr.CharacterAdded:Connect(function() task.wait(1); createESP(plr) end)
        if plr.Character then createESP(plr) end
    end
end
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function() task.wait(1); createESP(plr) end)
end)
Players.PlayerRemoving:Connect(function(plr)
    destroyESPForTarget(plr)
end)

-- ===========
-- TEMMIE / COMPUTER TABLES (escaneo inicial + childadded controlado)
-- ===========
local TEMMIE_IMAGE_ID = "rbxassetid://106452528796091"
local OFFSET_Y = -1
local TEMMIE_WIDTH = 86
local TEMMIE_HEIGHT = TEMMIE_WIDTH * (2496 / 1920)
local TEMMIE_SIZE = UDim2.new(0, TEMMIE_WIDTH, 0, TEMMIE_HEIGHT)

local function createTemmieBillboard(originalBill)
    if not originalBill or not originalBill:IsA("BillboardGui") then return end
    local screen = originalBill.Parent
    local tableModel = screen and screen.Parent
    if not (screen and screen:IsA("BasePart")) then return end
    if not (tableModel and tableModel.Name == "ComputerTable") then return end

    if screen:FindFirstChild("BillboardGuiTemmie") then return end

    local temmie = Instance.new("BillboardGui")
    temmie.Name = "BillboardGuiTemmie"
    temmie.Size = TEMMIE_SIZE
    temmie.AlwaysOnTop = true
    temmie.Enabled = true
    temmie.Active = true
    temmie.LightInfluence = 0
    temmie.MaxDistance = math.huge
    temmie.Parent = screen

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "ImageLabel"
    imageLabel.BackgroundTransparency = 1
    imageLabel.Size = UDim2.new(1, 0, 1, 0)
    imageLabel.Image = TEMMIE_IMAGE_ID
    imageLabel.ImageTransparency = 0.35
    imageLabel.Parent = temmie

    -- attachment
    if originalBill.Adornee and originalBill.Adornee:IsA("BasePart") then
        local adornee = originalBill.Adornee
        local attach = adornee:FindFirstChild("TemmieAttachment")
        if not attach then
            attach = Instance.new("Attachment")
            attach.Name = "TemmieAttachment"
            attach.Position = Vector3.new(0, OFFSET_Y, 0)
            attach.Parent = adornee
        end
        temmie.Adornee = attach
    else
        local attach = screen:FindFirstChild("TemmieAttachment")
        if not attach then
            attach = Instance.new("Attachment")
            attach.Name = "TemmieAttachment"
            attach.Position = Vector3.new(0, OFFSET_Y, 0)
            attach.Parent = screen
        end
        temmie.Adornee = attach
    end
end

-- inicial scan (una vez)
local function initialScanForTables()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") then
            for _, child in ipairs(obj:GetChildren()) do
                if child.Name == "ComputerTable" then
                    local screen = child:FindFirstChild("Screen")
                    if screen then
                        local originalBill = screen:FindFirstChild("BillboardGui")
                        if originalBill then
                            createTemmieBillboard(originalBill)
                        end
                    end
                end
            end
        elseif obj.Name == "ComputerTable" then
            -- top-level ComputerTable
            createTemmieBillboard(obj:FindFirstChild("Screen") and obj.Screen:FindFirstChild("BillboardGui"))
        end
    end
end

initialScanForTables()

-- escuchar nuevos modelos añadidos (no DescendantAdded en todo workspace)
Workspace.ChildAdded:Connect(function(child)
    -- si viene un model, revisar sus hijos
    task.defer(function()
        if not child:IsA("Model") then return end
        for _, v in ipairs(child:GetChildren()) do
            if v.Name == "ComputerTable" and v:FindFirstChild("Screen") then
                local screen = v.Screen
                local bill = screen:FindFirstChild("BillboardGui")
                if bill then createTemmieBillboard(bill) end
            end
        end
    end)
end)

-- fallback controlado: cada 90s verificar si falta alguno (muy baja frecuencia)
task.spawn(function()
    while task.wait(90) do
        -- si el player ya salió del juego o similar, cortar
        if not player or not player.Parent then break end
        initialScanForTables()
    end
end)

-- ===========
-- TABLE CONTOUR + TEMMIE VISIBILITY (FADE) -> integrado en un solo RenderStepped
-- ===========
local MIN_DIST = 15
local MAX_DIST = 30
local CONTOUR_COLOR = Color3.fromRGB(0, 255, 0)
local FADE_SPEED = 0.2

-- activeTables: tableModel -> {highlight, alpha}
local activeTables = {}

local function ensureTableContour(tableModel)
    if not tableModel or not tableModel:IsA("Model") then return end
    if activeTables[tableModel] then return end

    if not tableModel:FindFirstChild("TableESP") then
        local hl = Instance.new("Highlight")
        hl.Name = "TableESP"
        hl.Adornee = tableModel
        hl.FillTransparency = 1
        hl.OutlineTransparency = 1
        hl.OutlineColor = CONTOUR_COLOR
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = tableModel
    end

    activeTables[tableModel] = {alpha = 0}
end

-- inicial populate para mesas top-level
for _, obj in ipairs(Workspace:GetChildren()) do
    if obj.Name == "ComputerTable" and obj:IsA("Model") then
        ensureTableContour(obj)
    elseif obj:IsA("Model") then
        for _, c in ipairs(obj:GetChildren()) do
            if c.Name == "ComputerTable" then ensureTableContour(c) end
        end
    end
end

-- conectar ChildAdded para modelos nuevos
Workspace.ChildAdded:Connect(function(child)
    task.defer(function()
        if not child then return end
        if child.Name == "ComputerTable" then ensureTableContour(child) end
        if child:IsA("Model") then
            for _, c in ipairs(child:GetChildren()) do
                if c.Name == "ComputerTable" then ensureTableContour(c) end
            end
        end
    end)
end)

-- track de visibilidad por screen (para detectar color disable)
local lastColorState = setmetatable({}, {__mode = "k"}) -- weak keys

local function isDisabledColor(color)
    local r, g, b = math.floor(color.R * 255), math.floor(color.G * 255), math.floor(color.B * 255)
    return (r == 40 and g == 127 and b == 71)
end

local function updateVisuals(screen, temmie, esp)
    if not screen then return end
    local disabled = isDisabledColor(screen.Color)
    if lastColorState[screen] == disabled then return end
    lastColorState[screen] = disabled
    if temmie then temmie.Enabled = not disabled end
    if esp then esp.Enabled = not disabled end
end

local function connectScreen(tableModel)
    local screen = tableModel:FindFirstChild("Screen")
    if not screen then return end
    if screen:GetAttribute("Connected") then return end
    screen:SetAttribute("Connected", true)

    local temmie = screen:FindFirstChild("BillboardGuiTemmie")
    local esp = tableModel:FindFirstChild("TableESP")

    screen:GetPropertyChangedSignal("Color"):Connect(function()
        updateVisuals(screen, temmie, esp)
    end)
    updateVisuals(screen, temmie, esp)
end

local function scanArcadesOnce()
    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") then
            for _, obj in ipairs(model:GetChildren()) do
                if obj.Name == "ComputerTable" then
                    connectScreen(obj)
                end
            end
        end
    end
end

scanArcadesOnce()

-- Single RenderStepped that updates ESPs and table fades
local renderConn
renderConn = RunService.RenderStepped:Connect(function(dt)
    -- actualizar ESPs (lecturas y transformaciones por frame)
    local localTorso = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    for target, data in pairs(activeESPs) do
        -- validar existencia
        local ok = pcall(function()
            assert(target and target.Character and target.Character:FindFirstChild("HumanoidRootPart"))
        end)
        if not ok then
            destroyESPForTarget(target)
        else
            -- obtener valores
            local targetTorso = target.Character.HumanoidRootPart
            local dist = (localTorso and (localTorso.Position - targetTorso.Position).Magnitude) or 0

            -- stats
            local tempStats = target:FindFirstChild("TempPlayerStatsModule")
            local isBeast = tempStats and tempStats:FindFirstChild("IsBeast")
            local captured = tempStats and tempStats:FindFirstChild("Captured")
            local crawling = tempStats and tempStats:FindFirstChild("IsCrawling")
            local ragdoll = tempStats and tempStats:FindFirstChild("Ragdoll")
            local currentAnim = tempStats and tempStats:FindFirstChild("CurrentAnimation")

            local beastValue = isBeast and isBeast.Value
            local capturedValue = captured and captured.Value
            local crawlingValue = crawling and crawling.Value
            local ragdollValue = ragdoll and ragdoll.Value
            local currentAnimValue = (currentAnim and currentAnim.Value) or ""

            -- prioridad color
            local finalColor = Color3.fromRGB(255,255,255)
            local priority = 1
            if currentAnimValue == "Typing" and priority < 2 then finalColor = Color3.fromRGB(0,255,0); priority = 2 end
            if capturedValue and priority < 3 then finalColor = Color3.fromRGB(150,220,255); priority = 3 end
            if ragdollValue and priority < 4 then finalColor = Color3.fromRGB(170,0,255); priority = 4 end

            -- buscar bestia cercano (puede optimizarse aún más si hace falta)
            local beastNearby = false
            for _, plr in pairs(Players:GetPlayers()) do
                local ts = plr:FindFirstChild("TempPlayerStatsModule")
                if ts and ts:FindFirstChild("IsBeast") and ts.IsBeast.Value then
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local beastDist = (plr.Character.HumanoidRootPart.Position - targetTorso.Position).Magnitude
                        if beastDist < 30 then
                            beastNearby = true
                            if ragdollValue then
                                finalColor = Color3.fromRGB(220,120,255); priority = 5
                            elseif priority < 5 then
                                finalColor = Color3.fromRGB(255,180,50); priority = 5
                            end
                            break
                        end
                    end
                end
            end

            if beastValue and priority < 10 then
                finalColor = Color3.fromRGB(255,0,0); priority = 10
            end

            if crawlingValue then
                local r, g, b = finalColor.R * 255, finalColor.G * 255, finalColor.B * 255
                finalColor = Color3.fromRGB(r * 0.7, g * 0.7, b * 0.7)
            end

            -- aplicar visuals
            if data.highlight and data.highlight.Parent then
                data.highlight.OutlineColor = finalColor
            end
            if data.nameLabel and data.nameLabel.Parent then
                -- calcular BeastChance visual como antes
                local baseChance = (target:FindFirstChild("SavedPlayerStatsModule")
                    and target.SavedPlayerStatsModule:FindFirstChild("BeastChance")
                    and target.SavedPlayerStatsModule.BeastChance.Value) or 0
                local playerCount = math.max(#Players:GetPlayers(), 1)
                local visualChance
                if baseChance == 0 then visualChance = 0 else visualChance = math.clamp(baseChance + ((100 - baseChance) / playerCount), 0, 100) end

                data.nameLabel.Text = string.format("%s [%s (≈%.0f%%)] - %.1f",
                    target.Name,
                    beastValue and "Beast" or "Human",
                    visualChance,
                    dist)
                data.nameLabel.TextColor3 = finalColor
            end

            -- tracker part posicion/size/color
            if data.trackerPart and data.trackerPart.Parent then
                local midpoint = (localTorso and (localTorso.Position) or targetTorso.Position + Vector3.new(0,0,0) + targetTorso.Position) / 2
                local direction = (targetTorso.Position - (localTorso and localTorso.Position or targetTorso.Position))
                local distance = direction.Magnitude
                data.trackerPart.Size = Vector3.new(0.04, 0.04, math.max(0.01, distance))
                data.trackerPart.CFrame = CFrame.lookAt(midpoint, targetTorso.Position)
                data.trackerPart.Color = finalColor
                data.trackerPart.Transparency = 0.35
            end
        end
    end

    -- actualizar table fades
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local root = player.Character.HumanoidRootPart
        for tableModel, data in pairs(activeTables) do
            if tableModel and tableModel.Parent then
                local screen = tableModel:FindFirstChild("Screen")
                local hl = tableModel:FindFirstChild("TableESP")
                if screen and hl then
                    local temmie = screen:FindFirstChild("BillboardGuiTemmie")
                    local adornee = temmie and temmie.Adornee
                    if adornee and adornee:IsA("Attachment") and adornee.Parent then
                        local dist = (root.Position - adornee.Parent.Position).Magnitude
                        local targetAlpha = math.clamp((dist - MIN_DIST) / (MAX_DIST - MIN_DIST), 0, 1)
                        data.alpha = data.alpha + (targetAlpha - data.alpha) * (FADE_SPEED * 60 * dt)
                        local image = temmie:FindFirstChildWhichIsA("ImageLabel") or temmie:FindFirstChildWhichIsA("ImageButton")
                        if image then
                            image.ImageTransparency = 1 - (data.alpha * 0.65)
                        end
                        hl.OutlineTransparency = data.alpha
                    end
                end
                -- conectar screen si no lo esta
                connectScreen(tableModel)
            else
                activeTables[tableModel] = nil
            end
        end
    end
end)

-- Si el jugador sale o similar, limpiar
player.AncestryChanged:Connect(function(_, parent)
    if not parent then
        if renderConn then renderConn:Disconnect() end
        runCleanup(player)
    end
end)

-- ===========
-- FIN DEL SCRIPT
-- ===========