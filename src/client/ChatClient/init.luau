--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")

local CameraInput = require(game.Players.LocalPlayer.PlayerScripts.PlayerModule.CameraModule.CameraInput)
local ChatShared = require(ReplicatedStorage:FindFirstChild("ChatShared", true))
local CoreGuiInject = require(script.CoreGuiInject)
local CommandHandler = require(script.CommandHandler)

local Util = require(script.Util)

local preloadedSounds = {}
local ChatClient = {
    initialized = false,
    isChatting = false,
    upHeld = false,
    downHeld = false,
    _previousText = "",
    _teamChatting = false,
    _pressedOnChat = false,
    _hideThread = nil :: thread?,
    _playerConfirmedTyping = false,
    _messages = {} :: {CanvasGroup},
    _newMessages = {} :: {CanvasGroup},
}

local localPlayer = game.Players.LocalPlayer :: Player
local chatContext = script.ChatContext
local mouse = localPlayer:GetMouse()
local screenSize = Vector2.zero
local onSmallScreen = false
local defaultFontSize
local chatUI: Frame? = nil
local textScale = 1

local VERIFIED_EMOJI = utf8.char(0xE000)

local function hookValueToMessage(message: CanvasGroup): NumberValue
    local value = Instance.new("NumberValue")
    value.Parent = message

    local connection

    connection = value:GetPropertyChangedSignal("Value"):Connect(function()
        if not message or not message.Parent then
            connection:Disconnect()
            return
        end

        if not ChatClient.isChatting then
            message.GroupTransparency = value.Value
        end
    end)

    return value
end

local function updateTextAlignment(input: TextBox, richText: boolean?)
	local absSize = math.floor(input.AbsoluteSize.X)
	local bounds = input.TextBounds.X + 5

	if not richText then
		local text = ChatShared.removeTags(input.Text)
		local realAbsSize = TextService:GetTextSize(text, input.TextSize, Enum.Font.Roboto, screenSize).X
		bounds -= (absSize - realAbsSize)
	end

	local alignment = (bounds >= absSize) and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
	input.TextXAlignment = alignment
end

local function scaleUpAllText(scale: number)
    scale = math.floor(scale)
    textScale = scale

    for _,descendant in chatUI:GetDescendants() do
        if not (descendant:IsA("TextLabel") or descendant:IsA("TextBox")) then
            continue
        end

        if descendant.TextScaled then
            continue
        end
		
		local size = descendant:GetAttribute("OriginalFont") or descendant.FontSize.Value
		descendant:SetAttribute("OriginalFont", size)
		descendant.FontSize = size * scale
    end
end

-- uiscale literally scales up the gui and doesn't do this
local function onScreenSizeChange()
	local anchorPoint = chatUI:GetAttribute("OriginalAnchorPoint") or chatUI.AnchorPoint
	local position = chatUI:GetAttribute("OriginalPosition") or chatUI.Position
	local size = chatUI:GetAttribute("OriginalSize") or chatUI.Size
	
	chatUI:SetAttribute("OriginalAnchorPoint", anchorPoint)
	chatUI:SetAttribute("OriginalPosition", position)
	chatUI:SetAttribute("OriginalSize", size)
	
	chatUI.AnchorPoint = anchorPoint
	chatUI.Position = position
	chatUI.Size = size
	
	if screenSize.X < ChatShared.constants.MINIMUM_TABLET_SIZE.X 
		and screenSize.Y < ChatShared.constants.MINIMUM_TABLET_SIZE.Y then		
		chatUI.Size = UDim2.fromScale(
			size.X.Scale * ChatShared.constants.MOBILE_SCALE,
			size.Y.Scale * ChatShared.constants.MOBILE_SCALE
		)

		chatUI.Position = UDim2.new()
		chatUI.AnchorPoint = Vector2.zero

		scaleUpAllText(ChatShared.constants.MOBILE_SCALE)
		onSmallScreen = true
	elseif screenSize.X > ChatShared.constants.STUDIO_SIZE.X 
		and screenSize.Y > ChatShared.constants.STUDIO_SIZE.X then
		local ratio = (screenSize / ChatShared.constants.STUDIO_SIZE).Magnitude
		scaleUpAllText(ratio)
	end
