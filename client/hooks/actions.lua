--[[
    This file will contain specific functions that are called when specific
    events occur, the idea of this file is that server owners / developers can
    add custom code in here to allow them to customize other reactions when
    these events occur such as logging etc.
]]

--- This function runs whenever the client opens the bait car remote
function onClientRemoteOpen()
    logger:trace("hooks:onClientRemoteOpen()")
end


--- This function runs whenever the client closes the bait car remote
function onClientRemoteClose()
    logger:trace("hooks:onClientRemoteClose()")
end


--- This function runs whenever the client uses the remote to locate a bait car
---@param vehicleNetId number The network ID for the vehicle being located
---@param vehicleCoords vector3? The coordinates of the vehicle, or nil if unable to locate the vehicle
function onClientLocateBaitCar(vehicleNetId, vehicleCoords)
    logger:trace(
        "hooks:onClientLocateBaitCar(%s, %s)",
        tostring(vehicleNetId),
        tostring(vehicleCoords)
    )
end


--- This function runs whenever the client uses the remote to toggle power on a bait car
---@param vehicleNetId number The network ID for the vehicle being powered
---@param powerState boolean True when the client powered the vehicle on, false otherwise
function onClientPowerBaitCar(vehicleNetId, powerState)
    logger:trace(
        "hooks:onClientPowerBaitCar(%s, %s)",
        tostring(vehicleNetId),
        tostring(powerState)
    )
end


--- This function runs whenever the client uses the remote to toggle locks on a bait car
---@param vehicleNetId number The network ID for the vehicle being powered
---@param locksState boolean True when the client locked the vehicle, false otherwise
function onClientLockBaitCar(vehicleNetId, locksState)
    logger:trace(
        "hooks:onClientLockBaitCar(%s, %s)",
        tostring(vehicleNetId),
        tostring(locksState)
    )
end


--- This function runs whenever the client uses the remote to flash the lights on a bait car
---@param vehicleNetId number The network ID for the vehicle targeted
function onClientFlashLightsBaitCar(vehicleNetId)
    logger:trace(
        "hooks:onClientFlashLightsBaitCar(%s)",
        tostring(vehicleNetId)
    )
end


--- This function runs whenever the client uses the remote to trip the alarm on a bait car
---@param vehicleNetId number The network ID for the vehicle targeted
function onClientTripAlarmBaitCar(vehicleNetId)
    logger:trace(
        "hooks:onClientTripAlarmBaitCar(%s)",
        tostring(vehicleNetId)
    )
end