local ChatShared = require(game:GetService("ReplicatedStorage"):FindFirstChild("ChatShared", true))
local ChatClient

local Colors = {
	Color3.new(253/255, 41/255, 67/255),
	Color3.new(1/255, 162/255, 255/255),
	Color3.new(2/255, 184/255, 87/255),
	BrickColor.new("Bright violet").Color,
	BrickColor.new("Bright orange").Color,
	BrickColor.new("Bright yellow").Color,
	BrickColor.new("Light reddish violet").Color,
	BrickColor.new("Bright yellow").Color,
}

local Util = {}

local function getNameValue(pName: string): number
	local value = 0
	for index = 1, #pName do
		local cValue = string.byte(string.sub(pName, index, index))
		local reverseIndex = #pName - index + 1
		if #pName % 2 == 1 then
			reverseIndex = reverseIndex - 1
		end
		if reverseIndex % 4 >= 2 then
			cValue = -cValue
		end
		value = value + cValue
	end
	return value
end

function Util.init()
	ChatClient = require(script.Parent)
end

function Util.sendMessageToSelf(message: string, extra_data: ChatShared.extra_data)
	local message_data = {
		message = message,
		messageType = "SERVER_MSG"
	} :: ChatShared.message_data
	ChatClient._onMessageReceive(message_data, extra_data)
end

function Util.getChatColor(name: string): Color3
	local color: Color3 = Colors[(getNameValue(name) % #Colors) + 1]
	return color
end

return Util