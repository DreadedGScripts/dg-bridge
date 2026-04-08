-- DG-Bridge Server
-- Framework detection and utilities for server-side

local frameworkName = nil
local Framework = nil

local function detectInventoryResource()
    local candidates = {
        'ox_inventory',
        'qb-inventory',
        'ps-inventory',
        'lj-inventory',
        'qs-inventory',
        'codem-inventory'
    }

    for _, resourceName in ipairs(candidates) do
        if GetResourceState(resourceName) == 'started' then
            return resourceName
        end
    end

    return nil
end

local function callInventoryExport(resourceName, exportName, ...)
    if not resourceName or GetResourceState(resourceName) ~= 'started' then
        return false, nil
    end

    local exportTable = exports[resourceName]
    if not exportTable then
        return false, nil
    end

    local exportFn = exportTable[exportName]
    if type(exportFn) ~= 'function' then
        return false, nil
    end

    local ok, result = pcall(exportFn, ...)
    if not ok then
        return false, nil
    end

    return true, result
end

local function normalizeInventoryList(rawInventory)
    local normalized = {}
    if type(rawInventory) ~= 'table' then
        return normalized
    end

    for fallbackSlot, item in pairs(rawInventory) do
        if type(item) == 'table' then
            local itemName = tostring(item.name or item.item or '')
            local count = tonumber(item.amount) or tonumber(item.count) or tonumber(item.qty) or tonumber(item.quantity) or 0

            if itemName ~= '' and count > 0 then
                table.insert(normalized, {
                    name = itemName,
                    label = tostring(item.label or itemName),
                    amount = count,
                    count = count,
                    weight = tonumber(item.weight) or 0,
                    slot = tonumber(item.slot) or tonumber(item.slotId) or tonumber(fallbackSlot) or 0,
                    metadata = type(item.metadata) == 'table' and item.metadata or (type(item.info) == 'table' and item.info or {})
                })
            end
        end
    end

    return normalized
end

local function tryGetInventoryFromAdapter(src)
    local inventoryResource = detectInventoryResource()
    if not inventoryResource then
        return nil, nil
    end

    if inventoryResource == 'ox_inventory' then
        local okItems, oxItems = callInventoryExport('ox_inventory', 'GetInventoryItems', src)
        if okItems and type(oxItems) == 'table' then
            return normalizeInventoryList(oxItems), inventoryResource
        end

        local okInv, oxInv = callInventoryExport('ox_inventory', 'GetInventory', src)
        if okInv and type(oxInv) == 'table' then
            local rawItems = type(oxInv.items) == 'table' and oxInv.items or oxInv
            return normalizeInventoryList(rawItems), inventoryResource
        end

        return {}, inventoryResource
    end

    local okInv, inv = callInventoryExport(inventoryResource, 'GetInventory', src)
    if okInv and type(inv) == 'table' then
        local rawItems = type(inv.items) == 'table' and inv.items or inv
        return normalizeInventoryList(rawItems), inventoryResource
    end

    local okPlayerInv, playerInv = callInventoryExport(inventoryResource, 'GetPlayerInventory', src)
    if okPlayerInv and type(playerInv) == 'table' then
        local rawItems = type(playerInv.items) == 'table' and playerInv.items or playerInv
        return normalizeInventoryList(rawItems), inventoryResource
    end

    return {}, inventoryResource
end

local function tryGiveItemFromAdapter(src, item, amount, metadata)
    local inventoryResource = detectInventoryResource()
    if not inventoryResource then
        return nil, nil
    end

    if inventoryResource == 'ox_inventory' then
        local ok, result = callInventoryExport('ox_inventory', 'AddItem', src, item, amount, metadata)
        if ok then
            return result ~= false, inventoryResource
        end
        return false, inventoryResource
    end

    local attempts = {
        { 'AddItem', src, item, amount, false, metadata },
        { 'AddItem', src, item, amount, metadata },
        { 'AddItem', src, item, amount }
    }

    for _, args in ipairs(attempts) do
        local exportName = args[1]
        local ok, result = callInventoryExport(inventoryResource, exportName, table.unpack(args, 2))
        if ok then
            return result ~= false, inventoryResource
        end
    end

    return false, inventoryResource
end