end

local function destroyMessage(message: CanvasGroup)
    local index = table.find(ChatClient._messages, message)
    if index then
        table.remove(ChatClient._messages, index)
    end

    local newIndex = table.find(ChatClient._newMessages, message)
    if newIndex then
        table.remove(ChatClient._newMessages, newIndex)
    end

    message:Destroy()
end

local function isMouseOnFrame(frame: Frame): boolean
	local absPos = frame.AbsolutePosition
	local absSize = frame.AbsoluteSize

    if onSmallScreen then
        local safeArea = absSize * ChatShared.constants.MOBILE_SAFE_AREA_SCALE
        absSize += safeArea
        absPos -= safeArea / 2
    end
	
	local xCondition = absPos.X <= mouse.X and mouse.X <= absPos.X + absSize.X
	local yCondition = absPos.Y <= mouse.Y and mouse.Y <= absPos.Y + absSize.Y

	return xCondition and yCondition
end

local function makeNewMessage(): CanvasGroup
    local template = chatUI.ChatBox.Container.Template:Clone()
    template.Parent = chatUI.ChatBox.Container
    template.Name = "message"
    template.Visible = true

    if ChatClient.isChatting then
        template.Label:FindFirstChild("Selectable").Visible = true
    end

    table.insert(ChatClient._messages, template)
    table.insert(ChatClient._newMessages, template)

    return template
end

local function updateChatBoxTransparency(transparency: number)
	local tweenInfo = TweenInfo.new(
        transparency > 0.5 and 
        ChatShared.constants.CHATBOX_FADE_OUT_TIME 
        or ChatShared.constants.CHATBOX_FADE_IN_TIME
    )
	TweenService:Create(chatUI.Container, tweenInfo, {GroupTransparency = transparency}):Play()
	TweenService:Create(chatUI.ScrollBarButtons, tweenInfo, {GroupTransparency = transparency}):Play()
	TweenService:Create(chatUI.ChatBox.Container, tweenInfo, {ScrollBarImageTransparency = (transparency == 0 and 0.25 or transparency)}):Play()
end

local function disableRobloxChat()
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		TextChatService.ChatWindowConfiguration.Enabled = false
		TextChatService.ChatInputBarConfiguration.Enabled = false
		TextChatService.ChannelTabsConfiguration.Enabled = false
	else
        warn("DISABLE LEGACY CHAT FOR BEST SUPPORT ACROSS ALL PLATFORMS! TextChatService -> ChatVersion = TextChatService")
		task.spawn(function()
			local chat = localPlayer.PlayerGui:WaitForChild("Chat") :: ScreenGui
			if chat then
				chat.Enabled = false
			end
		end)
	end
end

local function getPlayerColor(player: Player): Color3
    if ChatShared.constants.TEAMS_ENABLED then
        if not player.Team then
            return ChatShared.constants.NEUTRAL_COLOR
        end

        return player.Team.TeamColor.Color
    end

    return Util.getChatColor(player.Name)
end

local function updateLabel(label: TextLabel | TextBox, string: string)
    local bottom = label:FindFirstChild("Bottom") :: TextLabel
    local selectable = label:FindFirstChild("Selectable") :: TextBox

    -- Have to do this like this without any rich text, otherwise the tags would show up when selecting
    -- the text. This WILL cause issues when tags change the font in any way except for font color.
    if ChatShared.constants.ALLOW_SELECTABLE_TEXT and selectable then
        selectable.Text = ChatShared.removeTags(string)
    end

    label.Text = string
	bottom.Text = string
end

-- Ensure rich text is properly scaled on all devices.
local function processText(text: string, isMessage: boolean?, whitelistedRichText: boolean?): string
    text = text:gsub('size="(%d+)"', function(size: string)
        size = tonumber(size) :: number

        -- Only whitelisted people can change font size.
        if isMessage and not whitelistedRichText then
            return `size="{defaultFontSize}"`
        end

        return `size="{size * textScale}"`
    end)
    
    return text
end

