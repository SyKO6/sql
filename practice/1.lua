local message = {
    error = "Ha ocurrido un error" 
}

permitido = true
sLine = "-- == == == == == == == --"

if permitido == true then
    print(sLine)
    print("Acceso permitido.\nBienvenid@")
    print(sLine)
elseif permitido == false then
    print(sLine)
    print("Acceso denegado.")
    print(sLine)
else
    print(sLine)
    print(message.error)
    print(sLine)
end