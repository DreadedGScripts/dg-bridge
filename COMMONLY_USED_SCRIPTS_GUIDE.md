# 🌉 DG-Bridge: Commonly Used Scripts Integration Guide

## Overview

Your DG-Bridge now includes comprehensive integrations for the most commonly used FiveM RP scripts across **12+ categories**. It auto-detects which scripts are running and provides unified wrapper functions.

---

## 📦 Integrated Script Categories

### 🏠 Housing & Properties
**Supported Scripts:**
- `qb-properties` ⭐ QBCore Official
- `qb-houses` 
- `ps-housing` ⭐ Premium
- `renewed-apartments`
- `lj-housing`
- `advanced-housing`

**Available Functions:**
```lua
-- Get all houses owned by a citizen
local houses = exports['dg-bridge']:getPlayerHouses(citizenid)

-- Add house key to player
local success = exports['dg-bridge']:addHouseKey(citizenid, house)
```

---

### 🚗 Vehicle Systems

#### Vehicle Keys
**Supported Scripts:**
- `qb-vehiclekeys` ⭐ QBCore Official
- `wasabi_carlock` ⭐ Very Popular
- `lj-vehiclekeys`
- `ps-vehiclekeys`
- `advanced-carlock`
- `ox_target` (OX Framework)

**Available Functions:**
```lua
-- Give player keys to vehicle (by plate)
local success = exports['dg-bridge']:giveVehicleKeys(plate, playerName)

-- Remove player's keys from vehicle
local success = exports['dg-bridge']:removeVehicleKeys(plate)
```

#### Garage System
**Supported Scripts:**
- `qb-garage` ⭐ QBCore Official
- `ps-garage` ⭐ Premium
- `lj-garage`
- `renewed-garage`
- `jg-garages`
- `advanced-garage`

**Available Functions:**
```lua
-- Store vehicle in garage
local success = exports['dg-bridge']:storeVehicleInGarage(vehicle, source)
```

#### Custom/Tuning Shops
**Supported Scripts:**
- `qb-customs` ⭐ QBCore Official
- `custom-shop`
- `ps-tuning` ⭐ Premium
- `advanced-customs`
- `renewed-customs`

---

### 💼 Business & Shops
**Supported Scripts:**
- `qb-shops` ⭐ QBCore Official
- `ps-stores` ⭐ Premium
- `renewed-shops`
- `lj-shops`
- `advanced-shops`

**Available Functions:**
```lua
-- Get all available shops and items
local shops = exports['dg-bridge']:getShopItems()
```

---

### 👔 Job Systems
**Supported Scripts:**
- `qb-policejob` ⭐ QBCore Police Job
- `qb-ambulancejob` ⭐ QBCore Ambulance Job
- `qb-mechanic` ⭐ QBCore Mechanic Job
- `qb-jobs` (Generic Job System)
- `ps-jobs` ⭐ Premium
- `renewed-jobs`
- `lj-jobsystem`

---

### 🏦 Banking System
**Supported Scripts:**
- `qb-banking` ⭐ QBCore Official
- `banking-ui`
- `ps-banking` ⭐ Premium
- `renewed-banking`
- `advanced-banking`

**Available Functions:**
```lua
-- Get player's total bank balance
local balance = exports['dg-bridge']:getPlayerBankBalance(source)
```

---

### 📱 Phone & Communication
**Supported Scripts:**
- `qb-phone` ⭐ QBCore Official
- `mythic_phone` ⭐ Very Popular
- `gksphone`
- `npwd` 🎯 Modern Alternative
- `ps-phone` ⭐ Premium
- `ox_lib` (OX Framework)

**Available Functions:**
```lua
-- Send SMS message via phone
local success = exports['dg-bridge']:sendPhoneMessage(citizenid, phone, message, sender)
```

---

### 🎯 Targeting Systems
**Supported Scripts:**
- `qb-target` ⭐ QBCore Official
- `ox_target` ⭐ OX Framework (Recommended)
- `interact`
- `PointerTarget`
- `ps-target` ⭐ Premium

**Available Functions:**
```lua
-- Add interactive target to entity
local success = exports['dg-bridge']:addTargetEntity(entity, options)
```

---

### 🔪 Robbery & Criminal Systems
**Supported Scripts:**
- `qb-robbery` ⭐ QBCore Store Robbery
- `qb-bankrobbery` ⭐ QBCore Bank Robbery
- `bank-robbery`
- `store-robbery`
- `ps-robbery` ⭐ Premium
- `advanced-robbery`

---

### 💊 Drug & Illegal Activities
**Supported Scripts:**
- `qb-drugs` ⭐ QBCore Weed Growing
- `qb-cocainelabs` ⭐ QBCore Cocaine Cooking
- `qb-methlab` ⭐ QBCore Meth Lab
- `ps-drugs` ⭐ Premium
- `advanced-drugs`

---

