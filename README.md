The moded chobby is contained in the 2 directories libs and LuaMenu, and must be placed in the root of the installation of ZK.
To enable the mod, user need to modify the file LuaMenu\Config\IGL_data.lua.
In the subtable "Chili lobby", set loadLocalWidgets = true, (make the line if it doesn't exist).

Implemented so far:
PM notification ingame
Lobby commands (that can also work ingame), <user_name> can be autocompleted (in game in some case, and in lobby)
For this to work in game, it requires GameToLobbyMessage.lua and lobby_command.lua from Hel-K
    /r <message> to reply to last pm user
    /pm <user_name> <message>
    /join <room_name>
    /open <user_name> open tab of private discussion

Battle room chat reported in game (need Widgets/gui_chili_proconsole_test.lua from Hel-K)

Options added in Lobby Setting's tab:
    Notify (including ingame) on High Level 1v1
    Notify (including ingame) on any battle started
Implemented slide bars in Game and Graphic settings tabs
Implemented additional options in Game and Graphic settings tabs
Implemented emotes (need LuaUI\Widgets\Include\emotes.lua and eventually Widgets/gui_chili_proconsole_test.lua, from Hel-K.
Find name of emotes in emotes.lua and add more via the pro console widget option ingame.
Usage in message: Blabla :<emote_name>: blabla.



