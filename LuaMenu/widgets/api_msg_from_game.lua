
function widget:GetInfo()
    return {
        name      = "Message From Game",
        desc      = "",
        author    = "Helwor",
        date      = "June 2024",
        license   = "GNU GPL, v2 or later",
        layer     = 10e38,
        -- layer     = 2,
        enabled   = true,  --  loaded by default?
        api       = true,
        handler   = true,
    }
end
if not WG['avoidDuplicateWidgetLoad'..widget:GetInfo().name] then
    Spring.Echo('Avoiding duplicate load of local widget: ' .. widget:GetInfo().name)
    WG['avoidDuplicateWidgetLoad'..widget:GetInfo().name] = true
    return false
end
local sig = '[' .. widget:GetInfo().name .. ']:'
local Echo = Spring.Echo

local lobby, server, Conf

local host = "127.0.0.1"
local port = VFS.LoadFile("chobby_wrapper_port.txt")
if not port then
    Echo(widget:GetInfo().name .. " don't have any port set")
    return false
end
port = port + 1
LIB_LOBBY_DIRNAME = "libs/liblobby/lobby/" -- why is this needed? why doesnt api load first?
VFS.Include(LIB_LOBBY_DIRNAME .. "json.lua")
if not json then
    Echo(sig .. 'wrong include dir: ' .. LIB_LOBBY_DIRNAME .. "json.lua")
    return false
end
local server_t, cli_t = {}, {}
function widget:Initialize()
    server = socket.tcp()
    server:settimeout(0.1)
    local success, err = server:bind(host, port)
    if not success then
        Echo(sig .. err)
        widgetHandler:RemoveWidget(widget)
        return
    end
    local success, err = server:listen(5) -- maximum connections allowed
    if not success then
        Echo(sig .. err)
        widgetHandler:RemoveWidget(widget)
        return
    end
    server:settimeout(0)
    server_t[1] = server
end
local function GetAllUsers() -- indexed, for keyed => WG.LibLobby.lobby:GetUsers()
    local chatWindow = WG.Chobby.interfaceRoot.GetChatWindow()
    if chatWindow then
        local userListPanels = chatWindow.userListPanels
        if userListPanels then
            if userListPanels.zk then
                return userListPanels.zk:GetUsers()
            end
        end
    end
end
local function AutoComplete(subword)
    if subword:len() == 0 then
        return false, subword
    end
    local lobby = WG.LibLobby.lobby
    local users = lobby:GetUsers()
    if not users[subword] then
        local lowersubword = subword:lower()
        if users[lowersubword] then
            return true, lowersubword
        else
            for name in pairs(users) do
                local lowername = name:lower()
                if lowername:find('^' .. lowersubword) then
                    return true, name
                end
            end
        end
    end
    return false, subword
end

-- function widget:RecvLuaMsg(msg)
--     Echo("RecvLuaMsg msg is ", msg)
-- end
local nextword = function(str,n)
    local count = 0
    for word in str:gmatch('[%w_]+') do
        count = count + 1
        if count == (n or 2) then
            return word
        end
    end
end
local sentence = function(str, n) -- gather rest of line starting by a word; after n word, omitting blanks and newlines at end
    local st, fin = 1, 0
    local count = 0
    while st and (n or 0) >= count do
        st, fin = str:find('%S+', fin+1)
        count = count + 1
    end
    if st then
        fin = str:find('%s+$')
        return str:sub(st, (fin or 0) - 1)
        -- return str:sub(fin+2):match('(%S[^\n\r]+)')
    end
end
function string.explode(str, div)
if (div=='') then return false end
local pos,arr = 0,{}
-- for each divider found
for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
end
table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
return arr
end

