import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let state = Watched({
  orderType = 0
  orderUseEntity = ecs.INVALID_ENTITY_ID
})

ecs.register_es("human_context_command_state_es",
  {
    [["onInit", "onChange"]] = @(_evt, _eid, comp) state({
      orderType = comp["human_context_command__orderType"]
      orderUseEntity = comp["human_context_command__orderUseEntity"]
    })
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

return {
  orderType = Computed(@() state.value.orderType)
  orderUseEntity = Computed(@() state.value.orderUseEntity)
}