local function tryRemoveItemFromAdapter(src, item, amount)
    local inventoryResource = detectInventoryResource()
    if not inventoryResource then
        return nil, nil
    end

    if inventoryResource == 'ox_inventory' then
        local ok, result = callInventoryExport('ox_inventory', 'RemoveItem', src, item, amount)
        if ok then
            return result ~= false, inventoryResource
        end
        return false, inventoryResource
    end

    local attempts = {
        { 'RemoveItem', src, item, amount },
        { 'RemoveItem', src, item, amount, false }
    }

    for _, args in ipairs(attempts) do
        local exportName = args[1]
        local ok, result = callInventoryExport(inventoryResource, exportName, table.unpack(args, 2))
        if ok then
            return result ~= false, inventoryResource
        end
    end

    return false, inventoryResource
end

-- Auto-detect framework
local function detectFramework()
    -- Prefer Qbox if both are running
    local qbcoreStarted = GetResourceState('qb-core') == 'started'
    local qboxStarted = GetResourceState('qbx-core') == 'started'
    if qbcoreStarted and qboxStarted then
        return 'qbox'
    elseif qboxStarted then
        return 'qbox'
    elseif qbcoreStarted then
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
    elseif frameworkName == 'qbox' then
        Framework = exports['qbx-core']:GetCoreObject()
        print('^2[DG-Bridge] Detected framework: Qbox^0')
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
    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
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
    
    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
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
    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
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
    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
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
    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
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

    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddMoney(moneyType, amount)
            TriggerEvent('dg-adminpanel:economyActivity', {
                eventType = 'money_add',
                actorId = tonumber(src) or 0,
                actorName = GetPlayerName(src) or 'Unknown',
                actorLicense = getLicense(src),
                targetId = tonumber(src) or 0,
                targetName = GetPlayerName(src) or 'Unknown',
                targetLicense = getLicense(src),
                moneyType = tostring(moneyType or 'cash'),
                moneyAmount = tonumber(amount) or 0,
                context = 'bridge_export',
                details = { framework = frameworkName }
            })
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
            TriggerEvent('dg-adminpanel:economyActivity', {
                eventType = 'money_add',
                actorId = tonumber(src) or 0,
                actorName = GetPlayerName(src) or 'Unknown',
                actorLicense = getLicense(src),
                targetId = tonumber(src) or 0,
                targetName = GetPlayerName(src) or 'Unknown',
                targetLicense = getLicense(src),
                moneyType = tostring(moneyType or 'cash'),
                moneyAmount = tonumber(amount) or 0,
                context = 'bridge_export',
                details = { framework = frameworkName }
            })
            return true
        end
    end
    return false
end

-- Export: Remove money from player
function removeMoney(src, moneyType, amount)
    moneyType = moneyType or 'cash'
    amount = tonumber(amount) or 0

    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveMoney(moneyType, amount)
            TriggerEvent('dg-adminpanel:economyActivity', {
                eventType = 'money_remove',
                actorId = tonumber(src) or 0,
                actorName = GetPlayerName(src) or 'Unknown',
                actorLicense = getLicense(src),
                targetId = tonumber(src) or 0,
                targetName = GetPlayerName(src) or 'Unknown',
                targetLicense = getLicense(src),
                moneyType = tostring(moneyType or 'cash'),
                moneyAmount = tonumber(amount) or 0,
                context = 'bridge_export',
                details = { framework = frameworkName }
            })
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
            TriggerEvent('dg-adminpanel:economyActivity', {
                eventType = 'money_remove',
                actorId = tonumber(src) or 0,
                actorName = GetPlayerName(src) or 'Unknown',
                actorLicense = getLicense(src),
                targetId = tonumber(src) or 0,
                targetName = GetPlayerName(src) or 'Unknown',
                targetLicense = getLicense(src),
                moneyType = tostring(moneyType or 'cash'),
                moneyAmount = tonumber(amount) or 0,
                context = 'bridge_export',
                details = { framework = frameworkName }
            })
            return true
        end
    end
    return false
end

