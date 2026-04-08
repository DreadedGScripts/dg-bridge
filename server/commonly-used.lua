-- ==========================================================================
-- DG-Bridge: Commonly Used Scripts Integration (Server-Side)
-- ==========================================================================
-- Server-side detection and wrapper functions for commonly used RP scripts

local vehicleKeysResource = nil
local garageResource = nil
local housingResource = nil
local customShopResource = nil
local shopResource = nil
local jobResource = nil
local bankingResource = nil
local phoneResource = nil
local targetResource = nil
local robberyResource = nil
local drugResource = nil
local tableResource = nil

-- ==========================================================================
-- HELPER FUNCTIONS
-- ==========================================================================

local function isResourceStarted(resource)
    return GetResourceState(resource) == 'started'
end

local function tryExport(resource, funcName, ...)
    if not isResourceStarted(resource) then return false end
    local args = {...}
    local ok, result = pcall(function()
        return exports[resource][funcName](table.unpack(args))
    end)
    return ok, result
end

-- ==========================================================================
-- RESOURCE DETECTION
-- ==========================================================================

local function getHousingResource()
    local candidates = {
        'qb-properties', 'qb-houses', 'ps-housing', 'renewed-apartments',
        'lj-housing', 'advanced-housing'
    }
    for _, res in ipairs(candidates) do
        if isResourceStarted(res) then
            housingResource = res
            return res
        end
    end
    return nil
end

local function getVehicleKeysResource()
    local candidates = {
        'qb-vehiclekeys', 'wasabi_carlock', 'lj-vehiclekeys', 'ps-vehiclekeys',
        'advanced-carlock', 'ox_target'
    }
    for _, res in ipairs(candidates) do
        if isResourceStarted(res) then
            vehicleKeysResource = res
            return res
        end
    end
    return nil
end

local function getGarageResource()
    local candidates = {
        'qb-garage', 'ps-garage', 'jg-garages', 'renewed-garages',
        'lj-garages', 'advanced-garage'
    }
    for _, res in ipairs(candidates) do
        if isResourceStarted(res) then
            garageResource = res
            return res
        end
    end
    return nil
end

local function getCustomShopResource()
    local candidates = {
        'qb-customs', 'ps-tuning', 'advanced-customs', 'lj-customs',
        'custom-garage', 'tuning-shop'
    }
    for _, res in ipairs(candidates) do
        if isResourceStarted(res) then
            customShopResource = res
            return res
        end
    end
    return nil
end

local function getShopResource()
    local candidates = {
        'qb-shops', 'ps-stores', 'renewed-shops', 'lj-stores',
        'shop-system'
    }
    for _, res in ipairs(candidates) do
        if isResourceStarted(res) then
            shopResource = res
            return res
        end
    end
    return nil
end

local function getJobResource()
    local candidates = {
        'qb-jobs', 'qb-policejob', 'qb-ambulancejob', 'qb-mechanic',
        'ps-jobs', 'renewed-jobs', 'esx_job'
    }
    for _, res in ipairs(candidates) do
        if isResourceStarted(res) then
            jobResource = res
            return res
        end
    end
    return nil
end

local function getBankingResource()
    local candidates = {
        'qb-banking', 'ps-banking', 'renewed-banking', 'lj-banking',
        'banking-system'
    }
    for _, res in ipairs(candidates) do
        if isResourceStarted(res) then
            bankingResource = res
            return res
        end
    end
    return nil
end

local function getPhoneResource()
    local candidates = {
        'qb-phone', 'mythic_phone', 'npwd', 'gksphone', 'renewed-phone',
        'lj-phone', 'phone-system'
    }
    for _, res in ipairs(candidates) do
        if isResourceStarted(res) then
            phoneResource = res
            return res
        end
    end
    return nil
end

local function getTargetResource()
    local candidates = {
        'qb-target', 'ox_target', 'interact', 'PointerTarget', 'targeting-system'
    }
    for _, res in ipairs(candidates) do
        if isResourceStarted(res) then
            targetResource = res
            return res
        end
    end
    return nil
end

local function getRobberyResource()
    local candidates = {
        'qb-robbery', 'qb-bankrobbery', 'ps-robbery', 'renewed-robbery',
        'lj-robbery', 'robbery-system'
    }
    for _, res in ipairs(candidates) do
        if isResourceStarted(res) then
            robberyResource = res
            return res
        end
    end
    return nil
end

local function getDrugResource()
    local candidates = {
        'qb-drugs', 'qb-cocainelabs', 'qb-methlab', 'ps-drugs',
        'drug-system'
    }
    for _, res in ipairs(candidates) do
        if isResourceStarted(res) then
            drugResource = res
            return res
        end
    end
    return nil
end

local function getTableResource()
    local candidates = {
        'ox_lib', 'oxmysql', 'mysql-async', 'qb-core', 'es_extended'
    }
    for _, res in ipairs(candidates) do
        if isResourceStarted(res) then
            tableResource = res
            return res
        end
    end
    return nil
end

-- ==========================================================================
-- WRAPPER FUNCTIONS
-- ==========================================================================

