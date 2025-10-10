loadstring(game:HttpGet("https://raw.githubusercontent.com/SyKO6/sql/refs/heads/main/scripts/intro.lua"))()  
  
--// CONFIGURACIONES INICIALES  
local Players = game:GetService("Players")  
local Lighting = game:GetService("Lighting")  
local RunService = game:GetService("RunService")  
  
local player = Players.LocalPlayer  
local camera = workspace.CurrentCamera  
  
--// Variables  
local normalSpeed = 18.8  
local crawlSpeed = 10.8  
local beastSpeed = 18.8  
local fov = 80  
  
--// Aplicar configuración visual  
camera.FieldOfView = fov  
player.CameraMode = Enum.CameraMode.Classic  
player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam  
player.CameraMaxZoomDistance = 1000  
  
--// Corrección de iluminación (visión clara)  
Lighting.GlobalShadows = false  
Lighting.Atmosphere.Density = 0  
Lighting.Brightness = 1  
Lighting.FogEnd = 100000  
Lighting.ExposureCompensation = 0.5  
  
task.spawn(function()  
	while true do  
		task.wait(1)  
		if Lighting.GlobalShadows then Lighting.GlobalShadows = false end  
		if Lighting.Atmosphere and Lighting.Atmosphere.Density ~= 0 then  
			Lighting.Atmosphere.Density = 0  
		end  
	end  
end)  
  
--// Sistema de velocidad dinámica (Humano + Bestia)  
--// Sistema de velocidad dinámica (Humano + Bestia)  
local function enforceWalkSpeed()  
	local character = player.Character or player.CharacterAdded:Wait()  
	local humanoid = character:WaitForChild("Humanoid")  
  
	local tempStats = player:FindFirstChild("TempPlayerStatsModule")  
	if not tempStats then return end  
  
	local isCrawling = tempStats:FindFirstChild("IsCrawling")  
	local isBeast = tempStats:FindFirstChild("IsBeast")  
  
	-- bandera para evitar programar múltiples delays  
	local beastSpeedPending = false  
  
	RunService.Heartbeat:Connect(function()  
		if humanoid and isCrawling and isBeast then  
			local crawling = isCrawling.Value  
			local beast = isBeast.Value  
  
			-- 🧍‍♂️ Jugador normal  
			if not beast then  
				humanoid.WalkSpeed = crawling and crawlSpeed or normalSpeed  
			else  
				-- 🧟‍♂️ Bestia: si tiene velocidad menor a beastSpeed, esperar 1s y luego establecer  
				if humanoid.WalkSpeed < beastSpeed then  
					if not beastSpeedPending then  
						beastSpeedPending = true  
						task.delay(1, function()  
							-- comprobar que el humanoide sigue existiendo y sigue con velocidad menor  
							if humanoid and humanoid.Parent and humanoid.WalkSpeed < beastSpeed then  
								humanoid.WalkSpeed = beastSpeed  
							end  
							beastSpeedPending = false  
						end)  
					end  
				end  
				-- Nota: ya no forzamos inmediatamente WalkSpeed = beastSpeed si es distinto.  
			end  
		end  
	end)  
end  
  
if player.Character then enforceWalkSpeed() end  
player.CharacterAdded:Connect(enforceWalkSpeed)  
  
--// Función para oscurecer color  
local function darkenColor(color, percent)  
	return Color3.new(color.R * (1 - percent), color.G * (1 - percent), color.B * (1 - percent))  
end  
  
