-- ==========================================================================
-- DG-Bridge: Commonly Used Scripts Integration (Client-Side)
-- ==========================================================================
-- Client-side wrappers for commonly used FiveM RP scripts

-- ==========================================================================
-- NOTIFY/ALERT SYSTEMS
-- ==========================================================================

local function getNotifyResource()
    local candidates = {
        'ox_lib', 'qb-core', 'mythic_notify', 'okokNotify',
        'ps-notify', 'notify-system'
    }
    for _, res in ipairs(candidates) do
        if GetResourceState(res) == 'started' then return res end
    end
    return nil
end

-- Unified notify wrapper
function notifyClient(type, title, message, duration)
    duration = duration or 5000
    local notifyRes = getNotifyResource()
    
    if not notifyRes then
        print('WARNING: No notification system found')
        return
    end
    
    if notifyRes == 'ox_lib' then
        lib.notify({
            title = title,
            description = message,
            type = type or 'info',
            duration = duration
        })
    elseif notifyRes == 'qb-core' then
        TriggerEvent('QBCore:Notify', message, type or 'primary')
    elseif notifyRes == 'mythic_notify' then
        TriggerEvent('mythic_notify:SendAlert', {
            type = type or 'inform',
            text = message,
            length = duration
        })
    elseif notifyRes == 'okokNotify' then
        TriggerEvent('okokNotify:Alert', title, message, duration, type or 'info')
    end
end

-- ==========================================================================
-- TARGETING SYSTEMS (Client)
-- ==========================================================================

local function getTargetSystemResource()
    local candidates = {
        'qb-target', 'ox_target', 'interact', 'PointerTarget'
    }
    for _, res in ipairs(candidates) do
        if GetResourceState(res) == 'started' then return res end
    end
    return nil
end

function addDrawTextTarget(coords, message, distance)
    distance = distance or 5.0
    
    local targetRes = getTargetSystemResource()
    if not targetRes then return false end
    
    while true do
        Wait(0)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        local dist = #(playerCoords - coords)
        
        if dist < distance then
            -- Draw 3D text
            local camCoords = GetGameplayCamCoords()
            local distance = #(camCoords - coords)
            
            local scale = 1.0
            if distance > 100 then scale = 0.5
            elseif distance > 50 then scale = 0.7 end
            
            BeginTextCommandDisplayText('STRING')
            AddTextComponentString(message)
            SetTextScale(0.0 * scale, 0.30 * scale)
            SetTextColour(255, 255, 255, 255)
            SetTextOutline()
            EndTextCommandDisplayText(coords.x, coords.y, coords.z)
        end
    end
end

-- ==========================================================================
-- PLAYER DATA RETRIEVAL
-- ==========================================================================

function getPlayerData()
    if GetResourceState('qb-core') == 'started' then
        local qbCore = exports['qb-core']:GetCoreObject()
        return {
            name = qbCore.Functions.GetPlayerData().charinfo.firstname .. ' ' .. qbCore.Functions.GetPlayerData().charinfo.lastname,
            job = qbCore.Functions.GetPlayerData().job.name,
            cash = qbCore.Functions.GetPlayerData().money['cash'],
            bank = qbCore.Functions.GetPlayerData().money['bank'],
            gang = qbCore.Functions.GetPlayerData().gang.name
        }
    elseif GetResourceState('es_extended') == 'started' then
        local esx = exports.es_extended:getSharedObject()
        TriggerEvent('esx:getSharedObject', function(obj) esx = obj end)
        
        return {
            name = esx.getPlayerData().name,
            job = esx.getPlayerData().job.name,
            cash = esx.getPlayerData().money,
            bank = 0,
            gang = 'None'
        }
    end
    
    return nil
end

-- ==========================================================================
-- INVENTORY CHECKS
-- ==========================================================================

function hasClientItem(itemName)
    if GetResourceState('qb-core') == 'started' then
        local qbCore = exports['qb-core']:GetCoreObject()
        return qbCore.Functions.HasItem(itemName)
    elseif GetResourceState('ox_inventory') == 'started' then
        local items = exports.ox_inventory:GetInventoryItems()
        for _, item in ipairs(items or {}) do
            if item.name == itemName and item.count > 0 then
                return true
            end
        end
    end
    return false
