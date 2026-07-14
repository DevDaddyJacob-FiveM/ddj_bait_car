local function applyBaitCarEffects(vehicle)
    if not isBaitCar(vehicle) then
        return
    end

    -- Only the entity owner may reliably mutate it.
    if NetworkGetEntityOwner(vehicle) ~= PlayerId() then
        return
    end

    local state = getBaitCarState(vehicle)

    if true == state.engineDisabled then
        if GetIsVehicleEngineRunning(vehicle) then
            SetVehicleEngineOn(vehicle, false, true, true)
        end

        if Config["LockEngineWhenDisabled"] then
            SetVehicleUndriveable(vehicle, true)
        end
    else
        SetVehicleUndriveable(vehicle, false)
    end

    local lockStatus = 1
    if true == state.doorsLocked then
        lockStatus = 2
    end

    SetVehicleDoorsLocked(vehicle, lockStatus)
end


AddStateBagChangeHandler("baitCar", nil, function(bagName, _key, _value, _reserved, _replicated)
    local vehicle = GetEntityFromStateBagName(bagName)
    if 0 == vehicle then
        return
    end

    applyBaitCarEffects(vehicle)

    if nui.isOpen then
        updateRemote()
    end
end)


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        local vehicles = GetGamePool("CVehicle")
        for i = 1, #vehicles do
            applyBaitCarEffects(vehicles[i])
        end
    end
end)


RegisterNetEvent("DevJacob:BaitCar:Client:Momentary", function(vehNetId, action)
    if not NetworkDoesNetworkIdExist(vehNetId) then
        return
    end

    local vehicle = NetToVeh(vehNetId)
    if not DoesEntityExist(vehicle) then
        return
    end

    if "alarm" == action then
        SetVehicleAlarm(vehicle, true)
        StartVehicleAlarm(vehicle)

        return
    end

    if "flash" == action then
        Citizen.CreateThread(function()
            for _ = 1, 4 do
                SetVehicleLights(vehicle, 2)
                Citizen.Wait(180)
                SetVehicleLights(vehicle, 1)
                Citizen.Wait(180)
            end

            SetVehicleLights(vehicle, 0)
        end)

        return
    end
end)


RegisterNetEvent("DevJacob:BaitCar:Client:Notify", function(_kind, message)
    notify(message)
end)



-- Keep the remote's readout in sync while it is open, since control changes
-- take a round trip through the server before the statebag updates.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(400)

        if nui.isOpen then
            updateRemote()
        end
    end
end)


local function resolveGearTarget()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if 0 == vehicle then
        vehicle = getNearestVehicle(Config["InstallDistance"])
    end

    return vehicle
end


local function baitcarUninstallCommand()
    local vehicle = resolveGearTarget()

    if 0 == vehicle or not DoesEntityExist(vehicle) then
        notify("No vehicle nearby to remove the bait car gear from")
        return
    end

    if not isBaitCar(vehicle) then
        notify("This vehicle does not have bait car gear installed")
        return
    end

    TriggerServerEvent("DevJacob:BaitCar:Server:Uninstall", VehToNet(vehicle))
end


local function baitcarInstallCommand()
    local vehicle = resolveGearTarget()

    if 0 == vehicle or not DoesEntityExist(vehicle) then
        notify("No vehicle nearby to install the bait car gear on")
        return
    end

    if isBaitCar(vehicle) then
        notify("This vehicle already has bait car gear installed")
        return
    end

    TriggerServerEvent("DevJacob:BaitCar:Server:Install", VehToNet(vehicle))
end


RegisterCommand("baitcar", function(p1, args, p3)
    if 0 < #args and "uninstall" == args[1] then
        baitcarUninstallCommand()
        return
    end

    if 0 < #args and "install" == args[1] then
        baitcarInstallCommand()
        return
    end

    nui:open()
end, false)

if
    nil ~= Config["RemoteKeybind"]
    and "" ~= Config["RemoteKeybind"]["DefaultPrimary"]
then
    RegisterKeyMapping(
        "baitcar",
        "Open the bait car remote",
        Config["RemoteKeybind"]["Mapper"],
        Config["RemoteKeybind"]["DefaultPrimary"]
    )
end


RegisterCommand("baitcar install", function() /* no-op */ end, false)
RegisterCommand("baitcar uninstall", function() /* no-op */ end, false)


-- Make sure focus is released if the resource is stopped while the remote is
-- open, otherwise the player would be stuck with a locked cursor.
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName and nui.isOpen then
        SetNuiFocus(false, false)
    end
end)


--[[
    Exports for external resources to hook into.

    The headline use case: a resource that keeps engines running should skip
    any vehicle where `isEngineDisabled` returns true, so it does not fight the
    operator who has killed the bait car.
]]
exports("isBaitCar", function(vehicle)
    return isBaitCar(vehicle)
end)

exports("isEngineDisabled", function(vehicle)
    return isEngineDisabled(vehicle)
end)

exports("areDoorsLocked", function(vehicle)
    return areDoorsLocked(vehicle)
end)

exports("getBaitCarState", function(vehicle)
    return getBaitCarState(vehicle)
end)

exports("getNearestBaitCar", function(maxDistance)
    local cars = collectBaitCars()
    local limit = maxDistance or Config["RemoteRange"]

    for i = 1, #cars do
        if cars[i].dist <= limit then
            return NetToVeh(cars[i].netId), cars[i].netId
        end
    end

    return 0, nil
end)
