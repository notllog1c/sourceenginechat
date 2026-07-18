-- !strict
local ChatShared = require(game.ReplicatedStorage:FindFirstChild("ChatShared", true))
local Util = require(script.Parent.Util)
local ExtraDataHandler = {
    _savedData = {}
}

-- This is where you can add custom prefixes, subfixes, player message colors, and change who can use richtext!

-- Everything except chatColor supports rich text. If you wish to make text bold, instead of using <b></b> you need 
-- to use <font weight="heavy"></font>, so keep that in mind. The script prioritizes player configs rather than
-- the group ones.
local Config = {
    Groups = {
        {
            groupId = 0,
            rank = 0,
            prefix = ``,
            subfix = ``,
            chatColor = Color3.new(0, 0, 0),
            chatFont = Font.new("ComicNeueAngular"),
            canUseRichText = false
        }--, ...
    },

    Players = {
        {
            userId = game.CreatorId,
            prefix = `<font color="#FF0000">[Get rid of me in <font color="#FFFFFF" weight="heavy">ExtraDataHandler.luau</font>!]</font> `,
            subfix = ` <i><font size="8"><font color="#FF0000">[<font weight="heavy">!!!</font>]</font></font></i>`,
            chatColor = Color3.new(1, 0.84, 0),
            --Custom fonts aren't recommended, due to them making text selecting harder.
            --chatFont = Font.new("Kalam", Enum.FontWeight.Heavy, Enum.FontStyle.Italic),
            canUseRichText = true
        }--, ...
    }
} :: {[string]: {
        groupId: number?,
        rank: number?,
        userid: number?,
        prefix: string?,
        subfix: string?,
        chatColor: Color3?,
        chatFont: Font?,
        canUseRichText: boolean?
}}

function ExtraDataHandler.removePlayerData(player: Player)
    if ExtraDataHandler._savedData[player] then
        table.clear(ExtraDataHandler._savedData[player])
        ExtraDataHandler._savedData[player] = nil
    end
end

function ExtraDataHandler._getDataForPlayer(player: Player): ChatShared.extra_data
    if ExtraDataHandler._savedData[player] then
        return ExtraDataHandler._savedData[player]
    end

    for _, playerConfig in Config.Players do
        if playerConfig.userId == player.UserId then
            ExtraDataHandler._savedData[player] = playerConfig
            return playerConfig
        end
    end

    for _, groupConfig in Config.Groups do
        if Util.isInGroup(player, groupConfig.groupId, groupConfig.requiredRank) then
            ExtraDataHandler._savedData[player] = groupConfig
            return groupConfig
        end
    end

    ExtraDataHandler._savedData[player] = {}
    return {}
end

function ExtraDataHandler.getExtraDataFor(player: Player): ChatShared.extra_data
    return ExtraDataHandler._getDataForPlayer(player)
end

return ExtraDataHandler