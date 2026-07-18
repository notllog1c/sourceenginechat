-- ty https://devforum.roblox.com/t/linking-your-custom-chat-to-the-roblox-chat-button/3752276
-- This is a hack, meaning this can break in the future!
local StarterGui = game:GetService("StarterGui")

local visibilityChangedBindable = Instance.new("BindableEvent")
local visibilityChanged = Instance.new("BindableEvent")
local activeChangedBindable = Instance.new("BindableEvent")

local function setCore(name: string, value: any)
    repeat
        local success = pcall(function()
            StarterGui:SetCore(name, value)
        end)
        if not success then task.wait() end
    until success
end

local function getCore(name: string): any
    local value
    repeat
        local success = pcall(function()
            value = StarterGui:GetCore(name)
        end)
        if not success then task.wait() end
    until success
    return value
end

local function setChatActive(active: boolean)
    setCore("ChatActive", active)
end

local CoreGuiInject = {
    chatActive = false,
    setChatActive = setChatActive,
    chatActiveChanged = activeChangedBindable.Event
}

local function onVisibilityChange()
    local isActive = getCore("ChatActive")
    visibilityChanged:Fire(isActive)

	if CoreGuiInject.chatActive ~= isActive then
		CoreGuiInject.chatActive = isActive
        activeChangedBindable:Fire(isActive)
    end
end

setCore("CoreGuiChatConnections", {
	["ChatWindow"] = {
		["ToggleVisibility"] = visibilityChangedBindable,
		["SetVisible"] = visibilityChangedBindable,
		["TopbarEnabledChanged"] = visibilityChangedBindable,
		["CoreGuiEnabled"] = visibilityChangedBindable,
		["VisibilityStateChanged"] = visibilityChanged
	}
})

visibilityChangedBindable.Event:Connect(onVisibilityChange)
onVisibilityChange()

return CoreGuiInject
