local savedVolume = GetResourceKvpString('boombox_volume')
local savedDistance = GetResourceKvpString('boombox_distance')
local currentVolume = savedVolume and tonumber(savedVolume) or 1.0
local DISTANCE = savedDistance and tonumber(savedDistance) or 15.0
local currentMusicId = nil
local placedBoombox = nil
local previewBoombox = nil
local heldBoombox = nil
local holdingBoombox = false
local MAX_DISTANCE = 1.0
local boomboxModel = `prop_boombox_01`
local blacklistedSongs = {}
local ESX, QBCore

CreateThread(function()
    if Config.Framework == "esx" then
        ESX = exports['es_extended']:getSharedObject()
        while not ESX or not ESX.PlayerData or not ESX.PlayerData.job do
            Wait(100)
        end
        print("ESX loaded on the client side.")
    elseif Config.Framework == "qb" then
        QBCore = exports['qb-core']:GetCoreObject()
        print("QBCore loaded on the client side.")
    end
end)


RegisterNetEvent('mysticBoombox:showBlacklistedSongs', function(songs)
    blacklistedSongs = songs
end)

local function isLinkBlacklisted(url)
    for _, song in pairs(blacklistedSongs) do
        if string.lower(song.link) == string.lower(url) then
            return true
        end
    end
    return false
end

function showBlacklistMenu()
    lib.registerContext({
        id = 'blackListLinks',
        title = 'Blacklist Links',
        options = {
            {
                title = 'Blacklist Song',
                description = 'Blaclist YouTube song link',
                icon = 'fa-solid fa-ban',
                onSelect = function()
                    local input = lib.inputDialog('Blacklist Song', {'Song Name', 'YouTube Link'})
                    if input and input[1] and input[2] and input[1] ~= '' and input[2] ~= '' then
                        TriggerServerEvent('mysticBoombox:addBlacklistedSong', input[1], input[2])
                        Wait(500)
                        TriggerServerEvent('mysticBoombox:requestBlacklistedSongs')
                    else
                        NotifyBoomBox("BoomBox", "You must enter both the song name and the link.", "error")
                    end
                end
            },
            {
                title = 'Blacklisted Songs',
                description = 'List of blacklisted songs',
                icon = 'fa-solid fa-list',
                onSelect = function()
                    local list = {}
                    for _, song in pairs(blacklistedSongs) do
                        table.insert(list, {
                            title = song.name,
                            description = song.link,
                            icon = 'fa-solid fa-music'
                        })
                    end

                    lib.registerContext({
                        id = 'blacklistedSongsList',
                        title = 'Blacklisted Songs',
                        options = list
                    })

                    lib.showContext('blacklistedSongsList')
                end
            },
        }
    })

    lib.showContext('blackListLinks')
end

function boomBoxSettings()
    TriggerServerEvent('mysticBoombox:requestBlacklistedSongs')
    Wait(300)

    lib.registerContext({
        id = 'BoomBox',
        title = 'BoomBox Settings',
        options = {
            {
                title = 'Distance',
                description = 'At what distance will the music be heard (Currently: ' .. DISTANCE .. 'm)',
                icon = 'fa-solid fa-arrows-to-dot',
                onSelect = function()
                    local input = lib.inputDialog('Set Distance', {'Distance (5-50)'})
                    if input and tonumber(input[1]) then
                        local dist = tonumber(input[1])
                        if dist >= 5 and dist <= 50 then
                            DISTANCE = dist
                            if currentMusicId then
                                exports.xsound:Distance(currentMusicId, DISTANCE)
                            end
                            NotifyBoomBox('BoomBox', 'Distance set to ' .. dist .. ' meters.', 'success')
                        else
                            NotifyBoomBox('Error', 'Please enter a number between 5 and 50.', 'error')
                        end
                    end
                end,
            },
            {
                title = 'Start Volume',
                description = 'Adjust start volume (Currently: ' .. math.floor(currentVolume * 100) .. '%)',
                icon = 'fa-solid fa-volume-high',
                onSelect = function()
                    local input = lib.inputDialog('Set Start Volume', {'Volume (0 - 100)'})
                    if input and tonumber(input[1]) then
                        local vol = tonumber(input[1])
                        if vol >= 0 and vol <= 100 then
                            currentVolume = vol / 100
                            if currentMusicId then
                                exports.xsound:setVolume(currentMusicId, currentVolume)
                            end
                            NotifyBoomBox('BoomBox', 'Start volume set to ' .. vol .. '%.', 'success')
                        else
                            NotifyBoomBox('Error', 'Please enter a number between 0 and 100.', 'error')
                        end
                    end
                end,
            },
            {
                title = 'Blacklisted Links',
                description = 'Blacklisted links',
                icon = 'fa-solid fa-ban',
                onSelect = function()
                    showBlacklistMenu()
                end,
            },
            {
                title = 'Disable all Boomboxes',
                description = 'All placed boombox props will be deleted!',
                icon = 'fa-solid fa-power-off',
                onSelect = function()
                    if currentMusicId then
                        exports.xsound:Destroy(currentMusicId)
                        currentMusicId = nil
                    end
                    if placedBoombox and DoesEntityExist(placedBoombox) then
                        DeleteEntity(placedBoombox)
                        placedBoombox = nil
                    end
                    NotifyBoomBox('BoomBox', 'All Boomboxes have been deleted.', 'success')
                end,
            },
        }
    })

    lib.showContext('BoomBox')
