require ecs
require EnlistedHuman
require HumanPhys

[es(on_event=EventComponentChanged, track=human_state__lockCrawl)]
def human_lock_crawl_es(evt : Event; human_state__lockCrawl : bool; var human_net_phys : HumanActor)
  human_net_phys.phys.canCrawl = !human_state__lockCrawl

[es(on_event=EventComponentChanged, track=human_state__lockCrouch)]
def human_lock_crouch_es(evt : Event; human_state__lockCrouch : bool; var human_net_phys : HumanActor)
  human_net_phys.phys.canCrouch = !human_state__lockCrouch

[es(tag=gameClient, track=isInVehicle, REQUIRE=human_input)]
def human_input_enter_exit(evt : Event;
                           isInVehicle : bool;
                           human_anim__vehicleSelected : EntityId;
                           var human_input__standState : int&)
  if isInVehicle
    human_input__standState = has(human_anim__vehicleSelected, "antiAircraftCannon") ? int(HumanPhysControlType HCT_CROUCH) : 0
  else
    human_input__standState = 0

[es(on_event=EventEntityRevived)]
def human_set_revived_es(evt : Event; var human_net_phys : HumanActor)
  human_phys_state_set_is_downed(human_net_phys.phys.currentState, false)