-- Export: Give item to player
function giveItem(src, item, amount, metadata)
    amount = tonumber(amount) or 1

    local adapterResult, inventoryResource = tryGiveItemFromAdapter(src, item, amount, metadata)
    if adapterResult == true then
        TriggerEvent('dg-adminpanel:economyActivity', {
            eventType = 'item_add',
            actorId = tonumber(src) or 0,
            actorName = GetPlayerName(src) or 'Unknown',
            actorLicense = getLicense(src),
            targetId = tonumber(src) or 0,
            targetName = GetPlayerName(src) or 'Unknown',
            targetLicense = getLicense(src),
            itemName = tostring(item or 'unknown'),
            itemAmount = tonumber(amount) or 1,
            context = 'bridge_export',
            details = { framework = frameworkName, inventory = inventoryResource }
        })
        return true
    end

    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddItem(item, amount, false, metadata)
            TriggerEvent('dg-adminpanel:economyActivity', {
                eventType = 'item_add',
                actorId = tonumber(src) or 0,
                actorName = GetPlayerName(src) or 'Unknown',
                actorLicense = getLicense(src),
                targetId = tonumber(src) or 0,
                targetName = GetPlayerName(src) or 'Unknown',
                targetLicense = getLicense(src),
                itemName = tostring(item or 'unknown'),
                itemAmount = tonumber(amount) or 1,
                context = 'bridge_export',
                details = { framework = frameworkName, inventory = 'framework' }
            })
            return true
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.addInventoryItem(item, amount)
            TriggerEvent('dg-adminpanel:economyActivity', {
                eventType = 'item_add',
                actorId = tonumber(src) or 0,
                actorName = GetPlayerName(src) or 'Unknown',
                actorLicense = getLicense(src),
                targetId = tonumber(src) or 0,
                targetName = GetPlayerName(src) or 'Unknown',
                targetLicense = getLicense(src),
                itemName = tostring(item or 'unknown'),
                itemAmount = tonumber(amount) or 1,
                context = 'bridge_export',
                details = { framework = frameworkName, inventory = 'framework' }
            })
            return true
        end
    end
    return false
end

-- Export: Remove item from player
function removeItem(src, item, amount)
    amount = tonumber(amount) or 1

    local adapterResult, inventoryResource = tryRemoveItemFromAdapter(src, item, amount)
    if adapterResult == true then
        TriggerEvent('dg-adminpanel:economyActivity', {
            eventType = 'item_remove',
            actorId = tonumber(src) or 0,
            actorName = GetPlayerName(src) or 'Unknown',
            actorLicense = getLicense(src),
            targetId = tonumber(src) or 0,
            targetName = GetPlayerName(src) or 'Unknown',
            targetLicense = getLicense(src),
            itemName = tostring(item or 'unknown'),
            itemAmount = tonumber(amount) or 1,
            context = 'bridge_export',
            details = { framework = frameworkName, inventory = inventoryResource }
        })
        return true
    end

    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(item, amount)
            TriggerEvent('dg-adminpanel:economyActivity', {
                eventType = 'item_remove',
                actorId = tonumber(src) or 0,
                actorName = GetPlayerName(src) or 'Unknown',
                actorLicense = getLicense(src),
                targetId = tonumber(src) or 0,
                targetName = GetPlayerName(src) or 'Unknown',
                targetLicense = getLicense(src),
                itemName = tostring(item or 'unknown'),
                itemAmount = tonumber(amount) or 1,
                context = 'bridge_export',
                details = { framework = frameworkName, inventory = 'framework' }
            })
            return true
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.removeInventoryItem(item, amount)
            TriggerEvent('dg-adminpanel:economyActivity', {
                eventType = 'item_remove',
                actorId = tonumber(src) or 0,
                actorName = GetPlayerName(src) or 'Unknown',
                actorLicense = getLicense(src),
                targetId = tonumber(src) or 0,
                targetName = GetPlayerName(src) or 'Unknown',
                targetLicense = getLicense(src),
                itemName = tostring(item or 'unknown'),
                itemAmount = tonumber(amount) or 1,
                context = 'bridge_export',
                details = { framework = frameworkName, inventory = 'framework' }
            })
            return true
        end
    end
    return false
end

