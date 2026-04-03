# 🔧 DG-Bridge Usage Examples

Real-world code examples for integrating DG-Bridge into your scripts and admin menu.

---

## Table of Contents

1. [Server-Side Examples](#server-side-examples)
2. [Client-Side Examples](#client-side-examples)
3. [Integration with Admin Menu](#integration-with-admin-menu)
4. [Common Workflows](#common-workflows)

---

## Server-Side Examples

### Example 1: Give Player a Vehicle with Keys

```lua
-- In your server script
local function givePlayerVehicle(source, vehicleModel, licensePlate)
    -- Get player info
    local playerName = GetPlayerName(source)
    local identifier = exports['dg-bridge']:getIdentifier(source)
    
    -- Spawn vehicle
    local vehicle = CreateVehicle(GetHashKey(vehicleModel), 100, 200, 50, true, false)
    
    -- Set plate
    SetVehicleNumberPlateText(vehicle, licensePlate)
    
    -- Give keys using bridge
    local success = exports['dg-bridge']:giveVehicleKeys(licensePlate, playerName)
    
    if success then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'Admin', 'Vehicle key added successfully!'},
            color = {0, 255, 0}
        })
    else
        TriggerClientEvent('chat:addMessage', source, {
            args = {'Admin', 'Failed to add vehicle keys!'},
            color = {255, 0, 0}
        })
    end
end
```

### Example 2: Give Player Housing

```lua
-- Give player a house
local function givePlayerHouse(source, houseId)
    local identifier = exports['dg-bridge']:getIdentifier(source)
    
    -- Add house key through bridge
    local success = exports['dg-bridge']:addHouseKey(identifier, houseId)
    
    if success then
        exports['dg-bridge']:notifyPlayer(source, 'You now own house ' .. houseId .. '!', 'success')
    else
        exports['dg-bridge']:notifyPlayer(source, 'Failed to give house!', 'error')
    end
end
```

### Example 3: Transfer Business Money

```lua
-- Transfer money from business to player account
local function transferBusinessMoney(source, businessId, amount)
    local identifier = exports['dg-bridge']:getIdentifier(source)
    
    -- Get business balance
    local bankBalance = exports['dg-bridge']:getPlayerBankBalance(source)
    
    if bankBalance and bankBalance >= amount then
        -- Remove from business
        exports['dg-bridge']:removeMoney(source, amount, 'bank')
        
        -- Add to player's account
        exports['dg-bridge']:addMoney(source, amount, 'cash')
        
        print('^2[Business] ' .. identifier .. ' withdrew $' .. amount .. '^7')
    else
        exports['dg-bridge']:notifyPlayer(source, 'Insufficient funds!', 'error')
    end
end
```

### Example 4: Complete Job Assignment Workflow

```lua
-- Assign player to job with all data
local function assignPlayerToJob(source, jobName, jobGrade)
    local identifier = exports['dg-bridge']:getIdentifier(source)
    local name = exports['dg-bridge']:getCharacterName(source)
    
    -- Set job using bridge
    local success = exports['dg-bridge']:setPlayerJob(source, jobName, jobGrade)
    
    if success then
        -- Notify player
        exports['dg-bridge']:notifyPlayer(source, 'You are now a ' .. jobName, 'success')
        
        -- Log action
        print('^3[Admin] ' .. name .. ' assigned to job: ' .. jobName .. ' (Grade: ' .. jobGrade .. ')^7')
        
        -- Broadcast to staff
        TriggerEvent('chat:addMessage', {
            args = {'Admin System', name .. ' is now ' .. jobName},
            color = {255, 165, 0}
        })
    end
end
```

### Example 5: Check Player Inventory

```lua
-- Check if player has required items
local function playerHasRequiredItems(source, requiredItems)
    local inventory = exports['dg-bridge']:getInventory(source)
    
    for itemName, requiredCount in pairs(requiredItems) do
        local hasItem = false
        
        for _, item in ipairs(inventory) do
            if item.name == itemName and item.amount >= requiredCount then
                hasItem = true
                break
            end
        end
        
        if not hasItem then
            return false, itemName
        end
    end
    
    return true
end

-- Usage
local required = { ['lockpick'] = 1, ['testkit'] = 2 }
local hasAll, missingItem = playerHasRequiredItems(source, required)

if not hasAll then
    exports['dg-bridge']:notifyPlayer(source, 'You need: ' .. missingItem, 'error')
end
```

---

## Client-Side Examples

### Example 1: Enhanced Notification System

```lua
-- Wrapper that uses bridge for consistent notifications
local function showNotification(title, message, type, duration)
    type = type or 'info'
    duration = duration or 5000
    
    exports['dg-bridge']:notifyClient(type, title, message, duration)
end

-- Usage
showNotification('LPFD', 'You have responded to the scene', 'success', 3000)
showNotification('LSPD', 'Invalid access level', 'error', 4000)
showNotification('Bank', 'Transaction completed', 'info', 5000)
```

### Example 2: Get and Display Player Info

```lua
-- Display player stats in chat
local function displayPlayerStats()
    local playerData = exports['dg-bridge']:getPlayerData()
    
    if not playerData then
        print('Error: Could not retrieve player data')
        return
    end
    
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {'Stats', 
            'Name: ' .. playerData.name ..
            '\nJob: ' .. playerData.job ..
            '\nCash: $' .. playerData.cash ..
            '\nBank: $' .. playerData.bank ..
            '\nGang: ' .. playerData.gang
        }
    })
end
```

### Example 3: Interactive Location Markers

```lua
-- Create an interactive location with blip and text
local function createLocationMarker(coords, label, blipSprite, distance)
    -- Draw blip on map
    exports['dg-bridge']:drawBlip(coords, blipSprite, 2, 0.8, label)
    
    -- Continuously draw text when player is near
    Citizen.CreateThread(function()
        while true do
            Wait(0)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - coords)
            
            if dist < distance then
                exports['dg-bridge']:draw3DText(coords + vector3(0, 0, 1), 
                    '[E] ' .. label .. '\n' .. string.format('%.1f m', dist))
            elseif dist > distance * 2 then
                break
            end
        end
    end)
end

-- Usage
createLocationMarker(vector3(425.5, 280.2, 103.4), 'Bank ATM', 227, 20.0)
```

### Example 4: Inventory Check and Item Usage

```lua
-- Check inventory and use item
local function useItemFromInventory(itemName)
    local itemCount = exports['dg-bridge']:getItemCount(itemName)
    
    if itemCount > 0 then
        -- Play animation
        exports['dg-bridge']:playAnimation('mp_player_inteat@chips', 'mp_player_int_eat_chip')
        
        -- Show notification
        exports['dg-bridge']:notifyClient('success', 'Item Used', 'You used 1x ' .. itemName, 3000)
        
        -- Trigger remove on server
        TriggerServerEvent('item:use', itemName)
    else
        exports['dg-bridge']:notifyClient('error', 'Inventory', 'You don\'t have: ' .. itemName, 3000)
    end
end
```

### Example 5: Vehicle Access Check and Entry

```lua
-- Check if player has access to vehicle
local function checkVehicleAccess(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    
    -- This would be a custom event to server to check
    TriggerServerEvent('vehicle:checkAccess', plate)
    
    -- Wait for response
    local hasAccess = false
    
    RegisterNetEvent('vehicle:accessResponse', function(canAccess)
        hasAccess = canAccess
    end)
    
    if hasAccess then
        exports['dg-bridge']:notifyClient('success', 'Vehicle', 'You have access', 2000)
        TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_STUPOR', 0, true)
    else
        exports['dg-bridge']:notifyClient('error', 'Vehicle', 'You don\'t have keys!', 2000)
    end
end
```

---

## Integration with Admin Menu

### Admin Command: Give Vehicle with Keys

Add this to your admin menu backend:

```lua
-- Server-side command handler
RegisterCommand('giveveh', function(source, args, rawCommand)
    local targetId = tonumber(args[1])
    local vehModel = args[2]
    
    if not targetId or not vehModel then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'Admin', 'Usage: /giveveh [id] [model]'},
            color = {255, 0, 0}
        })
        return
    end
    
    local isAdmin = exports['dg-bridge']:isPlayerAdmin(source)
    if not isAdmin then
        return
    end
    
    local playerName = GetPlayerName(targetId)
    local vehicle = CreateVehicle(GetHashKey(vehModel), 100, 200, 50, true, false)
    local plate = 'VEH' .. math.random(1000, 9999)
    
    SetVehicleNumberPlateText(vehicle, plate)
    
    -- Use bridge to give keys
    local success = exports['dg-bridge']:giveVehicleKeys(plate, playerName)
    
    if success then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'Admin', 'Vehicle given to ' .. playerName},
            color = {0, 255, 0}
        })
    end
end, false)
```

### Admin Command: Assign Job

```lua
-- Server-side job assignment command
RegisterCommand('setjob', function(source, args, rawCommand)
    local targetId = tonumber(args[1])
    local jobName = args[2]
    local jobGrade = tonumber(args[3]) or 0
    
    if not targetId or not jobName then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'Admin', 'Usage: /setjob [id] [job] [grade]'},
            color = {255, 0, 0}
        })
        return
    end
    
    if not exports['dg-bridge']:isPlayerAdmin(source) then
        return
    end
    
    local success = exports['dg-bridge']:setPlayerJob(targetId, jobName, jobGrade)
    local targetName = GetPlayerName(targetId)
    
    if success then
        exports['dg-bridge']:notifyPlayer(targetId, 'You are now a ' .. jobName, 'success')
        TriggerClientEvent('chat:addMessage', source, {
            args = {'Admin', targetName .. ' assigned to ' .. jobName},
            color = {0, 255, 0}
        })
        
        print('^3[Admin] ' .. GetPlayerName(source) .. ' assigned ' .. targetName .. ' to ' .. jobName .. '^7')
    end
end, false)
```

### Admin Command: Give Money

```lua
-- Give player cash or bank money
RegisterCommand('givemoney', function(source, args, rawCommand)
    local targetId = tonumber(args[1])
    local amount = tonumber(args[2])
    local type = args[3] or 'cash'
    
    if not targetId or not amount then
        TriggerClientEvent('chat:addMessage', source, {
            args = {'Admin', 'Usage: /givemoney [id] [amount] [cash/bank]'},
            color = {255, 0, 0}
        })
        return
    end
    
    if not exports['dg-bridge']:isPlayerAdmin(source) then
        return
    end
    
    local success = exports['dg-bridge']:addMoney(targetId, amount, type)
    local targetName = GetPlayerName(targetId)
    
    if success then
        exports['dg-bridge']:notifyPlayer(targetId, 'Received $' .. amount, 'success')
        TriggerClientEvent('chat:addMessage', source, {
            args = {'Admin', 'Gave $' .. amount .. ' ' .. type .. ' to ' .. targetName},
            color = {0, 255, 0}
        })
    end
end, false)
```

---

## Common Workflows

### Workflow 1: Complete NewPlayer Onboarding

```lua
-- Complete setup for new player
local function onboardNewPlayer(source)
    local name = exports['dg-bridge']:getCharacterName(source)
    local identifier = exports['dg-bridge']:getIdentifier(source)
    
    -- 1. Give starting job
    exports['dg-bridge']:setPlayerJob(source, 'unemployed', 0)
    
    -- 2. Give starting items
    exports['dg-bridge']:giveItem(source, 'phone', 1)
    exports['dg-bridge']:giveItem(source, 'id_card', 1)
    
    -- 3. Give starting money
    exports['dg-bridge']:addMoney(source, 500, 'cash')
    exports['dg-bridge']:addMoney(source, 1000, 'bank')
    
    -- 4. Notify player
    exports['dg-bridge']:notifyPlayer(source, 'Welcome to the city! You have been set up.', 'success')
    
    print('^2[System] ' .. name .. ' has been onboarded^7')
end
```

### Workflow 2: Business Deposit System

```lua
-- Player deposits money to business account
local function depositToBusiness(source, businessId, amount)
    local identifier = exports['dg-bridge']:getIdentifier(source)
    local playerMoney = exports['dg-bridge']:getPlayerMoney(source, 'cash')
    
    if playerMoney < amount then
        exports['dg-bridge']:notifyPlayer(source, 'Insufficient cash!', 'error')
        return
    end
    
    -- Remove from player
    exports['dg-bridge']:removeMoney(source, amount, 'cash')
    
    -- Log to database (custom implementation)
    MySQL.Async.execute('INSERT INTO business_deposits (business_id, player_id, amount, date) VALUES (?, ?, ?, NOW())',
        { businessId, identifier, amount })
    
    exports['dg-bridge']:notifyPlayer(source, 'Deposited $' .. amount .. ' to business', 'success')
end
```

### Workflow 3: Item Crafting System

```lua
-- Craft item from other items
local function craftItem(source, recipe)
    local playerInventory = exports['dg-bridge']:getInventory(source)
    
    -- Check if player has all required items
    for itemName, count in pairs(recipe.requires) do
        local hasItem = false
        for _, item in ipairs(playerInventory) do
            if item.name == itemName and item.amount >= count then
                hasItem = true
                break
            end
        end
        
        if not hasItem then
            exports['dg-bridge']:notifyPlayer(source, 'Missing: ' .. itemName, 'error')
            return
        end
    end
    
    -- Remove required items
    for itemName, count in pairs(recipe.requires) do
        exports['dg-bridge']:removeItem(source, itemName, count)
    end
    
    -- Give crafted item
    exports['dg-bridge']:giveItem(source, recipe.result, recipe.amount)
    
    exports['dg-bridge']:notifyPlayer(source, 'Crafted: ' .. recipe.result, 'success')
end
```

---

## Best Practices

### 1. Always Check If Resource Exists
```lua
local housing = exports['dg-bridge']:getHousingResource()
if not housing then
    print('WARNING: Housing system not available')
    return false
end
```

### 2. Use Error Handling
```lua
local success = exports['dg-bridge']:giveVehicleKeys(plate, playerName)
if not success then
    -- Handle failure gracefully
    print('ERROR: Could not give keys to ' .. plate)
end
```

### 3. Combine with Admin Checks
```lua
if not exports['dg-bridge']:isPlayerAdmin(source) then
    TriggerClientEvent('chat:addMessage', source, {
        args = {'System', 'You do not have permission!'},
        color = {255, 0, 0}
    })
    return
end
```

### 4. Log Important Actions
```lua
print('^3[Admin] ' .. GetPlayerName(source) .. ' executed admin command^7')
```

### 5. Provide Visual Feedback
```lua
exports['dg-bridge']:notifyPlayer(source, 'Action completed successfully!', 'success')
```

---

**More examples coming soon!** Check back for additional workflows and integrations.
