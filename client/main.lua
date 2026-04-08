-- DG-Bridge Client
-- Framework detection and utilities for client-side

local Framework = nil
local frameworkName = nil

-- Detect framework on startup
local function detectFramework()
    local cfg = Config and Config.Framework and Config.Framework:lower() or 'auto'
    if cfg == 'qbcore' then
        if GetResourceState('qb-core') == 'started' then
            Framework = exports['qb-core']:GetCoreObject()
            frameworkName = 'qbcore'
            print('^2[DG-Bridge] Forced framework: QBCore^0')
        end
    elseif cfg == 'qbox' then
        if GetResourceState('qbx-core') == 'started' then
            Framework = exports['qbx-core']:GetCoreObject()
            frameworkName = 'qbox'
            print('^2[DG-Bridge] Forced framework: Qbox^0')
        end
    elseif cfg == 'esx' then
        if GetResourceState('es_extended') == 'started' then
            Framework = exports['es_extended']:getSharedObject()
            frameworkName = 'esx'
            print('^2[DG-Bridge] Forced framework: ESX^0')
        end
    elseif cfg == 'standalone' then
        Framework = nil
        frameworkName = 'standalone'
        print('^2[DG-Bridge] Forced Standalone mode^0')
    else
        -- auto-detect
        if GetResourceState('qb-core') == 'started' then
            Framework = exports['qb-core']:GetCoreObject()
            frameworkName = 'qbcore'
            print('^2[DG-Bridge] Detected framework: QBCore^0')
        elseif GetResourceState('qbx-core') == 'started' then
            Framework = exports['qbx-core']:GetCoreObject()
            frameworkName = 'qbox'
            print('^2[DG-Bridge] Detected framework: Qbox^0')
        elseif GetResourceState('es_extended') == 'started' then
            Framework = exports['es_extended']:getSharedObject()
            frameworkName = 'esx'
            print('^2[DG-Bridge] Detected framework: ESX^0')
        else
            Framework = nil
            frameworkName = 'standalone'
            print('^2[DG-Bridge] Running in Standalone mode^0')
        end
    end
end

CreateThread(detectFramework)

-- Export: Get framework object
function getFramework()
    return Framework
end

-- Export: Check if QBCore
function isQBCore()
    return frameworkName == 'qbcore'
end

-- Export: Check if ESX
function isESX()
    return frameworkName == 'esx'
end

-- Export: Check if Standalone
function isStandalone()
    return frameworkName == 'standalone'
end

-- Export: Get player data (framework-agnostic)
function getPlayerData()
    if Framework and Framework.Functions and Framework.Functions.GetPlayerData then
        return Framework.Functions.GetPlayerData()
    elseif Framework and Framework.GetPlayerData then
        return Framework.GetPlayerData()
    end
    return nil
end

-- Listen for framework player loaded events
RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    TriggerEvent('dg-bridge:playerLoaded')
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function()
    TriggerEvent('dg-bridge:playerLoaded')
end)

-- Export: Show notification (framework-agnostic)
function notify(message, type, duration)
    type = type or 'info'
    duration = duration or 5000
    
    if frameworkName == 'qbcore' and Framework and Framework.Functions then
        Framework.Functions.Notify(message, type, duration)
    elseif frameworkName == 'esx' and Framework then
        Framework.ShowNotification(message)
    else
        -- Fallback to basic notification
        SetNotificationTextEntry('STRING')
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end

-- Client event: Receive notification from server
RegisterNetEvent('dg-bridge:notify')
AddEventHandler('dg-bridge:notify', function(message, type, duration)
    notify(message, type, duration)
end)

-- Export: Get player job (client-side)
function getJob()
    local playerData = getPlayerData()
    if playerData then
        if frameworkName == 'qbcore' and playerData.job then
            return playerData.job.name, playerData.job.grade.level, playerData.job.label
        elseif frameworkName == 'esx' and playerData.job then
            return playerData.job.name, playerData.job.grade, playerData.job.label
        end
    end
    return 'unemployed', 0, 'Unemployed'
end

-- Export: Get player money (client-side)
function getMoney(moneyType)
    moneyType = moneyType or 'cash'
    local playerData = getPlayerData()
    
    if playerData then
        if frameworkName == 'qbcore' and playerData.money then
            return playerData.money[moneyType] or 0
        elseif frameworkName == 'esx' and playerData.accounts then
            for _, account in ipairs(playerData.accounts) do
                if account.name == moneyType or (moneyType == 'cash' and account.name == 'money') then
                    return account.money or 0
                end
            end
        end
    end
    return 0
end

