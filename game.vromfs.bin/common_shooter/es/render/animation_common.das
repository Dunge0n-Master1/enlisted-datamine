module animation_common shared

require ecs
require AnimV20

let
  upperHash = ecs_hash("upper")
  lowerHash = ecs_hash("lower")

def set_human_anim_state(eid : EntityId; state : int)
  send_change_anim_state_event(eid, "lower", lowerHash, state)
  send_change_anim_state_event(eid, "upper", upperHash, state)
