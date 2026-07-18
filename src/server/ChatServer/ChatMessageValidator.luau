--!strict
local TextChatService = game:GetService("TextChatService")
local RunSerivce = game:GetService("RunService")

local ChatShared = require(game.ReplicatedStorage:FindFirstChild("ChatShared", true))
local ChatServer

local ChatMessageValidator = {}

local function canPlayerChat(player: Player): boolean
    if RunSerivce:IsStudio() then
        return true
    end

    local success, canChat = pcall(function()
        return TextChatService:CanUserChatAsync(player.UserId)
    end)

    return success and canChat
end

function ChatMessageValidator.init()
    ChatServer = require(script.Parent)
end

function ChatMessageValidator.isMessageInvalid(player: Player, message: string): boolean
    if not canPlayerChat(player) then
        ChatServer.sendMessageTo(player, {
            message = ChatShared.constants.CANT_CHAT_TEXT,
            messageType = "SERVER_MSG"
        })
        return true
    end

    if ChatShared.removeTags(message):len() > ChatShared.constants.MAX_MESSAGE_LENGTH + 1 then
        ChatServer.sendMessageTo(player, {
            message = ChatShared.constants.ABOVE_CHARACTER_LIMIT,
            messageType = "SERVER_MSG"
        })
        return true
    end

    return false
end

return ChatMessageValidator