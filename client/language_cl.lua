function NotifyBoomBox(title, description, type)
    if Config.Notifi == "ox" then
        lib.notify({
            title = title,
            description = description,
            type = type or 'inform'
        })
    elseif Config.Notifi == "esx" then
        ESX = ESX or exports['es_extended']:getSharedObject()
        if ESX then
            local msg = ('%s - %s'):format(title, description)
            ESX.ShowNotification(msg)
        else
            print("esx object not found!")
        end
    elseif Config.Notifi == "qb" then
        local QBCore = QBCore or exports['qb-core']:GetCoreObject()
        if QBCore then
            QBCore.Functions.Notify(description, type or 'primary')
        else
            print("qb object not found!")
        end
    else
        print(('Notification Error: %s - %s'):format(title, description))
    end
end

RegisterNetEvent("NotifyBoomBox", function(title, description, typss)
    NotifyBoomBox(title, description, typss)
end)