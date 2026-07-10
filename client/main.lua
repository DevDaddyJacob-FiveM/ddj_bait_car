local remoteOpen = false
local remoteCars = {}
local remoteIndex = 1


--[[ ------------------------------------------------------------------------
    Effect enforcement

    The client which owns a bait car entity is responsible for physically
    applying the remote controlled state (engine killed / doors locked) to it.
    We both react to statebag changes for a snappy response and sweep on a
    thread so that ownership migrations are picked up.
--------------------------------------------------------------------------- ]]
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

    if remoteOpen then
        pushRemoteStatus()
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


--[[ ------------------------------------------------------------------------
    Momentary actions (alarm / lights) routed to us by the server because we
    own the entity.
--------------------------------------------------------------------------- ]]
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
    elseif "flash" == action then
        Citizen.CreateThread(function()
            for _ = 1, 4 do
                SetVehicleLights(vehicle, 2)
                Citizen.Wait(180)
                SetVehicleLights(vehicle, 1)
                Citizen.Wait(180)
            end

            SetVehicleLights(vehicle, 0)
        end)
    end
end)


RegisterNetEvent("DevJacob:BaitCar:Client:Notify", function(_kind, message)
    notify(message)
end)


--[[ ------------------------------------------------------------------------
    The remote UI
--------------------------------------------------------------------------- ]]
function pushRemoteStatus()
    local car = remoteCars[remoteIndex]
    if nil == car then
        SendNUIMessage({ action = "empty" })
        return
    end

    local vehicle = NetToVeh(car.netId)
    local state = getBaitCarState(vehicle)

    SendNUIMessage({
        action = "status",
        index = remoteIndex,
        total = #remoteCars,
        car = {
            model = car.model,
            plate = car.plate,
            installed = nil ~= state and true == state.installed,
            engineDisabled = nil ~= state and true == state.engineDisabled,
            doorsLocked = nil ~= state and true == state.doorsLocked,
        },
    })
end


function openRemote()
    if remoteOpen then
        closeRemote()
        return
    end

    remoteCars = collectBaitCars()
    remoteIndex = 1
    remoteOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open" })
    pushRemoteStatus()
end


function closeRemote()
    remoteOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end


-- Keep the remote's readout in sync while it is open, since control changes
-- take a round trip through the server before the statebag updates.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(400)

        if remoteOpen then
            pushRemoteStatus()
        end
    end
end)


local function selectedNetId()
    local car = remoteCars[remoteIndex]
    if nil == car then
        return nil
    end

    return car.netId
end


RegisterNUICallback("baitcar:action", function(data, cb)
    local action = data.action

    if "close" == action then
        closeRemote()

    elseif "next" == action then
        if #remoteCars > 0 then
            remoteIndex = (remoteIndex % #remoteCars) + 1
            pushRemoteStatus()
        end

    elseif "prev" == action then
        if #remoteCars > 0 then
            remoteIndex = ((remoteIndex - 2) % #remoteCars) + 1
            pushRemoteStatus()
        end

    elseif "refresh" == action then
        remoteCars = collectBaitCars()
        remoteIndex = 1
        pushRemoteStatus()

    elseif "locate" == action then
        local netId = selectedNetId()
        if nil ~= netId and NetworkDoesNetworkIdExist(netId) then
            local coords = GetEntityCoords(NetToVeh(netId))
            SetNewWaypoint(coords.x, coords.y)
            notify("Waypoint set to bait car")
        end

    elseif "power" == action or "doors" == action then
        local netId = selectedNetId()
        if nil ~= netId then
            local state = getBaitCarState(NetToVeh(netId))

            -- POWER tracks the engine state (it kills the engine and locks the
            -- doors together); LOCKS tracks the doors on their own.
            local current = false
            if "power" == action then
                current = nil ~= state and true == state.engineDisabled
            else
                current = nil ~= state and true == state.doorsLocked
            end

            -- The button name doubles as the control name ("power" / "doors").
            TriggerServerEvent("DevJacob:BaitCar:Server:SetControl", netId, action, not current)
        end

    elseif "flash" == action or "alarm" == action then
        local netId = selectedNetId()
        if nil ~= netId then
            TriggerServerEvent("DevJacob:BaitCar:Server:Momentary", netId, action)
        end
    end

    cb({ ok = true })
end)


--[[ ------------------------------------------------------------------------
    Commands & keybinds
--------------------------------------------------------------------------- ]]
RegisterCommand("baitcar", function()
    openRemote()
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


local function resolveGearTarget()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if 0 == vehicle then
        vehicle = getNearestVehicle(Config["InstallDistance"])
    end

    return vehicle
end


RegisterCommand("installbaitcar", function()
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
end, false)


RegisterCommand("uninstallbaitcar", function()
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
end, false)


-- Make sure focus is released if the resource is stopped while the remote is
-- open, otherwise the player would be stuck with a locked cursor.
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() == resourceName and remoteOpen then
        SetNuiFocus(false, false)
    end
end)


--[[ ------------------------------------------------------------------------
    Exports for other resources to hook into.

    The headline use case: a resource that keeps engines running should skip
    any vehicle where `isEngineDisabled` returns true, so it does not fight the
    operator who has killed the bait car.
--------------------------------------------------------------------------- ]]
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
