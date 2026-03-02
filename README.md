# DG-Bridge

Framework Bridge for DG Scripts - Provides unified API across QBCore, ESX, and Standalone servers.

## Features

- **Auto-Detection**: Automatically detects QBCore, ESX, or runs in Standalone mode
- **Unified API**: Single interface for all framework operations
- **Player Management**: License retrieval, identifier lookup, admin checks
- **Framework-Agnostic**: Write code once, works on any framework

## Exports

### Client Exports
```lua
-- Framework Detection
exports['dg-bridge']:getFramework()      -- Get framework object
exports['dg-bridge']:isQBCore()          -- Check if QBCore
exports['dg-bridge']:isESX()             -- Check if ESX

-- Player Data
exports['dg-bridge']:getPlayerData()     -- Get full player data (framework-agnostic)
exports['dg-bridge']:getJob()            -- Get job name, grade, label
exports['dg-bridge']:getMoney(type)      -- Get money amount (cash, bank, etc)
exports['dg-bridge']:getGang()           -- Get gang info (QBCore only)
exports['dg-bridge']:getCharName()       -- Get character name

-- Utilities
exports['dg-bridge']:notify(msg, type, duration)  -- Show notification
exports['dg-bridge']:hasItem(itemName)            -- Check if player has item
exports['dg-bridge']:draw3DText(coords, text, scale) -- Draw 3D text at coordinates
```

### Server Exports
```lua
-- Framework & Identifiers
exports['dg-bridge']:getFramework()              -- Get framework name
exports['dg-bridge']:getLicense(src)             -- Get player license
exports['dg-bridge']:getIdentifier(src, type)    -- Get specific identifier (steam, discord, etc)
exports['dg-bridge']:getAllIdentifiers(src)      -- Get all identifiers as table

-- Player Management
exports['dg-bridge']:kickPlayer(src, reason)     -- Kick player
exports['dg-bridge']:banPlayer(src, reason, hrs) -- Ban player
exports['dg-bridge']:notifyPlayer(src, msg, type, duration) -- Send notification
exports['dg-bridge']:isPlayerAdmin(src)          -- Check if admin

-- Character Info
exports['dg-bridge']:getPlayerJob(src)           -- Get job name, grade, label
exports['dg-bridge']:getPlayerGang(src)          -- Get gang info (QBCore)
exports['dg-bridge']:getCharacterName(src)       -- Get character name
exports['dg-bridge']:getPlayerCoords(src)        -- Get player coordinates

-- Economy
exports['dg-bridge']:getPlayerMoney(src, type)   -- Get money amount
exports['dg-bridge']:addMoney(src, type, amount) -- Add money
exports['dg-bridge']:removeMoney(src, type, amount) -- Remove money

-- Inventory
exports['dg-bridge']:giveItem(src, item, amount, metadata) -- Give item
exports['dg-bridge']:removeItem(src, item, amount)         -- Remove item
exports['dg-bridge']:getInventory(src)                     -- Get full inventory

-- Metadata
exports['dg-bridge']:getMetadata(src, key)       -- Get player metadata
exports['dg-bridge']:setMetadata(src, key, val)  -- Set player metadata

-- Teleport
exports['dg-bridge']:teleportPlayer(src, coords) -- Teleport player
```

## Events

### Client Events
- `dg-bridge:playerLoaded` - Triggered when player fully loads (QBCore/ESX compatible)

## Usage Examples

```lua
-- Server-side: Check admin and get info
local function onPlayerConnect(playerId)
    local isAdmin = exports['dg-bridge']:isPlayerAdmin(playerId)
    if isAdmin then
        local license = exports['dg-bridge']:getLicense(playerId)
        local charName = exports['dg-bridge']:getCharacterName(playerId)
        print('Admin ' .. charName .. ' (' .. license .. ') connected')
    end
end

-- Server-side: Give money and items
RegisterCommand('givereward', function(source, args)
    exports['dg-bridge']:addMoney(source, 'cash', 5000)
    exports['dg-bridge']:giveItem(source, 'bread', 5)
    exports['dg-bridge']:notifyPlayer(source, 'You received a reward!', 'success')
end)

-- Server-side: Teleport player
RegisterCommand('tpto', function(source, args)
    local targetId = tonumber(args[1])
    if targetId then
        local coords = exports['dg-bridge']:getPlayerCoords(targetId)
        exports['dg-bridge']:teleportPlayer(source, coords)
    end
end)

-- Client-side: Check player job and money
RegisterNetEvent('dg-bridge:playerLoaded')
AddEventHandler('dg-bridge:playerLoaded', function()
    local job, grade, label = exports['dg-bridge']:getJob()
    local cash = exports['dg-bridge']:getMoney('cash')
    exports['dg-bridge']:notify('Welcome! Job: ' .. label .. ' | Cash: $' .. cash, 'info')
end)

-- Client-side: Check for item
RegisterCommand('checkitem', function()
    local hasItem, amount = exports['dg-bridge']:hasItem('bread')
    if hasItem then
        print('You have ' .. amount .. ' bread')
    else
        print('You do not have any bread')
    end
end)
```

## Installation

1. Place `dg-bridge` in your resources folder
2. Add to `server.cfg`:
```
ensure dg-bridge
```

## Dependencies

None - this is a standalone bridge resource.
