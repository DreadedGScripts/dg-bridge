-- DG-Bridge Server
-- Framework detection and utilities for server-side

local frameworkName = nil
local Framework = nil

-- Auto-detect framework
local function detectFramework()
    if GetResourceState('qb-core') == 'started' then
        return 'qbcore'
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx'
    else
        return 'standalone'
    end
end

-- Initialize framework on startup
CreateThread(function()
    frameworkName = detectFramework()
    
    if frameworkName == 'qbcore' then
        Framework = exports['qb-core']:GetCoreObject()
        print('^2[DG-Bridge] Detected framework: QBCore^0')
    elseif frameworkName == 'esx' then
        Framework = exports['es_extended']:getSharedObject()
        print('^2[DG-Bridge] Detected framework: ESX^0')
    else
        print('^2[DG-Bridge] Running in Standalone mode^0')
    end
end)

-- Export: Get framework name
function getFramework()
    return frameworkName
end

-- Export: Get license identifier
function getLicense(src)
    if not src or src == 0 then
        return 'N/A'
    end
    for _, v in ipairs(GetPlayerIdentifiers(src)) do
        if v:find("license:") then return v end
    end
    return tostring(src)
end

-- Export: Get specific identifier (steam, discord, etc)
function getIdentifier(src, idType)
    if not src or src == 0 then return 'N/A' end
    
    for _, v in ipairs(GetPlayerIdentifiers(src)) do
        if v:find(idType) then
            -- Handle both steamid64: and steam: formats
            if idType == 'steamid64:' and v:find('steam:') then
                local hex = v:gsub('steam:', '')
                local steamid64 = tonumber(hex, 16)
                if steamid64 then
                    return 'steamid64:' .. tostring(steamid64)
                end
            end
            return v
        end
    end
    return 'N/A'
end

-- Export: Kick player (framework-agnostic)
function kickPlayer(src, reason)
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        Framework.Functions.Kick(src, reason or 'Kicked by admin', nil, nil)
    elseif frameworkName == 'esx' and Framework then
        -- ESX doesn't have built-in kick, use DropPlayer
        DropPlayer(src, reason or 'Kicked by admin')
    else
        DropPlayer(src, reason or 'Kicked by admin')
    end
end

-- Export: Ban player (framework-agnostic)
function banPlayer(src, reason, duration)
    local license = getLicense(src)
    local playerName = GetPlayerName(src) or 'Unknown'
    
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        -- QBCore has built-in ban system
        local banTime = duration and (os.time() + (duration * 3600)) or 9999999999
        Framework.Functions.BanInjection(src, playerName, license, reason, banTime)
    elseif frameworkName == 'esx' then
        -- ESX: Drop player and log ban (requires custom ban system)
        DropPlayer(src, reason or 'Banned')
        -- Trigger custom ban event if exists
        TriggerEvent('esx:banPlayer', src, reason, duration)
    else
        -- Standalone: just drop player
        DropPlayer(src, reason or 'Banned')
    end
end

-- Export: Get player job (framework-agnostic)
function getPlayerJob(src)
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.job then
            return Player.PlayerData.job.name, Player.PlayerData.job.grade.level
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer and xPlayer.job then
            return xPlayer.job.name, xPlayer.job.grade
        end
    end
    return 'unemployed', 0
end

-- Export: Get player money (framework-agnostic)
function getPlayerMoney(src, moneyType)
    moneyType = moneyType or 'cash'
    
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.money then
            return Player.PlayerData.money[moneyType] or 0
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            if moneyType == 'cash' then
                return xPlayer.getMoney() or 0
            elseif moneyType == 'bank' then
                return xPlayer.getAccount('bank').money or 0
            end
        end
    end
    return 0
end

-- Export: Check if player is admin
function isPlayerAdmin(src)
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local hasPermission = IsPlayerAceAllowed(src, 'command.admin') or 
                            IsPlayerAceAllowed(src, 'dg.admin') or
                            IsPlayerAceAllowed(src, 'group.admin')
        return hasPermission
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        return xPlayer and xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin'
    else
        -- Standalone: check ACE permissions
        return IsPlayerAceAllowed(src, 'command.admin') or IsPlayerAceAllowed(src, 'dg.admin')
    end
