--[[
    Reads the raw bait car statebag from a vehicle handle.
    Returns `nil` when the entity is invalid or has no gear installed.
]]
function getBaitCarState(vehicle)
    if nil == vehicle or 0 == vehicle or not DoesEntityExist(vehicle) then
        return nil
    end

    return Entity(vehicle).state.baitCar
end


--[[
    Returns `true` when the given vehicle has bait car gear installed.
]]
function isBaitCar(vehicle)
    local state = getBaitCarState(vehicle)
    return nil ~= state and true == state.installed
end


--[[
    Returns `true` when the vehicle is a bait car whose engine has been
    remotely killed by the operator. This is the signal other resources
    should read before trying to keep the engine running.
]]
function isEngineDisabled(vehicle)
    local state = getBaitCarState(vehicle)
    return nil ~= state and true == state.installed and true == state.engineDisabled
end


--[[
    Returns `true` when the vehicle is a bait car whose doors have been
    remotely locked by the operator.
]]
function areDoorsLocked(vehicle)
    local state = getBaitCarState(vehicle)
    return nil ~= state and true == state.installed and true == state.doorsLocked
end


--[[
    Finds the closest vehicle to the player within `maxDistance` meters.
    Returns the vehicle handle, or `0` when nothing is in range.
]]
function getNearestVehicle(maxDistance)
    local pedCoords = GetEntityCoords(PlayerPedId())
    local vehicles = GetGamePool("CVehicle")
    local best = 0
    local bestDist = maxDistance or 5.0

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        local dist = #(pedCoords - GetEntityCoords(vehicle))

        if dist < bestDist then
            best = vehicle
            bestDist = dist
        end
    end

    return best
end


--[[
    Resolves a vehicle's friendly display name, falling back to the raw model
    label when the game has no localized text for it.
]]
function getVehicleDisplayName(vehicle)
    local label = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local friendly = GetLabelText(label)

    if nil == friendly or "" == friendly or "NULL" == friendly then
        return label
    end

    return friendly
end


--[[
    Collects every bait car currently streamed near the player and within
    `Config.RemoteRange`, sorted by distance (closest first). Each entry is a
    lightweight descriptor the remote UI can render and act upon later by net
    id (so it survives the entity handle being recreated while streaming).
]]
function collectBaitCars()
    local pedCoords = GetEntityCoords(PlayerPedId())
    local vehicles = GetGamePool("CVehicle")
    local result = {}

    for i = 1, #vehicles do
        local vehicle = vehicles[i]

        if isBaitCar(vehicle) then
            local dist = #(pedCoords - GetEntityCoords(vehicle))

            if dist <= Config["RemoteRange"] then
                result[#result + 1] = {
                    netId = VehToNet(vehicle),
                    dist = dist,
                    model = getVehicleDisplayName(vehicle),
                    plate = (GetVehicleNumberPlateText(vehicle) or ""):gsub("%s+$", ""),
                }
            end
        end
    end

    table.sort(result, function(a, b)
        return a.dist < b.dist
    end)

    return result
end


--[[
    Shows a short notification in the top left feed.
]]
function notify(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end