--// ESP avanzado con tracker 3D  
local function createESP(target)  
	if target == player then return end  
  
	local highlight = Instance.new("Highlight")  
	highlight.Name = "ESPHighlight"  
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- se ve a través de paredes  
	highlight.FillTransparency = 1  
	highlight.OutlineTransparency = 0  
	highlight.Parent = target.Character  
  
	local billboard = Instance.new("BillboardGui")  
	billboard.Name = "NameTag"  
	billboard.Size = UDim2.new(0, 220, 0, 18)  
	billboard.AlwaysOnTop = true  
	billboard.Adornee = target.Character:WaitForChild("Head")  
	billboard.Parent = target.Character  
  
	local nameLabel = Instance.new("TextLabel")  
	nameLabel.Size = UDim2.new(1, 0, 1, 0)  
	nameLabel.BackgroundTransparency = 1  
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)  
	nameLabel.TextStrokeTransparency = 0.5  
	nameLabel.TextTransparency = 0.25 -- 🧿 75% visible
	nameLabel.Font = Enum.Font.GothamBold  
	nameLabel.TextScaled = true  
	nameLabel.Parent = billboard  
  
	-- 🧠 Tracker 3D (línea entre torsos)  
	local playerTorso = player.Character:WaitForChild("HumanoidRootPart")  
	local targetTorso = target.Character:WaitForChild("HumanoidRootPart")  
  
	local trackerPart = Instance.new("Part")  
	trackerPart.Name = "TorsoTrackerLine"  
	trackerPart.Anchored = true  
	trackerPart.CanCollide = false  
	trackerPart.Material = Enum.Material.Neon  
	trackerPart.Transparency = 0.35  
	trackerPart.Size = Vector3.new(0.15, 0.15, 0.15)  
	trackerPart.Color = Color3.fromRGB(255, 255, 255)  
	trackerPart.Parent = workspace  
	trackerPart.Locked = true  
	trackerPart.CastShadow = false  
	trackerPart:SetAttribute("NonInteractive", true)  
  
	RunService.RenderStepped:Connect(function()  
		if not (target.Character and target.Character:FindFirstChild("HumanoidRootPart")) then  
			if trackerPart then trackerPart.Transparency = 1 end  
			return  
		end  
  
		local dist = (playerTorso.Position - targetTorso.Position).Magnitude  
  
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
  
		-- 🔢 Sistema de prioridad de colores  
		local finalColor = Color3.fromRGB(255, 255, 255)  
		local priority = 1  
  
		if currentAnimValue == "Typing" and priority < 2 then  
			finalColor = Color3.fromRGB(0, 255, 0)  
			priority = 2  
		end  
		if capturedValue and priority < 3 then  
			finalColor = Color3.fromRGB(150, 220, 255)  
			priority = 3  
		end  
		if ragdollValue and priority < 4 then  
			finalColor = Color3.fromRGB(170, 0, 255)  
			priority = 4  
		end  
  
		local beastNearby = false  
		local beastPlayer  
		for _, plr in pairs(Players:GetPlayers()) do  
			local ts = plr:FindFirstChild("TempPlayerStatsModule")  
			if ts and ts:FindFirstChild("IsBeast") and ts.IsBeast.Value then  
				beastPlayer = plr  
				break  
			end  
		end  
  
		if beastPlayer and beastPlayer.Character and beastPlayer.Character:FindFirstChild("HumanoidRootPart") then  
			local beastDist = (beastPlayer.Character.HumanoidRootPart.Position - targetTorso.Position).Magnitude  
			if beastDist < 30 then  
				beastNearby = true  
				if ragdollValue then  
					finalColor = Color3.fromRGB(220, 120, 255) -- púrpura claro (ragdoll + beast cerca)  
					priority = 5  
				elseif priority < 5 then  
					finalColor = Color3.fromRGB(255, 180, 50) -- naranja  
					priority = 5  
				end  
			end  
		end  
  
		if beastValue and priority < 10 then  
			finalColor = Color3.fromRGB(255, 0, 0)  
			priority = 10  
		end  
  
		-- Si está agachado (IsCrawling), aplicar siempre opaco sin importar prioridad  
		if crawlingValue then  
			local r, g, b = finalColor.R * 255, finalColor.G * 255, finalColor.B * 255  
			finalColor = Color3.fromRGB(r * 0.7, g * 0.7, b * 0.7)  
		end  
  
		-- Actualizar visual  
		highlight.OutlineColor = finalColor  
		nameLabel.TextColor3 = finalColor  
		-- 🧠 Obtener el BeastChance directamente del GUI del jugador
        nameLabel.Text = string.format("%s [%s (%.0f%%)] - %.1f",  
			target.Name,  
			beastValue and "Beast" or "Human",  
			(target:FindFirstChild("SavedPlayerStatsModule")  
				and target.SavedPlayerStatsModule:FindFirstChild("BeastChance")  
				and target.SavedPlayerStatsModule.BeastChance.Value) or 0,  
			dist  
		)  
  
		local midpoint = (playerTorso.Position + targetTorso.Position) / 2  
		local direction = (targetTorso.Position - playerTorso.Position)  
		local distance = direction.Magnitude  
  
		trackerPart.Size = Vector3.new(0.04, 0.04, distance)  
		trackerPart.CFrame = CFrame.lookAt(midpoint, targetTorso.Position)  
		trackerPart.Color = finalColor  
		trackerPart.Transparency = 0.35  
	end)  
