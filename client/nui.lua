nui = {}
nui.isOpen = false
nui.index = 1
nui.cars = {}

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
    self.cars = collectBaitCars()
    self.remoteIndex = 1

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

function updateRemote()
    local car = nui.cars[nui.index]
    if nil == car then
        nui:empty()
        return
    end

    local vehicle = NetToVeh(car.netId)
    local state = getBaitCarState(vehicle)

    nui:updateStatus(
        nui.index,
        #nui.cars,
        {
            model = car.model,
            plate = car.plate,
            installed = nil ~= state and true == state.installed,
            engineDisabled = nil ~= state and true == state.engineDisabled,
            doorsLocked = nil ~= state and true == state.doorsLocked,
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
            _nui.cars = collectBaitCars()
            _nui.index = 1
            updateRemote()
        end,

        ["locate"] = function(_nui, data)
            local netId = selectedNetId()

            if nil ~= netId and NetworkDoesNetworkIdExist(netId) then
                local coords = GetEntityCoords(NetToVeh(netId))
                SetNewWaypoint(coords.x, coords.y)

                notify("Waypoint set to bait car")
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