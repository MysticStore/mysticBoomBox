Config = {}

-- Enter name of your frameworkd: esx, qb
Config.Framework = "esx"

-- Notification system: "ox", "esx", or "qb"
Config.Notifi = "esx"

-- The command players use to open or control the boombox (e.g. /boombox)
Config.Command = 'boombox'

-- List of allowed groups (ranks) that can use the command
Config.Permission = { 'owner', 'developer', 'headadmin' }

-- If true, the boombox item will be removed from the player's inventory when placed on the ground.
Config.RemoveItemOnPlace = true

-- The exact item name in the inventory that represents the boombox
Config.BoomboxItemName = "boombox"
