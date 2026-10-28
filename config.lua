logger = Logger.new("bait-car")

Config = {
    --[[
        The default keybind used to open the bait car remote. It can be changed
        by the player in the FiveM keybind settings.
        See https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/
    ]]
    RemoteKeybind = {
        Mapper = "keyboard",

        --[[ The default primary keybinding, set to `""` to not set a default ]]
        DefaultPrimary = "F7",

        --[[ The default secondary keybinding, set to `""` to not set a default ]]
        DefaultSecondary = "",
    },

    --[[
        How close (in meters) the player must be to a vehicle to install or
        remove the gear when they are not sat inside of it.
    ]]
    InstallDistance = 5.0,

    --[[
        The maximum distance (in meters) a bait car may be from the operator
        to show up as a controllable unit on the remote.
    ]]
    RemoteRange = 300.0,

    --[[
        When `true`, remotely killing the engine also makes the vehicle
        undriveable so the thief is unable to restart it.
    ]]
    LockEngineWhenDisabled = true,

    --[[
        When `true`, a ped inside a bait car whose doors are locked is
        blocked from exiting or being dragged out of it. Set to `false` if
        your server wants to roll its own logic for this instead (e.g. a
        separate vehicle lock resource).
    ]]
    PreventExitWhenLocked = true,
}