function giveVehicleKeys(plate, playerName)
    if not vehicleKeysResource then return false end
    
    if vehicleKeysResource:find('qb%-vehiclekeys') then
        local ok, result = tryExport(vehicleKeysResource, 'GiveKeys', plate)
        return ok and result or false
    elseif vehicleKeysResource:find('wasabi_carlock') then
        local ok, result = tryExport(vehicleKeysResource, 'giveCarLock', plate)
        return ok and result or false
    end
    
    return false
end

function removeVehicleKeys(plate)
    if not vehicleKeysResource then return false end
    
    if vehicleKeysResource:find('qb%-vehiclekeys') then
        local ok, result = tryExport(vehicleKeysResource, 'RemoveKeys', plate)
        return ok and result or false
    end
    
    return false
end

function storeVehicleInGarage(vehicle, source)
    if not garageResource then return false end
    
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local ok, result = tryExport(garageResource, 'storeVehicle', netId, source)
    
    return ok and result or false
end

function getPlayerHouses(citizenid)
    if not housingResource then return nil end
    
    local ok, result = tryExport(housingResource, 'GetPlayerHouses', citizenid)
    return ok and result or nil
end

function addHouseKey(citizenid, house)
    if not housingResource then return false end
    
    local ok, result = tryExport(housingResource, 'AddHouseKey', citizenid, house)
    return ok and result or false
end

function getPlayerBankBalance(src)
    if not bankingResource then return nil end
    
    local ok, result = tryExport(bankingResource, 'GetBalance', src)
    return ok and result or nil
end

function sendPhoneMessage(citizenid, phone, message, sender)
    if not phoneResource then return false end
    
    if phoneResource:find('qb%-phone') then
        local ok, result = tryExport(phoneResource, 'SendMessage', citizenid, phone, message, sender)
        return ok and result or false
    end
    
    return false
end

function getShopItems()
    if not shopResource then return nil end
    
    local ok, result = tryExport(shopResource, 'GetShopItems')
    return ok and result or nil
end

function addTargetEntity(entity, options)
    if not targetResource then return false end
    
    if targetResource:find('ox_target') then
        local ok, result = tryExport(targetResource, 'addEntity', entity, options)
        return ok and result or false
    end
    
    return false
end

-- ==========================================================================
-- INITIALIZATION
-- ==========================================================================

-- Initialize all resource detections
Citizen.CreateThread(function()
    Wait(1000)
    
    getHousingResource()
    getVehicleKeysResource()
    getGarageResource()
    getCustomShopResource()
    getShopResource()
    getJobResource()
    getBankingResource()
    getPhoneResource()
    getTargetResource()
    getRobberyResource()
    getDrugResource()
    getTableResource()
    
    local detected = {}
    if housingResource then table.insert(detected, 'Housing: ' .. housingResource) end
    if vehicleKeysResource then table.insert(detected, 'Vehicle Keys: ' .. vehicleKeysResource) end
    if garageResource then table.insert(detected, 'Garage: ' .. garageResource) end
    if customShopResource then table.insert(detected, 'Custom Shop: ' .. customShopResource) end
    if shopResource then table.insert(detected, 'Shop: ' .. shopResource) end
    if jobResource then table.insert(detected, 'Job: ' .. jobResource) end
    if bankingResource then table.insert(detected, 'Banking: ' .. bankingResource) end
    if phoneResource then table.insert(detected, 'Phone: ' .. phoneResource) end
    if targetResource then table.insert(detected, 'Target: ' .. targetResource) end
    if robberyResource then table.insert(detected, 'Robbery: ' .. robberyResource) end
    if drugResource then table.insert(detected, 'Drug: ' .. drugResource) end
    if tableResource then table.insert(detected, 'Utilities: ' .. tableResource) end
    
    print('^2[DG-Bridge] Commonly Used Scripts Integration Ready^7')
    if #detected > 0 then
        print('^3[DG-Bridge] Detected Scripts:^7')
        for _, script in ipairs(detected) do
            print('  - ' .. script)
        end
    else
        print('^1[DG-Bridge] WARNING: No commonly used scripts detected. Some features may not work.^7')
    end
end)

-- ==========================================================================
-- EXPORTS
-- ==========================================================================

exports('getHousingResource', getHousingResource)
exports('getVehicleKeysResource', getVehicleKeysResource)
exports('getGarageResource', getGarageResource)
exports('getCustomShopResource', getCustomShopResource)
exports('getShopResource', getShopResource)
exports('getJobResource', getJobResource)
exports('getBankingResource', getBankingResource)
exports('getPhoneResource', getPhoneResource)
exports('getTargetResource', getTargetResource)
exports('getRobberyResource', getRobberyResource)
exports('getDrugResource', getDrugResource)
exports('getTableResource', getTableResource)

exports('giveVehicleKeys', giveVehicleKeys)
exports('removeVehicleKeys', removeVehicleKeys)
exports('storeVehicleInGarage', storeVehicleInGarage)
exports('getPlayerHouses', getPlayerHouses)
exports('addHouseKey', addHouseKey)
exports('getPlayerBankBalance', getPlayerBankBalance)
exports('sendPhoneMessage', sendPhoneMessage)
exports('getShopItems', getShopItems)
exports('addTargetEntity', addTargetEntity)

print('^2[DG-Bridge] Server-side Commonly Used Scripts Integration Ready^7')
