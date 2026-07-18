--!strict
local ChatShared = require(game.ReplicatedStorage:FindFirstChild("ChatShared", true))
local Util = require(script.Parent.Util)
local ChatServer

local floodCheckTable = {}
-- wow! anti-flood for you and you only!
local whitelistedSpeakers ={
    Players =  {
        game.CreatorId--, ...
    },

    Groups = {
        {
            groupId = 0,
            rank = 0
        }--, ...
    }
}

local ChatFloodDetector = {}

local function isWhitelisted(player: Player): boolean
    if table.find(whitelistedSpeakers.Players, player.UserId) then
        return true
    end

    for _,group in whitelistedSpeakers.Groups do
        if Util.isInGroup(player, group.groupId, group.rank) then
            return true
        end
    end

    return false
end

local function enterTimeIntoLog(log: {any})
    table.insert(log, tick() + ChatShared.constants.FLOOD_DECAY_TIME_PERIOD)
end

function ChatFloodDetector.init()
    ChatServer = require(script.Parent)
end

function ChatFloodDetector.playerLeaving(player: Player)
    if floodCheckTable[player] then
        table.clear(floodCheckTable[player])
        floodCheckTable[player] = nil
    end
end

function ChatFloodDetector.isntAllowedToType(player: Player): boolean
    if isWhitelisted(player) then 
        return false 
    end

    if not floodCheckTable[player] then
        floodCheckTable[player] = {}
    end

    local t = floodCheckTable[player] :: {number}
    local now = tick()

    while #t > 0 and t[1] < now do
        table.remove(t, 1)
    end

    if #t < ChatShared.constants.MESSAGES_ALLOWED_BEFORE_LIMIT then
        enterTimeIntoLog(t)
        return false
    end

    local timeDiff = math.ceil(t[1] - now)

    if ChatShared.constants.INFORM_SPEAKER_OF_WAITTIME then
        ChatServer.sendMessageTo(player, {
            message = string.format(ChatShared.constants.FLOOD_MESSAGE_DISPLAY_SECONDS, timeDiff, timeDiff > 1 and "seconds" or "second"),
            messageType = "SERVER_MSG"
        })
    else
        ChatServer.sendMessageTo(player, {
            message = ChatShared.constants.FLOOD_DETECTED_MESSAGE,
            messageType = "SERVER_MSG"
        })
    end

    return true
end

return ChatFloodDetector