require ecs
require EnlistedHuman
require HumanPhys
require Gun

[es(before=after_net_phys_sync, after=human_weap_phys_es)]
def enlisted_human_weap_phys_es(info : UpdateStageInfoAct;
                                human_weap__canAimInJump : bool = false;
                                var human_net_phys : HumanActor&)
  assume ct = human_net_phys.phys.currentState

  let isJumpState = !human_weap__canAimInJump && (uint(human_net_phys.phys.currentState.states) & uint(StateFlag ST_JUMP)) != 0u
  human_phys_state_set_can_aim(ct, human_phys_state_can_aim(ct) && !isJumpState)
  human_phys_state_set_can_zoom(ct, human_phys_state_can_zoom(ct) && !isJumpState)

[es(on_event=CmdPostPhysUpdate)]
def enlisted_human_weap_phys_reduce_to_walk_when_shoot(evt : Event;
                                                       human_weap__currentGunEid : EntityId;
                                                       var human_net_phys : HumanActor&)
  var reduceToWalk = false
  query(human_weap__currentGunEid) <| $ [es(REQUIRE=gun__reduceToWalkWhenShot)] (gun : Gun)
    reduceToWalk = gun.curState.atTime < gun.curState.nextShotAtTime
  human_phys_state_set_reduceToWalk(human_net_phys.phys.currentState, reduceToWalk)
