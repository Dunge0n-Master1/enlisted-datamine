require ecs
require EnlistedHuman
require HumanPhys

[es(track=human_state__lockCrawl)]
def human_lock_crawl_es(evt : Event; human_state__lockCrawl : bool; var human_net_phys : HumanActor)
  human_net_phys.phys.canCrawl = !human_state__lockCrawl

[es(track=human_state__lockCrouch)]
def human_lock_crouch_es(evt : Event; human_state__lockCrouch : bool; var human_net_phys : HumanActor)
  human_net_phys.phys.canCrouch = !human_state__lockCrouch

[es(tag=gameClient, track=isInVehicle, REQUIRE=(human_input, isInVehicle))]
def human_input_enter_exit(evt : Event; var human_input__standState : int&)
  human_input__standState = 0

[es(on_event=EventEntityRevived)]
def human_set_revived_es(evt : Event; var human_net_phys : HumanActor)
  human_phys_state_set_is_downed(human_net_phys.phys.currentState, false)
