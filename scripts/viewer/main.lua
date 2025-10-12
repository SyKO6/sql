local function getCharacterInfo(character)
    local info = {}
    
    -- Información básica del personaje
    table.insert(info, string.format("=== Información del Personaje ==="))
    table.insert(info, string.format("Nombre del Jugador: %s", game.Players.LocalPlayer.Name))
    
    -- Obtener todos los objetos decorativos
    for _, descendant in pairs(character:GetDescendants()) do
        if descendant:IsA("Accessory") or 
           descendant:IsA("Tool") or 
           descendant:IsA("Shirt") or 
           descendant:IsA("Pants") or 
           descendant:IsA("Hat") then
            
            local objectInfo = {
                Tipo = descendant.ClassName,
                Nombre = descendant.Name,
                Padre = descendant.Parent.Name,
                ID = tostring(descendant),
                Posicion = tostring(descendant.CFrame),
                Anchura = descendant.Handle and descendant.Handle.Width or "",
                Altura = descendant.Handle and descendant.Handle.Height or ""
            }
            
            -- Agregar información al texto
            table.insert(info, "\n=== " .. objectInfo.Tipo .. ": " .. objectInfo.Nombre .. " ===")
            table.insert(info, "ID: " .. objectInfo.ID)
            table.insert(info, "Padre: " .. objectInfo.Padre)
            table.insert(info, "Posición: " .. objectInfo.Posicion)
            
            if objectInfo.Ancura ~= "" then
                table.insert(info, "Dimensiones:")
                table.insert(info, "Anchura: " .. objectInfo.Ancura)
                table.insert(info, "Altura: " .. objectInfo.Altura)
            end
        end
    end
    
    return table.concat(info, "\n")
end

local function crearGUI()
    -- Crear el frame principal
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "CharacterInfoGUI"
    
    -- Frame principal con scrollbar
    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Size = UDim2.new(0, 300, 0, 400)
    ScrollingFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
    ScrollingFrame.BackgroundTransparency = 0.5
    ScrollingFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ScrollingFrame.ScrollBarThickness = 8
    
    -- Textbox para mostrar la información
    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(1, -10, 1, -10)
    TextBox.Position = UDim2.new(0, 5, 0, 5)
    TextBox.BackgroundTransparency = 0.5
    TextBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    TextBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    TextBox.Font = Enum.Font.Code
    TextBox.MultiLine = true
    TextBox.ClearTextOnFocus = false
    TextBox.TextEditable = true
    
    -- Configuración de la GUI
    TextBox.Parent = ScrollingFrame
    ScrollingFrame.Parent = ScreenGui
    
    return ScreenGui, TextBox
end

-- Función principal para ejecutar el script
local function iniciarScript(modo)
    modo = modo or "normal"
    
    -- Obtener o esperar al character
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    
    -- Crear la GUI
    local ScreenGui, TextBox = crearGUI()
    
    -- Modo normal: colocar en PlayerGui
    if modo == "normal" then
        ScreenGui.Parent = player.PlayerGui
        
    -- Modo prueba: usar función de inyección
    elseif modo == "prueba" then
        -- Aquí va tu código de inyección personalizado
        -- Por ejemplo:
        -- loadstring(game:HttpGet("tu-url-aqui"))()
        print("Modo prueba activado")
    end
    
    -- Actualizar la información cuando el personaje cambie
    local function updateInfo()
        TextBox.Text = getCharacterInfo(character)
    end
    
    -- Conectar eventos
    character.DescendantAdded:Connect(function()
        task.wait(0.1)
        updateInfo()
    end)
    
    character.DescendantRemoving:Connect(function()
        task.wait(0.1)
        updateInfo()
    end)
    
    -- Actualizar inicialmente
    updateInfo()
end

-- Ejecutar el script
iniciarScript() -- ^q^