end

function getItemCount(itemName)
    if GetResourceState('qb-core') == 'started' then
        local qbCore = exports['qb-core']:GetCoreObject()
        local items = qbCore.Functions.GetPlayerData().items
        for _, item in ipairs(items) do
            if item.name == itemName then
                return item.amount or 0
            end
        end
    elseif GetResourceState('ox_inventory') == 'started' then
        local items = exports.ox_inventory:GetInventoryItems()
        for _, item in ipairs(items or {}) do
            if item.name == itemName then
                return item.count or 0
            end
        end
    end
    return 0
end

-- ==========================================================================
-- DRAW TEXT UTILITIES
-- ==========================================================================

function draw3DText(coords, text)
    local camCoords = GetGameplayCamCoords()
    local distance = #(camCoords - coords)
    
    if distance > 200 then return end
    
    local scale = 1.0
    if distance > 100 then scale = 0.5
    elseif distance > 50 then scale = 0.7 end
    
    BeginTextCommandDisplayText('STRING')
    AddTextComponentString(text)
    SetTextScale(0.0 * scale, 0.30 * scale)
    SetTextColour(255, 255, 255, 255)
    SetTextOutline()
    EndTextCommandDisplayText(coords.x, coords.y, coords.z)
end

-- ==========================================================================
-- ANIMATIONS & EMOTES
-- ==========================================================================

function playAnimation(animDict, animName, flags)
    flags = flags or 49
    
    local ped = PlayerPedId()
    
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
    end
    
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, flags, 0, false, false, false)
end

function stopAnimation()
    local ped = PlayerPedId()
    StopAnimTask(ped, 0, 0, true)
end

-- ==========================================================================
-- UTILITIES
-- ==========================================================================

function teleportClient(coords)
    local ped = PlayerPedId()
    
    if coords.z then
        while true do
            RequestModel(GetHashKey('a_m_m_business_1'))
            if HasModelLoaded(GetHashKey('a_m_m_business_1')) then
                break
            end
            Wait(100)
        end
    end
    
    SetEntityCoords(ped, coords.x, coords.y, coords.z or GetEntityCoords(ped).z, false, false, false, false)
    SetEntityHeading(ped, coords.w or GetEntityHeading(ped))
end

function drawBlip(coords, sprite, color, scale, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, scale or 0.8)
    SetBlipAsNoLongerNeeded(blip)
    
    if label then
        AddTextComponentString(label)
        BeginTextCommandCreateTwoLineGroupedText()
        EndTextCommandCreateTwoLineGroupedText(blip)
    end
    
    return blip
end

-- ==========================================================================
-- VEHICLE UTILITIES
-- ==========================================================================

function getPlayerVehicle()
    return GetVehiclePedIsIn(PlayerPedId(), false)
end

function getVehicleClass(vehicle)
    return GetVehicleClass(vehicle)
end

function openVehicleDoorsNearby(distance)
    distance = distance or 10.0
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    
    local vehicles = {}
    local handle, vehicle = FindFirstVehicle()
    local success
    
    repeat
        success, vehicle = FindNextVehicle(handle)
        local vehCoords = GetEntityCoords(vehicle)
        local dist = #(pedCoords - vehCoords)
        
        if dist < distance then
            table.insert(vehicles, vehicle)
        end
    until not success
    
    EndFindVehicle(handle)
    return vehicles
end

-- ==========================================================================
-- EXPORTS
-- ==========================================================================

exports('getNotifyResource', getNotifyResource)
exports('getTargetSystemResource', getTargetSystemResource)
exports('notifyClient', notifyClient)
exports('addDrawTextTarget', addDrawTextTarget)
exports('getPlayerData', getPlayerData)
exports('hasClientItem', hasClientItem)
exports('getItemCount', getItemCount)
exports('draw3DText', draw3DText)
exports('playAnimation', playAnimation)
exports('stopAnimation', stopAnimation)
exports('teleportClient', teleportClient)
exports('drawBlip', drawBlip)
exports('getPlayerVehicle', getPlayerVehicle)
exports('getVehicleClass', getVehicleClass)
exports('openVehicleDoorsNearby', openVehicleDoorsNearby)

print('^2[DG-Bridge] Client-side Commonly Used Scripts Integration Ready^7')
