import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let { DBGLEVEL } = require("dagor.system")

let switchSendModesAllowed = Watched(DBGLEVEL > 0)

ecs.register_es("allow_switch_chat_mode_es", {
  [["onInit","onChange"]] = @(_evt, _eid, comp) switchSendModesAllowed(comp.game_option__allowSwitchChatMode)
},
{
  comps_track = [["game_option__allowSwitchChatMode", ecs.TYPE_BOOL]]
})

return {
  switchSendModesAllowed
}