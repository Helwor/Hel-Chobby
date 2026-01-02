Console = LCS.class{}

local Echo = Spring.Echo

-- getting emotes
local emotes 
local luaconf = VFS.FileExists('LuaUI/Config/ZK_data.lua') and VFS.Include('LuaUI/Config/ZK_data.lua', nil, VFS.RAW_FIRST)
if luaconf then
    emotes = luaconf['EPIC Menu'] and luaconf['EPIC Menu'].config.epic_Chili_Pro_Console_emotes
    luaconf = nil
end
if not emotes then
    emotes = VFS.FileExists('LuaUI/Widgets/Include/emotes.lua')
        and VFS.Include('LuaUI/Widgets/Include/emotes.lua', nil, VFS.RAW_FIRST)
        or {}
end


local ProcessHistoryLine, WriteMonthDay
do
	local previousDay, nextDay, isToday, monthName, daySuffix
	local end_time_pattern = '%d%d:%d%d%] '
	local time_pattern = '^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):%d%d %- %[(%d%d):(%d%d)%] '
	do
		local date = {year = 2025, month = 1, day = 1, hour = 12} -- 
		local oneDay = 86400 -- one day in seconds
		local osdate, ostime = os.date, os.time
		function previousDay(year, month, day)
			date.year, date.month, date.day = year, month, day
		   local timestamp = ostime(date) - oneDay
		   return osdate("%Y", timestamp), osdate("%m", timestamp), osdate("%d", timestamp)
		end

		function nextDay(year, month, day)
			date.year, date.month, date.day = year, month, day
		   local timestamp = ostime(date) + oneDay
		   return osdate("%Y", timestamp), osdate("%m", timestamp), osdate("%d", timestamp)
		end
		function isToday(year, month, day)
			return osdate("%Y") == year and osdate("%m") == month and osdate("%d") == day
		end
		function monthName(month)
			date.month = month
			return osdate("%B", ostime(date)):sub(1,3)
		end
		function daySuffix(d)
			if d:sub(1,1) == '1' then
				return 'th'
			end
			d = d:sub(2)
			if d == '1' then
				return 'st'
			elseif d == '2' then
				return 'nd'
			elseif d == '3' then
				return 'rd'
			else
				return 'th'
			end
		end
	end
	function WriteMonthDay(month, day, numFormat)
		if numFormat then
			return month ..'/'.. day
		else
			return monthName(month) .. ' ' .. day:gsub('^0', '').. daySuffix(day)
		end
	end
	function ProcessHistoryLine(s, curDate, numFormat)
		local ye, mo, da, h, min, loc_h, loc_min = s:match(time_pattern)
		local st = 1 -- where do we start extracting the string from
		if ye then
			local nh, nloc_h = tonumber(h), tonumber(loc_h)
			if nh > 12 and nloc_h < 12 then
				ye, mo, da = nextDay(ye, mo, da)
			elseif nh < 12 and nloc_h > 12 then
				ye, mo, da = previousDay(ye, mo, da)
			end
			-- if not isToday(ye, mo, da) then
				if ye ~= curDate.year or mo ~= curDate.month or da ~= curDate.day then
					curDate.year = ye
					curDate.month = mo
					curDate.day = da
					s = s:gsub("("..end_time_pattern..")", WriteMonthDay(mo, da, numFormat) .. " %1", 1)
				end
			-- end
		   st = s:find("%[.-"..end_time_pattern)
		end
	   local fin = s:find("%s+$") or 0
	   return "\255\128\128\128" .. s:sub(st, fin - 1)
	end
end

