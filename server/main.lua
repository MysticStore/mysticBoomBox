local ESX, QBCore
local boombox = 'blacklist.json'

CreateThread(function()
    if Config.Framework == "esx" then
        ESX = exports['es_extended']:getSharedObject()
        print("ESX loaded on the server side.")
    elseif Config.Framework == "qb" then
        QBCore = exports['qb-core']:GetCoreObject()
        print("QBCore loaded on the server side.")
    end
end)

local function loadBlacklist()
    local data = LoadResourceFile(GetCurrentResourceName(), boombox)
    return data and json.decode(data) or {}
end

local function saveBlacklist(songs)
    SaveResourceFile(GetCurrentResourceName(), boombox, json.encode(songs, { indent = true }), -1)
end

RegisterServerEvent('mysticBoombox:addBlacklistedSong')
AddEventHandler('mysticBoombox:addBlacklistedSong', function(name, link)
    local songs = loadBlacklist()

    table.insert(songs, {
        name = name,
        link = link
    })

    saveBlacklist(songs)
    print(song)
    print("[mysticBoomBox] Song blacklisted: " .. name)
end)

RegisterServerEvent('mysticBoombox:requestBlacklistedSongs')
AddEventHandler('mysticBoombox:requestBlacklistedSongs', function()
    local src = source
    local songs = loadBlacklist()
    TriggerClientEvent('mysticBoombox:showBlacklistedSongs', src, songs)
end)

RegisterServerEvent("mysticBoombox:removeItem", function()
    local src = source

    if Config.Framework == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.removeInventoryItem(Config.BoomboxItemName, 1)
        end

    elseif Config.Framework == "qb" and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem(Config.BoomboxItemName, 1)
        end
    end
end)

RegisterServerEvent("mysticBoombox:returnItem", function()
    local src = source

    if Config.Framework == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.addInventoryItem(Config.BoomboxItemName, 1)
        end

    elseif Config.Framework == "qb" and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.AddItem(Config.BoomboxItemName, 1)
        end
    end
end)

RegisterCommand(Config.Command, function(source, args, rawCommand)
    local src = source
    local playerGroup = 'user'

    if Config.Framework == "esx" and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
            playerGroup = xPlayer.getGroup()

    elseif Config.Framework == "qb" and QBCore then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player and Player.PlayerData and Player.PlayerData.group then
            playerGroup = Player.PlayerData.group
        end
    end

    local allowed = false

    if type(Config.Permission) == 'table' then
        for _, rank in ipairs(Config.Permission) do
            if playerGroup == rank then
                allowed = true
                break
            end
        end
    else
        allowed = (playerGroup == Config.Permission)
    end

    if allowed then
        TriggerClientEvent("mysticBoombox:openMenu", src)
    else
        TriggerClientEvent("NotifyBoomBox", src, "BoomBox", "You do not have permission for this command.", "error")
    end
end)
