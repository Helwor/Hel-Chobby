--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:GetInfo()
	return {
		name      = "Ingame Interface",
		desc      = "Contains the interface between ingame and luaMenu",
		author    = "GoogleFrog",
		date      = "18 November 2016",
		license   = "GPL-v2",
		layer     = -0,
		handler   = true,
		api       = true,
		enabled   = true,
	}
end
if not WG['avoidDuplicateWidgetLoad'..widget:GetInfo().name] then
    Spring.Echo('Avoiding duplicate load of local widget: ' .. widget:GetInfo().name)
	WG['avoidDuplicateWidgetLoad'..widget:GetInfo().name] = true
    return false
end
local Echo = Spring.Echo

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("libs/liblobby/lobby/json.lua")

local SEND_USER_CHANGE_MESSAGE = true

local TRY_1v1_NOTIF = false
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local lobby
local conf
local Chobby

local spectators = {}

local INGAME, INMENU = false, false
-- Externals Functions

local externalFunctions = {}

function externalFunctions.SetLobbyOverlayActive(newActive)
	if Spring.SendLuaUIMsg then
		Spring.SendLuaUIMsg("LobbyOverlayActive" .. ((newActive and "1") or "0"))
	else
		Spring.Echo("Spring.SendLuaUIMsg does not exist in LuaMenu")
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Patterns to send

local LOBBY_CHAT_UPDATE = "LobbyChatUpdate_"
local LOBBY_CHAT_UPDATE2 = "LobbyChatUpdate2_"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Patterns to match

local TTT_SAY = "textToSpeechSay_"
local TTS_VOLUME = "textToSpeechVolume_"
local REMOVE_BUTTON = "disableLobbyButton"
local ENABLE_OVERLAY = "showLobby"
local LUAMENU_SETTING = "changeSetting "
local OPEN_SETTINGS_TAB = "openSettingsTab "
local LOAD_FILENAME = "loadFilename "
local RESTART_GAME = "restartGame"
local GAME_INIT = "ingameInfoInit"
local GAME_START = "ingameInfoStart"
local REPORT_USER = "reportUser"
local AUTOSAVE_COMPLETE = "autosaveComplete"

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Utilities

local function ConvertString(str)
	if str == "true" then
		return true
	elseif str == "false" then
		return false
	elseif tonumber(str) then
		return tonumber(str)
	end
	return str
end

local function StringToDataTable(msg)
	local data = msg:split("_")
	local dataTable = {}
	local index = 3
	while data[index] do
		dataTable[data[index - 1]] = ConvertString(data[index])
		index = index + 2
	end
	return dataTable
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Text To Speech

local function HandleTextToSpeech(msg)
	local Configuration = WG.Chobby.Configuration
	if not Configuration.enableTextToSpeech then
		return false
	end

	if string.find(msg, TTT_SAY) == 1 then
		msg = string.sub(msg, 17)
		local nameEnd = string.find(msg, "%s")
		local name = string.sub(msg, 0, nameEnd)
		msg = string.sub(msg, nameEnd + 1)
		WG.WrapperLoopback.TtsSay(name, msg)
		return true
	end

	if string.find(msg, TTS_VOLUME) == 1 then
		msg = string.sub(msg, 20)
		WG.WrapperLoopback.TtsVolume(tonumber(msg) or 0)
		return true
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Lobby Overlay

local function HandleLobbyOverlay(msg)
	--Spring.Echo("HandleLobbyOverlay", msg)
	local interfaceRoot = Chobby and Chobby.interfaceRoot
	if interfaceRoot then
		if msg == REMOVE_BUTTON then
			interfaceRoot.SetLobbyButtonEnabled(false)
			return true
		elseif msg == ENABLE_OVERLAY then
			Spring.Echo("HandleLobbyOverlay SetMainInterfaceVisibley")
			interfaceRoot.SetMainInterfaceVisible(true)
			return true
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Settings

local function HandleSettingsChange(msg)
	if string.find(msg, LUAMENU_SETTING) ~= 1 then
		return
	end
	local Configuration = WG.Chobby.Configuration
	if Configuration then
		local data = msg:split(" ")
		if data[2] and data[3] then
			Configuration:SetSettingsConfigOption(data[2], tonumber(data[3]) or data[3])
		end
	end
end