end  
  
--// Aplicar ESP a todos los jugadores  
for _, plr in pairs(Players:GetPlayers()) do  
	if plr ~= player then  
		plr.CharacterAdded:Connect(function()  
			task.wait(1)  
			createESP(plr)  
		end)  
		if plr.Character then createESP(plr) end  
	end  
end  
  
Players.PlayerAdded:Connect(function(plr)  
	plr.CharacterAdded:Connect(function()  
		task.wait(1)  
		createESP(plr)  
	end)  
end)  
  
  
  
  
  
-- 🧿 Sistema de Temmie flotante solo en ComputerTable > Screen  
local TEMMIE_IMAGE_ID = "rbxassetid://90866842257772"  
local OFFSET_Y = -1  
local TEMMIE_SIZE = UDim2.new(0, 40, 0, 40)  
  
-- Crea el Temmie debajo del BillboardGui original  
local function createTemmieBillboard(originalBill)  
	if not originalBill or not originalBill:IsA("BillboardGui") then return end  
  
	local screen = originalBill.Parent  
	local tableModel = screen and screen.Parent  
	if not (screen and screen:IsA("BasePart")) then return end  
	if not (tableModel and tableModel.Name == "ComputerTable") then return end  
  
	-- Evitar duplicados  
	if screen:FindFirstChild("BillboardGuiTemmie") then return end  
  
	local temmie = Instance.new("BillboardGui")  
	temmie.Name = "BillboardGuiTemmie"  
	temmie.Size = TEMMIE_SIZE  
	temmie.AlwaysOnTop = true  
	temmie.Enabled = true  
	temmie.Active = true  
	temmie.LightInfluence = 0  
	temmie.MaxDistance = math.huge -- 🔥 visible desde cualquier distancia  
	temmie.Parent = screen  
  
	local imageLabel = Instance.new("ImageLabel")  
	imageLabel.Name = "ImageLabel"  
	imageLabel.BackgroundTransparency = 1  
	imageLabel.Size = UDim2.new(1, 0, 1, 0)  
	imageLabel.Image = TEMMIE_IMAGE_ID  
	imageLabel.ImageTransparency = 0.3 -- 🟦 Por defecto 90% visible (0 = opaco, 1 = invisible)  
	imageLabel.Parent = temmie  
  
	-- Posición igual al original, pero 1 bloque más abajo  
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
		-- fallback: colocar directamente en Screen  
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
  
-- Buscar todos los ComputerTable existentes  
local function ensureAllTemmies()  
	for _, tbl in ipairs(workspace:GetDescendants()) do  
		if tbl.Name == "ComputerTable" and tbl:FindFirstChild("Screen") then  
			local screen = tbl.Screen  
			local originalBill = screen:FindFirstChild("BillboardGui")  
			if originalBill then  
				createTemmieBillboard(originalBill)  
			end  
		end  
	end  
end  
  
-- Ejecutar al inicio  
ensureAllTemmies()  
  
