local ChatServer = require(script.Parent:WaitForChild("ChatServer"))
ChatServer.init()

task.wait(8)
ChatServer.sendMessageTo(game.Players.not_Iog1c, {
    player = game.Players.not_Iog1c,
    trophy = "balls!!!!",
    messageType = "TROPHY_MSG"
})