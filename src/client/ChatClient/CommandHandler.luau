--!strict
local Commands = script.Parent.Commands
local CommandHandler = {
    _loaded = {}
}

function CommandHandler.init(gui: Frame)
    for _,command in Commands:GetChildren() do
        CommandHandler._loaded[command.Name] = require(command)
        CommandHandler._loaded[command.Name].gui = gui
    end
end

function CommandHandler.TextUpdate(message: string)
    for _,command in CommandHandler._loaded do
        if not command.TextUpdate then
            continue
        end

        command.TextUpdate(message)
    end
end

-- If true, don't automatically send message to the server.
function CommandHandler.ProcessMessage(message: string): boolean
    for _,command in CommandHandler._loaded do
        if not command.ProcessMessage then
            continue
        end

        if command.ProcessMessage(message) then
            return true
        end
    end

    return false
end

return CommandHandler