local function HandleSettingsOpenTab(msg)
	if string.find(msg, OPEN_SETTINGS_TAB) ~= 1 then
		return
	end
	local data = msg:split(" ")
	if WG.Chobby.interfaceRoot then
		WG.Chobby.interfaceRoot.OpenRightPanelTab("settings")
		WG.Chobby.interfaceRoot.SetMainInterfaceVisible(true)
		if data[2] and WG.SettingsWindow then
			WG.SettingsWindow.OpenTab(data[2])
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Load and Restart

local function HandleLoadGame(msg)
	if string.find(msg, LOAD_FILENAME) ~= 1 then
		return
	end
	local data = msg:split(" ")
	if WG.LoadGame and data and data[2] then
		WG.LoadGame.LoadGameByFilename(data[2])
	end
end

local function HandleRestartGame(msg)
	if string.find(msg, RESTART_GAME) ~= 1 then
		return
	end
	WG.SteamCoopHandler.RestartGame()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Ingame Info

local function MsgToIngameData(msg)
	local data = msg:split("_")
	if tonumber(data[2]) then
		return {
			isPlayer = (data[2] == "1"),
			playerCount = tonumber(data[3]) or 0,
			teamOnePlayers = tonumber(data[4]) or 0,
			teamTwoPlayers = tonumber(data[5]) or 0,
			teamPlayers = tonumber(data[3]) or 0,
			isFFA = (data[6] == "1"),
			isReplay = (data[7] == "1"),
			isAI = (data[8] == "1"),
			isChicken = (data[9] == "1"),
			isCampaign = (data[10] == "1"),
			planetName = data[11],
		}
	end

	return StringToDataTable(msg)
end

local function HandleGameInfoInit(msg)
	if string.find(msg, GAME_INIT) ~= 1 then
		return
	end
	if WG.DiscordHandler then
		WG.DiscordHandler.SetIngameInfo(MsgToIngameData(msg))
	end
end

local function HandleGameInfoStart(msg)
	if string.find(msg, GAME_START) ~= 1 then
		return
	end
	local ingameData = MsgToIngameData(msg)
	if WG.DiscordHandler then
		WG.DiscordHandler.SetIngameInfo(ingameData)
	end
	if WG.QueueStatusPanel then
		WG.QueueStatusPanel.SetWantAutosaveFromGameData(ingameData)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Reporting

local function HandleReport(msg)
	if string.find(msg, REPORT_USER) ~= 1 then
		return
	end
	local data = msg:split(";")
	if not (data and data[3]) then
		return
	end
	
	WG.ReportPanel.OpenReportWindow(data[2], data[3], true)
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Autosave

local function HandleAutosaveComplete(msg)
	if string.find(msg, AUTOSAVE_COMPLETE) ~= 1 then
		return
	end
	local data = msg:split("_")
	if not (data and data[2]) then
		return
	end

	if WG.QueueStatusPanel then
		local saveName = data[2]
		local delayAutosave = function ()
			WG.QueueStatusPanel.OnAutosaveComplete(saveName)
		end
		WG.Delay(delayAutosave, 1)
	end

	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Battle room chat

local function ShouldSendLobbyUpdatesIngame()
	local debug = conf.debugLobbyGameChat
	if conf.enableDebugBuffer then
		if debug then
			Spring.Echo("ShouldSendLobbyUpdatesIngame true, reason: debug buffer")
		end
		return true
	end
	if Spring.GetGameName() == "" then
		if debug then
			Spring.Echo("ShouldSendLobbyUpdatesIngame false, reason: empty game name")
		end
		return false
	end
	local lobby = lobby or WG.LibLobby.lobby
	local myBattleID = lobby and lobby:GetMyBattleID()
	if not myBattleID then
		if debug then
			Spring.Echo("ShouldSendLobbyUpdatesIngame false, reason: no myBattleID")
		end
		return false
	end
	if conf:IsLobbyVisible() then
		if debug then
			Spring.Echo("ShouldSendLobbyUpdatesIngame false, reason: lobby is visible")
		end
		return false
	end
	local battle = lobby:GetBattle(myBattleID) 
	local battleIngame = battle and battle.isRunning

	if battleIngame then
		if debug then
			Spring.Echo("ShouldSendLobbyUpdatesIngame false, reason: my battle is running")
		end
		return false
	end
	return true
