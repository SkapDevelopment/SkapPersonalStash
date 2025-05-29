local spawnedPeds = {}
local spawnedTargets = {}

CreateThread(function()
    for job, data in pairs(Config.Stashes) do
        local coords = data.coords
        local model = data.model

        RequestModel(model)
        while not HasModelLoaded(model) do Wait(100) end

        if data.type == "ped" then
            local ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, false, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            FreezeEntityPosition(ped, true)
            spawnedPeds[job] = ped
        elseif data.type == "prop" then
            local prop = CreateObject(model, coords.x, coords.y, coords.z - 1.0, false, false, false)
            SetEntityHeading(prop, coords.w)
            FreezeEntityPosition(prop, true)
        end
    end
end)

function RefreshStashTargets()
    local Player = QBCore.Functions.GetPlayerData()
    if not Player or not Player.job then return end

    for stashName, _ in pairs(spawnedTargets) do
        exports['qb-target']:RemoveZone(stashName)
    end
    spawnedTargets = {}

    for job, data in pairs(Config.Stashes) do
        local coords = data.coords
        local zoneName = "stashzone_" .. job

        local options = {
            options = {
                {
                    type = "client",
                    event = "skapPersonalStashes:openPersonalStash",
                    icon = "fas fa-box-open",
                    label = "Open stash",
                    job = job
                }
            },
            distance = 2.0
        }

        if Player.job.name == job and Player.job.isboss then
            table.insert(options.options, {
                type = "client",
                event = "skapPersonalStashes:openEmployeeMenu",
                icon = "fas fa-users",
                label = "Open employees stash",
                job = job
            })
        end

        exports['qb-target']:AddBoxZone(zoneName, vector3(coords.x, coords.y, coords.z), 1.5, 1.5, {
            name = zoneName,
            heading = coords.w,
            debugPoly = false,
            minZ = coords.z - 1,
            maxZ = coords.z + 1,
        }, options)

        spawnedTargets[zoneName] = true
    end
end

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do Wait(100) end
    RefreshStashTargets()
end)

RegisterNetEvent("skapPersonalStashes:openEmployeeMenu", function()
    local Player = QBCore.Functions.GetPlayerData()
    local job = Player.job.name

    if Config.Stashes[job] then
        TriggerServerEvent("skapPersonalStashes:getAllEmployees", job)
    else
        QBCore.Functions.Notify("You don't have access to this", "error")
    end
end)

RegisterNetEvent("skapPersonalStashes:showEmployeeMenu", function(employees)
    if #employees == 0 then
        lib.notify({
            title = "Stash",
            description = "No employess founded.",
            type = "info"
        })
        return
    end

    local options = {}

    for _, emp in ipairs(employees) do
        table.insert(options, {
            title = emp.name,
            description = emp.citizenid,
            icon = "box-open",
            onSelect = function()
                TriggerEvent("skapPersonalStashes:openStashAsBoss", {
                    citizenid = emp.citizenid
                })
            end
        })
    end

    lib.registerContext({
        id = "employee_stash_menu",
        title = "👤 Employess stash",
        options = options
    })

    lib.showContext("employee_stash_menu")
end)


RegisterNetEvent("skapPersonalStashes:openStashAsBoss", function(data)
    local Player = QBCore.Functions.GetPlayerData()
    local job = Player.job.name
    local stashName = "stash_" .. job .. "_" .. data.citizenid

    local config = Config.Stashes[job] or {}
    local maxWeight = config.MaxWeight or 40000
    local maxSlots = config.MaxSlots or 40

    TriggerServerEvent("skapPersonalStashes:logOpenStash", job, data.citizenid)
    TriggerServerEvent("inventory:server:OpenInventory", "stash", stashName, {
        maxweight = maxWeight,
        slots = maxSlots
    })
    TriggerEvent("inventory:client:SetCurrentStash", stashName)
end)

RegisterNetEvent("skapPersonalStashes:openPersonalStash", function()
    local Player = QBCore.Functions.GetPlayerData()
    local citizenid = Player.citizenid
    local job = Player.job.name
    local stashName = "stash_" .. job .. "_" .. citizenid

    local config = Config.Stashes[job] or {}
    local maxWeight = config.MaxWeight or 40000
    local maxSlots = config.MaxSlots or 40

    TriggerServerEvent("skapPersonalStashes:logOpenStash", job, citizenid)
    TriggerServerEvent("inventory:server:OpenInventory", "stash", stashName, {
        maxweight = maxWeight,
        slots = maxSlots
    })
    TriggerEvent("inventory:client:SetCurrentStash", stashName)
end)

RegisterNetEvent("skapPersonalStashes:addItemToStash", function(data)
    TriggerServerEvent("skapPersonalStashes:addItemToPlayerStash", data.citizenid, data.item, data.amount)
end)

RegisterNetEvent("skapPersonalStashes:removeItemFromStash", function(data)
    TriggerServerEvent("skapPersonalStashes:removeItemFromPlayerStash", data.citizenid, data.item, data.amount)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    RefreshStashTargets()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    RefreshStashTargets()
end)