end

RegisterNetEvent("mysticBoombox:openMenu", function()
  boomBoxSettings()
end)

function playBoomboxMusic(url, coords)
    if isLinkBlacklisted(url) then
        NotifyBoomBox('Error', 'This link is blacklisted.', 'error')
        return
    end

    currentVolume = Config.StartVolume
    currentMusicId = 'music_' .. tostring(math.random(1111, 9999))

    exports.xsound:PlayUrlPos(currentMusicId, url, currentVolume, coords)
    exports.xsound:Distance(currentMusicId, MAX_DISTANCE)
    exports.xsound:setVolume(currentMusicId, currentVolume)
end

CreateThread(function()
    TriggerServerEvent('mysticBoombox:requestBlacklistedSongs')
end)

local function loadModel(model)
    local modelHash = type(model) == 'string' and GetHashKey(model) or model
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Citizen.Wait(10)
        end
    end
    return modelHash
end

local function musicMenu()
    lib.registerContext({
        id = 'music',
        title = 'Music - Volume: ' .. math.floor(currentVolume * 100) .. '%',
        options = {
            {
                title = 'Play music',
                icon = 'fa-solid fa-play',
                onSelect = function()
                    local input = lib.inputDialog('Music Menu', {'URL'})
                    if not input or not input[1] then return end
                    local url = input[1]
                    if isLinkBlacklisted(url) then
                        NotifyBoomBox('Error', 'This song is blacklisted.', 'error')
                        return
                    end

                    if currentMusicId then
                        exports.xsound:Destroy(currentMusicId)
                    end

                    currentMusicId = 'music_' .. tostring(math.random(10000, 99999))
                    local coords = GetEntityCoords(PlayerPedId())
                    exports.xsound:PlayUrlPos(currentMusicId, url, currentVolume, coords)
                    exports.xsound:Distance(currentMusicId, 15)
                    exports.xsound:setVolume(currentMusicId, currentVolume)
                end,
            },
            {
                title = 'Stop music',
                icon = 'fa-solid fa-stop',
                onSelect = function()
                    if currentMusicId then
                        exports.xsound:Destroy(currentMusicId)
                        currentMusicId = nil
                    end
                end,
            },
            {
                title = 'Volume up 10%',
                icon = 'fa-solid fa-volume-up',
                onSelect = function()
                    if currentMusicId then
                        currentVolume = math.min(currentVolume + 0.1, 1.0)
                        exports.xsound:setVolume(currentMusicId, currentVolume)
                        musicMenu()
                    end
                end,
            },
            {
                title = 'Volume down 10%',
                icon = 'fa-solid fa-volume-down',
                onSelect = function()
                    if currentMusicId then
                        currentVolume = math.max(currentVolume - 0.1, 0.0)
                        exports.xsound:setVolume(currentMusicId, currentVolume)
                        musicMenu()
                    end
                end,
            },
        }
    })
    lib.showContext('music')
end

local previewThread = nil

