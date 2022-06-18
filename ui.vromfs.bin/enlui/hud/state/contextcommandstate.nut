import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let contextCommandState = {
  orderType = mkWatched(persist, "orderType", 0)
  orderUseEntity = mkWatched(persist, "orderUseEntity", INVALID_ENTITY_ID)
}

let function updateContextCommand(_evt, _eid, comp) {
  contextCommandState.orderType(comp["human_context_command__orderType"])
  contextCommandState.orderUseEntity(comp["human_context_command__orderUseEntity"])
}

ecs.register_es("human_context_command_state_es",
  {
    [["onInit", "onChange"]] = updateContextCommand
  },
  {
    comps_rq = ["human_context_command_input"]
    comps_track = [
      ["human_context_command__orderType", ecs.TYPE_INT],
      ["human_context_command__orderUseEntity", ecs.TYPE_EID],
    ]
  },
  { tags="gameClient" }
)

return contextCommandState
