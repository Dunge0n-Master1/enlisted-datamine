require ecs
require game.es.events
require Action
require EnlistedHuman
require HumanPhys

[es]
def human_block_sprint_es(info : CmdPostPhysUpdate;
                          eid : ecs::EntityId;
                          var human_net_phys : HumanActor;
                          human_weap__throwMode : bool;
                          human_phys__jumpEndTime : float;
                          human_phys__afterJumpDelay : float = -1.;
                          human_phys__blockSpringHeight : float = -0.5;
                          burning__isPuttingOut : bool = false)
  let physTime = float(info.tick) * info.dt
  assume currentState = human_net_phys.phys.currentState
  let isBlockedByJump = physTime < human_phys__jumpEndTime + human_phys__afterJumpDelay
  let isBlockedByPose = currentState.height < human_phys__blockSpringHeight
  let blocked = isBlockedByPose || human_weap__throwMode || does_action_block_sprint(eid) || burning__isPuttingOut || isBlockedByJump
  human_phys_state_set_block_sprint(currentState, blocked)
