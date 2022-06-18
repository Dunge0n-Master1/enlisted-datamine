from "%enlSqGlob/ui_library.nut" import *

let getPlayersCountInRoomText = @(r) $"{r?.membersCnt ?? 0}/{r?.maxPlayers ?? 0}"

return getPlayersCountInRoomText