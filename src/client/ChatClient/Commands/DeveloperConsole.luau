local StarterGui = game:GetService("StarterGui")
local DeveloperConsole = {}

function DeveloperConsole.ProcessMessage(message: string): boolean
    if string.sub(message, 1, 8):lower() ~= "/console" 
    and string.sub(message, 1, 11):lower() ~= "/newconsole" then
        return false
    end

    local success, visible = pcall(function()
        return StarterGui:GetCore("DevConsoleVisible") 
    end)

    if success then
        local secondSuccess, err = pcall(function()
            StarterGui:SetCore("DevConsoleVisible", not visible) 
        end)

        if not secondSuccess and err then
            warn("Error making developer console visible: " ..err)
        end
    end

    return true
end

return DeveloperConsole