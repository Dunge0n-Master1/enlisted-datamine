import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {has_network} = require("net")
let sessionId = Watched(null)
let {EventLevelLoaded} = require("gameevents")
let { get_session_id } = require("app")

//not sure if this is the best way to handle sessionId in game. It can be straightforward with native Observable
if (has_network()){
  ecs.register_es(
    "session_id_ui_es",
    {[EventLevelLoaded] = @() sessionId.update(get_session_id())}
  )
}
return sessionId