local stashPins = {}

function getEmployees(stashKey)
    local stashData = Config.Stashes[stashKey]
    local isGang = stashData.gang ~= nil
    local targetName = isGang and stashData.gang or stashData.job
    local employees = {}

    local people = MySQL.query.await('SELECT * FROM players', {})
    for _, v in pairs(people) do 
        local match = false

        if Config.UseMultiJob then
            local jobs = exports['ps-multijob']:GetJobs(v.citizenid)
            if isGang and jobs and jobs[targetName] then match = true end
            if not isGang and jobs and jobs[targetName] then match = true end
        else
            local decoded = json.decode(v.job)
            local decodedGang = json.decode(v.gang)
            if not isGang and decoded and decoded.name == targetName then match = true end
            if isGang and decodedGang and decodedGang.name == targetName then match = true end
        end

        if match then
            local p = QBCore.Functions.GetPlayerByCitizenId(v.citizenid) or QBCore.Functions.GetOfflinePlayerByCitizenId(v.citizenid)
            if p and p.PlayerData and p.PlayerData.charinfo then
                table.insert(employees, {
                    citizenid = v.citizenid,
                    name = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname,
                    stashKey = stashKey
                })
            end
        end
    end
    return employees
end

RegisterNetEvent("skapPersonalStashes:getAllEmployees", function(stashKey)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local stashData = Config.Stashes[stashKey]
    if not stashData then return end

    local job = Player.PlayerData.job.name
    local gang = Player.PlayerData.gang and Player.PlayerData.gang.name or nil
    local grade = type(Player.PlayerData.job.grade) == "table" and Player.PlayerData.job.grade.level or Player.PlayerData.job.grade
    local isBoss = false

    if stashData.job and job == stashData.job and grade >= (stashData.BossGrade or 2) then
        isBoss = true
    elseif stashData.gang and gang == stashData.gang and Player.PlayerData.gang.grade >= (stashData.BossGrade or 2) then
        isBoss = true
    end

    if not isBoss then
        TriggerClientEvent("QBCore:Notify", src, "You are not authorized", "error")
        return
    end

    local employees = getEmployees(stashKey)
    if #employees == 0 then
        TriggerClientEvent("QBCore:Notify", src, "No employees found", "error")
        return
    end

    TriggerClientEvent("skapPersonalStashes:showEmployeeMenu", src, employees)
end)

function getEmployees(stashKey)
    local stashData = Config.Stashes[stashKey]
    if not stashData then return {} end

    local jobName = stashData.job
    local gangName = stashData.gang
    local isGang = stashData.isGang or false
    local queryKey = isGang and gangName or jobName
    local field = isGang and "$.gang.name" or "$.job.name"

    local employees = {}

    local results = MySQL.query.await("SELECT citizenid, charinfo FROM players WHERE JSON_EXTRACT("..(isGang and "gang" or "job")..", '$.name') = ?", { queryKey })


    for _, row in ipairs(results) do
        local charinfo = json.decode(row.charinfo or "{}")
        local firstname = charinfo.firstname or "Okänd"
        local lastname = charinfo.lastname or ""
        local fullname = firstname .. " " .. lastname
    
        local online = false
        for _, pid in pairs(QBCore.Functions.GetPlayers()) do
            local xPlayer = QBCore.Functions.GetPlayer(pid)
            if xPlayer and xPlayer.PlayerData.citizenid == row.citizenid then
                online = true
                break
            end
        end
    
        table.insert(employees, {
            name = fullname,
            citizenid = row.citizenid,
            stashKey = stashKey,
            isOnline = online
        })
    end

    return employees
end


RegisterNetEvent("skapPersonalStashes:addItemToPlayerStash", function(citizenid, itemName, amount)
    local src = source
    local player = QBCore.Functions.GetPlayerByCitizenId(citizenid)

    if not player then return print("Player not found for citizenid: " .. citizenid) end

    local item = player.Functions.GetItemByName(itemName)
    if not item or item.amount < amount then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid item or quantity.', 'error')
        return
    end

    player.Functions.RemoveItem(itemName, amount)
    TriggerClientEvent('QBCore:Notify', src, 'Item added to stash', 'success')

    local result = exports.oxmysql:executeSync("SELECT amount FROM skapdevzstash WHERE citizenid = ? AND item_name = ?", { citizenid, itemName })
    if result and result[1] then
        exports.oxmysql:execute("UPDATE skapdevzstash SET amount = amount + ? WHERE citizenid = ? AND item_name = ?", { amount, citizenid, itemName })
    else
        exports.oxmysql:execute("INSERT INTO skapdevzstash (citizenid, item_name, amount) VALUES (?, ?, ?)", { citizenid, itemName, amount })
    end
end)

