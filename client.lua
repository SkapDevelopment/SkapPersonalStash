local QBCore = exports['qb-core']:GetCoreObject()
local spawnedPeds = {}
local spawnedTargets = {}

CreateThread(function()
    for key, data in pairs(Config.Stashes) do
        local model = data.model
        local coords = data.coords

        RequestModel(model)
        while not HasModelLoaded(model) do Wait(100) end

        if data.type == "ped" then
            local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            FreezeEntityPosition(ped, true)
            spawnedPeds[key] = ped
        elseif data.type == "prop" then
            local prop = CreateObject(model, coords.x, coords.y, coords.z - 1.0, false, false, false)
            SetEntityHeading(prop, coords.w)
            FreezeEntityPosition(prop, true)
        end
    end
end)

function MakePedTalk(key)
    local ped = spawnedPeds[key]
    if ped and DoesEntityExist(ped) and Config.PedSpeechPhrases then
        local phrases = Config.PedSpeechPhrases
        local phrase = phrases[math.random(1, #phrases)]
        StopCurrentPlayingAmbientSpeech(ped)
        PlayAmbientSpeech1(ped, phrase, "SPEECH_PARAMS_FORCE_NORMAL")
    end
end

local function GetGroupName()
    local Player = QBCore.Functions.GetPlayerData()
    if Config.UseMultiJob then
        return Player.job.name, Player.job, Player.gang.name, Player.gang
    else
        return Player.job.name, Player.job, nil, nil
    end
end

function RefreshStashTargets()
    local Player = QBCore.Functions.GetPlayerData()
    if not Player then return end

    for zone, _ in pairs(spawnedTargets) do
        exports['qb-target']:RemoveZone(zone)
    end
    spawnedTargets = {}

    local jobName, jobData, gangName, gangData = GetGroupName()

    for key, data in pairs(Config.Stashes) do
        local coords = data.coords
        local zoneName = "stashzone_" .. key

        local belongsToJob = data.job and data.job == jobName
        local belongsToGang = data.gang and data.gang == gangName

        if belongsToJob or belongsToGang then
            local options = {
                options = {
                    {
                        type = "client",
                        event = "skapPersonalStashes:openPersonalStash",
                        icon = "fas fa-box-open",
                        label = "Öppna förråd",
                        stashKey = key
                    }
                },
                distance = 2.0
            }

            local bossGrade = data.BossGrade or 2
            local jobGrade = type(jobData.grade) == "table" and jobData.grade.level or jobData.grade
            local gangGrade = gangData and type(gangData.grade) == "table" and gangData.grade or 0
            local isBoss = (belongsToJob and jobGrade >= bossGrade)
                         or (belongsToGang and gangGrade >= bossGrade)

            if isBoss and data.stashType ~= "shared" then
                table.insert(options.options, {
                    type = "client",
                    event = "skapPersonalStashes:openEmployeeMenu",
                    icon = "fas fa-users",
                    label = "Anställdas förråd",
                    stashKey = key
                })
            end

            if isBoss and Config.UseStashPin then
                table.insert(options.options, {
                    type = "client",
                    icon = "fas fa-key",
                    label = "Sätt pinkod",
                    event = "skapPersonalStashes:setStashPinMenu",
                    stashKey = key
                })
            end

            exports['qb-target']:AddBoxZone(zoneName, vector3(coords.x, coords.y, coords.z), 1.5, 1.5, {
                name = zoneName,
                heading = coords.w,
                debugPoly = false,
                minZ = coords.z - 1.0,
                maxZ = coords.z + 1.0,
            }, options)

            spawnedTargets[zoneName] = true
        end
    end
end


CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(100) end
    RefreshStashTargets()
end)

RegisterNetEvent("skapPersonalStashes:openEmployeeMenu", function(data)
    TriggerServerEvent("skapPersonalStashes:getAllEmployees", data.stashKey)   
end)

RegisterNetEvent("skapPersonalStashes:setStashPinMenu", function(data)
    local stashKey = data.stashKey
    local input = lib.inputDialog("Ange ny pinkod", {
        { type = "input", label = "Pinkod (4–10 siffror)", password = true, min = 4, max = 10, required = true }
    })

    if input and input[1] then
        TriggerServerEvent("skapPersonalStashes:setStashPin", stashKey, input[1])
        Wait(300)
        RefreshStashTargets()
    end
end)

RegisterNetEvent("skapPersonalStashes:showEmployeeMenu", function(employees)
    if #employees == 0 then
        lib.notify({ title = "Förråd", description = "Inga anställda hittades.", type = "info" })
        return
    end

    local options = {}
    for _, emp in ipairs(employees) do
        local prefix = ""
        if Config.ShowOnlineStatus then
            prefix = emp.isOnline and "🟢 " or "🔴 "
        end
        
        table.insert(options, {
            title = prefix .. emp.name,
        
            description = emp.citizenid,
            icon = emp.isOnline and "user-check" or "user-times",
            onSelect = function()
                TriggerEvent("skapPersonalStashes:openStashAsBoss", {
                    citizenid = emp.citizenid,
                    stashKey = emp.stashKey
                })
            end
        })
    end
    lib.registerContext({
        id = "employee_stash_menu",
        title = "👤 Anställdas förråd",
        options = options
    })

    lib.showContext("employee_stash_menu")
end)

RegisterNetEvent("skapPersonalStashes:openStashAsBoss", function(data)
    local stashName = "stash_" .. data.stashKey .. "_" .. data.citizenid
    local config = Config.Stashes[data.stashKey] or {}
    TriggerServerEvent("skapPersonalStashes:logOpenStash", data.stashKey, data.citizenid)
    TriggerServerEvent("inventory:server:OpenInventory", "stash", stashName, {
        maxweight = config.MaxWeight or 40000,
        slots = config.MaxSlots or 40
    })
    TriggerEvent("inventory:client:SetCurrentStash", stashName)
end)

RegisterNetEvent("skapPersonalStashes:openPersonalStash", function()
    local Player = QBCore.Functions.GetPlayerData()
    local stashKey = nil

    local pos = GetEntityCoords(PlayerPedId())
    for key, data in pairs(Config.Stashes) do
        local dist = #(pos - vector3(data.coords.x, data.coords.y, data.coords.z))
        if dist <= 2.5 then
            stashKey = key
            break
        end
    end

    if not stashKey then
        QBCore.Functions.Notify("Ingen stash hittad", "error")
        return
    end

    MakePedTalk(stashKey)
    AnimatePedInteraction(stashKey)

    local config = Config.Stashes[stashKey] or {}
    local stashType = config.stashType or "personal"
    local stashName

    if stashType == "shared" then
        stashName = "stash_" .. stashKey 
    elseif stashType == "secure" then
        stashName = "stash_" .. stashKey .. "_boss"
    else
        stashName = "stash_" .. stashKey .. "_" .. Player.citizenid
    end

    local jobName, _, gangName, _ = GetGroupName()
    local allowed = false
    if config.job and config.job == jobName then
        allowed = true
    elseif config.gang and config.gang == gangName then
        allowed = true
    end

    if not allowed then
        QBCore.Functions.Notify("Du har inte behörighet att öppna detta förråd.", "error")
        return
    end

    if Config.UseStashPin then
        local input = lib.inputDialog("Pinkod krävs", {
            { type = "input", label = "Ange pinkod", password = true, required = true }
        })

        if not input or not input[1] then
            QBCore.Functions.Notify("Pinkod krävs.", "error")
            return
        end

        TriggerServerEvent("skapPersonalStashes:verifyStashPin", stashKey, input[1], stashName)
        return
    end

    TriggerServerEvent("skapPersonalStashes:logOpenStash", stashKey, Player.citizenid)
    TriggerServerEvent("inventory:server:OpenInventory", "stash", stashName, {
        maxweight = config.MaxWeight or 40000,
        slots = config.MaxSlots or 40
    })
    TriggerEvent("inventory:client:SetCurrentStash", stashName)
end)

RegisterNetEvent("skapPersonalStashes:openStashWithPin", function(stashName, maxweight, slots)
    TriggerServerEvent("inventory:server:OpenInventory", "stash", stashName, {
        maxweight = maxweight or 40000,
        slots = slots or 40
    })
    TriggerEvent("inventory:client:SetCurrentStash", stashName)
end)


RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job)
    Wait(250)
    RefreshStashTargets()
