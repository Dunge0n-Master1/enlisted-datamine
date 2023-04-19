require ecs
require DagorInput
require enlisted.events_enlisted
require HumanPhys
require DngHuman
require net
require game.es.input.input_common


[es(tag=input, REQUIRE=hero, track=(human_net_phys__isHctAim, human_net_phys__isHctShoot, human_net_phys__states))]
def fortification_destroying_interrupt_on_gamepad(evt : Event;
                                                  eid : EntityId;
                                                  human_net_phys__isHctAim : bool;
                                                  human_net_phys__isHctShoot : bool;
                                                  human_net_phys__states : int;
                                                  building_action__target : EntityId)
  if !is_gamepad_input()
    return

  query(building_action__target) <| $ [es(REQUIRE_NOT=undestroyableBuilding)] (building_destroy__timeToDestroy : float)
    if building_destroy__timeToDestroy <= 0.0
      return

    let isHumanJumping = ((uint(human_net_phys__states) & uint(StateFlag ST_JUMP)) != 0u)
    if human_net_phys__isHctAim || human_net_phys__isHctShoot || isHumanJumping
      send_net_event(eid, [[EventSetBuildingTarget target=INVALID_ENTITY_ID]])


[es(tag=input)]
def fortification_reset_toggle_on_set_building_target(evt : EventSetBuildingTarget; human_input__buildingAction : int)
  if !evt.target
    reset_digital_action_sticky_toggle(uint16(human_input__buildingAction))