local function processExtraData(text: string, extra_data: SharedTable.extra_data?): string
    if not extra_data then
        return text
    end

    local fontFamily = ""
    local fontWeight = ""
    local color = ""

    if extra_data.chatColor then
        color = ` color="#{extra_data.chatColor:ToHex()}"`
    end

    if extra_data.chatFont then
        fontFamily = ` family="{extra_data.chatFont.Family}"`
        fontWeight = ` weight="{extra_data.chatFont.Weight.Value}"`

        if extra_data.chatFont.Style == Enum.FontStyle.Italic then
            text = `<i>{text}</i>`
        end
    end

    if color or fontFamily or fontWeight then
        text = `<font{color}{fontFamily}{fontWeight} >{text}</font>`
        return text
    end
end

local function playSound(soundId: number)
    -- Sounds aren't loaded at first when made with Instance.new(), hence the approach
    if preloadedSounds[soundId] then
        local sound = preloadedSounds[soundId]:Clone()
        sound.Parent = SoundService
        sound:Play()
        sound.Ended:Once(function()
            sound:Destroy()        
        end)
    end
end

local function preloadSound(soundId: number)
    if soundId == 0 or not soundId then
        return
    end

    local preload = Instance.new("Sound")
    preload.SoundId = `rbxassetid://{soundId}`
    preload.Parent = script
    preloadedSounds[soundId] = preload
end

function ChatClient.init(): typeof(ChatClient)
    if ChatClient.initialized then
        warn("Something tried to initialize 'ChatClient' again!", debug.traceback())
        return ChatClient
    end

    --[[if camera.ViewportSize == Vector2.one then
  	    camera:GetPropertyChangedSignal("ViewportSize"):Wait()
    end]]

	screenSize = workspace.CurrentCamera.ViewportSize
	
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		screenSize = workspace.CurrentCamera.ViewportSize
		onScreenSizeChange()
	end)

    preloadSound(ChatShared.constants.ACHIEVEMENT_EARNED_SOUND_ID)
    preloadSound(ChatShared.constants.WARNING_SOUND_ID)
    preloadSound(ChatShared.constants.TALK_SOUND_ID)

    disableRobloxChat()
    Util.init()
    ChatShared.init()
    CommandHandler.init()
    ChatClient._initGui()
    ChatClient._initInput()

    if not TextChatService:CanUserChatAsync(localPlayer.UserId) then
        ChatClient._onMessageReceive({
            message = ChatShared.constants.CANT_CHAT_TEXT,
            messageType = "SERVER_MSG"
        })
    end

    RunService.Heartbeat:Connect(function(deltaTime: number)
        local scrollingFrame: ScrollingFrame = chatUI.ChatBox.Container
        local value = 500 * deltaTime

        if not ChatClient.isChatting then
            return
		end
		
        if ChatClient.upHeld then
            scrollingFrame.CanvasPosition -= Vector2.new(0, value)
        end

        if ChatClient.downHeld then
            scrollingFrame.CanvasPosition += Vector2.new(0, value)
        end
    end)

    ChatShared.sendMessage.OnClientEvent:Connect(function(
        message_data: ChatShared.message_data, 
        extra_data: ChatShared.extra_data?
    )
        ChatClient._onMessageReceive(message_data, extra_data)
    end)

    ChatClient.close()
    ChatClient.initialized = true

    return ChatClient
end