function Console:init(channelName, sendMessageListener, noHistoryLoad, onResizeFunc, isBattleChat)
	self.listener = sendMessageListener
	self.showDate = true
	self.dateFormat = "%H:%M"
	self.currentDate = {year = '0', month = '0', day = '0'}
	self.dateNumFormat = false
	self.sentMsgHistory = {}
	self.sentMsgHistoryCount = 0
	self.sentMsgHistoryMax = 500
	self.sentMsgHistoryCursor = 1
	self.currentMsgBuffer = ""

	self.channelName = channelName
	local onResize
	if onResizeFunc then
		onResize = {
			function ()
				onResizeFunc(self)
			end
		}
	end

	-- TODO: currently this is handled by chat windows and battleroom chat separately
	self.unreadMessages = 0

	self.spHistory = ScrollPanel:New {
		name = self.channelName and (self.channelName .. " scroll panel"),
		x = 0,
		right = 2,
		y = 0,
		bottom = 35,
		verticalSmartScroll = true,
	}
	self.tbHistory = TextBox:New {
		x = 0,
		right = 0,
		y = 0,
		agressiveMaxLines = 500,
		agressiveMaxLinesPreserve = 100,
		lineSpacing = 2,
		bottom = 0,
		text = "",
		objectOverrideFont = Configuration:GetFont(Configuration.chatFontSize, "console_" .. Configuration.chatFontSize, false, true),
		parent = self.spHistory,
		selectable = true,
		subTooltips = true,

		_inmousemove = false,
		OnClick = { function(obj)
			if not obj._inmousemove then
				screen0:FocusControl(self.ebInputText)
			end
			obj._inmousemove = false
		end},
		OnMouseMove = { function(obj, x, y, dx, dy, button)
			if button ~= 1 then
				return
			end
			obj._inmousemove = true
		end},
		onResize = onResize
	}

	self.ebInputText = EditBox:New {
		x = 0,
		bottom = 7,
		height = 25,
		right = 2,
		text = "",
		objectOverrideFont = Configuration:GetFont(Configuration.chatFontSize, "console_" .. Configuration.chatFontSize, false, true),
		objectOverrideHintFont = Configuration:GetHintFont(Configuration.chatFontSize, "console_hint_" .. Configuration.chatFontSize, false, true),
		--hint = i18n("type_here_to_chat"),
	}

	local function onConfigurationChange(listener, key, value)
		if key == "lastLoginChatLength" then
			if self.tbHistory then
				self:ClearHistory()
				self:LoadHistory(value)
			end
		elseif key == "chatFontSize" then
			local oldFont = self.ebInputText.font
			-- Relevant settings depend on skin
			local fontSettings = {
				font         = oldFont.font,
				color        = oldFont.color,
				outlineColor = oldFont.outlineColor,
				outline      = oldFont.outline,
				shadow       = oldFont.shadow,
				size         = value,
			}
			self.ebInputText.font = Configuration:GetFont(value, "console_font", fontSettings, true)
			self.ebInputText:UpdateLayout()

			self.tbHistory.font = Configuration:GetFont(value, "console_font", fontSettings, true)
			self.tbHistory:UpdateLayout()
		end
	end
	Configuration:AddListener("OnConfigurationChange", onConfigurationChange)

	local keyUP, keyDOWN, keyENTER, keyKP_ENTER, keyESCAPE, keyTAB = 
		Spring.GetKeyCode("up"),
		Spring.GetKeyCode("down"),
		Spring.GetKeyCode("enter"),
		Spring.GetKeyCode("numpad_enter"),
		Spring.GetKeyCode("escape"),
		Spring.GetKeyCode("tab")

	self.ebInputText.KeyPress = function(something, key, ...)
		if key == keyTAB then
			self:Autocomplete(self.ebInputText.text)
			return false
		else
			self.subword = nil
			local newtext, block = false, false
			local up, down = key == keyUP, key == keyDOWN
			if up or down then
				local cursor = self.sentMsgHistoryCursor
				local count = self.sentMsgHistoryCount
				cursor = cursor + (up and -1 or 1)
				if cursor == count + 2 then
					-- skip, the msg history has not yet be browsed up, nothing to do
				elseif cursor == 0 then
					-- skip, we've already gone to the first msg in history
				else
					if cursor == count + 1 then -- we gone back to the current text
						newtext = self.currentMsgBuffer
						self.currentMsgBuffer = ""
					else
						if up and cursor == count then -- we're starting going into history, saving the current text
							self.currentMsgBuffer = self.ebInputText.text
						end
						newtext = self.sentMsgHistory[cursor]
					end
					self.sentMsgHistoryCursor = cursor
				end
			elseif key == keyESCAPE then
				if self.ebInputText.text ~= "" then
					-- clearing field and resetting cursor pos
					self.sentMsgHistoryCursor = self.sentMsgHistoryCount + 1
					newtext = ""
					block = true -- block the action of escape that would leave the current lobby tab
				end
			else
				local text =  (self.ebInputText.text):gsub(':([%w_]+):', emotes)
				if text ~= self.ebInputText.text then
					newtext = text
				end
			end
			if newtext then
				self.ebInputText:SetText(newtext)
				self.ebInputText.cursor = #self.ebInputText.text + 1
				self.ebInputText:Invalidate()
				return block
			end

			return Chili.EditBox.KeyPress(something, key, ...)
		end
	end


	self.ebInputText.OnKeyPress = {
		function(obj, key, mods, ...)
			if key == keyENTER or
				key == keyKP_ENTER then
				self:SendMessage()
				return true
			end
		end
	}

	self.fakeImage = Image:New {
		x = 0, y = 0,
		bottom = 0, right = 0,
		OnClick = { function()
			screen0:FocusControl(self.ebInputText)
		end}
	}

	self.panel = Control:New {
		x = 0,
		y = 0,
		right = 0,
		bottom = 0,
		padding      = {0, 0, 0, 0},
		itemPadding  = {0, 0, 0, 0},
		itemMargin   = {0, 0, 0, 0},
		children = {
			self.spHistory,
			self.ebInputText,
			self.fakeImage,
		},
	}

	if not noHistoryLoad then
		self:LoadHistory(Configuration.lastLoginChatLength)
	end
