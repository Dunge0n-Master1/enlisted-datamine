require ecs
require MotionMatching
require DngHuman
require PhysVars
require %danetlibs/motion_matching/es/mm_events
require %danetlibs/motion_matching/es/tags_common


[es(tag=gameClient)]
def motion_matching_locomotion_state(act : ParallelUpdateFrameDelayed;
                                     human_net_phys : HumanActor;
                                     human_anim__isFpvVarId : int;
                                     phys_vars : PhysVars;
                                     var motion_matching__goalTags : StringList;
                                     var motion_matching__afterSprintTime : float&;
                                     var motion_matching__enabled : bool&;
                                     motion_matching__enableInFpv : bool = false;
                                     motion_matching__keepEnabledAfterSprint : float = 0.5f)
  assume phys = human_net_phys.phys
  let isSprinting = (int(phys.currentState.states) & int(StateFlag ST_SPRINT)) != 0
  if isSprinting
    motion_matching__afterSprintTime = motion_matching__keepEnabledAfterSprint
  elif motion_matching__afterSprintTime > 0f
    motion_matching__afterSprintTime -= act.dt
  motion_matching__enabled = isSprinting || motion_matching__afterSprintTime > 0f
  // we have special sprint animations for fpv mode, but they are not ready to be used in MM
  if phys_vars |> getVar(human_anim__isFpvVarId) > 0f
    motion_matching__enabled &&= motion_matching__enableInFpv
  set_tag(motion_matching__goalTags, isSprinting, "sprint")

[es(tag=gameClient)]
def motion_matching_set_wish_speed(act : ParallelUpdateFrameDelayed;
                                   human_net_phys : HumanActor;
                                   var mm_trajectory__wishLinearVelocity : float3&)
  assume phys = human_net_phys.phys
  let isSprinting = (int(phys.currentState.states) & int(StateFlag ST_SPRINT)) != 0
  let sprintSpeed = phys |> human_phys_getWalkSpeed(HUStandState ESS_STAND, HUMoveState EMS_SPRINT)
  if isSprinting
    mm_trajectory__wishLinearVelocity = normalize(phys.currentState.velocity) * sprintSpeed
  else
    mm_trajectory__wishLinearVelocity = float3(0f)
