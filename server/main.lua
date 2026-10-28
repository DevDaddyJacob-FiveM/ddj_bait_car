local function getVehicle(vehNetId)
    if nil == vehNetId then
        return nil
    end

    local entity = NetworkGetEntityFromNetworkId(vehNetId)
    if 0 == entity or not DoesEntityExist(entity) then
        return nil
    end

    return entity
end


local function getState(entity)
    return Entity(entity).state.baitCar
end


local function setState(entity, newState)
    Entity(entity).state:set("baitCar", newState, true)
end


local function notify(source, kind, message)
    TriggerClientEvent("DevJacob:BaitCar:Client:Notify", source, kind, message)
end


RegisterNetEvent("DevJacob:BaitCar:Server:Install", function(vehNetId)
    local source = source

    local entity = getVehicle(vehNetId)
    if nil == entity then
        return
    end

    local state = getState(entity)
    if nil ~= state and true == state.installed then
        notify(source, "error", "This vehicle already has bait car gear installed")
        return
    end

    setState(entity, {
        installed = true,
        engineDisabled = false,
        doorsLocked = false,
    })

    logger:info("player %d installed bait car gear on net id %d", source, vehNetId)
    notify(source, "success", "Bait car gear installed")
end)


RegisterNetEvent("DevJacob:BaitCar:Server:Uninstall", function(vehNetId)
    local source = source

    local entity = getVehicle(vehNetId)
    if nil == entity then
        return
    end

    local state = getState(entity)
    if nil == state or true ~= state.installed then
        notify(source, "error", "This vehicle does not have bait car gear installed")
        return
    end

    setState(entity, nil)

    logger:info("player %s removed bait car gear from net id %d", source, vehNetId)
    notify(source, "success", "Bait car gear removed")
end)


RegisterNetEvent("DevJacob:BaitCar:Server:SetControl", function(vehNetId, control, value)
    local entity = getVehicle(vehNetId)
    if nil == entity then
        return
    end

    local state = getState(entity)
    if nil == state or true ~= state.installed then
        return
    end

    -- Rebuild the whole table so the statebag replicates the change.
    local newState = {
        installed = true,
        engineDisabled = state.engineDisabled,
        doorsLocked = state.doorsLocked,
    }

    if "power" == control then
        -- Killing power cuts the engine and locks the doors together;
        -- restoring it lets the engine start and unlocks the doors.
        newState.engineDisabled = (true == value)
        newState.doorsLocked = (true == value)
    elseif "engine" == control then
        newState.engineDisabled = (true == value)
    elseif "doors" == control then
        newState.doorsLocked = (true == value)
    else
        return
    end

    setState(entity, newState)

    logger:debug("net id %s control %s set to %s", vehNetId, control, tostring(value))
end)


--[[
    Lets the client fetch a bait car's state by net id when its entity is no
    longer streamed in locally (e.g. the operator is far away), so the
    remote can keep showing an accurate readout instead of going blank.
]]
rpc.register("DevJacob:BaitCar:Server:GetState", function(source, cb, vehNetId)
    local entity = getVehicle(vehNetId)
    if nil == entity then
        cb(nil)
        return
    end

    cb(getState(entity))
end)


RegisterNetEvent("DevJacob:BaitCar:Server:Momentary", function(vehNetId, action)
    local entity = getVehicle(vehNetId)
    if nil == entity then
        return
    end

    local state = getState(entity)
    if nil == state or true ~= state.installed then
        return
    end

    -- Route momentary effects to the entity's owner where they will actually
    -- take hold, falling back to a broadcast if there is no clear owner.
    local owner = NetworkGetEntityOwner(entity)
    if nil ~= owner and -1 ~= owner then
        TriggerClientEvent("DevJacob:BaitCar:Client:Momentary", owner, vehNetId, action)
    else
        TriggerClientEvent("DevJacob:BaitCar:Client:Momentary", -1, vehNetId, action)
    end
end)


--[[ ------------------------------------------------------------------------
    Server side exports mirroring the client ones, for resources that reason
    about bait cars from the server.
--------------------------------------------------------------------------- ]]
exports("isBaitCar", function(entity)
    local state = getState(entity)
    return nil ~= state and true == state.installed
end)

exports("isEngineDisabled", function(entity)
    local state = getState(entity)
    return nil ~= state and true == state.installed and true == state.engineDisabled
end)

exports("areDoorsLocked", function(entity)
    local state = getState(entity)
    return nil ~= state and true == state.installed and true == state.doorsLocked
end)

exports("getBaitCarState", function(entity)
    return getState(entity)
end)