local function ReceiveMessage(msg, cli, writeable) -- WE CAN ASLO DISCUSS THROUGH Spring.SendLuaMenuMsg <=> Spring.SendLuaUIMsg
    if not lobby then
        lobby = WG.LibLobby and WG.LibLobby.lobby --(lobby is interface_shared + interface_zerok see api_lobby.lua)
    end
    if msg:find('^tell ') then
        local key = sentence(msg, 1)

        key = tostring(key)
        local value
        if key:find('.') then
            local keys = key:explode('.')
        

            value = lobby
            for i, k in ipairs(keys) do
                k = tonumber(k) or k
                if type(value[k]) == 'table' then
                    value = value[k]
                elseif not keys[i+1] then
                    value = tostring(value[k])
                else
                    value = 'wrong type for key ' .. k .. ' : ' .. type(value[k])
                    break
                end
            end
        else
            key = tonumber(key) or key
            value = lobby[key]
        end

        if type(value) == 'table' then
            value = tostring(value) .. ' #' .. table.size(value)
        else
            value = tostring(value)
        end
        Echo('Tell ' .. key, value)
        WG.Chotify:Post{
            title = 'Tell ' .. key,
            body = value,
            time = 15,
        }
        return
    elseif msg:find('^r ') then
        if writeable then
            cli:send(lobby.lastPMUser or '')
        else
            Echo('there was a problem, the client proxy is not writeable',cli)
        end
        return
    elseif msg:find('^join ') then
        -- JoinChannel {"ChannelName":"clan_ELOKR"}
        local channelName = sentence(msg,1)
        if channelName then
            lobby:Join(channelName)
        end
        return
    elseif msg:find('^reload api') then
        widgetHandler:RemoveWidget(widget)
        widgetHandler:EnableWidget(widget:GetInfo().name)
        return
    elseif msg:find('^reload lobby ') then
        local name = sentence(msg,2)
        -- widgetHandler is actually luaHandler in Chobby
        if name then
            local w = widgetHandler:FindByName(name)
            if not w then
                Echo('warn, this is an api widget', name)
                for k,v in widgetHandler.widgets:iter() do
                    if v.GetInfo().name == name then
                        w = v
                        break
                    end
                end
            end
            if w then
                Echo('reloading widget ' .. name)
                widgetHandler:RemoveWidget(w)
                widgetHandler:EnableWidget(name)
            else
                Echo('widget ' .. name .. ' not found')
            end
        end
        return
    elseif msg:find('^open ') then
        local room = msg:sub(6)
        if room:len() > 0 then
            WG.Chobby.interfaceRoot.OpenPrivateChat(room)
        end
        return
    elseif msg:find('^pm ') then
        local userName, message = nextword(msg,2), sentence(msg,2)
        if userName and message then
            local changed, newTarget = AutoComplete(userName)
            if changed then
                Echo('target autocompleted: ' .. newTarget)
                userName = newTarget
            end
            if message:find('^/me ') then
                lobby:SayPrivateEx(userName, message:sub(4))
            else
                lobby:SayPrivate(userName, message)
            end
        end

    -- elseif msg:find('^Say ') then
    --     local target = msg:match('\"Target\":\"([%w_]+)')
    --     if target then
    --         local changed, newtarget = AutoComplete(target)
    --         if changed then
    --             msg = msg:gsub('(\"Target\":\")([%w_]+)','%1' .. newtarget)
    --         end
    --     end
    --     lobby:_SendCommand(msg)
    else
        WG.Chotify:Post{
            title = '',
            body = 'Unrecognized command ' .. msg .. ',\n' .. 'reloading just in case.',
            time = 3,
        }
        Echo('reloading just in case')
        widgetHandler:RemoveWidget(widget)
        widgetHandler:EnableWidget(widget:GetInfo().name)

    end
    -- cli:send('OK\n')
end
WG.UserCommand = ReceiveMessage

function widget:Update()
    if not cli then
        local readable , _, err = socket.select(server_t, nil, 0)
        if err == 'timeout' then
            return
        elseif not err then
            if readable and readable[server] then
                cli = server:accept()
                Echo('new client connected', cli)
                cli_t[1] = cli
            end
        end
    end
    if cli then
        local readable , writeable, err = socket.select(cli_t, cli_t, 0)
        if err then
            if err=="timeout" then
                return
            end
            Echo(sig .. "Error in select: " .. err)
            return
        end

        if readable[cli] then
            local s, status, partial = cli:receive() 
            if status == "timeout" or status == nil then
                ReceiveMessage(s or partial, cli, writeable[cli])
            elseif status == "closed" then
                Echo('client closed', cli)
                cli:close()
                cli_t[1] = nil
                cli = nil
                return
            end
        end
    end
end
function widget:Shutdown()
    if server then
        server:close()
        server = nil
    end
    if cli then
        cli:close()
    end
end