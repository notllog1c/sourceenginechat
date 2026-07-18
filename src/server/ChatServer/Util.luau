local Util = {}

-- Stole this from CoreScripts
function Util.isInGroup(player: Player, groupId: number, requiredRank: number?): boolean
	assert(type(requiredRank) == "nil" or type(requiredRank) == "number", "requiredRank must be a number or nil")

	local inGroup = false
	local success, err = pcall(function() -- Many things can error is the IsInGroup check
		if requiredRank then
			inGroup = player:GetRankInGroupAsync(groupId) > requiredRank
		else
			inGroup = player:IsInGroupAsync(groupId)
		end
	end)

	if not success and err then
		warn("Error checking in group: " ..err, debug.traceback())
	end

	return inGroup
end

return Util