local function holdBoomboxInHand()
    if holdingBoombox then return end
    local ped = PlayerPedId()
    local modelHash = loadModel('prop_boombox_01')
    local x, y, z = table.unpack(GetEntityCoords(ped))

    heldBoombox = CreateObject(modelHash, x, y, z + 0.2, true, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    AttachEntityToEntity(heldBoombox, ped, GetPedBoneIndex(ped, 57005), 0.32, 0.0, -0.05, 0.0, 270.0, 60.0, true, true, false, true, 1, true)
    holdingBoombox = true
end

local function removeHeldBoombox()
    if heldBoombox and DoesEntityExist(heldBoombox) then
        DeleteEntity(heldBoombox)
        heldBoombox = nil
        holdingBoombox = false
    end
end

local function startPreviewPositioning()
    if previewThread then return end
    previewThread = Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        while previewBoombox and DoesEntityExist(previewBoombox) do
            local pCoords = GetEntityCoords(playerPed)
            local forward = GetEntityForwardVector(playerPed)
            local targetX = pCoords.x + forward.x * MAX_DISTANCE
            local targetY = pCoords.y + forward.y * MAX_DISTANCE

            local foundGround, groundZ = GetGroundZFor_3dCoord(targetX, targetY, pCoords.z + 10.0, 0)
            if not foundGround then groundZ = pCoords.z end

            SetEntityCoords(previewBoombox, targetX, targetY, groundZ, false, false, false, false)
            SetEntityHeading(previewBoombox, GetEntityHeading(playerPed))

            Citizen.Wait(50)
        end
        previewThread = nil
    end)
end

function placeBoomboxPreview()
    local playerPed = PlayerPedId()

    loadModel(boomboxModel)

    if previewBoombox and DoesEntityExist(previewBoombox) then
        DeleteEntity(previewBoombox)
        previewBoombox = nil
    end
    
    holdBoomboxInHand()

    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 10.0, 0)
    if not foundGround then groundZ = coords.z end

    previewBoombox = CreateObject(boomboxModel, coords.x, coords.y, groundZ + 5.0, false, false, false)
    SetEntityAlpha(previewBoombox, 150, false)

    startPreviewPositioning()
end

function playAnimation(dict, anim, duration)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end

    TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, -8.0, duration or -1, 49, 0, false, false, false)
end

function confirmPlaceBoombox()
    if not previewBoombox or not DoesEntityExist(previewBoombox) then return end

    playAnimation("pickup_object", "pickup_low", 1500)
    Wait(2000)

    local coords = GetEntityCoords(previewBoombox)
    local heading = GetEntityHeading(previewBoombox)

    loadModel(boomboxModel)

    local boombox = CreateObject(boomboxModel, coords.x, coords.y, coords.z, true, true, true)
    SetEntityHeading(boombox, heading)
    FreezeEntityPosition(boombox, true)
    placedBoombox = boombox

    DeleteEntity(previewBoombox)
    previewBoombox = nil

    removeHeldBoombox()

    if Config.RemoveItemOnPlace then
        TriggerServerEvent("mysticBoombox:removeItem")
    end

    exports.ox_target:addLocalEntity(boombox, {
        {
            label = "Play Music",
            icon = "fa-solid fa-music",
            onSelect = musicMenu
        },
        {
            label = "Pick up Boombox",
            icon = "fa-solid fa-box",
            onSelect = function()
                playAnimation("pickup_object", "pickup_low", 1500)
                Wait(1500)

                if placedBoombox and DoesEntityExist(placedBoombox) then
                    DeleteEntity(placedBoombox)
                    placedBoombox = nil
                end 
                if currentMusicId then
                    exports.xsound:Destroy(currentMusicId)
                    currentMusicId = nil
                end

                if Config.RemoveItemOnPlace then
                    TriggerServerEvent("mysticBoombox:returnItem")
                end
            end
        }
    })
end

function cancelPlaceBoombox()
    if previewBoombox and DoesEntityExist(previewBoombox) then
        DeleteEntity(previewBoombox)
        previewBoombox = nil
    end
    removeHeldBoombox()
end

RegisterNetEvent("boombox:use", function()
    placeBoomboxPreview()

    NotifyBoomBox("Boombox", "Press [E] to set up, [X] to cancel", "inform")

    Citizen.CreateThread(function()
        while previewBoombox and DoesEntityExist(previewBoombox) do
            Citizen.Wait(0)
            if IsControlJustReleased(0, 38) then -- E
                confirmPlaceBoombox()
            elseif IsControlJustReleased(0, 73) then -- X
                cancelPlaceBoombox()
            end
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if placedBoombox and DoesEntityExist(placedBoombox) then
            DeleteEntity(placedBoombox)
            placedBoombox = nil
        end
        if previewBoombox and DoesEntityExist(previewBoombox) then
            DeleteEntity(previewBoombox)
            previewBoombox = nil
        end
        if heldBoombox and DoesEntityExist(heldBoombox) then
            DeleteEntity(heldBoombox)
            heldBoombox = nil
            holdingBoombox = false
        end
        if currentMusicId then
            exports.xsound:Destroy(currentMusicId)
            currentMusicId = nil
        end
    end
end)