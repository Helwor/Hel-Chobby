--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Command Buffering",
		desc      = "Buffers commands while ingame.",
		author    = "GoogleFrog",
		date      = "30 April 2018",
		license   = "GNU LGPL, v2.1 or later",
		layer     = -100005,
		enabled   = true  --  loaded by default?
	}
end
if not WG['avoidDuplicateWidgetLoad'..widget:GetInfo().name] then
    Spring.Echo('Avoiding duplicate load of local widget: ' .. widget:GetInfo().name)
	WG['avoidDuplicateWidgetLoad'..widget:GetInfo().name] = true
    return false
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Variables
local Echo = Spring.Echo
local onlyBufferCommands = {
	Say = true,
}

local onlyBufferSubstring = {
	Say = [["Place":0]]
}

local CMD_PER_UPDATE = 14

function widget:ActivateGame()
	local lobby = WG.LibLobby.lobby
	if not lobby.bufferCommandsEnabled then
		lobby.onlyBufferCommands = onlyBufferCommands
		lobby.onlyBufferSubstring = onlyBufferSubstring
		lobby.bufferCommandsEnabled = true
	end
	--WG.Chobby.interfaceRoot.GetChatWindow():ClearHistory()
	--WG.BattleRoomWindow.ClearChatHistory()
end

function widget:Update()
	local lobby = WG.LibLobby.lobby
	local Configuration = WG.Chobby.Configuration
	local isLobbyVisible = Configuration:IsLobbyVisible() and not Configuration.enableDebugBuffer
	if not isLobbyVisible then
		if not lobby.bufferCommandsEnabled then
			lobby.onlyBufferCommands = onlyBufferCommands
			lobby.onlyBufferSubstring = onlyBufferSubstring
			lobby.bufferCommandsEnabled = true
		end
		return
	end

	lobby.bufferCommandsEnabled = false
	local repetitions = 1
	while repetitions <= CMD_PER_UPDATE and lobby:ProcessBuffer() do
		repetitions = repetitions + 1
	end
end
