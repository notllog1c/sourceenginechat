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

local function GetNameValue(pName: string): number
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

local function GetChatColor(name: string): Color3
	local color: Color3 = Colors[(GetNameValue(name) % #Colors) + 1]
	return color
end

return GetChatColor