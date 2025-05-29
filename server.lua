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
    TriggerClientEvent('QBCore:Notify', src, 'item added in stash', 'success')
    local result = exports.oxmysql:executeSync("SELECT amount FROM skapdevzstash WHERE citizenid = ? AND item_name = ?", { citizenid, itemName })
    if result and result[1] then
        exports.oxmysql:execute("UPDATE skapdevzstash SET amount = amount + ? WHERE citizenid = ? AND item_name = ?", { amount, citizenid, itemName })
    else
        exports.oxmysql:execute("INSERT INTO skapdevzstash (citizenid, item_name, amount) VALUES (?, ?, ?)", { citizenid, itemName, amount })
    end
end)

function getEmployees(job)
    local employees = {}
    local people = MySQL.query.await('SELECT * FROM players', {})
    for _, v in pairs(people) do 
        local jobList = exports['ps-multijob']:GetJobs(v.citizenid)
        if jobList and jobList[job] then 
            local p = QBCore.Functions.GetPlayerByCitizenId(v.citizenid) or QBCore.Functions.GetOfflinePlayerByCitizenId(v.citizenid)

            if p and p.PlayerData and p.PlayerData.charinfo then
                table.insert(employees, {
                    citizenid = v.citizenid,
                    name = p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname
                })
            end
        end
    end
    return employees
end     

RegisterNetEvent("skapPersonalStashes:removeItemFromStash", function(citizenid, itemName, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    local result = exports.oxmysql:executeSync("SELECT amount FROM skapdevzstash WHERE citizenid = ? AND item_name = ?", { citizenid, itemName })
    local currentAmount = result[1] and result[1].amount or 0
    if currentAmount < amount then
        TriggerClientEvent("QBCore:Notify", src, "Too little in the stash!", "error")
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
    local job = Player.PlayerData.job.name
end)

QBCore.Functions.CreateCallback("skapPersonalStashes:getStashItems", function(source, cb, citizenid)
    local stashItems = exports.oxmysql:executeSync("SELECT item_name AS name, amount FROM skapdevzstash WHERE citizenid = ?", { citizenid })
    for _, item in ipairs(stashItems) do
        item.label = QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].label or "Unknown item"
    end
    cb(stashItems or {})
end)

RegisterNetEvent("skapPersonalStashes:logOpenStash", function(job, citizenid)
    local src = source
    local name = GetPlayerName(src)
end)

RegisterNetEvent("skapPersonalStashes:openAllEmployeeStashes", function(job)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    if Player.PlayerData.job.name == job and Player.PlayerData.job.grade >= 2 then
        local employeeList = QBCore.Functions.GetPlayersByJob(job)
        for _, playerId in ipairs(employeeList) do
            local player = QBCore.Functions.GetPlayer(playerId)
            if player then
                local citizenid = player.PlayerData.citizenid
                TriggerClientEvent("skapPersonalStashes:openEmployeeStashMenu", src, citizenid)
            end
        end
    else
        TriggerClientEvent("QBCore:Notify", src, "You do not have the correct authorization to open these stashes.", "error")
    end
end)

QBCore.Functions.CreateCallback("skapPersonalStashes:getStashItems", function(source, cb, citizenid)
    local stashItems = exports.oxmysql:executeSync("SELECT item_name AS name, amount FROM skapdevzstash WHERE citizenid = ?", { citizenid })
    for _, item in ipairs(stashItems) do
        item.label = QBCore.Shared.Items[item.name] and QBCore.Shared.Items[item.name].label or "Unknown Object"
    end
    cb(stashItems or {})
end)

RegisterNetEvent("skapPersonalStashes:getAllEmployees", function(job)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local gradeLevel = type(Player.PlayerData.job.grade) == "table" and Player.PlayerData.job.grade.level or Player.PlayerData.job.grade
    if Player.PlayerData.job.name ~= job or gradeLevel < 2 then
        TriggerClientEvent("QBCore:Notify", src, "You are not authorized", "error")
        return
    end

    local employees = getEmployees(job)
    if #employees == 0 then
        TriggerClientEvent("QBCore:Notify", src, "No employees found", "error")
        return
    end
    TriggerClientEvent("skapPersonalStashes:showEmployeeMenu", src, employees)
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