RegisterNetEvent("skapPersonalStashes:removeItemFromStash", function(citizenid, itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local result = exports.oxmysql:executeSync("SELECT amount FROM skapdevzstash WHERE citizenid = ? AND item_name = ?", { citizenid, itemName })
    local currentAmount = result[1] and result[1].amount or 0

    if currentAmount < amount then
        TriggerClientEvent("QBCore:Notify", src, "Too little in stock!", "error")
        return
    end

    if currentAmount == amount then
        exports.oxmysql:execute("DELETE FROM skapdevzstash WHERE citizenid = ? AND item_name = ?", { citizenid, itemName })
    else
        exports.oxmysql:execute("UPDATE skapdevzstash SET amount = amount - ? WHERE citizenid = ? AND item_name = ?", { amount, citizenid, itemName })
    end

    Player.Functions.AddItem(itemName, amount)
    TriggerClientEvent("inventory:client:ItemBox", src, QBCore.Shared.Items[itemName], "add")
    TriggerClientEvent("skapPersonalStashes:takeItemsFromStash", src, { citizenid = citizenid })
end)

QBCore.Functions.CreateCallback("skapPersonalStashes:getStashItems", function(source, cb, citizenid)
    local stashItems = exports.oxmysql:executeSync("SELECT item_name AS name, amount FROM skapdevzstash WHERE citizenid = ?", { citizenid })
    for _, item in ipairs(stashItems) do
        item.label = QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].label or "Okänt föremål"
    end
    cb(stashItems or {})
end)

RegisterNetEvent("skapPersonalStashes:setStashPin", function(stashKey, pin)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local stashData = Config.Stashes[stashKey]
    if not stashData then return end

    local job = Player.PlayerData.job.name
    local gang = Player.PlayerData.gang and Player.PlayerData.gang.name or nil
    local grade = type(Player.PlayerData.job.grade) == "table" and Player.PlayerData.job.grade.level or Player.PlayerData.job.grade
    local bossGrade = stashData.BossGrade or 2

    local allowed = false
    if stashData.job and stashData.job == job and grade >= bossGrade then allowed = true end
    if stashData.gang and stashData.gang == gang and Player.PlayerData.gang.grade >= bossGrade then allowed = true end

    if not allowed then
        TriggerClientEvent("QBCore:Notify", src, "You are not authorized to change the PIN code.", "error")
        return
    end

    exports.oxmysql:execute("REPLACE INTO skapdevzstash_pins (stash_key, pin) VALUES (?, ?)", { stashKey, pin })
    TriggerClientEvent("QBCore:Notify", src, "Pin code updated!", "success")
end)

QBCore.Functions.CreateCallback("skapPersonalStashes:getStashPin", function(source, cb, stashKey)
    local result = exports.oxmysql:executeSync("SELECT pin FROM skapdevzstash_pins WHERE stash_key = ?", { stashKey })
    cb(result[1] and result[1].pin or nil)
end)

local stashPins = {}

function LoadStashPin(stashKey, cb)
    if stashPins[stashKey] then
        cb(stashPins[stashKey])
        return
    end

    exports.oxmysql:execute('SELECT pin FROM skapdevzstash_pins WHERE stash_key = ?', { stashKey }, function(result)
        if result[1] then
            stashPins[stashKey] = result[1].pin
            cb(result[1].pin)
        else
            cb(nil)
        end
    end)
end

RegisterNetEvent("skapPersonalStashes:verifyStashPin", function(stashKey, inputPin, stashName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    LoadStashPin(stashKey, function(correctPin)
        if not correctPin then
            TriggerClientEvent("QBCore:Notify", src, "No pin code is set.", "error")
            return
        end

        if tostring(inputPin) == tostring(correctPin) then
            local config = Config.Stashes[stashKey] or {}
            local maxweight = config.MaxWeight or 40000
            local slots = config.MaxSlots or 40

            TriggerClientEvent("skapPersonalStashes:openStashWithPin", src, stashName, maxweight, slots)
            TriggerEvent("skapPersonalStashes:logOpenStash", stashKey, Player.PlayerData.citizenid)
        else
            TriggerClientEvent("QBCore:Notify", src, "Wrong pin code.", "error")
        end
    end)
end)



AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        MySQL.Async.fetchAll('SELECT * FROM skapdevzstash', {}, function(results)
            for _, row in ipairs(results) do
                local Player = QBCore.Functions.GetPlayerByCitizenId(row.citizenid)
                if Player then
                    Player.Functions.AddItem(row.item_name, row.amount)
                end
            end
        end)
    end
end)