end

-- Export: Add money to player
function addMoney(src, moneyType, amount)
    moneyType = moneyType or 'cash'
    amount = tonumber(amount) or 0
    
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddMoney(moneyType, amount)
            return true
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            if moneyType == 'cash' or moneyType == 'money' then
                xPlayer.addMoney(amount)
            elseif moneyType == 'bank' then
                xPlayer.addAccountMoney('bank', amount)
            elseif moneyType == 'black_money' then
                xPlayer.addAccountMoney('black_money', amount)
            end
            return true
        end
    end
    return false
end

-- Export: Remove money from player
function removeMoney(src, moneyType, amount)
    moneyType = moneyType or 'cash'
    amount = tonumber(amount) or 0
    
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveMoney(moneyType, amount)
            return true
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            if moneyType == 'cash' or moneyType == 'money' then
                xPlayer.removeMoney(amount)
            elseif moneyType == 'bank' then
                xPlayer.removeAccountMoney('bank', amount)
            elseif moneyType == 'black_money' then
                xPlayer.removeAccountMoney('black_money', amount)
            end
            return true
        end
    end
    return false
end

-- Export: Give item to player
function giveItem(src, item, amount, metadata)
    amount = tonumber(amount) or 1
    
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddItem(item, amount, false, metadata)
            return true
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.addInventoryItem(item, amount)
            return true
        end
    end
    return false
end

-- Export: Remove item from player
function removeItem(src, item, amount)
    amount = tonumber(amount) or 1
    
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(item, amount)
            return true
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.removeInventoryItem(item, amount)
            return true
        end
    end
    return false
end

-- Export: Get player inventory
function getInventory(src)
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player and Player.PlayerData then
            return Player.PlayerData.items or {}
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            return xPlayer.getInventory() or {}
        end
    end
    return {}
end

-- Export: Get player gang (QBCore only)
function getPlayerGang(src)
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.gang then
            return Player.PlayerData.gang.name, Player.PlayerData.gang.grade.level
        end
    end
    return 'none', 0
end

-- Export: Get all player identifiers
function getAllIdentifiers(src)
    if not src or src == 0 then return {} end
    
    local identifiers = {
        license = 'N/A',
        steam = 'N/A',
        discord = 'N/A',
        ip = 'N/A',
        xbl = 'N/A',
        live = 'N/A'
    }
    
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find('license:') then
            identifiers.license = id
        elseif id:find('steam:') then
            identifiers.steam = id
        elseif id:find('discord:') then
            identifiers.discord = id
        elseif id:find('ip:') then
            identifiers.ip = id
        elseif id:find('xbl:') then
            identifiers.xbl = id
        elseif id:find('live:') then
            identifiers.live = id
        end
    end
    
    return identifiers
end

-- Export: Notify player (server-side trigger)
function notifyPlayer(src, message, type, duration)
    TriggerClientEvent('dg-bridge:notify', src, message, type, duration)
end

-- Export: Get player character name
function getCharacterName(src)
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.charinfo then
            return Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            return xPlayer.getName() or GetPlayerName(src)
        end
    end
    return GetPlayerName(src) or 'Unknown'
end

-- Export: Get player metadata
function getMetadata(src, key)
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.metadata then
            return Player.PlayerData.metadata[key]
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            return xPlayer.get(key)
        end
    end
    return nil
end

-- Export: Set player metadata
function setMetadata(src, key, value)
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player and Player.Functions then
            Player.Functions.SetMetaData(key, value)
            return true
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.set(key, value)
            return true
        end
    end
    return false
end

-- Export: Get player coordinates
function getPlayerCoords(src)
    local ped = GetPlayerPed(src)
    if ped > 0 then
        return GetEntityCoords(ped)
    end
    return vector3(0, 0, 0)
end

-- Export: Teleport player
function teleportPlayer(src, coords)
    if type(coords) == 'table' then
        coords = vector3(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3])
    end
    TriggerClientEvent('dg-bridge:teleport', src, coords)
end

