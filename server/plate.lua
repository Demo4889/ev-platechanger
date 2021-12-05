local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('ev:getPlate', function(plate, currentPlate)
    local source <const> = source
    local xPlayer = QBCore.Functions.GetPlayer(source)
    if xPlayer then
        if GetVehiclePedIsIn(GetPlayerPed(source)) == 0 or not currentPlate then
            return TriggerClientEvent('QBCore:Notify', source, Config.Locales.ErrorVehicle)
        elseif plate:len() > Config.MaxChars then
            return TriggerClientEvent('QBCore:Notify', source, Config.Locales.ErrorCharsMax)
        end
        for i=0, #Config.Blacklist, 1 do
            if Config.Blacklist[i] == plate then
                return TriggerClientEvent('QBCore:Notify', source, 'You tried to set a plate with a bad word: ' .. plate)
            end
        end
        exports.oxmysql:execute('SELECT plate FROM player_vehicles WHERE plate = @plate AND citizenid = @citizenid', {
            ['plate'] = currentPlate,
            ['citizenid'] = xPlayer.PlayerData.citizenid
        }, function(result)
            if result[1] then
                exports.oxmysql:execute('SELECT * FROM player_vehicles WHERE plate = @plate', {
                    ['plate'] = plate
                }, function(exist)
                    if not exist[1] then
                        exports.oxmysql:execute('SELECT plate, mods FROM player_vehicles WHERE plate = @plate', {
                            ['plate'] = currentPlate
                        },function(currentVehicle)
                            if currentVehicle[1] then
                                local vehicle = json.decode(currentVehicle[1].mods)
                                if not vehicle.plate then
                                    return TriggerClientEvent('QBCore:Notify', source, Config.Locales.ErrorPlateReal)
                                end
                                local oldPlate = vehicle.plate
                                vehicle.plate = plate
                                exports.oxmysql:execute('UPDATE player_vehicles SET plate = @newplate, mods = @vehicle WHERE plate = @oldplate AND citizenid=@citizenid', {
                                    ['newplate'] = plate,
                                    ['oldplate'] = oldPlate,
                                    ['citizenid'] = xPlayer.PlayerData.citizenid,
                                    ['vehicle'] = json.encode(vehicle)
                                })
                                SetVehicleNumberPlateText(GetVehiclePedIsIn(GetPlayerPed(source)), plate)
                                xPlayer.Functions.RemoveItem('licenseplate', 1)
                                TriggerClientEvent('QBCore:Notify', source, Config.Locales.NewPlate)
                                return
                            end
                        end)
                    else
                        TriggerClientEvent('QBCore:Notify', source, Config.Locales.ErrorPlate)
                    end
                end)
            else
                TriggerClientEvent('QBCore:Notify', source, Config.Locales.ErrorOwner)
            end
        end)
    end
end)

QBCore.Functions.CreateUseableItem('licenseplate', function(source)
    local source <const> = source
    local xPlayer = QBCore.Functions.GetPlayer(source)
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(source))
    if vehicle ~= 0 then
        exports.oxmysql:execute('SELECT plate FROM player_vehicles WHERE plate = @plate AND citizenid = @citizenid', {
            ['plate'] = GetVehicleNumberPlateText(vehicle):match( "^%s*(.-)%s*$" ),
            ['citizenid'] = xPlayer.PlayerData.citizenid
        }, function(result)
            if result[1] then
                TriggerClientEvent('ev:getPlateNui', source)
            else
                TriggerClientEvent('QBCore:Notify', source, Config.Locales.ErrorOwner)
            end
        end)
    else
        TriggerClientEvent('QBCore:Notify', source, Config.Locales.ErrorWalking)
    end
end)