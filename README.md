# DG-Bridge

Framework bridge for DG scripts.

- Resource: `dg-bridge`
- Version: `1.0.0`
- Framework modes: `qbcore`, `esx`, `standalone`

## What It Does

- Auto-detects framework on startup.
- Exposes a unified API for framework-dependent operations.
- Normalizes common player/admin/economy/inventory tasks.
- Provides a shared client event for loaded state: `dg-bridge:playerLoaded`.

## Dependencies

None required in `fxmanifest.lua`.

Notes:

- Works best when `qb-core` or `es_extended` is started before this resource.
- Can run in standalone mode when no supported framework is found.

## Exports

This list matches the current `fxmanifest.lua`.

### Shared Exports (`exports`)

- `getFramework`
- `isQBCore`
- `isESX`
- `isStandalone`

### Server Exports (`server_exports`)

- `getFramework`
- `detectFramework`
- `getLicense`
- `getIdentifier`
- `kickPlayer`
- `banPlayer`
- `getPlayerJob`
- `getPlayerMoney`
- `isPlayerAdmin`
- `addMoney`
- `removeMoney`
- `giveItem`
- `removeItem`
- `getInventory`
- `getAllItems`
- `getPlayerGang`
- `getAllIdentifiers`
- `notifyPlayer`
- `getCharacterName`
- `getMetadata`
- `setMetadata`
- `getPlayerCoords`
- `teleportPlayer`
- `setPlayerJob`
- `getAllJobs`
- `revivePlayer`
- `giveVehicleKeys`
- `getPlayerIdentifier`

### Client Exports (`client_exports`)

- `isQBCore`
- `isESX`
- `getPlayerData`
- `notify`
- `getJob`
- `getMoney`
- `getGang`
- `getCharName`
- `draw3DText`
- `hasItem`

## Client Events

- `dg-bridge:playerLoaded`
- `dg-bridge:notify`
- `dg-bridge:teleport`
- `dg-bridge:revive`
- `dg-bridge:vehicleKeys`
- `dg-bridge:removeWeapons`
- `dg-bridge:giveWeapons`

## Server Events

- `dg-bridge:giveVehicleKeys`

## Installation

Add to `server.cfg`:

```cfg
ensure dg-bridge
```

## Minimal Usage

```lua
-- Server
local framework = exports['dg-bridge']:getFramework()
local isAdmin = exports['dg-bridge']:isPlayerAdmin(source)
local license = exports['dg-bridge']:getLicense(source)

-- Client
local job, grade, label = exports['dg-bridge']:getJob()
exports['dg-bridge']:notify(('Job: %s'):format(label), 'info', 5000)
```