end)

function AnimatePedInteraction(stashKey)
    local data = Config.Stashes[stashKey]
    if not data then return end

    if data.type == "ped" and Config.EnablePedAnimation then
        local ped = spawnedPeds[stashKey]
        if not ped or not DoesEntityExist(ped) then return end

        local propModel = Config.PedCarryProp or "prop_ld_suitcase_01"
        local originalPos = GetEntityCoords(ped)
        local originalHeading = GetEntityHeading(ped)
        local backPos = GetOffsetFromEntityInWorldCoords(ped, 0.0, -2.0, 0.0) 

        FreezeEntityPosition(ped, false)

        local propHash = GetHashKey(propModel)
        RequestModel(propHash)
        while not HasModelLoaded(propHash) do Wait(10) end

        local groundProp = CreateObject(propHash, backPos.x, backPos.y, backPos.z - 1.0, true, true, true)
        SetEntityHeading(groundProp, originalHeading)

        TaskGoStraightToCoord(ped, backPos.x, backPos.y, backPos.z, 1.0, -1, originalHeading, 0.0)
        Wait(2000)

        RequestAnimDict("pickup_object")
        while not HasAnimDictLoaded("pickup_object") do Wait(10) end
        TaskPlayAnim(ped, "pickup_object", "pickup_low", 8.0, -8.0, 1500, 0, 0, false, false, false)
        Wait(1600)
        DeleteEntity(groundProp)

        local carryProp = CreateObject(propHash, 0, 0, 0, true, true, true)
        AttachEntityToEntity(carryProp, ped, GetPedBoneIndex(ped, 28422), 0.15, 0.0, -0.02, 0.0, 90.0, 240.0, true, true, false, true, 1, true)

        TaskGoStraightToCoord(ped, originalPos.x, originalPos.y, originalPos.z, 1.0, -1, originalHeading, 0.0)
        Wait(2000)

        RequestAnimDict("mp_common")
        while not HasAnimDictLoaded("mp_common") do Wait(10) end
        TaskPlayAnim(ped, "mp_common", "givetake1_a", 8.0, -8.0, 1500, 0, 0, false, false, false)
        Wait(1600)

        DetachEntity(carryProp, true, true)
        DeleteEntity(carryProp)
        ClearPedTasks(ped)
        SetEntityHeading(ped, originalHeading)
        FreezeEntityPosition(ped, true)
        return
    end

    if data.type == "prop" and Config.PropAnimation then
        local player = PlayerPedId()
        local coords = data.coords
        local heading = coords.w

        TaskGoStraightToCoord(player, coords.x, coords.y, coords.z, 1.0, -1, heading, 0.0)
        Wait(1500)

        local animDict = "mini@safe_cracking"
        local animName = "dial_turn_anti_fast"
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do Wait(10) end
        
        local heading = 70.42
        local distance = 0.6 
        
        local offsetX = math.cos(math.rad(heading - 90.0)) * distance
        local offsetY = math.sin(math.rad(heading - 90.0)) * distance
        
        local backOffset = 0.3 
        local backX = math.cos(math.rad(heading)) * backOffset
        local backY = math.sin(math.rad(heading)) * backOffset


        local camX = 231.66 + offsetX - backX
        local camY = -807.45 + offsetY - backY        
        local camZ = 30.45 + 0.6  
        
        local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA",
        230.00, -807.98, 31.15,
        0.00, 0.00, 278.42,      
        50.00,
        false, 0
    )

        SetCamActive(cam, true)
        RenderScriptCams(true, true, 1000, true, true)
    
        TaskPlayAnim(player, animDict, animName, 8.0, -8.0, 6000, 0, 0, false, false, false)
        Wait(6000)

        ClearPedTasks(player)
        RenderScriptCams(false, true, 1000, true, true)
        DestroyCam(cam, false)

        return
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', RefreshStashTargets)