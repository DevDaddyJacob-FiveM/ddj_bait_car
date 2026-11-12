--[[
    This file will contain specific functions that are able to be easily
    customized in one spot, the idea of this file is that server owners /
    developers can edit the code in here to allow them to customize certain
    actions and better integrate the script into their environment.
    
    Hook files are not frequently edited with updates which aims to make
    updating your resource with integrations easier.
]]

--- Used for integrations into custom notification scripts
---@param variant "success"|"error" The kind of message this is
---@param message string The message to display
function displayNotification(variant, message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end