-- Feel free to modify this function to your needs.
function ChatClient._initGui()
    local gui = script.ChatGui
	gui.Parent = localPlayer.PlayerGui
	-- Never change this variable, it must be always set to this exact frame.
	chatUI = gui.Chat

	local input: TextBox = chatUI.Container.Type.Container.Input
	
	if ChatShared.constants.APPEAR_IN_TOP_LEFT_CORNER then
		chatUI.Position = UDim2.new(chatUI.Position.X.Scale, 0, 0, 24)
		chatUI.AnchorPoint = Vector2.zero
	end

    defaultFontSize = chatUI.ChatBox.Container.Template.Label.TextSize
	
	-- damn rojo..
	chatContext.ScrollUp.TouchBinding.UIButton = chatUI.ScrollBarButtons.Up
	chatContext.ScrollDown.TouchBinding.UIButton = chatUI.ScrollBarButtons.Down

    GuiService.MenuClosed:Connect(function()
        if not ChatClient.isChatting or GuiService.MenuIsOpen then
            return
        end

        if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
            GuiService.AutoSelectGuiEnabled = true
            GuiService.SelectedObject = input
            GuiService.AutoSelectGuiEnabled = false

            ChatClient._playerConfirmedTyping = false
            input.PlaceholderText = ChatShared.constants.PRESS_TO_CONFIRM_TEXT
	    end
	end)

    -- i really tried adding a shadow (the one other textlabels have) to the textbox, but it just isn't possible.
    input.FocusLost:Connect(function(enterPressed: boolean, lastInput: InputObject)
        updateTextAlignment(input)

        if enterPressed or (lastInput and lastInput.KeyCode == Enum.KeyCode.ButtonA) then
            ChatClient.sendMessage()
            ChatClient.close()
            return
        end

        if UserInputService.PreferredInput == Enum.PreferredInput.Touch then
            input.PlaceholderText = ChatShared.constants.TAP_TO_START_TYPING_TEXT
        end
    end)

    input.Focused:Connect(function()
        input.PlaceholderText = "" 
    end)

    input:GetPropertyChangedSignal("Text"):Connect(function()
		updateTextAlignment(input, true)
        CommandHandler.TextUpdate(input.Text)
		
		if string.len(ChatShared.removeTags(input.Text)) > ChatShared.constants.MAX_MESSAGE_LENGTH then
			playSound(ChatShared.constants.WARNING_SOUND_ID)
			input.Text = ChatClient._previousText
			return
		end

        ChatClient._previousText = input.Text
	end)
	
    onScreenSizeChange()
end

-- Feel free to modify this function to your needs.
function ChatClient._initInput()
    CoreGuiInject.chatActiveChanged:Connect(function()
        if CoreGuiInject.chatActive then
            ChatClient.open()
        else
            ChatClient.close()
        end 
    end)

    chatContext.ShowChat.Released:Connect(function()
        if ChatClient.isChatting then
            return
        end

        ChatClient.open()
    end)

    chatContext.ShowTeamChat.Released:Connect(function()
        if ChatClient.isChatting then
            return
        end

        ChatClient.open(true)
    end)

    chatContext.CloseChat.Released:Connect(function()
        if not ChatClient.isChatting then
            return
        end

        ChatClient.close()
    end)

    chatContext.ScrollUp.Pressed:Connect(function()
        if not ChatClient.isChatting then
            return
        end
        
        CameraInput.setInputEnabled(false)
        ChatClient.upHeld = true
        ChatClient._pressedOnChat = true
    end)

    chatContext.ScrollUp.Released:Connect(function()
        if not ChatClient.downHeld then
            CameraInput.setInputEnabled(true)
        end
        
        ChatClient.upHeld = false
    end)

    chatContext.ScrollDown.Pressed:Connect(function()
        if not ChatClient.isChatting then
            return
        end

        CameraInput.setInputEnabled(false)
        ChatClient.downHeld = true
        ChatClient._pressedOnChat = true
    end)

    chatContext.ScrollDown.Released:Connect(function()
        if not ChatClient.upHeld then
            CameraInput.setInputEnabled(true)
        end

        ChatClient.downHeld = false
    end)

    UserInputService.InputBegan:Connect(function(inputObject: InputObject)
        if inputObject.UserInputType == Enum.UserInputType.MouseButton1 
        or inputObject.UserInputType == Enum.UserInputType.Touch then
            ChatClient._pressedOnChat = isMouseOnFrame(chatUI)
            return
        end

        if inputObject.KeyCode == Enum.KeyCode.ButtonA then
            local input: TextBox = chatUI.Container.Type.Container.Input

            if not ChatClient._playerConfirmedTyping then
                input.PlaceholderText = ""
                ChatClient._playerConfirmedTyping = true
            end
        end
    end)

    mouse.Button1Up:Connect(function()
        if not isMouseOnFrame(chatUI) and not ChatClient._pressedOnChat then
            ChatClient.close()
        end

        ChatClient._pressedOnChat = false
    end)
end