-- Detectar nuevas ComputerTables o Screens dinámicas  
workspace.DescendantAdded:Connect(function(obj)  
	if obj.Name == "ComputerTable" then  
		task.spawn(function()  
			obj:WaitForChild("Screen")  
			local screen = obj.Screen  
			local originalBill = screen:WaitForChild("BillboardGui")  
			createTemmieBillboard(originalBill)  
		end)  
	elseif obj.Name == "Screen" and obj.Parent and obj.Parent.Name == "ComputerTable" then  
		task.spawn(function()  
			local bill = obj:WaitForChild("BillboardGui")  
			createTemmieBillboard(bill)  
		end)  
	end  
end)  
  
-- ✅ Solución alternativa sin error  
-- Verifica periódicamente si falta algún Temmie y lo regenera  
task.spawn(function()  
	while task.wait(2) do  
		ensureAllTemmies()  
	end  
end)  
  
  
  
-- 🌀 TEMMIE VISIBILITY + COMPUTER TABLE CONTOUR SYSTEM  
  
local MIN_DIST = 15  
local MAX_DIST = 30  
local CONTOUR_COLOR = Color3.fromRGB(0, 255, 0)  
local FADE_SPEED = 0.2 -- suavidad (0.1 más lento, 0.3 más rápido)  
  
local activeTables = {}  
  
-- Función para crear el contorno azul (ESP)  
local function createContour(tableModel)  
	if not tableModel:FindFirstChild("TableESP") then  
		local hl = Instance.new("Highlight")  
		hl.Name = "TableESP"  
		hl.Adornee = tableModel  
		hl.FillTransparency = 1 -- sin relleno  
		hl.OutlineTransparency = 1 -- totalmente invisible al inicio  
		hl.OutlineColor = CONTOUR_COLOR  
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop  
		hl.Parent = tableModel  
	end  
	if not activeTables[tableModel] then  
		activeTables[tableModel] = {alpha = 0}  
	end  
end  
  
-- Detectar todas las mesas existentes  
for _, obj in ipairs(workspace:GetDescendants()) do  
	if obj.Name == "ComputerTable" then  
		createContour(obj)  
	end  
end  
  
-- Detectar nuevas mesas que aparezcan después  
workspace.DescendantAdded:Connect(function(obj)  
	if obj.Name == "ComputerTable" then  
		createContour(obj)  
	end  
end)  
  
-- Función principal de actualización (fade dinámico)  
RunService.RenderStepped:Connect(function(dt)  
	if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then  
		return  
	end  
  
	local root = player.Character.HumanoidRootPart  
  
	for tableModel, data in pairs(activeTables) do  
		if tableModel and tableModel.Parent then  
			local screen = tableModel:FindFirstChild("Screen")  
			local hl = tableModel:FindFirstChild("TableESP")  
  
			if screen and hl then  
				local temmie = screen:FindFirstChild("BillboardGuiTemmie")  
  
				if temmie and temmie:IsA("BillboardGui") then  
					local adornee = temmie.Adornee  
					if adornee and adornee:IsA("Attachment") and adornee.Parent then  
						local dist = (root.Position - adornee.Parent.Position).Magnitude  
  
						-- Calcular alpha: 0 cerca, 1 lejos  
						local targetAlpha = math.clamp((dist - MIN_DIST) / (MAX_DIST - MIN_DIST), 0, 1)  
  
						-- Suavizar cambio (interpolación progresiva)  
						data.alpha = data.alpha + (targetAlpha - data.alpha) * (FADE_SPEED * 60 * dt)  
  
						-- Aplicar transparencias inversas  
						local image = temmie:FindFirstChildWhichIsA("ImageLabel") or temmie:FindFirstChildWhichIsA("ImageButton")  
						if image then  
							image.ImageTransparency = 1 - (data.alpha * 0.7) -- límite 0.1 mínima (90% visible máximo)  
						end  
  
						hl.OutlineTransparency = data.alpha -- Contorno aparece al acercarse  
					end  
				end  
			end  
		end  
	end  
end)