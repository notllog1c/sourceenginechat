local Util = require(script.Parent.Parent.Util)

local localPlayer = game.Players.LocalPlayer
local PlayEmote = {}

local legacyDefaultEmotes = {
	wave = true,
	point = true,
	dance = true,
	dance2 = true,
	dance3 = true,
	laugh = true,
	cheer = true,
}

local NOT_SUPPORTED = "You can't use Emotes here."
local R15_ONLY = "Only R15 avatars can use Emotes."
local NO_MATCHING_EMOTE = "You can't use that Emote."
local TEMPORARILY_UNAVAILABLE = "You can't use Emotes right now."
local ERROR_COLOR = Color3.fromRGB(245, 50, 50)

local function getEmoteName(message): string?
	if string.sub(message, 1, 3) == "/e " then
		return string.sub(message, 4)
	elseif string.sub(message, 1, 7) == "/emote " then
		return string.sub(message, 8)
	end
end

local function sendErrorMessage(errorMessage: string)
    Util.sendMessageToSelf(errorMessage, {
        chatColor = ERROR_COLOR
    })
end

function PlayEmote.ProcessMessage(message: string): boolean
    local emoteName = getEmoteName(message)
    if not emoteName then
        return false
    end

    local character = localPlayer.Character
    if not character then
        sendErrorMessage(TEMPORARILY_UNAVAILABLE)
        return true
    end

    local animateScript = character:FindFirstChild("Animate")
    if not animateScript then
        sendErrorMessage(NOT_SUPPORTED)
        return true
    end

    local playEmoteBindable = animateScript:FindFirstChild("PlayEmote")
    if not playEmoteBindable then
        sendErrorMessage(NOT_SUPPORTED)
        return true
    end

    if legacyDefaultEmotes[emoteName] then
        playEmoteBindable:Invoke(emoteName)
        return true
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        sendErrorMessage(TEMPORARILY_UNAVAILABLE)
        return true
    end

    if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
        sendErrorMessage(R15_ONLY)
        return true
    end

    local humanoidDescription = humanoid:FindFirstChildOfClass("HumanoidDescription")
    if not humanoidDescription then
        sendErrorMessage(TEMPORARILY_UNAVAILABLE)
        return true
    end

    local lowerCaseEmoteNamesMap = {}

    local emotes = humanoidDescription:GetEmotes()
	for name, _ in pairs(emotes) do
		lowerCaseEmoteNamesMap[string.lower(name)] = name
	end

    local slot = tonumber(emoteName)
	if slot then
		local equippedEmotes = humanoidDescription:GetEquippedEmotes()
		for _, emoteInfo in equippedEmotes do
			if emoteInfo.Slot == slot then
				emoteName = emoteInfo.Name
			end
		end
	end

    local emoteNameLower = string.lower(emoteName)
	emoteName = lowerCaseEmoteNamesMap[emoteNameLower]

	if not emoteName then
		sendErrorMessage(NO_MATCHING_EMOTE)
		return true
	end

	task.spawn(function()
		local ok, didPlay = pcall(function() 
            return humanoid:PlayEmoteAsync(emoteName) 
        end)

		if not ok then
			sendErrorMessage(NOT_SUPPORTED)
		elseif not didPlay then
			sendErrorMessage(TEMPORARILY_UNAVAILABLE)
		end
	end)

	return true
end

return PlayEmote