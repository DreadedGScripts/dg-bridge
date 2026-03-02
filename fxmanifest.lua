fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dg-bridge'
description 'Framework Bridge for DG Scripts - Supports QBCore, ESX, Standalone'
author 'DG-Scripts'
version '1.0.0'

shared_scripts {
    'shared/*.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}

exports {
    'getFramework',
    'isQBCore',
    'isESX',
    'isStandalone'
}

server_exports {
    'getFramework',
    'detectFramework',
    'getLicense',
    'getIdentifier',
    'kickPlayer',
    'banPlayer',
    'getPlayerJob',
    'getPlayerMoney',
    'isPlayerAdmin',
    'addMoney',
    'removeMoney',
    'giveItem',
    'removeItem',
    'getInventory',
    'getAllItems',
    'getPlayerGang',
    'getAllIdentifiers',
    'notifyPlayer',
    'getCharacterName',
    'getMetadata',
    'setMetadata',
    'getPlayerCoords',
    'teleportPlayer'
}

client_exports {
    'isQBCore',
    'isESX',
    'getPlayerData',
    'notify',
    'getJob',
    'getMoney',
    'getGang',
    'getCharName',
    'draw3DText',
    'hasItem'
}