function ChatClient._hideNewMessages()
    task.defer(function()
        local messagesToHide = #ChatClient._newMessages

        while messagesToHide > 0 do
            local message = ChatClient._newMessages[1]
            local value = hookValueToMessage(message)

            local tween = TweenService:Create(value, TweenInfo.new(ChatShared.constants.NEW_MESSAGE_FADE_TIME), {Value = 1})
            tween:Play()
            tween.Completed:Wait()

            if message and message.Parent and not ChatClient.isChatting then
                message.Label:FindFirstChild("Selectable").Visible = false
                --message.Visible = false
            end

            value:Destroy()
            table.remove(ChatClient._newMessages, 1)
            messagesToHide -= 1
        end
    end)
end

function ChatClient._onMessageReceive(
    message_data: ChatShared.message_data, 
    extra_data: ChatShared.extra_data?
)

    if message_data.player and localPlayer.UserId > 0 then
        local blockedUserIds = StarterGui:GetCore("GetBlockedUserIds")
		
		for _,userId in blockedUserIds do
			if message_data.player.UserId == userId then
				return
			end
		end
    end

    if #ChatClient._messages > ChatShared.constants.MAX_MESSAGES then
        destroyMessage(ChatClient._messages[1])
    end

    ChatClient._displayMessage(message_data, extra_data)
end

function ChatClient._handlePlayerName(
    player: Player,
    playerTeamChatting: boolean?,
    extra_data: ChatShared.extra_data?
): string
    local color = getPlayerColor(player)
    local team = player.Team

    local verified = player.HasVerifiedBadge and ` {VERIFIED_EMOJI}` or ""

    local prefix = ""
    local subfix = ""

    if extra_data then
        prefix = extra_data.prefix and processText(extra_data.prefix) or ""--ChatClient._getPrefix(player)
        subfix = extra_data.subfix and processText(extra_data.subfix) or "" --ChatClient._getSubfix(player)
    end

    if (playerTeamChatting and team) 
    or (localPlayer.Team ~= player.Team and player.Team and ChatShared.constants.DISPLAY_OTHER_TEAM_PREFIX) then
        prefix = `({team}) {prefix}`
    end
    
    local final = `{prefix}<font color="#{color:ToHex()}">{player}</font>{verified}{subfix}`
    return final
end

-- You can add whatever you want to this, just be sure to also add new message types in ChatShared.luau too!
function ChatClient._handleMessage(
    message_data: ChatShared.message_data, 
    extra_data: ChatShared.extra_data?,
    label: TextBox
): boolean
    local allowedRichText = extra_data and extra_data.canUseRichText or false
    message_data.message = processText(message_data.message or "", true, allowedRichText)
    message_data.message = processExtraData(message_data.message, extra_data)

    if message_data.messageType == "SERVER_MSG" then
        updateLabel(label, message_data.message)
        return true
    end

    if message_data.messageType == "TROPHY_MSG" then
        if not message_data.trophy then
            warn("Didn't specify the trophy inside message_data!")
            return false
        end

        if not message_data.player then
            warn("Didn't specify the player inside message_data!")
            return false
        end

        local trophy = string.upper(message_data.trophy)
        label.Size = UDim2.new(1, 0, 0, label.Size.Y.Offset)

		local text = `<font color="#{getPlayerColor(message_data.player):ToHex()}">{message_data.player}</font> has earned the achievement <font color="#{ChatShared.constants.ACHIEVEMENT_COLOR:ToHex()}">{trophy}</font>`
        updateLabel(label, text)
        playSound(ChatShared.constants.ACHIEVEMENT_EARNED_SOUND_ID)

        return true
    end

    if message_data.messageType == "PLAYER_MSG" then
        if not message_data.player then
            warn("Didn't specify the player inside message_data!")
            return false
        end

        if ChatShared.constants.BUBBLE_CHAT_ENABLED and message_data.player.Character then
            local raw = ChatShared.removeTags(message_data.message)
            TextChatService:DisplayBubble(message_data.player.Character, raw)
        end

        local final = ChatClient._handlePlayerName(message_data.player, message_data.teamChat, extra_data)
        final = `{final} : {message_data.message}`
        updateLabel(label, final)
        playSound(ChatShared.constants.TALK_SOUND_ID)

        return true
    end

    if message_data.messageType == "LOCKED_MSG" then
        if not ChatShared.constants.SHOW_MESSAGES_FROM_AGE_RESTRICTED_PLAYERS then
            return false
        end

        local final = `🔒 : {message_data.message}`
        updateLabel(label, final)
        return true
    end

    return false
