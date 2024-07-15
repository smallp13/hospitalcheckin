-- Config
local checkInLocation = vector3(312.3889, -592.7520, 43.2841)  -- Updated check-in location
local hospitalBeds = {
    {coords = vector4(327.0233, -576.1498, 44.0217, 154.1978)},
    {coords = vector4(317.6172, -585.4524, 44.2040, 338.9336)},
    {coords = vector4(311.0369, -583.0424, 44.2040, 337.9036)}
}

-- Function to teleport player to available bed
local function teleportToBed(player)
    for _, bed in ipairs(hospitalBeds) do
        local bedOccupant = GetClosestPlayer(bed.coords.xyz, 1.0)
        if not bedOccupant then
            SetEntityCoords(player, bed.coords.x, bed.coords.y, bed.coords.z)
            SetEntityHeading(player, bed.coords.w)

            -- Play animation
            TaskPlayAnim(player, "anim@gangops@morgue@table@", "body_search", 8.0, 1.0, -1, 02, 0, false, false, false)

            -- Wait 1 second after starting animation
            Citizen.Wait(1000)

            -- Freeze entity position after animation starts
            FreezeEntityPosition(player, true)

            return bed
        end
    end
    return nil
end

-- Function to heal player
local function healPlayer(player)
    SetEntityHealth(player, GetEntityMaxHealth(player))
end

-- Function to get the closest low health player
local function getClosestLowHealthPlayer(coords, radius)
    local players = GetActivePlayers()
    local closestPlayer = nil
    local closestDistance = radius

    for _, player in ipairs(players) do
        local playerPed = GetPlayerPed(player)
        local playerCoords = GetEntityCoords(playerPed)
        local playerHealth = GetEntityHealth(playerPed)
        local distance = #(coords - playerCoords)

        if playerHealth < GetEntityMaxHealth(playerPed) and distance < closestDistance then
            closestPlayer = player
            closestDistance = distance
        end
    end

    return closestPlayer
end

-- Main logic
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        if #(playerCoords - checkInLocation) < 1.5 then
            DrawText3D(checkInLocation.x, checkInLocation.y, checkInLocation.z, "[E] Check In Patient")
            if IsControlJustReleased(0, 38) then -- E key
                local closestLowHealthPlayer = getClosestLowHealthPlayer(playerCoords, 5.0)
                if closestLowHealthPlayer then
                    local bed = teleportToBed(GetPlayerPed(closestLowHealthPlayer))
                    if bed then
                        local targetPed = GetPlayerPed(closestLowHealthPlayer)
                        
                        local timeLeft = 60  -- 60 seconds
                        Citizen.CreateThread(function()
                            while timeLeft > 0 do
                                Citizen.Wait(3000)
                                timeLeft = timeLeft - 1
                                DrawText3D(GetEntityCoords(targetPed).x, GetEntityCoords(targetPed).y, GetEntityCoords(targetPed).z + 1.0, "Time left: " .. timeLeft .. "s")
                            end
                        end)

                        Citizen.Wait(60000)  -- Wait for 1 minute
                        ClearPedTasks(targetPed)
                        healPlayer(targetPed)
                        FreezeEntityPosition(targetPed, false)

                        TriggerEvent("chat:addMessage", {
                            color = {255, 0, 0},
                            multiline = true,
                            args = {"Hospital", "You are ready to leave!"}
                        })
                    else
                        TriggerEvent("chat:addMessage", {
                            color = {255, 0, 0},
                            multiline = true,
                            args = {"Hospital", "No beds available!"}
                        })
                    end
                else
                    TriggerEvent("chat:addMessage", {
                        color = {255, 0, 0},
                        multiline = true,
                        args = {"Hospital", "No patients with low health nearby!"}
                    })
                end
            end
        end
    end
end)

-- Helper function to draw 3D text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)
    local factor = (string.len(text)) / 370
    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
end

-- Helper function to get the closest player
function GetClosestPlayer(coords, radius)
    local players = GetActivePlayers()
    local closestPlayer = nil
    local closestDistance = radius

    for _, player in ipairs(players) do
        local playerPed = GetPlayerPed(player)
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(coords - playerCoords)

        if distance < closestDistance then
            closestPlayer = player
            closestDistance = distance
        end
    end

    return closestPlayer
end