### 🛠️ Utility & Tables
**Supported Scripts:**
- `ox_lib` ⭐ Modern Framework (Full Replacement)
- `ox_target` ⭐ Modern Targeting
- `qb-core` (Main QBCore)
- `es_extended` (ESX Framework)
- `mysql-async` (Database)
- `oxmysql` (Modern Database)

---

## 🔧 Usage Examples

### Example 1: Give Vehicle Keys
```lua
-- In your script
local plate = 'ABC123'
local playerName = GetPlayerName(source)

local success = exports['dg-bridge']:giveVehicleKeys(plate, playerName)
if success then
    TriggerClientEvent('chat:addMessage', source, {
        args = { 'System', 'You now have keys to this vehicle!' }
    })
end
```

### Example 2: Check Housing
```lua
local citizenid = 'ABC12345'
local houses = exports['dg-bridge']:getPlayerHouses(citizenid)

if #houses > 0 then
    print('Player owns ' .. #houses .. ' houses')
    for _, house in ipairs(houses) do
        print('House: ' .. house.label)
    end
else
    print('Player owns no houses')
end
```

### Example 3: Store Vehicle in Garage
```lua
local vehicleEntity = GetVehiclePedIsIn(PlayerPedId(), false)
if vehicleEntity ~= 0 then
    -- Get the vehicle's plate
    local plate = GetVehicleNumberPlateText(vehicleEntity)
    
    -- Store in garage
    local success = exports['dg-bridge']:storeVehicleInGarage(vehicleEntity, source)
    
    if success then
        print('Vehicle stored successfully!')
    end
end
```

### Example 4: Send Phone Message
```lua
local citizenid = 'ABC12345'
local phoneNumber = '555-0123'
local message = 'Your business account has been updated.'
local sender = 'BUSINESS'

exports['dg-bridge']:sendPhoneMessage(citizenid, phoneNumber, message, sender)
```

### Example 5: Detect Available Resources
```lua
-- Check what scripts are running
local housingRes = exports['dg-bridge']:getHousingResource()
local vehicleKeysRes = exports['dg-bridge']:getVehicleKeysResource()
local garageRes = exports['dg-bridge']:getGarageResource()
local bankingRes = exports['dg-bridge']:getBankingResource()

print('Housing: ' .. (housingRes or 'Not Found'))
print('Vehicle Keys: ' .. (vehicleKeysRes or 'Not Found'))
print('Garage: ' .. (garageRes or 'Not Found'))
print('Banking: ' .. (bankingRes or 'Not Found'))
```

---

## 📋 All Available Functions

### Resource Detection Functions
```lua
exports['dg-bridge']:getHousingResource()          -- Returns housing script name
exports['dg-bridge']:getVehicleKeysResource()     -- Returns vehicle keys script name
exports['dg-bridge']:getGarageResource()           -- Returns garage script name
exports['dg-bridge']:getCustomShopResource()       -- Returns custom shop script name
exports['dg-bridge']:getShopResource()             -- Returns shop script name
exports['dg-bridge']:getJobResource()              -- Returns job script name
exports['dg-bridge']:getBankingResource()          -- Returns banking script name
exports['dg-bridge']:getPhoneResource()            -- Returns phone script name
exports['dg-bridge']:getTargetResource()           -- Returns target script name
exports['dg-bridge']:getRobberyResource()          -- Returns robbery script name
exports['dg-bridge']:getDrugResource()             -- Returns drug script name
exports['dg-bridge']:getTableResource()            -- Returns table/utility script name
```

### Vehicle Keys Functions
```lua
exports['dg-bridge']:giveVehicleKeys(plate, playerName)    -- Give keys to player
exports['dg-bridge']:removeVehicleKeys(plate)              -- Remove keys from player
```

### Garage Functions
```lua
exports['dg-bridge']:storeVehicleInGarage(vehicle, source) -- Store vehicle
```

### Housing Functions
```lua
exports['dg-bridge']:getPlayerHouses(citizenid)            -- Get player's houses
exports['dg-bridge']:addHouseKey(citizenid, house)         -- Add house key
```

### Banking Functions
```lua
exports['dg-bridge']:getPlayerBankBalance(source)          -- Get bank balance
```

### Phone Functions
```lua
exports['dg-bridge']:sendPhoneMessage(citizenid, phone, message, sender) -- Send SMS
```

### Shop Functions
```lua
exports['dg-bridge']:getShopItems()                        -- Get all shop items
```

### Target Functions
```lua
exports['dg-bridge']:addTargetEntity(entity, options)      -- Add target zone
```

---

## ⚙️ Configuration

The bridge **automatically detects** which scripts are running on your server. No manual configuration needed!

**Script Priority (Detection Order):**
Each category checks scripts in order of popularity:
1. Official QBCore versions (highest priority)
2. Premium/popular alternatives
3. Generic/other versions

---

## 🔍 Troubleshooting

### "Resource not found" errors
**Solution:** The bridge checks if a resource is started using `GetResourceState()`. Ensure the script is:
- Included in your `server.cfg`
- Marked as `ensure` (not commented out)  
- Named exactly as required

