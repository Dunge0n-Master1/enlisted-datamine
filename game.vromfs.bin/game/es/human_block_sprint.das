require ecs
require game.es.events
require game.es.action_common
require DngHuman
require HumanPhys

[es]
def human_block_sprint_es(info : CmdPostPhysUpdate;
                          eid : ecs::EntityId;
                          var human_net_phys : HumanActor;
                          human_weap__throwMode : bool;
                          human_phys__jumpEndTime : float;
                          human_phys__afterJumpDelay : float = -1.;
                          human_phys__blockSpringHeight : float = -0.5;
                          burning__isPuttingOut : bool = false;
                          human_melee_charge__isOnCooldown : bool = false)
  let physTime = float(info.tick) * info.dt
  assume currentState = human_net_phys.phys.currentState
  let isBlockedByJump = physTime < human_phys__jumpEndTime + human_phys__afterJumpDelay
  let isBlockedByPose = currentState.height < human_phys__blockSpringHeight
  let isBlockedByAction = does_action_block_sprint(eid)
  let blocked = isBlockedByPose || human_weap__throwMode || isBlockedByAction || burning__isPuttingOut || isBlockedByJump || human_melee_charge__isOnCooldown
  human_phys_state_set_block_sprint(currentState, blocked)
