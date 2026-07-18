--!strict
local IS_CLIENT = game:GetService("RunService"):IsClient()

local ChatShared = {
    initialized = false,
	sendMessage = nil :: RemoteEvent?,
	constants = require(script.Constants),
}

export type message_data = {
	message: string,
    player: Player?, 
    trophy: string?,
	teamChat: boolean?,
    messageType: message_type
}

export type message_type =  "PLAYER_MSG"    |
                            "TROPHY_MSG"    |
                            "SERVER_MSG"    |
                            "LOCKED_MSG"
export type extra_data = {
    prefix: string?,
    subfix: string?,
    chatColor: Color3?,
    chatFont: Font?,
    canUseRichText: boolean?
}

local function createRemote(name: string): RemoteEvent
    local remote = Instance.new("RemoteEvent")
    remote.Name = name
    remote.Parent = script
    return remote
end

function ChatShared.init(): typeof(ChatShared)
    if ChatShared.initialized then
        warn("Something tried to initialize 'ChatShared' again!", debug.traceback())
        return ChatShared
    end

    if IS_CLIENT then
        ChatShared.sendMessage = script:WaitForChild("sendMessage") :: RemoteEvent
    else
        ChatShared.sendMessage = createRemote("sendMessage")
    end

    ChatShared.initialized = true
    return ChatShared
end 

function ChatShared.removeTags(message: string): string
	message = message:gsub("<br%s*/>", "\n")
	return (message:gsub("<[^<>]->", ""))
end

return ChatShared