-- Export: Get all available items from framework
function getAllItems()
    local items = {}
    
    if frameworkName == 'qbcore' then
        -- Try multiple methods to get QBCore items
        local qbItems = nil
        
        print('^3[DG-Bridge] Attempting to retrieve QBCore items...^0')
        
        -- Method 1: Try Framework.Shared.Items
        if Framework and Framework.Shared and Framework.Shared.Items then
            qbItems = Framework.Shared.Items
            print('^2[DG-Bridge] Method 1 SUCCESS: Framework.Shared.Items found^0')
        else
            print('^1[DG-Bridge] Method 1 FAILED: Framework.Shared.Items not available^0')
        end
        
        -- Method 2: Try direct export from qb-core
        if not qbItems and GetResourceState('qb-core') == 'started' then
            local success, result = pcall(function()
                return exports['qb-core']:GetItems()
            end)
            if success and result then
                qbItems = result
                print('^2[DG-Bridge] Method 2 SUCCESS: exports qb-core GetItems found^0')
            else
                print('^1[DG-Bridge] Method 2 FAILED: qb-core GetItems not available^0')
            end
        end
        
        -- Method 3: Try to get shared object again and check
        if not qbItems then
            local success, QBCore = pcall(function()
                return exports['qb-core']:GetCoreObject()
            end)
            if success and QBCore and QBCore.Shared and QBCore.Shared.Items then
                qbItems = QBCore.Shared.Items
                print('^2[DG-Bridge] Method 3 SUCCESS: Fresh QBCore.Shared.Items found^0')
            else
                print('^1[DG-Bridge] Method 3 FAILED: Fresh GetCoreObject failed^0')
            end
        end
        
        -- Method 4: Try qb-inventory export
        if not qbItems and GetResourceState('qb-inventory') == 'started' then
            local success, result = pcall(function()
                return exports['qb-inventory']:GetItemList()
            end)
            if success and result then
                qbItems = result
                print('^2[DG-Bridge] Method 4 SUCCESS: qb-inventory GetItemList found^0')
            else
                print('^1[DG-Bridge] Method 4 FAILED: qb-inventory GetItemList not available^0')
            end
        end
        
        -- Process QBCore items
        if qbItems then
            local count = 0
            for itemName, itemData in pairs(qbItems) do
                table.insert(items, {
                    name = itemName,
                    label = itemData.label or itemName,
                    weight = itemData.weight or 0,
                    description = itemData.description or itemData.info or '',
                    useable = itemData.useable or itemData.shouldClose or false,
                    unique = itemData.unique or false,
                    type = itemData.type or 'item',
                    image = itemData.image or (itemName .. '.png')
                })
                count = count + 1
            end
            print('^2[DG-Bridge] Processed ' .. count .. ' QBCore items^0')
        else
            print('^1[DG-Bridge] ERROR: No QBCore items found by any method!^0')
        end
        
    elseif frameworkName == 'esx' then
        -- ESX items - Try to get from ESX.Items if available
        if Framework and Framework.Items then
            for itemName, itemData in pairs(Framework.Items) do
                table.insert(items, {
                    name = itemName,
                    label = itemData.label or itemName,
                    weight = itemData.weight or 0,
                    description = itemData.description or '',
                    useable = true,
                    unique = itemData.unique or false,
                    type = 'item',
                    image = itemName .. '.png'
                })
            end
        end
    end
    
    -- Try to load from ox_inventory if available (overrides or adds)
    if GetResourceState('ox_inventory') == 'started' then
        local success, oxItems = pcall(function()
            return exports.ox_inventory:Items()
        end)
        if success and oxItems then
            for itemName, itemData in pairs(oxItems) do
                local exists = false
                for _, existing in ipairs(items) do
                    if existing.name == itemName then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(items, {
                        name = itemName,
                        label = itemData.label or itemName,
                        weight = itemData.weight or 0,
                        description = itemData.description or '',
                        useable = itemData.consume ~= nil or false,
                        unique = itemData.stack == false or false,
                        type = 'item',
                        image = itemName .. '.png'
                    })
                end
            end
        end
    end
    
    print('^2[DG-Bridge] Retrieved ' .. #items .. ' items for item browser^0')
    return items
end

print('^2[DG-Bridge] Server initialized^0')