end

local oldPlayerCount = false
local oldUsers = false
local newRoom = false
local oldBattleID = false
local oldPlayers = false
local function DiffTables(t1, t2)
	local paired1, paired2 = {}, {}
	local more, less = {}, {}
	local len1, len2 = #t1, #t2
	for i, v in ipairs(t1) do
		paired1[v] = true
	end
	for i, v in ipairs(t2) do
		paired2[v] = true
	end
	for i, v in ipairs(t2) do
		if not paired1[v] then
			more[#more+1] = v
		end
	end 
	for i, v in ipairs(t1) do
		if not paired2[v] then
			less[#less+1] = v
		end
	end 
	if (len1 ~= len2) or next(more) or next(less) then
		return len2 - len1, more, less
	end
	return false
end
local function IsNewUserList(newUsers)
	if not oldUsers then
		oldUsers = Spring.Utilities.ShallowCopy(newUsers)
		return #oldUsers, oldUsers, {}
	end
	-- for i = 1, math.max(#newUsers, #oldUsers) do
	-- 	if newUsers[i] ~= oldUsers[i] then
	-- 		oldUsers = Spring.Utilities.ShallowCopy(newUsers)
	-- 		return true
	-- 	end
	-- end

	local diff, more, less = DiffTables(oldUsers, newUsers)
	if diff then
		oldUsers = Spring.Utilities.ShallowCopy(newUsers)
		return diff, more, less
	end
	return false
end

local function GetPlayers(users, players)
	local players = {}
	for i, name in ipairs(users) do
		local userBattleStatus = lobby:GetUserBattleStatus(name)
		players[name] = (userBattleStatus or false) and not userBattleStatus.isSpectator
	end
	return players
end

local function UpdatePlayers(playerStatus)
	local newSpec, newPlayer = {}, {}
	local changed = false
	if type(playerStatus) == 'table' then
		for name, oldPlayer in pairs(playerStatus) do
			local userBattleStatus = lobby:GetUserBattleStatus(name)
			local isPlayer = (userBattleStatus or false) and not userBattleStatus.isSpectator
			if isPlayer ~= oldPlayer then
				playerStatus[name] = isPlayer
				if oldPlayer then
					changed = true
					newSpec[#newSpec+1] = name
				else
					changed = true
					newPlayer[#newPlayer+1] = name
				end
			end
		end
	end
	return changed, newSpec, newPlayer
end

local function UpdatePlayer(playerStatus)
	local newSpec, newPlayer = {}, {}
	local changed = false
	if type(playerStatus) == 'table' then
		for name, oldPlayer in pairs(playerStatus) do
			local userBattleStatus = lobby:GetUserBattleStatus(name)
			local isPlayer = (userBattleStatus or false) and not userBattleStatus.isSpectator
			if isPlayer ~= oldPlayer then
				playerStatus[name] = isPlayer
				if oldPlayer then
					changed = true
					newSpec[#newSpec+1] = name
				else
					changed = true
					newPlayer[#newPlayer+1] = name
				end
			end
		end
	end
	return changed, newSpec, newPlayer
end
local function OnLeftBattle(listeners, updateBattleID, userName)
	local myBattleID = lobby:GetMyBattleID()
	if not myBattleID or updatedBattleID ~= myBattleID then
		return
	end
	Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. userName .. " left room.")

	-- Spring.SendLuaUIMsg(prefix ..'btl:' .. tostring(oldBattleID) .. ', ' .. tostring(myBattleID))

	-- if not ShouldSendLobbyUpdatesIngame() then
	-- 	return
	-- end
	local newPlayerCount = (lobby:GetBattlePlayerCount(updatedBattleID) or "??")

	if newPlayerCount == oldPlayerCount and not SEND_USER_CHANGE_MESSAGE then
		return
	end
	
	--Spring.Echo(LOBBY_CHAT_UPDATE .. " Players waiting " .. (lobby:GetBattlePlayerCount(updatedBattleID) or "??") .. "/" .. (battle.maxPlayers or "??"))
	if Spring.SendLuaUIMsg then
		if newPlayerCount ~= oldPlayerCount then
			Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. "Players waiting: " .. newPlayerCount .. "/" .. ((lobby:GetBattle(myBattleID) or {}).maxPlayers or "??"))
		end	
		if SEND_USER_CHANGE_MESSAGE then
			Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. 'Left Room: ' .. userName)
		end
	else
		Spring.Echo("Spring.SendLuaUIMsg does not exist in LuaMenu")
	end
	oldPlayerCount = newPlayerCount
end

local function OnJoinedBattle(listeners, updateBattleID, userName)

	local myBattleID = lobby:GetMyBattleID()
	if not myBattleID or updatedBattleID ~= myBattleID then
		return
	end
	-- Echo('On Joined', userName)
	Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. userName .. 'entered room.')
	if not ShouldSendLobbyUpdatesIngame() then
		return
	end
	local newPlayerCount = (lobby:GetBattlePlayerCount(updatedBattleID) or "??")

	if newPlayerCount == oldPlayerCount and not SEND_USER_CHANGE_MESSAGE then
		return
	end
	
	--Spring.Echo(LOBBY_CHAT_UPDATE .. " Players waiting " .. (lobby:GetBattlePlayerCount(updatedBattleID) or "??") .. "/" .. (battle.maxPlayers or "??"))
	if Spring.SendLuaUIMsg then
		if newPlayerCount ~= oldPlayerCount then
			Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. "Players waiting: " .. newPlayerCount .. "/" .. ((lobby:GetBattle(myBattleID) or {}).maxPlayers or "??"))
		end	
		-- if SEND_USER_CHANGE_MESSAGE then
		-- 	Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. 'Enter Room: ' .. userName)
		-- end
	else
		Spring.Echo("Spring.SendLuaUIMsg does not exist in LuaMenu")
	end
	oldPlayerCount = newPlayerCount
end

local function PlayersUpdate(listeners, updatedBattleID, ...)
	local myBattleID = lobby:GetMyBattleID()
	if updatedBattleID ~= myBattleID then
		return
	end
	-- local prefix = LOBBY_CHAT_UPDATE .. '[' .. os.clock() .. ']: '
	-- Spring.SendLuaUIMsg(prefix ..'btl:' .. tostring(oldBattleID) .. ', ' .. tostring(myBattleID))
	-- Spring.SendLuaUIMsg(prefix ..'btl:' .. tostring(oldBattleID) .. ', ' .. tostring(myBattleID))
	local battle = lobby:GetBattle(myBattleID) or {}
	-- Echo('--')
	-- Echo("oldID, updatedBattleID, ... is ",oldBattleID,  updatedBattleID, ...)
	-- Echo('Player Count', oldPlayerCount,  '=>', (lobby:GetBattlePlayerCount(updatedBattleID) or "??"))
	-- Echo('Diff Users:', IsNewUserList(battle.users))
	-- Echo('Should Send', ShouldSendLobbyUpdatesIngame())
	if oldBattleID ~= myBattleID then
		-- Echo('new room')
		newRoom = true
		oldUsers = Spring.Utilities.ShallowCopy(battle.users)
		oldBattleID = myBattleID
	else
		oldPlayers = GetPlayers(battle.users)
		if type(oldPlayer) == 'table' then
			local changed, newSpec, newPlayer = UpdatePlayer(oldPlayers)
			if changed then
				for i, name in ipairs(newSpec) do
					Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. name .. " gone spec.")
				end
				for i, name in ipairs(newPlayer) do
					Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. name .. " joined players.")
				end
			end
		end
	end
	-- local battle = lobby:GetBattle(updatedBattleID )
	local newPlayerCount = (lobby:GetBattlePlayerCount(updatedBattleID) or "??")

	if not ShouldSendLobbyUpdatesIngame() then
		oldPlayerCount = newPlayerCount
		return
	end
	local haveNewUsers, more, less = false
	if SEND_USER_CHANGE_MESSAGE then
		-- haveNewUsers, more, less = IsNewUserList(battle.users)
		-- if haveNewUsers then
		-- 	oldPlayers = GetPlayers(battle.users)
		-- end
	end
	-- Echo('haveNewUsers', haveNewUsers)
	if newPlayerCount == oldPlayerCount and not haveNewUsers then
		return
	end

	oldPlayerCount = newPlayerCount
	--Spring.Echo(LOBBY_CHAT_UPDATE .. " Players waiting " .. (lobby:GetBattlePlayerCount(updatedBattleID) or "??") .. "/" .. (battle.maxPlayers or "??"))
	if Spring.SendLuaUIMsg then
		if battle.users and battle.users[1] then
			Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. "Players waiting: " .. newPlayerCount .. "/" .. (battle.maxPlayers or "??"))
			local userString = ""
			if haveNewUsers then
				-- if next(more) then
				-- 	userString = "Entered Room: " .. ' ' .. table.concat(more, ', ')
				-- end
				-- if next(less) then
				-- 	userString = (next(more) and userString or '') .. 'Left Room: ' .. table.concat(less, ', ')
				-- end
				-- Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. userString)
			elseif SEND_USER_CHANGE_MESSAGE then
				-- local changed, newSpec, newPlayer = UpdatePlayers(oldPlayers)
				-- Echo('changed', changed)
				-- if changed then
				-- 	if newSpec[1] then
				-- 		Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. 'Gone to Spec: ' .. table.concat(newSpec, ', '))
				-- 	end
				-- 	if newPlayer[1] then
				-- 		Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. 'Gone to Player: ' .. table.concat(newPlayer, ', '))
				-- 	end
				-- end
			end
			-- local userString = ""
			-- for i = 1, (#battle.users) - 1 do
			-- 	userString = userString .. (battle.users[i] or "??") .. ", "
			-- end
			-- userString = userString .. (battle.users[#battle.users] or "??")
			newRoom = false
		end
	else
		Spring.Echo("Spring.SendLuaUIMsg does not exist in LuaMenu")
	end
end

local function HandleLobbySay(command, argumentsPos)

	if not argumentsPos then
		return
	end
	if (string.find(command, [["Place":1]]) or 0) < 1 then
		return
	end
	arguments = command:sub(argumentsPos + 1)
	local Conf = WG.Chobby.Configuration
	local success, cmdData = pcall(json.decode, arguments)
	if not success then
		Spring.Log(LOG_SECTION, LOG.ERROR, "Failed to parse JSON: " .. tostring(arguments))
		if Conf.debugLobbyGameChat then
			Spring.Echo("HandleLobbySay", "json fail")
		end
		return false
	end
	if cmdData.Place ~= 1 then
		if Conf.debugLobbyGameChat then
			Spring.Echo("HandleLobbySay", "Place ~= 1")
		end
		return false -- Not battle text
	end
	--Spring.Echo(LOBBY_CHAT_UPDATE .. "<" .. (cmdData.User or "unknown") .. "> " .. (cmdData.Text or ""))
	if Spring.SendLuaUIMsg then
		Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE .. (cmdData.User or "unknown") .. ": " .. (cmdData.Text or ""))
	else
		Spring.Echo("Spring.SendLuaUIMsg does not exist in LuaMenu")
	end
end
local function GetOpponents(battleID, myBattleID, myBattle, ImSpec)
	local battle = lobby.battles[battleID]
	-- Echo('..')
	-- Echo("battleID, myBattleID, lobby:GetMyBattleID() is ", battleID, myBattleID, lobby:GetMyBattleID())
	-- Echo('...')
	-- if lobby.myBattleID ~= battleID then
	-- 	Echo('hax myBattleID')
	-- 	lobby.myBattleID = battleID
	-- end
	-- lobby:SetBattleStatus({isSpectator = true})
	if not battle then
		return
	end
	if battle then
		local vs 
		if battle.isMatchMaker then
			vs = (battle.users[1] or '???') .. ' vs ' .. (battle.users[2] or '???')
		else
			for i, name in ipairs(battle.users) do
				local userBattleStatus = lobby:GetUserBattleStatus(name)
				local user = lobby.users[name]
				-- Echo('***', name, "userBattleStatus, user is ", userBattleStatus, userBattleStatus and userBattleStatus.isSpectator, user, user and user.isSpectator,'team',user.team, user.allyTeam, user.allyNumber, userBattleStatus and userBattleStatus.allyNumber, user and user.allyNumber)
				local isSpec = userBattleStatus and userBattleStatus.isSpectator or user and user.isSpectator
				-----------------------
				if not isSpec then
					-- vs = (vs or '') .. name ..', '
					-- if user.casualSkill < 2500 and user.skill < 2500 then
					-- 	break
					-- else
						vs = (vs and ' vs ' or '') .. name
					-- end
				end
			end
		end
		if vs then
			WG.Chotify:Post{
				title = 'Duel ' .. battle.title,
				body =  vs .. ' !!\n' .. battle.mapName,
				time = 15,
				sound = 'sounds/beep4.wav',
				-- sound = 'sounds/beep6.wav',
				-- sound = 'detriment_jump.wav',
				-- sound = 'jump.wav',
				-- sound = 'jump_land.wav',
				-- sound = 'something.wav',
				-- sound = 'something2.wav',
			}

		end
	end
	if true then
		return
	end
	--- This part is too hacky, maybe find a way to know the players without physically enter and leave room, or maybe enter fast and leave fast
	if myBattleID then
		local backToMyBattle

		if lobby.battles[myBattleID] then
			lobby:JoinBattle(myBattleID) -- 
			SET_ME_SPEC = true
			backToMyBattle = true
			Echo('BACK TO MY BATTLE', lobby.battles[myBattleID].title)
		else
			-- was alone in the room and game was not started => recreate the room
			Echo('I WAS ALONE? THE ROOM DIED WHEN I LEFT')
			if myBattle and not myBattle.users[2] then

			end
		end

		-- if backToMyBattle and (SetMeSpec or ImSpec) then
		-- 	Echo('I WAS SPEC THOUGH')
		-- 	SetMeSpec = {myBattleID,wait = 50 }
		-- end
	else
		Echo('LEAVE BATTLE?')
		lobby:LeaveBattle()

	end
end


local function OnBattleIngameUpdate(self, battleID, started)
	if not started then
		return
	end
	if not conf then
		return
	end
	if not (conf.notifyStartedHigh1v1 or conf.notifyAnyStarted) then
		return
	end
	local myBattleID = lobby:GetMyBattleID()
	if myBattleID == battleID then
		return
	end
	local battle = lobby.battles[battleID]
	if not (battle or battle.passworded) then
		return
	end
	local title = battle.title
	local _title = title:lower()

	if JOIN_FOR_INFO then
		return
	end
	local vs
	if conf.notifyStartedHigh1v1 then
		if battle.playerCount == 2 then
			if battle.isMatchMaker and title:find(': 1v1') then
				if (title:find('Singularity') or title:find('Neutron Star')) then
					vs = (battle.users[1] or '???') .. ' vs ' .. (battle.users[2] or '???')
				end
			else
				for i, name in ipairs(battle.users) do 
					-- this will likely not happen because we don't get the user infos if we haven't come into the room
					local userBattleStatus = lobby:GetUserBattleStatus(name)
					local user = lobby.users[name]
					-- Echo('***', name, "userBattleStatus, user is ", userBattleStatus, userBattleStatus and userBattleStatus.isSpectator, user, user and user.isSpectator,'team',user.team, user.allyTeam, user.allyNumber, userBattleStatus and userBattleStatus.allyNumber, user and user.allyNumber)
					local isSpec = userBattleStatus and userBattleStatus.isSpectator or user and user.isSpectator
					-----------------------
					local p1, p2
					if isSpec == false then
						-- vs = (vs or '') .. name ..', '
						if user.casualSkill > 2500 or user.skill > 2500 then
							if not p1 then
								p1 = name
							elseif not p2 then
								p2 = name
								break
							end
						end
					end
				end
				if p2 then
					vs = p1 .. ' vs ' .. p2
				end
			end
		end
		if vs then
			WG.Chotify:Post{
				-- title = 'Duel ' .. vs .. ' !!',
				-- body =  battle.title .. '\n' .. battle.mapName,
				title = '',
				body =  'Duel ' .. vs .. ' !!'
					.. battle.title .. '\n' .. battle.mapName,

				time = 15,
				-- sound = 'sounds/beep4.wav',
				-- sound = 'sounds/beep6.wav',
				-- sound = 'sounds/detriment_jump.wav',
				sound = 'sounds/jump.wav',
				-- sound = 'jump_land.wav',
				-- sound = 'something.wav',
				-- sound = 'something2.wav',
			}
			return
		end
	end
	if not vs and conf.notifyAnyStarted then
		-- more discreet
		WG.Chotify:Post{
			title = '',
			body =  table.concat({
				battle.title .. (battle.battleAis and battle.battleAis[1] and ' (AI)' or ''), -- afaik AI might not be detected aswell if not present in the room
				battle.mapName,
				battle.playerCount .. ' players',
			},'\n'),
			time = 4,
		}
	end


			-- Echo('---------')
			-- Echo(battle.Title)
			-- Echo('---------')
			-- for k,v in pairs(battle) do
			-- 	Echo('=>>',k,v)
			-- end
			-- local name = battle.users[1]
			-- CHECK_THIS_NAME = name
			-- local lobbyUser
			-- if name then
			-- 	lobbyUser = lobby.users[name]
			-- end
			-- Echo("battle started is ", battle.title, 'players',battle.playerCount,'users',#battle.users, (battle.battleAis and battle.battleAis[1] and 'with AI' or 'no AI')
			--  --	,'first user', name
			--  -- ,'lobby user', lobbyUser, 'spec?', lobbyUser and lobbyUser.isSpectator, 'isInGame?', lobbyUser and lobbyUser.isInGame
			--  -- ,'allyNumber', lobbyUser and lobbyUser.allyNumber
			-- )
			
			-- 	--- This part is too hacky, maybe find a way to know the players without physically enter and leave room, or maybe enter fast and leave fast
			-- 	if false then
			-- 		local myBattle = lobby.battles[myBattleID]
			-- 		if not myBattle or not myBattle.passworded then -- go in the room to have the spectators
			-- 			local ImSpec = lobby:GetUserBattleStatus(lobby:GetMyUserName())

			-- 			ImSpec = ImSpec and ImSpec.isSpectator
			-- 			Echo("ImSpec is ", ImSpec)
			-- 			JOIN_FOR_INFO = {battleID, myBattleID, myBattle, ImSpec, wait = 100}
			-- 			Echo('Joining battle', battle.title)
			-- 			lobby:JoinBattle(battleID)
			-- 			if ImSpec then
			-- 				SET_ME_SPEC = true
			-- 			end
			-- 			return
			-- 			-- lobby:JoinBattle(battleID) --

			-- 			-- ...
			-- 			-- ...
			-- 			-- -- TODO: DELAY SOME TIME (OnJoinedBattle) => LEAVE
			-- 			-- battle = lobby.battles[battleID]
			-- 			-- if myBattle then
			-- 			-- 	lobby:JoinBattle(myBattleID) -- back in our room
			-- 			-- else
			-- 			-- 	lobby:LeaveBattle(battleID)
			-- 			-- end
			-- 		end
			-- 	end
			-- 	pass = true
			-- 	--
end
-- local function OnUpdateUserBattleStatus(_, userName, status)
-- 	Echo(math.round(os.clock()),'OnUpdateUserBattleStatus',_,userName, status)
-- 	if status.isSpectator ~= nil then
-- 		spectators[userName] = status.isSpectator
-- 	end
-- end

local function BeforeCommandSent(_, command)
	if SET_ME_SPEC and command:find(lobby:GetMyUserName()) and command:find('isSpectator":false') then
		SET_ME_SPEC = false
		return command:gsub('isSpectator":false','isSpectator":true' )
	end
end

local function OnCommandReceived(_, command)

	if command:find('^Say ') and command:find('"Place":1') then
		if ShouldSendLobbyUpdatesIngame() then
			if Spring.SendLuaUIMsg then
				local st, fin = command:find('^[%w_]+')
				local success, cmdData = pcall(json.decode, command:sub(fin+2))
				if success and cmdData.Place == 1 then -- making sure "Place":1 is really what it is
					Spring.SendLuaUIMsg(LOBBY_CHAT_UPDATE2 .. (cmdData.User or "unknown") .. ": " .. (cmdData.Text or ""))
				end
			end
		end
	end
	-- Echo('OK',ok,cmdName == 'Say', command:find('Place"'),command:find('Place\"'),command:find('Place\":1'))
end

local function OnCommandBuffered(_, cmdName, command, argumentsPos)
	Echo('ON COMMAND BUFFERED', cmdName, command) -- it never happen because the buffer has been made impossible to act
	if not ShouldSendLobbyUpdatesIngame() then
		return
	end
	local Conf = WG.Chobby.Configuration
	if Conf.debugLobbyGameChat then
		Spring.Echo("OnCommandBuffered")
	end
	if cmdName == "Say" then
		HandleLobbySay(command, argumentsPos)
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Callins

function widget:RecvLuaMsg(msg)
	if HandleLobbyOverlay(msg) then
		return
	end
	if HandleTextToSpeech(msg) then
		return
	end
	if HandleSettingsChange(msg) then
		return
	end
	if HandleSettingsOpenTab(msg) then
		return
	end
	if HandleLoadGame(msg) then
		return
	end
	if HandleRestartGame(msg) then
		return
	end
	if HandleGameInfoInit(msg) then
		return
	end
	if HandleGameInfoStart(msg) then
		return
	end
	if HandleReport(msg) then
		return
	end
	if HandleAutosaveComplete(msg) then
		return
	end

end


function widget:ActivateMenu()
	INMENU = true
	INGAME = false

	local interfaceRoot = Chobby and Chobby.interfaceRoot

	-- Another game might be started without the ability to display lobby button.
	if interfaceRoot then
		interfaceRoot.SetLobbyButtonEnabled(true)
	end
end


function widget:ActivateGame()
	INGAME = true
	INMENU = false
end
function table.size(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end
local round = 0

---

local HKEY = 104
function widget:KeyPress(key, mods, isRepeat)
	if isRepeat then
		return
	end
	if mods.ctrl and mods.alt and key == HKEY then --
		Echo('RELOADING')
        widgetHandler:RemoveWidget(widget)
        widgetHandler:EnableWidget(widget:GetInfo().name)

	end
end
---


function widget:Update()
	
	-- local cnt, specs = 0, 0
	-- if round % 100 == 0 then
	-- 	for name, isSpec in pairs(spectators) do
	-- 		cnt = cnt + 1
	-- 		if isSpec then
	-- 			specs = specs + 1
	-- 		end
	-- 	end
	-- 	Echo('users size',cnt,'specs',specs)
	-- end
	if not (Chobby and conf) then
		Chobby = WG.Chobby
		if Chobby then
			conf = Chobby.Configuration
			Echo("conf.notifyStartedHigh1v1 is ", conf, conf and conf.notifyStartedHigh1v1)
	-- round = round + 1
			-- widgetHandler:RemoveWidgetCallIn('Update', widget)
		end
	end
	if SetMeSpec then
		if SetMeSpec.wait > 0 then
			SetMeSpec.wait = SetMeSpec.wait - 1
		else
			local myBattleID = unpack(SetMeSpec)
			Echo('now can set to spec ?','rmb battleID',myBattleID,'battle exist?', lobby.battles[myBattleID],'lobby.myBattleID',lobby.myBattleID)
			if myBattleID ~= lobby.myBattleID --[[and lobby.battles[myBattleID]--]] then
				Echo('hax myBattleID to go to spec')
				lobby.myBattleID = myBattleID
			else

			end
			lobby:SetBattleStatus({isSpectator = true})
			SetMeSpec = nil
		end
	end
	if JOIN_FOR_INFO then -- hacky stuff
		if JOIN_FOR_INFO.wait > 0 then
			JOIN_FOR_INFO.wait = JOIN_FOR_INFO.wait - 1
		else
			Echo('Get Opponents')
			GetOpponents(unpack(JOIN_FOR_INFO))
			JOIN_FOR_INFO = nil
		end
	end
end
local listeners = {

	-- OnBattleAboutToStart = OnBattleStartMultiplayer,
	OnCommandBuffered = OnCommandBuffered,
	-- OnCommandSent =OnCommandSent,
	OnCommandReceived = OnCommandReceived,
	-- OnUpdateUserBattleStatus = OnUpdateUserBattleStatus,
	-- BeforeCommandSent = BeforeCommandSent,
	OnLeftBattle = OnLeftBattle,
	-- OnLeftBattle = PlayersUpdate,
	OnJoinedBattle = OnJoinedBattle,
	-- OnJoinedBattle = PlayersUpdate,
	OnUpdateBattleInfo = PlayersUpdate,
	OnBattleIngameUpdate = OnBattleIngameUpdate,


}
function widget:Initialize()
	WG.IngameInterface = externalFunctions
	
	lobby = WG.LibLobby.lobby
	for name, func in pairs(listeners) do
		lobby:AddListener(name, func)
	end
end

function widget:Shutdown()
	for name, func in pairs(listeners) do
		lobby:RemoveListener(name, func)
	end
end