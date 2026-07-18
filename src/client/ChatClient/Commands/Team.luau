--!strict
local ChatClient = require(script.Parent.Parent)

local localPlayer = game.Players.LocalPlayer
local Team = {
    gui = nil :: Frame?
}
local commands = {
    "/t ",
    "/team "
}

local function checkForCommand(message: string): boolean
    for _,command: string in commands do
        if string.sub(message, 1, command:len()):lower() == command then
            return true
        end
    end
end

function Team.TextUpdate(message: string)
    if not localPlayer.Team then
        return
    end

    if checkForCommand(message) then
        ChatClient.isChatting = false
        ChatClient.open(true)
    end
end

return Team