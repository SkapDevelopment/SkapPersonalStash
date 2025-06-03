local cam = nil
local fov = 50.0
local pos = GetEntityCoords(PlayerPedId())
local rot = vector3(0.0, 0.0, GetEntityHeading(PlayerPedId()))
local step = 0.05
local rotStep = 2.0
local active = false

local function GetRightVector(entity)
    local forward = GetEntityForwardVector(entity)
    return vector3(-forward.y, forward.x, 0.0)
end



RegisterCommand("camdebug", function()
    if active then return end
    active = true

    pos = GetEntityCoords(PlayerPedId())
    rot = vector3(0.0, 0.0, GetEntityHeading(PlayerPedId()))
    fov = 50.0

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, pos.x, pos.y, pos.z)
    SetCamRot(cam, rot.x, rot.y, rot.z)
    SetCamFov(cam, fov)
    RenderScriptCams(true, true, 0, true, true)

    print("[CamDebug] Kameraläge aktivt. Använd WASD / piltangenter för att justera. Tryck [E] för att kopiera.")
    ShowHelpNotification("~b~[CamDebug]~s~ WASD/arrows = flytta | PgUp/PgDn = höjd | Num4/6 = yaw | Num8/2 = pitch | +/- = zoom | ~g~E~s~ = kopiera | ~r~BACKSPACE~s~ = stäng")
end)

CreateThread(function()
    while true do
        Wait(0)
        if not active or not cam then
            Wait(500)
        else
            DisableControlAction(0, 1, true) -- Disable look
            DisableControlAction(0, 2, true)

            local moved = false

            -- Rörelse
            if IsControlPressed(0, 32) then pos = pos + GetEntityForwardVector(PlayerPedId()) * step moved = true end -- W
            if IsControlPressed(0, 33) then pos = pos - GetEntityForwardVector(PlayerPedId()) * step moved = true end -- S
            if IsControlPressed(0, 34) then pos = pos - GetRightVector(PlayerPedId()) * step moved = true end -- A
            if IsControlPressed(0, 35) then pos = pos + GetRightVector(PlayerPedId()) * step moved = true end -- D                    
            if IsControlPressed(0, 10) then pos = pos + vector3(0, 0, step) moved = true end -- PgUp
            if IsControlPressed(0, 11) then pos = pos - vector3(0, 0, step) moved = true end -- PgDn

            -- Rotation
            if IsControlPressed(0, 108) then rot = vector3(rot.x, rot.y, rot.z + rotStep) moved = true end -- Num 4
            if IsControlPressed(0, 109) then rot = vector3(rot.x, rot.y, rot.z - rotStep) moved = true end -- Num 6
            if IsControlPressed(0, 111) then rot = vector3(rot.x + rotStep, rot.y, rot.z) moved = true end -- Num 8
            if IsControlPressed(0, 110) then rot = vector3(rot.x - rotStep, rot.y, rot.z) moved = true end -- Num 2
            

            -- FOV
            if IsControlJustPressed(0, 61) then fov = math.min(fov + 2.0, 100.0) moved = true end -- +
            if IsControlJustPressed(0, 60) then fov = math.max(fov - 2.0, 10.0) moved = true end -- -

            if moved then
                SetCamCoord(cam, pos.x, pos.y, pos.z)
                SetCamRot(cam, rot.x, rot.y, rot.z)
                SetCamFov(cam, fov)
            end

            -- Tryck [E] för att kopiera
            if IsControlJustPressed(0, 38) then
                local output = string.format(
                    'CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, false, 0)',
                    pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, fov
                )
                print("[CamDebug] " .. output)
                TriggerEvent("chat:addMessage", {
                    color = {0, 255, 0},
                    multiline = true,
                    args = {"CamDebug", "Kamerainställning kopierad till konsolen!"}
                })
                SendNUIMessage({clipboard = output}) -- Om du har stöd för det
            end

            -- Avsluta med Backspace
            if IsControlJustPressed(0, 177) then
                RenderScriptCams(false, true, 1000, true, true)
                DestroyCam(cam, false)
                cam = nil
                active = false
                print("[CamDebug] Kameraläge avslutat.")
            end
        end
    end
end)

function ShowHelpNotification(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end