-- Export: Get player inventory
function getInventory(src)
    local adapterInventory, inventoryResource = tryGetInventoryFromAdapter(src)
    if adapterInventory ~= nil then
        print('^3[DG-Bridge] Inventory adapter (' .. tostring(inventoryResource) .. ') for player ' .. tostring(src) .. ': ' .. tostring(#adapterInventory) .. ' items^0')
        return adapterInventory
    end

    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.items then
            -- QBCore items can be a table with numeric keys or slot keys
            -- Convert to array format for consistent handling
            local items = {}
            local itemCount = 0
            for slot, item in pairs(Player.PlayerData.items) do
                if item and type(item) == 'table' and item.name then
                    -- Ensure slot is set
                    item.slot = item.slot or slot
                    table.insert(items, item)
                    itemCount = itemCount + 1
                end
            end
            print('^3[DG-Bridge] QBCore inventory for player ' .. src .. ': ' .. itemCount .. ' items')
            return items
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            local inventory = xPlayer.getInventory() or {}
            -- ESX inventory structure: array of items with name, count, label
            local items = {}
            for _, item in pairs(inventory) do
                if item and item.name and item.count and item.count > 0 then
                    table.insert(items, {
                        name = item.name,
                        label = item.label or item.name,
                        amount = item.count,
                        count = item.count,
                        weight = item.weight or 0
                    })
                end
            end
            print('^3[DG-Bridge] ESX inventory for player ' .. src .. ': ' .. (#items) .. ' items')
            return items
        end
    end
    return {}
end

-- Export: Get player gang (QBCore only)
function getPlayerGang(src)
    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
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
    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
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
    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
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
    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
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

    local function hasItem(itemName)
        for _, existing in ipairs(items) do
            if existing.name == itemName then
                return true
            end
        end
        return false
    end

    local function addItemDefinition(itemName, itemData)
        if not itemName or itemName == '' or hasItem(itemName) then
            return
        end

        itemData = type(itemData) == 'table' and itemData or {}
        table.insert(items, {
            name = itemName,
            label = itemData.label or itemName,
            weight = itemData.weight or 0,
            description = itemData.description or itemData.info or '',
            useable = itemData.useable or itemData.usable or itemData.shouldClose or (itemData.consume ~= nil) or false,
            unique = itemData.unique or (itemData.stack == false) or false,
            type = itemData.type or 'item',
            image = itemData.image or (itemName .. '.png')
        })
    end
    
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
                addItemDefinition(itemName, itemData)
                count = count + 1
            end
            print('^2[DG-Bridge] Processed ' .. count .. ' QBCore items^0')
        else
            print('^1[DG-Bridge] ERROR: No QBCore items found by any method!^0')
        end
        
    elseif frameworkName == 'esx' then
        print('^3[DG-Bridge] Retrieving ESX items...^0')
        
        -- Method 1: Try to get from ESX.Items if available (newer ESX Legacy)
        if Framework and Framework.Items then
            local count = 0
            for itemName, itemData in pairs(Framework.Items) do
                addItemDefinition(itemName, itemData)
                count = count + 1
            end
            print('^2[DG-Bridge] Retrieved ' .. count .. ' ESX items from Framework.Items^0')
        else
            print('^3[DG-Bridge] Framework.Items not available, trying database...^0')
            
            -- Method 2: Try to get from database (older ESX)
            if MySQL and MySQL.Sync and MySQL.Sync.fetchAll then
                local dbItems = MySQL.Sync.fetchAll('SELECT * FROM items', {})
                if dbItems then
                    for _, itemData in ipairs(dbItems) do
                        addItemDefinition(itemData.name, itemData)
                    end
                    print('^2[DG-Bridge] Retrieved ' .. #dbItems .. ' ESX items from database^0')
                end
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
                addItemDefinition(itemName, itemData)
            end
        end
    end

    -- Additional inventory adapters (qs/codem/ps/lj etc)
    local inventoryResource = detectInventoryResource()
    if inventoryResource and inventoryResource ~= 'ox_inventory' then
        local adapterItems = nil
        local okList, list = callInventoryExport(inventoryResource, 'GetItemList')
        if okList and type(list) == 'table' then
            adapterItems = list
        else
            local okItems, resultItems = callInventoryExport(inventoryResource, 'GetItems')
            if okItems and type(resultItems) == 'table' then
                adapterItems = resultItems
            else
                local okRaw, rawItems = callInventoryExport(inventoryResource, 'Items')
                if okRaw and type(rawItems) == 'table' then
                    adapterItems = rawItems
                end
            end
        end

        if type(adapterItems) == 'table' then
            for key, itemData in pairs(adapterItems) do
                if type(itemData) == 'table' then
                    local itemName = tostring(itemData.name or key or '')
                    addItemDefinition(itemName, itemData)
                end
            end
        end
    end
    
    print('^2[DG-Bridge] Retrieved ' .. #items .. ' items for item browser^0')
    return items
end

-- Export: Set player job and grade
function setPlayerJob(src, jobName, grade)
    grade = tonumber(grade) or 0
    
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player and Player.Functions then
            Player.Functions.SetJob(jobName, grade)
            return true
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.setJob(jobName, grade)
            return true
        end
    end
    return false
end

-- Export: Get all available jobs from framework
function getAllJobs()
    local jobs = {}
    
    if frameworkName == 'qbcore' and Framework and Framework.Shared and Framework.Shared.Jobs then
        for jobName, jobData in pairs(Framework.Shared.Jobs) do
            jobs[jobName] = {
                label = jobData.label or jobName,
                grades = jobData.grades or {},
                type = jobData.type or 'none',
                defaultDuty = jobData.defaultDuty or false
            }
        end
    elseif frameworkName == 'esx' then
        print('^3[DG-Bridge] Retrieving ESX jobs...^0')
        
        -- Method 1: Try Framework.Jobs (ESX Legacy)
        if Framework and Framework.Jobs then
            for jobName, jobData in pairs(Framework.Jobs) do
                jobs[jobName] = {
                    label = jobData.label or jobName,
                    grades = {}
                }
                -- ESX grades structure
                if jobData.grades then
                    for _, gradeData in pairs(jobData.grades) do
                        jobs[jobName].grades[gradeData.grade] = {
                            name = gradeData.name or 'Unknown',
                            label = gradeData.label or gradeData.name or 'Unknown',
                            salary = gradeData.salary or 0
                        }
                    end
                end
            end
            print('^2[DG-Bridge] Retrieved ' .. tableCount(jobs) .. ' ESX jobs from Framework.Jobs^0')
        else
            print('^3[DG-Bridge] Framework.Jobs not available, trying database...^0')
            
            -- Method 2: Try to get from database (older ESX)
            if MySQL and MySQL.Sync and MySQL.Sync.fetchAll then
                local dbJobs = MySQL.Sync.fetchAll('SELECT * FROM jobs', {})
                if dbJobs then
                    for _, jobData in ipairs(dbJobs) do
                        jobs[jobData.name] = {
                            label = jobData.label or jobData.name,
                            grades = {}
                        }
                    end
                    
                    -- Get job grades
                    local dbGrades = MySQL.Sync.fetchAll('SELECT * FROM job_grades', {})
                    if dbGrades then
                        for _, gradeData in ipairs(dbGrades) do
                            if jobs[gradeData.job_name] then
                                jobs[gradeData.job_name].grades[gradeData.grade] = {
                                    name = gradeData.name or 'Unknown',
                                    label = gradeData.label or gradeData.name or 'Unknown',
                                    salary = gradeData.salary or 0
                                }
                            end
                        end
                    end
                    print('^2[DG-Bridge] Retrieved ' .. #dbJobs .. ' ESX jobs from database^0')
                end
            end
        end
    end
    
    return jobs
end

-- Helper function to count table entries
local function tableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- Export: Revive player (framework-compatible)
function revivePlayer(src)
    -- Trigger client-side revive
    TriggerClientEvent('dg-bridge:revive', src)
    
    -- Framework-specific server-side handling
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player and Player.Functions then
            -- Reset metadata if needed
            Player.Functions.SetMetaData("isdead", false)
            Player.Functions.SetMetaData("inlaststand", false)
        end
    elseif frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            -- ESX revive handling (if custom ambulance)
            TriggerClientEvent('esx_ambulancejob:revive', src)
        end
    end
    
    return true
end

-- Export: Unified revive (framework-agnostic)
function revivePlayer(src, health)
    health = tonumber(health) or 200
    -- Always trigger the unified revive event on the client
    TriggerClientEvent('dg-bridge:revive', src, health)
    -- Also update metadata if using QBCore/Qbox
    if (frameworkName == 'qbcore' or frameworkName == 'qbox') and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player then
            Player.PlayerData.metadata["isdead"] = false
            Player.PlayerData.metadata["inlaststand"] = false
        end
    end
    return true
end

-- Export: Give vehicle keys to player
function giveVehicleKeys(src, plate)
    if not plate or plate == '' then return false end
    
    -- Try multiple vehicle key systems
    if GetResourceState('qb-vehiclekeys') == 'started' then
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
        TriggerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', src, plate)
        return true
    elseif GetResourceState('wasabi_carlock') == 'started' then
        exports.wasabi_carlock:GiveKey(src, plate)
        return true
    elseif GetResourceState('cd_garage') == 'started' then
        TriggerClientEvent('cd_garage:AddKeys', src, plate)
        return true
    elseif GetResourceState('qs-vehiclekeys') == 'started' then
        exports['qs-vehiclekeys']:GiveKeys(src, plate)
        return true
    end
    
    -- Fallback: trigger generic key event
    TriggerClientEvent('dg-bridge:vehicleKeys', src, plate)
    return true
end

-- Export: Get player's framework-specific identifier
function getPlayerIdentifier(src, format)
    format = format or 'auto'
    
    if format == 'auto' then
        if frameworkName == 'qbcore' then
            format = 'citizenid'
        elseif frameworkName == 'esx' then
            format = 'identifier'
        else
            format = 'license'
        end
    end
    
    if format == 'citizenid' and frameworkName == 'qbcore' and Framework and Framework.Functions then
        local Player = Framework.Functions.GetPlayer(src)
        if Player and Player.PlayerData then
            return Player.PlayerData.citizenid
        end
    elseif format == 'identifier' and frameworkName == 'esx' and Framework then
        local xPlayer = Framework.GetPlayerFromId(src)
        if xPlayer then
            return xPlayer.identifier
        end
    end
    
    -- Fallback to license
    return getLicense(src)
end

-- Export: Remove all weapons from player
function removePlayerWeapons(src)
    if not src or src == 0 then return false end
    
    if frameworkName == 'qbcore' and Framework then
        -- QBCore: Remove weapon items
        if Framework.Functions and Framework.Functions.GetPlayer then
            local Player = Framework.Functions.GetPlayer(src)
            if Player and Player.PlayerData and Player.PlayerData.items then
                for slot, item in pairs(Player.PlayerData.items) do
                    if item and item.name and item.name:find('weapon_') then
                        Player.Functions.RemoveItem(item.name, item.amount or 1)
                    end
                end
            end
        end
    elseif frameworkName == 'esx' and Framework then
        -- ESX: Remove all weapons
        if Framework.GetPlayerFromId then
            local xPlayer = Framework.GetPlayerFromId(src)
            if xPlayer then
                -- Get loadout and remove each weapon
                local loadout = xPlayer.getLoadout and xPlayer.getLoadout() or {}
                for _, weapon in ipairs(loadout) do
                    if weapon.name then
                        xPlayer.removeWeapon(weapon.name)
                    end
                end
            end
        end
    end
    
    -- Client-side removal for any framework (uses natives)
    TriggerClientEvent('dg-bridge:removeWeapons', src)
    return true
end

-- Export: Give weapons to player (common troll/admin weapons)
function givePlayerWeapons(src, weapons)
    if not src or src == 0 then return false end
    
    weapons = weapons or {'WEAPON_PISTOL', 'WEAPON_SMG'}
    
    if frameworkName == 'qbcore' and Framework then
        -- QBCore: Add to weapons inventory
        if Framework.Functions and Framework.Functions.GetPlayer then
            local Player = Framework.Functions.GetPlayer(src)
            if Player and Player.Functions then
                for _, weaponName in ipairs(weapons) do
                    local itemName = 'weapon_' .. weaponName:lower():gsub('weapon_', '')
                    Player.Functions.AddItem(itemName, 1, false, {
                        ammo = 999,
                        quality = 100
                    })
                end
            end
        end
    elseif frameworkName == 'esx' and Framework then
        -- ESX: Give weapons directly to player
        if Framework.GetPlayerFromId then
            local xPlayer = Framework.GetPlayerFromId(src)
            if xPlayer and xPlayer.addWeapon then
                for _, weaponName in ipairs(weapons) do
                    -- Ensure weapon name is uppercase and has WEAPON_ prefix
                    local weapon = weaponName:upper()
                    if not weapon:find('WEAPON_') then
                        weapon = 'WEAPON_' .. weapon
                    end
                    xPlayer.addWeapon(weapon, 999)
                end
            end
        end
    end
    
    -- Client-side fallback for any framework (uses GiveWeaponToPed native)
    TriggerClientEvent('dg-bridge:giveWeapons', src, weapons)
    return true
end

-- Server event: Give vehicle keys (triggered from client)
RegisterServerEvent('dg-bridge:giveVehicleKeys')
AddEventHandler('dg-bridge:giveVehicleKeys', function(plate)
    local src = source
    giveVehicleKeys(src, plate)
end)

-- Export: Unified event hooks (player join/leave, death, revive, job change)
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    TriggerEvent('dg-bridge:playerConnecting', source, name)
end)

AddEventHandler('playerDropped', function(reason)
    TriggerEvent('dg-bridge:playerDropped', source, reason)
end)


AddEventHandler('baseevents:onPlayerDied', function(playerId)
    TriggerEvent('dg-bridge:playerDied', playerId)
end)

AddEventHandler('hospital:client:Revive', function()
    TriggerEvent('dg-bridge:playerRevived', source)
end)

print('^2[DG-Bridge] Server initialized^0')
