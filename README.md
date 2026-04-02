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

## 📚 Related Resources

| Resource | Description |
|----------|-------------|
| [`dg-adminmenu`](https://github.com/DreadedGScripts/dgscripts-admin-menu) | Admin and anti-cheat panel |
| [`dg-discord-bot`](https://github.com/DreadedGScripts/dg-discord) | Discord thread/webhook integration |
| [`dg-notifications`](https://github.com/DreadedGScripts/dg-notifications) | Realtime popup notifications |
