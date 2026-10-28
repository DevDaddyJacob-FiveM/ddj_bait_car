nui = {}
nui.isOpen = false
nui.index = 1
nui.cars = {}

local function mergeDiscoveredCars(cars)
    local seen = {}
    for i = 1, #cars do
        seen[cars[i].netId] = true
    end

    local discovered = collectBaitCars()
    for i = 1, #discovered do
        local entry = discovered[i]

        if not seen[entry.netId] then
            cars[#cars + 1] = {
                netId = entry.netId,
                model = entry.model,
                plate = entry.plate,
            }
            seen[entry.netId] = true
        end
    end

    return cars
end

function nui:toggle()
    logger:trace("nui:toggle()")

    if self.isOpen then
        self:close()
    else
        self:open()
    end
end

function nui:open()
    logger:trace("nui:open()")

    self.isOpen = true
    self.cars = mergeDiscoveredCars(self.cars)

    if 0 == #self.cars or self.index > #self.cars then
        self.index = 1
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open" })

    updateRemote()
end

function nui:close()
    logger:trace("nui:close()")

    self.isOpen = false

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end

function nui:empty()
    logger:trace("nui:empty()")

    SendNUIMessage({ action = "empty" })
end

function nui:updateStatus(index, total, car)
    logger:trace("nui:updateStatus(%d, %d, %s)", index, total, json.encode(car))

    SendNUIMessage({
        action = "status",
        index = index,
        total = total,
        car = car,
    })
end

-- Last known state per net id, used as a fallback when a bait car's entity
-- is no longer streamed in locally (the operator is too far away for the
-- game to keep it loaded), so the remote doesn't go blank out of range.
local remoteStateCache = {}
local pendingStateRequests = {}
local STATE_REQUEST_INTERVAL = 1000

local function removeCarFromList(netId)
    for i = #nui.cars, 1, -1 do
        if netId ~= nui.cars[i].netId then
            goto continue
        end

        table.remove(nui.cars, i)

        if nui.index > i then
            nui.index = nui.index - 1
        end

        if nui.index > #nui.cars then
            nui.index = math.max(1, #nui.cars)
        end

        break

        ::continue::
    end
end

local function requestRemoteState(netId)
    local now = GetGameTimer()

    if 
        nil ~= pendingStateRequests[netId]
        and STATE_REQUEST_INTERVAL > (now - pendingStateRequests[netId])
    then
        return
    end

    pendingStateRequests[netId] = now

    rpc.invoke("DevJacob:BaitCar:Server:GetState", function(state, coords)
        if nil == state then
            -- No longer installed, or the vehicle itself is gone, drop it
            -- instead of leaving a dead entry the operator actually use.
            remoteStateCache[netId] = nil
            removeCarFromList(netId)
        else
            local stateCoords = nil
            if nil ~= coords then
                stateCoords = vector3(coords.x, coords.y, coords.z)
            end

            remoteStateCache[netId] = {
                state = state,
                coords = stateCoords,
            }
        end

        if nui.isOpen then
            updateRemote()
        end
    end, netId)
end

function updateRemote()
    local car = nui.cars[nui.index]
    if nil == car then
        nui:empty()
        return
    end

    local vehicle = NetToVeh(car.netId)
    local state = getBaitCarState(vehicle)
    local cached = remoteStateCache[car.netId]
    local dist = nil
    local streamedIn = 0 ~= vehicle and DoesEntityExist(vehicle)

    local playerCoords = GetEntityCoords(PlayerPedId())
    if streamedIn then
        dist = #(playerCoords - GetEntityCoords(vehicle))

        if nil == state then
            removeCarFromList(car.netId)
            remoteStateCache[car.netId] = nil
            updateRemote()
            return
        end
    else
        if nil ~= cached and nil ~= cached.coords then
            dist = #(playerCoords - cached.coords)
            state = cached.state
        end

        requestRemoteState(car.netId)
    end

    -- Unknown distance (no cached position yet) is treated as out of range
    -- so the remote doesn't falsely show a car as controllable.
    local inRange = nil ~= dist and dist <= Config["RemoteRange"]

    nui:updateStatus(
        nui.index,
        #nui.cars,
        {
            model = car.model,
            plate = car.plate,
            installed = nil ~= state and true == state.installed,
            engineDisabled = nil ~= state and true == state.engineDisabled,
            doorsLocked = nil ~= state and true == state.doorsLocked,
            inRange = inRange,
        }
    )
end

local function selectedNetId()
    local car = nui.cars[nui.index]
    if nil == car then
        return nil
    end

    return car.netId
end

RegisterNUICallback("baitcar:action", function(data, cb)
    logger:trace("nui callback with data: %s", json.encode(data))

    local controlFunc = function(_nui, data)
        local netId = selectedNetId()
        
        if nil ~= netId then
            local state = getBaitCarState(NetToVeh(netId))

            -- POWER tracks the engine state (it kills the engine and locks the
            -- doors together); LOCKS tracks the doors on their own.
            local current = false
            if "power" == data.action then
                current = nil ~= state and true == state.engineDisabled
            else
                current = nil ~= state and true == state.doorsLocked
            end

            -- The button name doubles as the control name ("power" / "doors").
            TriggerServerEvent(
                "DevJacob:BaitCar:Server:SetControl",
                netId,
                data.action,
                not current
            )
        end
    end

    local momentaryFunc = function(_nui, data)
        local netId = selectedNetId()

        if nil ~= netId then
            TriggerServerEvent(
                "DevJacob:BaitCar:Server:Momentary",
                netId,
                data.action
            )
        end
    end

    local funcMap = {
        ["close"] = function(_nui, data)
            _nui:close()
        end,

        ["next"] = function(_nui, data)
            if 0 < #_nui.cars then
                _nui.index = (_nui.index % #_nui.cars) + 1
                updateRemote()
            end
        end,

        ["prev"] =  function(_nui, data)
            if 0 < #_nui.cars then
                _nui.index = ((_nui.index - 2) % #_nui.cars) + 1
                updateRemote()
            end
        end,

        ["refresh"] = function(_nui, data)
            _nui.cars = mergeDiscoveredCars(_nui.cars)

            if 0 == #_nui.cars or _nui.index > #_nui.cars then
                _nui.index = 1
            end

            updateRemote()
        end,

        ["locate"] = function(_nui, data)
            local netId = selectedNetId()
            if nil == netId then
                return
            end

            local vehicle = NetToVeh(netId)
            local coords = nil

            if NetworkDoesNetworkIdExist(netId) and DoesEntityExist(vehicle) then
                coords = GetEntityCoords(vehicle)
            else
                local cached = remoteStateCache[netId]
                if nil ~= cached then
                    coords = cached.coords
                end
            end

            if nil ~= coords then
                SetNewWaypoint(coords.x, coords.y)
                notify("Waypoint set to bait car")
            else
                notify("Unable to locate bait car")
            end
        end,

        ["power"] = controlFunc,
        ["doors"] = controlFunc,
        ["flash"] = momentaryFunc,
        ["alarm"] = momentaryFunc,
    }

    if "function" == type(funcMap[data.action]) then
        funcMap[data.action](nui, data)
    end

    cb({ ok = true })
end)