local ChatServer = require(script.Parent:WaitForChild("ChatServer"))
ChatServer.init()

game.Players.PlayerAdded:Connect(function(player: Player)
    ChatServer.sendMessageTo(player, {
        trophy = "joined!",
        player = player,
        messageType = "TROPHY_MSG"
    })

    --[[ChatServer.sendMessageToAll(
        {message = "hi", messageType = "SERVER_MSG"},
        {chatColor = Color3.new(0, 1, 0)}
    )]]
end)