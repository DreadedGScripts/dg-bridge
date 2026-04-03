<div align="center">

# 🌉 DG Bridge

### Framework Abstraction Layer for DG Scripts

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-Commercial-red.svg)
![Framework](https://img.shields.io/badge/framework-QBCore%20%7C%20ESX%20%7C%20Standalone-green.svg)

**One consistent API for framework-dependent server and client logic**

[Overview](#-overview) • [Exports](#-exports) • [Events](#-events) • [Installation](#-installation) • [Usage](#-usage)

---

</div>

## 📋 Overview

**DG Bridge** provides a unified API across QBCore, ESX, and standalone mode, allowing DG resources to use a single integration layer for player, inventory, money, job, admin, and utility operations.

| Property | Value |
|----------|-------|
| **Resource Name** | `dg-bridge` |
| **Version** | `1.0.0` |
| **Framework Modes** | `qbcore`, `esx`, `standalone` |
| **Hard Dependencies** | None |

---

## ✨ Features

- Auto-detects active framework on startup
- Normalizes common framework operations into stable exports
- Supports server and client helper APIs
- Emits a player-loaded bridge event for cross-resource use

---

## 📤 Exports

This list reflects the current `fxmanifest.lua` and implementation.

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

---

## 📡 Events

### Client Events

- `dg-bridge:playerLoaded`
- `dg-bridge:notify`
- `dg-bridge:teleport`
- `dg-bridge:revive`
- `dg-bridge:vehicleKeys`
- `dg-bridge:removeWeapons`
- `dg-bridge:giveWeapons`

### Server Events

- `dg-bridge:giveVehicleKeys`

---

## 📦 Installation

```cfg
ensure dg-bridge
```

Recommended load order:

```cfg
ensure qb-core       # if using QBCore
ensure es_extended   # if using ESX
ensure dg-bridge
```

---

## 🧩 Usage

```lua
-- Server
local framework = exports['dg-bridge']:getFramework()
local isAdmin = exports['dg-bridge']:isPlayerAdmin(source)
local license = exports['dg-bridge']:getLicense(source)

-- Client
local job, grade, label = exports['dg-bridge']:getJob()
exports['dg-bridge']:notify(('Job: %s'):format(label), 'info', 5000)
```

---

## 🌟 Commonly Used Scripts Integration

**NEW!** DG Bridge now includes comprehensive support for 60+ commonly used FiveM RP scripts across 12+ categories!

### What's Included

- **60+ Script Variants** supported out of the box
- **Auto-Detection System** - Automatically finds which scripts you have running
- **Unified Wrapper Functions** - Same API regardless of which script variant you use
- **Server & Client Functions** - Complete client-side utilities for animations, notifications, player data, and more

### Integrated Categories

🏠 Housing • 🚗 Vehicles • 🏪 Shops • 👔 Jobs • 🏦 Banking • 📱 Phone • 🎯 Targeting • 🔪 Robbery • 💊 Drugs • 🎒 Inventory

### Example Usage

```lua
-- Server: Give player vehicle keys (auto-detects which keys script you use)
exports['dg-bridge']:giveVehicleKeys('ABC1234', 'John Doe')

-- Server: Add house key
exports['dg-bridge']:addHouseKey(citizenid, houseId)

-- Client: Show notification (auto-detects your notify system)
exports['dg-bridge']:notifyClient('success', 'Success!', 'Task completed', 5000)

-- Client: Get player data
local playerData = exports['dg-bridge']:getPlayerData()
print('Job: ' .. playerData.job)
```

### Documentation

- 📖 **[COMMONLY_USED_SCRIPTS_GUIDE.md](./COMMONLY_USED_SCRIPTS_GUIDE.md)** - Complete reference for all 20 new functions
- 💡 **[BRIDGE_USAGE_EXAMPLES.md](./BRIDGE_USAGE_EXAMPLES.md)** - Real-world code examples and workflows

### Supported Scripts

| Category | Examples |
|----------|----------|
| Housing | qb-properties, ps-housing, renewed-apartments, and 3+ others |
| Vehicle Keys | qb-vehiclekeys, wasabi_carlock, ox_target, and 3+ others |
| Garages | qb-garage, ps-garage, jg-garages, and 3+ others |
| Shops | qb-shops, ps-stores, renewed-shops, and 2+ others |
| Jobs | qb-policejob, qb-ambulancejob, qb-mechanic, and 4+ others |
| Banking | qb-banking, ps-banking, renewed-banking, and 2+ others |
| Phone | qb-phone, mythic_phone, npwd, gksphone, and 3+ others |
| And 5+ more categories... | See [COMMONLY_USED_SCRIPTS_GUIDE.md](./COMMONLY_USED_SCRIPTS_GUIDE.md) for complete list |

### New Server Exports

```lua
-- Detection Functions (check what's running)
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

-- Wrapper Functions (unified API)
giveVehicleKeys(plate, playerName)
removeVehicleKeys(plate)
storeVehicleInGarage(vehicle, source)
getPlayerHouses(citizenid)
addHouseKey(citizenid, house)
getPlayerBankBalance(src)
sendPhoneMessage(citizenid, phone, message, sender)
getShopItems()
addTargetEntity(entity, options)
```

### New Client Exports

```lua
-- Notification System
notifyClient(type, title, message, duration)
getNotifyResource()

-- Player Data
getPlayerData()

-- Inventory
hasClientItem(itemName)
getItemCount(itemName)

-- Animations & Visuals
playAnimation(animDict, animName, flags)
stopAnimation()
draw3DText(coords, text)
drawBlip(coords, sprite, color, scale, label)

-- Utilities
teleportClient(coords)
getPlayerVehicle()
getVehicleClass(vehicle)
openVehicleDoorsNearby(distance)

-- Targeting
getTargetSystemResource()
addDrawTextTarget(coords, message, distance)
```

---

## 📚 Related Resources

| Resource | Description |
|----------|-------------|
| [`dg-adminmenu`](https://github.com/DreadedGScripts/dgscripts-admin-menu) | Admin and anti-cheat panel |
| [`dg-discord-bot`](https://github.com/DreadedGScripts/dg-discord) | Discord thread/webhook integration |
| [`dg-notifications`](https://github.com/DreadedGScripts/dg-notifications) | Realtime popup notifications |