end

function ChatClient._displayMessage(
    message_data: ChatShared.message_data, 
    extra_data: ChatShared.extra_data?
)
    local template = makeNewMessage()
    local label: TextLabel = template.Label

    local success = ChatClient._handleMessage(message_data, extra_data, label)

    if not success then
        destroyMessage(template)
        return
    end
    
    if not ChatClient.isChatting then
        if ChatClient._hideThread then
            task.cancel(ChatClient._hideThread)
        end

        ChatClient._hideThread = task.delay(ChatShared.constants.TIME_TO_HIDE_MESSAGES, function()
            ChatClient._hideNewMessages()
        end)
    end

    -- have to do this lmao
    label.TextScaled = true
    label.TextScaled = false

    chatUI.ChatBox.Container.CanvasPosition += Vector2.new(0, label.AbsoluteSize.Y)
end

function ChatClient.sendMessage()
    local message = chatUI.Container.Type.Container.Input.Text

    if not ChatClient.isChatting or #ChatShared.removeTags(message):gsub("%s+", "") == 0 then
        return
    end

    if CommandHandler.ProcessMessage(message) then
        return
    end

    ChatShared.sendMessage:FireServer(message, ChatClient._teamChatting)
end

function ChatClient._toggle(active: boolean)
    local input: TextBox = chatUI.Container.Type.Container.Input
    local canvas: ScrollingFrame = chatUI.ChatBox.Container

    input.Text = ""
    input.Visible = active
    input.Selectable = active
    
    chatContext.ScrollUp.Enabled = active
    chatContext.ScrollDown.Enabled = active
    canvas.ScrollingEnabled = active
    
    updateChatBoxTransparency(active and 0 or 1)
    CoreGuiInject.setChatActive(active)
    ChatClient.isChatting = active
end

function ChatClient.open(teamChat: boolean?)
    if ChatClient.isChatting then
        return
    end

    ChatClient._teamChatting = (localPlayer.Team and teamChat) and teamChat or false
    updateLabel(chatUI.Container.Type.Label, ChatClient._teamChatting and `Say ({localPlayer.Team}):` or `Say: `)

    ChatClient._toggle(true)
    chatUI.Container.Type.Container.Input:CaptureFocus()

    for _, message in ChatClient._messages do
        message.Visible = true
        message.Label:FindFirstChild("Selectable").Visible = true
        TweenService:Create(message, TweenInfo.new(ChatShared.constants.CHATBOX_FADE_IN_TIME), {GroupTransparency = 0}):Play()
    end

    if ChatClient._hideThread then
        task.cancel(ChatClient._hideThread)
    end
end

function ChatClient.close()
    if not ChatClient.isChatting then
        return
    end

    local canvas: ScrollingFrame = chatUI.ChatBox.Container
    local input: TextBox = chatUI.Container.Type.Container.Input

    canvas.CanvasPosition = Vector2.new(0, canvas.AbsoluteCanvasSize.Y - canvas.AbsoluteWindowSize.Y)
    input.PlaceholderText = ""

    ChatClient._playerConfirmedTyping = true
    ChatClient._pressedOnChat = false
    ChatClient._teamChatting = false
    ChatClient.isChatting = false
    ChatClient.downHeld = false
    ChatClient.upHeld = false

    ChatClient._toggle(false)
    input:ReleaseFocus()

    if GuiService.SelectedObject == input then
        GuiService.SelectedObject = nil
    end

    for _,message in ChatClient._messages do
        message.Label:FindFirstChild("Selectable").Visible = false

        if table.find(ChatClient._newMessages, message) then
            continue
        end

        local tween = TweenService:Create(message, TweenInfo.new(ChatShared.constants.CHATBOX_FADE_OUT_TIME), {GroupTransparency = 1})
        tween:Play()

        --[[tween.Completed:Once(function()
            message.Visible = false
        end)]]
    end

    ChatClient._hideThread = task.delay(ChatShared.constants.TIME_TO_HIDE_MESSAGES, function()
        ChatClient._hideNewMessages()
    end)
end

return ChatClient