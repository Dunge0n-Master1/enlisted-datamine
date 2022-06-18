import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {localPlayerEid} = require("%ui/hud/state/local_player.nut")
let {CmdCreateMapPoint} = require("dasevents")

let function command(event, minimapState){
  let rect = event.targetRect
  let elemW = rect.r - rect.l
  let elemH = rect.b - rect.t
  let relX = (event.screenX - rect.l - elemW*0.5) * 2 / elemW
  let relY = (event.screenY - rect.t - elemH*0.5) * 2 / elemH
  let worldPos = minimapState.mapToWorld(relY, relX) // take care of rotation
  ecs.g_entity_mgr.sendEvent(localPlayerEid.value, CmdCreateMapPoint({x = worldPos.x, z = worldPos.z}))
}

return command