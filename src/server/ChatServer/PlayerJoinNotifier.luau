-- !strict
local Players = game:GetService("Players")

local ChatShared = require(game.ReplicatedStorage:FindFirstChild("ChatShared", true))
local ChatServer

local PlayerJoinNotifier = {}

function PlayerJoinNotifier._sendFriendJoinNotification(player: Player, joinedFriend: Player)
    ChatServer.sendMessageTo(player, {
        message = string.format(ChatShared.constants.FRIEND_JOIN_MESSAGE, joinedFriend.Name),
        messageType = "SERVER_MSG"
    }, ChatShared.constants.FRIEND_MESSAGE_EXTRA_DATA)
end

function PlayerJoinNotifier._trySendingFriendNotification(player: Player, joinedPlayer: Player): boolean
    if not ChatShared.constants.SHOW_FRIEND_JOIN_NOTIFICATION then
        return false
    end

    coroutine.wrap(function()
        if player:IsFriendsWithAsync(joinedPlayer.UserId) then
            PlayerJoinNotifier._sendFriendJoinNotification(player, joinedPlayer)
            return true
        end 
    end)()

    return false
end

function PlayerJoinNotifier._sendJoinNotification(player: Player, joinedPlayer: Player)
    ChatServer.sendMessageTo(player, {
        message = string.format(ChatShared.constants.PLAYER_JOIN_MESSAGE, joinedPlayer.Name),
        messageType = "SERVER_MSG"
    })
end

function PlayerJoinNotifier._sendLeaveNotification(player: Player, leavingPlayer: Player)
    ChatServer.sendMessageTo(player, {
        message = string.format(ChatShared.constants.PLAYER_LEAVE_MESSAGE, leavingPlayer.Name),
        messageType = "SERVER_MSG"
    })
end

function PlayerJoinNotifier.init()
    ChatServer = require(script.Parent)

    Players.PlayerAdded:Connect(function(joinedPlayer: Player)
        local players = Players:GetPlayers()

        for _, player in players do
            if player == joinedPlayer then
                continue
            end

            local sentFriendNotification = PlayerJoinNotifier._trySendingFriendNotification(player, joinedPlayer)
            if not sentFriendNotification and ChatShared.constants.SHOW_PLAYER_JOIN_NOTIFICATION then
                PlayerJoinNotifier._sendJoinNotification(player, joinedPlayer)
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(leavingPlayer: Players)
        local players = Players:GetPlayers()

        for _, player in players do
            if player == leavingPlayer then
                continue
            end

            if ChatShared.constants.SHOW_PLAYER_JOIN_NOTIFICATION then
                PlayerJoinNotifier._sendLeaveNotification(player, leavingPlayer)
            end
        end
    end)
end

return PlayerJoinNotifier