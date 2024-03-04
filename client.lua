local isHovering, hoverPosition, currentHelicopter, keyPressedTime = false, nil, nil, nil

local Config = {
    HoverHeightAdjustment = 5.0,
    Debug = true,
    NotificationSystem = 'standalone', -- options are ox_lib or standalone
    AllowJumpOutOfHelicopter = true
}

local function Debug(message)
    if Config.Debug then
        print(message)
    end
end

function DrawTxt(x, y, width, height, scale, text, r, g, b, a)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextDropshadow(0, 0, 0, 0, 150)
    SetTextEdge(2, 0, 0, 0, 250)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x - width / 2, y - height / 2 + 0.005)
end

local function SendNotification(title, description, type)
    if Config.NotificationSystem == 'ox_lib' then
        exports['ox_lib']:notify({title = title, description = description, type = type})
    elseif Config.NotificationSystem == 'standalone' then
        hoverStatusMessage = title .. ": " .. description
        showHoverStatus = true
        Citizen.SetTimeout(5000, function()
            showHoverStatus = false
        end)
    else
        Debug("No valid notification system configured.")
    end
end

local function AdjustHoverHeight(increase)
    local adjustment = Config.HoverHeightAdjustment
    if not increase then
        adjustment = -adjustment
    end
    if hoverPosition then
        local newPosZ = hoverPosition.z + adjustment
        local _, groundZ = GetGroundZFor_3dCoord(hoverPosition.x, hoverPosition.y, newPosZ + 10.0, true)
        if newPosZ >= groundZ then
            hoverPosition = vector3(hoverPosition.x, hoverPosition.y, newPosZ)
            Debug("Adjusted hover height by " .. tostring(adjustment))
        else
            SendNotification('Cannot Adjust', 'Below ground level.', 'error')
        end
    end
end

local function ToggleHoverMode()
    local playerPed = PlayerPedId()
    if IsPedInAnyHeli(playerPed) and GetPedInVehicleSeat(GetVehiclePedIsIn(playerPed, false), -1) == playerPed then
        currentHelicopter = GetVehiclePedIsIn(playerPed, false)
        isHovering = not isHovering
        hoverPosition = isHovering and GetEntityCoords(currentHelicopter) or nil
        FreezeEntityPosition(currentHelicopter, isHovering)
        SendNotification('Hover Mode', isHovering and 'Engaged' or 'Disengaged', isHovering and 'success' or 'error')
    else
        if not IsPedInAnyHeli(playerPed) then
            Debug("You need to be in a helicopter.")
        else
            Debug("You need to be in the driver seat.")
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        if IsPedInAnyHeli(playerPed) and GetPedInVehicleSeat(GetVehiclePedIsIn(playerPed, false), -1) == playerPed then
            if IsControlPressed(0, 73) then
                if not keyPressedTime then keyPressedTime = GetGameTimer() end
            elseif keyPressedTime and (GetGameTimer() - keyPressedTime) > 2000 then
                ToggleHoverMode()
                keyPressedTime = nil
            end
            
            if showHoverStatus then
                DrawTxt(0.5, 0.5, 1.0, 1.0, 0.5, hoverStatusMessage, 255, 255, 255, 255)
            end

            if isHovering then
                if IsControlJustPressed(0, 172) then
                    AdjustHoverHeight(true)
                elseif IsControlJustPressed(0, 173) then
                    AdjustHoverHeight(false)
                end
                SetEntityCoordsNoOffset(currentHelicopter, hoverPosition.x, hoverPosition.y, hoverPosition.z, true, true, true)
            end
        end
    end
end)
