local TextChatService = game:GetService("TextChatService")
local Teams = game:GetService("Teams")

return {
    -- Change these to your own, otherwise you won't have any chat related sounds. 
    -- The sound files should be inside the github repo in /assets!
    ACHIEVEMENT_EARNED_SOUND_ID = 71426628700233,
    WARNING_SOUND_ID = 99076385938789,
    TALK_SOUND_ID = 124916214164440,

    -- Shared
    CANT_CHAT_TEXT = "<i>Your chat settings prevent you from sending messages.</i>",
    TEAMS_ENABLED = #Teams:GetChildren() > 0,
    SHOW_FRIEND_JOIN_NOTIFICATION = true,
	SHOW_PLAYER_JOIN_NOTIFICATION = true,
	DISPLAY_OTHER_TEAM_PREFIX = true,
    MAX_MESSAGE_LENGTH = 128,

    --Server
    FLOOD_MESSAGE_DISPLAY_SECONDS = "<i>You must wait %d %s before sending another message!</i>",
    UNEXPECTED_ERROR_TEXT = "<i>Something went wrong while processing your message.</i>",
    ABOVE_CHARACTER_LIMIT = "<i>Your message exceeds the maximum message length.</i>",
    FLOOD_DETECTED_MESSAGE = "<i>You must wait before sending another message!</i>",
    FRIEND_MESSAGE_EXTRA_DATA = { chatColor = Color3.new(1, 1, 1) },
    FRIEND_JOIN_MESSAGE = "Your friend %s joined the game",
    PLAYER_JOIN_MESSAGE = "Player %s joined the game",
    PLAYER_LEAVE_MESSAGE = "Player %s left the game.",
	CAN_EVERYONE_USE_RICHTEXT = false,
    INFORM_SPEAKER_OF_WAITTIME = true,
    MESSAGES_ALLOWED_BEFORE_LIMIT = 7,
    FLOOD_DECAY_TIME_PERIOD = 15,

    --Client
    BUBBLE_CHAT_ENABLED = TextChatService.BubbleChatConfiguration.Enabled,
    ACHIEVEMENT_COLOR = Color3.new(0.61, 0.76, 0.31),
    PRESS_TO_CONFIRM_TEXT = `Press "Confirm" to type`,
    TAP_TO_START_TYPING_TEXT = `Tap to start typing`,
    SHOW_MESSAGES_FROM_AGE_RESTRICTED_PLAYERS = false,
    MINIMUM_TABLET_SIZE = Vector2.new(1281,801),
    STUDIO_SIZE = Vector2.new(1920, 1079),
    NEUTRAL_COLOR = Color3.new(1, 1, 1),
    APPEAR_IN_TOP_LEFT_CORNER = false,
    ALLOW_SELECTABLE_TEXT = true,
    MOBILE_SAFE_AREA_SCALE = 0.1,
    NEW_MESSAGE_FADE_TIME = 2,
    CHATBOX_FADE_OUT_TIME = 0.3,
    CHATBOX_FADE_IN_TIME = 0.3,
    TIME_TO_HIDE_MESSAGES = 10,
    MESSAGE_FADE_TIME = 2,
    MOBILE_SCALE = 1.5,
    MAX_MESSAGES = 96,
}