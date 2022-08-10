require ecs
require debug.logerr_once
require strings
require AnimV20

[es(on_appear)]
def init_human_jump_anim_state(evt : Event;
                               eid : EntityId;
                               animchar : AnimcharBaseComponent;
                               human_anim__jumpUpperState : string;
                               var human_anim__jumpUpperStateId : int&)
  if empty(human_anim__jumpUpperState)
    return
  human_anim__jumpUpperStateId = anim_graph_getStateIdx(*animchar.animGraph, human_anim__jumpUpperState)
  if human_anim__jumpUpperStateId < 0
    logerr_once("anim state {human_anim__jumpUpperState} not found for {getEntityTemplateName(eid)}")