end



function Console:Autocomplete(textSoFar)
	if not self.subword then
		local start = 0
		for i = 1, 100 do
			local newStart = (string.find(textSoFar, " ", start) or (start - 1)) + 1

			if start ~= newStart then
				start = newStart
			else
				break
			end
		end

		self.subword = string.sub(textSoFar, start)
		self.unmodifiedLength = string.len(textSoFar)
		local length = string.len(self.subword)

		self.suggestion = 0
		self.suggestions = {}

		if length == 0 then
			return
		end

		local users = lobby:GetUsers()
		for name, _ in pairs(users) do
			if name:starts(self.subword) then
				self.suggestions[#self.suggestions + 1] = string.sub(name, length + 1)
			end
		end
	end

	if #self.suggestions == 0 then
		return
	end

	self.suggestion = self.suggestion + 1
	if self.suggestion > #self.suggestions then
		self.suggestion = 1
	end

	self.ebInputText.selStart = self.unmodifiedLength + 1
	self.ebInputText.selEnd = string.len(textSoFar) + 1
	self.ebInputText:ClearSelected()

	self.ebInputText:TextInput(self.suggestions[self.suggestion])
end

function Console:SendMessage()
	if self.ebInputText.text ~= "" then
		message = self.ebInputText.text

		local cursor = self.sentMsgHistoryCursor
		local count = self.sentMsgHistoryCount
		if cursor == count  and self.sentMsgHistory[cursor] == self.ebInputText.text then
			-- skip, don't add to history the last message coming from history 
			self.sentMsgHistoryCursor = count + 1
		else
			if count == self.sentMsgHistoryMax then
				table.remove(self.sentMsgHistory, 1)
			else
				count = count + 1
				self.sentMsgHistoryCount = count
			end
			self.sentMsgHistory[count] = message
			self.sentMsgHistoryCursor = count + 1
		end
		self.currentMsgBuffer = ""

		self.ebInputText:SetText("")

		if message:find('^/') and not message:find('^/me ') and WG.UserCommand then
			WG.UserCommand(message:sub(2))
			return
		end
		if self.listener then
			self.listener(message)
		end
	end
end

-- TODO: Refactor method to use an options table
-- if date is not passed, current time is assumed
function Console:AddMessage(message, userName, dateOverride, color, thirdPerson, nameColor, nameTooltip, supressNameClick, suppressLogging)
	nameColor = nameColor or "\255\50\160\255"
	nameTooltip = nameTooltip or (userName and ("user_chat_s_" .. userName))
	local txt = ""
	local whiteText = ""
	if self.showDate then
		local timeOverride
		if dateOverride then
			local utcHour = tonumber(os.date("!%H"))
			local utcMinute = tonumber(os.date("!%M"))
			local localHour = tonumber(os.date("%H"))
			local localMinute = tonumber(os.date("%M"))

			local messageHour = tonumber(string.sub(dateOverride, 12, 13))
			local messageMinute = tonumber(string.sub(dateOverride, 15, 16))

			if messageHour and messageMinute then
				local hour = (localHour - utcHour + messageHour)%24
				if hour < 10 then
					hour = "0" .. hour
				end
				local minute = (localMinute - utcMinute + messageMinute)%60
				if minute < 10 then
					minute = "0" .. minute
				end

				timeOverride = hour .. ":" .. minute
			else
				Spring.Echo("Bad dateOverride", dateOverride, messageHour, messageMinute)
			end
		end
		-- FIXME: the input "date" should ideally be a table so we can coerce the format
		local currentTime = timeOverride or os.date(self.dateFormat)
		local curDate = self.currentDate
		local completeDate = false
		local nowYe, nowMo, nowDa = os.date('%Y'), os.date('%m'), os.date('%d')
		if curDate.year ~= nowYe or curDate.month ~= nowMo or curDate.day ~= nowDa then
			curDate.year, curDate.month, curDate.day = nowYe, nowMo, nowDa
			completeDate = WriteMonthDay(nowMo, nowDa, self.dateNumFormat) .. " " .. currentTime
		end
		txt = txt .. "\255\128\128\128[" .. (completeDate or currentTime) .. "] "
		whiteText = whiteText .. "[" .. currentTime .. "] "
		if color ~= nil then
			txt = txt .. color
		end
	end

	local textTooltip, onTextClick
	if userName ~= nil then
		local userStartIndex, userEndIndex
		if thirdPerson then
			userStartIndex = #txt
			txt = txt .. userName .. " "
			userEndIndex = userStartIndex + #userName
		else
			userStartIndex = #txt + 4
			txt = txt .. nameColor .. userName .. ": \255\255\255\255"
			userEndIndex = userStartIndex + #userName
			whiteText = whiteText .. userName .. ": "
			if color ~= nil then
				txt = txt .. color
			end
		end

		textTooltip = {
			{
				startIndex = userStartIndex,
				endIndex = userEndIndex,
				tooltip = nameTooltip
			}
		}
		if supressNameClick then
			onTextClick = {} -- Think about putting discord link here?
		else
			onTextClick = {
				{
					startIndex = userStartIndex,
					endIndex = userEndIndex,
					OnTextClick = {
						function()
							WG.UserHandler.GetUserDropdownMenu(userName, isBattleChat)
							--Spring.Echo("Clicked on " .. userName .. ". TODO: Spawn popup.")
						end
					}
				}
			}
		end
	end

	onTextClick, textTooltip = WG.BattleProposalHandler.AddClickableInvites(userName, txt, message, onTextClick or {}, textTooltip or {})
	txt = txt .. message
	onTextClick, textTooltip = WG.BrowserHandler.AddClickableUrls(txt, onTextClick or {}, textTooltip or {})

	whiteText = whiteText .. message
	if self.tbHistory.text == "" then
		self.tbHistory:SetText(txt, textTooltip, onTextClick)
	else
		self.tbHistory:AddLine(txt, textTooltip, onTextClick)
	end

	if self.channelName and not suppressLogging then
		Spring.CreateDir("chatLogs")
		local logFile, errorMessage = io.open('chatLogs/' .. self.channelName .. ".txt", 'a')
		if logFile then
			if dateOverride then
				logFile:write("\n" .. ((string.sub(dateOverride, 0, 19) .. " - ") or "") .. whiteText)
			else
				logFile:write("\n" .. whiteText)
			end
			io.close(logFile)
		end
	end
end

function Console:SetTopic(newTopic)
	if self.currentTopic == nil or newTopic ~= self.currentTopic then
		self.currentTopic = newTopic
		self:AddMessage(newTopic, nil, nil, Configuration.meColor, nil, nil, nil, nil, true)
	end
end


function Console:LoadHistory(numLines)
	-- I was having hang detection because of a log > 15 MB and couldn't connect, code was really not optimized
	-- That new code process 15MB log in 5 ms.
	-- Also fixed potential missing/broken line and implemented proper time stamping for older days.
	if not self.channelName then
		return
	end

	local curDate, numFormat = self.currentDate, self.dateNumFormat
	local path = 'chatLogs/' .. self.channelName .. ".txt"
	if not VFS.FileExists(path) then
		return
	end
    local size = numLines * 1000 -- 1000 char per line, to make sure
    local file = io.open(path, 'r')
    local small = not file:seek('end', -size)

    local txt = file:read('*a')
    local count = select(2, txt:gsub('\n', ''))

    file:seek('cur', -1)
    if file:read('*a') ~= '\n' then
        count = count + 1
    end
    local beginning = count - numLines + 1
    -- Spring.Echo("beginning is at " .. beginning .. '/' .. count)
    if not small then
        file:seek('end', -size)
    else
        file:seek('set', 0)
    end

    local i, j = 0, 0
    local lines = {}
    for line in file:lines() do
        i = i + 1
        if i >= beginning and line ~= '' then
        	j = j + 1
        	lines[j] = ProcessHistoryLine(line, curDate, numFormat)
        end
    end

    file:close()
    local curDate = self.currentDate
    -- Echo('End of loading history of ' .. self.channelName .. ', current date is', curDate.year, curDate.month, curDate.day)
    self.tbHistory:SetText(table.concat(lines, '\n'))
end


function Console:ClearHistory()
	self.tbHistory:SetText("")
	self.currentDate = {year = '0', month = '0', day = '0'}
end

function Console:Delete()
	self = nil -- doesn't make any sense?
end
