--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")

local ExtraDataHandler = require(script.ExtraDataHandler)
local ChatFloodDetector = require(script.ChatFloodDetector)
local PlayerJoinNotifier = require(script.PlayerJoinNotifier)
local ChatMessageValidator = require(script.ChatMessageValidator)
local ChatShared = require(ReplicatedStorage:FindFirstChild("ChatShared", true))

local ChatServer = {
    initialized = false
}

local function handleUsersThatCantChat(
        from: Player, 
        to: Player,
        message_data: ChatShared.message_data
    ): boolean
    if from == to then
        return false
    end

    if TextChatService:CanUsersChatAsync(from.UserId, to.UserId) then
        return false
    end

    ChatServer.sendMessageTo(to, {
        message = message_data.message:gsub("[^%s]", "*"),
        messageType = "LOCKED_MSG"
    })

    return true
end

function ChatServer.init(): typeof(ChatServer)
    if ChatServer.initialized then
        warn("Something tried to initialize 'ChatServer' again!", debug.traceback())
        return ChatServer
    end

    ChatShared.init()
    ChatFloodDetector.init()
    PlayerJoinNotifier.init()
    ChatMessageValidator.init()

    ChatShared.sendMessage.OnServerEvent:Connect(function(
        player: Player,
        message: string,
        teamChat: boolean
    )
        ChatServer._onMessageReceive(player, message, teamChat)
    end)

    Players.PlayerRemoving:Connect(function(player: Player)
        ExtraDataHandler.removePlayerData(player)
    end)

    ChatServer.initialized = true
    return ChatServer
end

-- Returns if the message should be sent to everyone, and returns a message to the sender.
function ChatServer._filterMessage(sender: Player, message: string): (boolean, string?)
    -- Get rid of space spam
	message = message:gsub("%s+" , " ")
	-- Get rid of spaces at the beginning and the end
	message = message:gsub("^%s*(.-)%s*$", "%1")

    local filterResult
    local final = message

    if not (ChatShared.constants.CAN_EVERYONE_USE_RICHTEXT 
    or ExtraDataHandler._getDataForPlayer(sender).canUseRichText) then
        final = ChatShared.removeTags(message)
    end

    local success,_ = pcall(function()
        filterResult = TextService:FilterStringAsync(message, sender.UserId)
        local result = filterResult:GetNonChatStringForBroadcastAsync()

        if result ~= message then
            -- Replace hashtags with the appropriate equivalent
            final = result:gsub("#", "*")    
        end
    end)

    if success then
        return true, final
    else
        ChatServer.sendMessageTo(
            sender,
            {
                message = ChatShared.constants.UNEXPECTED_ERROR_TEXT,
                messageType = "SERVER_MSG"
            }
        )
        return false
    end
end

function ChatServer._onMessageReceive(sender: Player, message: string, teamChat: boolean)
    if typeof(message) ~= "string" or typeof(teamChat) ~= "boolean" then
        warn(string.format("%s is firing the remote through an executor!", sender.Name))
        return
    end

    if ChatMessageValidator.isMessageInvalid(sender, message) then
        return
    end

    if ChatFloodDetector.isntAllowedToType(sender) then
        return
    end

    if not sender.Team or not ChatShared.constants.TEAMS_ENABLED then
        teamChat = false
    end

    local success, final = ChatServer._filterMessage(sender, message)

    if success then
        ChatServer._sendMessageFromToAll(
            {
                player = sender,
                message = final,
                teamChat = teamChat,
                messageType = "PLAYER_MSG"
            },
            ExtraDataHandler.getExtraDataFor(sender)
        )          
    end
end

function ChatServer._sendMessageFromToAll(
    message_data: ChatShared.message_data,
    extra_data: ChatShared.extra_data
)
    if not message_data.player then
        warn("Invalid message data!")
        return
    end
    
    for _,player in Players:GetPlayers() do
        if handleUsersThatCantChat(message_data.player, player, message_data) then
            continue
        end

        if (message_data.teamChat and player.Team == message_data.player.Team) or not message_data.teamChat then
            ChatServer.sendMessageTo(player, message_data, extra_data)
        end
    end
end

function ChatServer.sendMessageToAll(
    message_data: ChatShared.message_data, 
    extra_data: ChatShared.extra_data
)
    ChatShared.sendMessage:FireAllClients(message_data, extra_data)
end

function ChatServer.sendMessageTo(
    player: Player,
    message_data: ChatShared.message_data,
    extra_data: ChatShared.extra_data
)
    ChatShared.sendMessage:FireClient(player, message_data, extra_data)
end

return ChatServer