### Function returns nil/false
**Solution:** This happens when:
- The supporting script isn't running
- The function call parameters are invalid
- The framework doesn't support that operation

**Check what's available:**
```lua
local housing = exports['dg-bridge']:getHousingResource()
if not housing then
    print('WARNING: No housing script detected!')
end
```

---

## 💻 Client-Side Integration Functions

The bridge also includes powerful client-side utilities for common RP operations:

### Notifications
```lua
-- Unified notification system (auto-detects ox_lib, qb-core, mythic_notify, etc.)
exports['dg-bridge']:notifyClient('success', 'Title', 'Message', 5000)
exports['dg-bridge']:notifyClient('error', 'Error', 'Something went wrong', 5000)

-- Get current notification resource
local notifyRes = exports['dg-bridge']:getNotifyResource()
print('Using: ' .. (notifyRes or 'None found'))
```

### Player Data
```lua
-- Get current player data (name, job, money, gang, etc.)
local playerData = exports['dg-bridge']:getPlayerData()
if playerData then
    print('Player:', playerData.name)
    print('Job:', playerData.job)
    print('Cash:', playerData.cash)
    print('Bank:', playerData.bank)
end
```

### Inventory Management
```lua
-- Check if player has item
if exports['dg-bridge']:hasClientItem('phone') then
    print('Player has a phone!')
end

-- Get item count
local lockpicks = exports['dg-bridge']:getItemCount('lockpick')
print('Lockpicks:', lockpicks)
```

### Animations & Visuals
```lua
-- Play animation
exports['dg-bridge']:playAnimation('anim@mp_emotes@static_variations', 'static_var_01')

-- Stop animation
exports['dg-bridge']:stopAnimation()

-- Draw 3D text (floating text above object)
exports['dg-bridge']:draw3DText(vector3(100, 200, 50), 'Hello World!')

-- Create map blip
exports['dg-bridge']:drawBlip(vector3(100, 200, 50), 480, 2, 0.8, 'My Location')
```

### Targeting & UI
```lua
-- Get current targeting system resource
local targetRes = exports['dg-bridge']:getTargetSystemResource()
print('Using targeting system: ' .. (targetRes or 'None'))

-- Add target zone with text
exports['dg-bridge']:addDrawTextTarget(vector3(425.5, 280.2, 103.4), '[E] Use ATM', 5.0)
```

### Vehicle Functions
```lua
-- Get vehicle player is in
local vehicle = exports['dg-bridge']:getPlayerVehicle()
if vehicle and vehicle ~= 0 then
    local class = exports['dg-bridge']:getVehicleClass(vehicle)
    print('Vehicle class:', class)
end

-- Get nearby vehicles (within radius)
local vehicles = exports['dg-bridge']:openVehicleDoorsNearby(10.0)
for _, veh in ipairs(vehicles) do
    print('Found vehicle:', veh)
end
```

### Teleportation
```lua
-- Teleport player to coordinates
exports['dg-bridge']:teleportClient(vector4(425.5, 280.2, 103.4, 45.0))

-- Teleport without heading
exports['dg-bridge']:teleportClient(vector3(425.5, 280.2, 103.4))
```

---

## 📚 Next Steps

1. **Review your `server.cfg`** - Ensure you have housing, vehicle, garage, and phone scripts running
2. **Test in-game** - Use the examples above to test functionality
3. **Check server console** - The bridge logs which scripts it detected on startup
4. **Customize** - Modify `server/commonly-used.lua` or `client/commonly-used.lua` to add additional script support
5. **Client Integration** - Use client functions in your scripts for notifications, player data, animations, etc.

---

## 🎯 Quick Reference

| Feature | Scripts Supported | Status | Side |
|---------|------------------|--------|------|
| 🏠 Housing | 6+ variants | ✅ Ready | Server |
| 🚗 Vehicle Keys | 6+ variants | ✅ Ready | Server |
| 🏪 Garages | 6+ variants | ✅ Ready | Server |
| 💼 Shops | 5+ variants | ✅ Ready | Server |
| 👔 Jobs | 7+ variants | ✅ Ready | Server |
| 🏦 Banking | 5+ variants | ✅ Ready | Server |
| 📱 Phone | 6+ variants | ✅ Ready | Server |
| 🎯 Targeting | 5+ variants | ✅ Ready | Server |
| 🔪 Robbery | 6+ variants | ✅ Ready | Server |
| 💊 Drugs | 5+ variants | ✅ Ready | Server |
| 🔔 Notifications | 6+ variants | ✅ Ready | Client |
| 👤 Player Data | Auto-detect | ✅ Ready | Client |
| 🎒 Inventory | Auto-detect | ✅ Ready | Client |
| ✋ Animations | Native | ✅ Ready | Client |
| 🗺️ Visuals | Built-in | ✅ Ready | Client |

---

**Your bridge is now fully ready to use with commonly used RP scripts (Server + Client)!** 🚀