-- Export: Get player gang (QBCore only)
function getGang()
    local playerData = getPlayerData()
    if frameworkName == 'qbcore' and playerData and playerData.gang then
        return playerData.gang.name, playerData.gang.grade.level, playerData.gang.label
    end
    return 'none', 0, 'No Gang'
end

-- Export: Get character name
function getCharName()
    local playerData = getPlayerData()
    if frameworkName == 'qbcore' and playerData and playerData.charinfo then
        return playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname
    elseif frameworkName == 'esx' and playerData then
        return playerData.name or GetPlayerName(PlayerId())
    end
    return GetPlayerName(PlayerId())
end

-- Export: Teleport player (client-side handler)
RegisterNetEvent('dg-bridge:teleport')
AddEventHandler('dg-bridge:teleport', function(coords)
    local ped = PlayerPedId()
    if type(coords) == 'table' then
        coords = vector3(coords.x or coords[1], coords.y or coords[2], coords.z or coords[3])
    end
    
    -- Fade out
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Teleport
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    
    -- Fade in
    Wait(100)
    DoScreenFadeIn(500)
end)

-- Export: Draw 3D text
function draw3DText(coords, text, scale)
    scale = scale or 0.35
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoord())
    
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 20, 20, 20, 150)
    end
end

-- Export: Check if player has item (client prediction)
function hasItem(itemName)
    local playerData = getPlayerData()
    if frameworkName == 'qbcore' and playerData and playerData.items then
        for _, item in pairs(playerData.items) do
            if item.name == itemName and item.amount > 0 then
                return true, item.amount
            end
        end
    elseif frameworkName == 'esx' and playerData and playerData.inventory then
        for _, item in ipairs(playerData.inventory) do
            if item.name == itemName and item.count > 0 then
                return true, item.count
            end
        end
    end
    return false, 0
end

-- Client event: Revive player
RegisterNetEvent('dg-bridge:revive')
AddEventHandler('dg-bridge:revive', function()
    local ped = PlayerPedId()
    
    -- Try framework-specific revive events first
    if frameworkName == 'qbcore' or frameworkName == 'qbox' then
        TriggerEvent('hospital:client:Revive')
    elseif frameworkName == 'esx' then
        TriggerEvent('esx_ambulancejob:revive')
    elseif frameworkName == 'standalone' then
        -- No framework, use fallback only
    else
        -- Try other common revive events for compatibility
        TriggerEvent('hospital:client:Revive')
        TriggerEvent('esx_ambulancejob:revive')
    end
    
    -- Universal fallback using natives
    if IsPedDeadOrDying(ped, 1) then
        local coords = GetEntityCoords(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, false)
        SetEntityInvincible(ped, false)
        ClearPedTasksImmediately(ped)
    end
    
    -- Set health and armor
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    ClearPedBloodDamage(ped)
end)

-- Client event: Teleport player
RegisterNetEvent('dg-bridge:teleport')
AddEventHandler('dg-bridge:teleport', function(coords)
    local ped = PlayerPedId()
    if type(coords) == 'table' then
        SetEntityCoords(ped, coords.x or coords[1], coords.y or coords[2], coords.z or coords[3], false, false, false, false)
    elseif type(coords) == 'vector3' then
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    end
end)

-- Client event: Vehicle keys received
RegisterNetEvent('dg-bridge:vehicleKeys')
AddEventHandler('dg-bridge:vehicleKeys', function(plate)
    -- Placeholder for custom key systems
    -- Can be expanded based on server's vehicle key script
end)

-- Client event: Remove all weapons from player
RegisterNetEvent('dg-bridge:removeWeapons')
AddEventHandler('dg-bridge:removeWeapons', function()
    local ped = PlayerPedId()
    
    -- Remove all weapons using native
    RemoveAllPedWeapons(ped, true)
    
    -- Clear weapon components
    SetPedWeaponTintIndex(ped, GetSelectedPedWeapon(ped), 0)
end)

-- Client event: Give weapons to player
RegisterNetEvent('dg-bridge:giveWeapons')
AddEventHandler('dg-bridge:giveWeapons', function(weapons)
    local ped = PlayerPedId()
    
    weapons = weapons or {'WEAPON_PISTOL', 'WEAPON_SMG'}
    
    for _, weaponName in ipairs(weapons) do
        -- Ensure weapon name is uppercase and has WEAPON_ prefix
        local weapon = weaponName:upper()
        if not weapon:find('WEAPON_') then
            weapon = 'WEAPON_' .. weapon
        end
        
        -- Get weapon hash
        local weaponHash = GetHashKey(weapon)
        
        -- Give weapon to ped
        GiveWeaponToPed(ped, weaponHash, 999, false, true)
        SetPedAmmo(ped, weaponHash, 999)
    end
end)

print('^2[DG-Bridge] Client initialized^0')
