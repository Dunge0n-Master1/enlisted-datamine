require ecs
require EnlistedHuman
require HumanPhys

[es(tag=gameClient, track=isInVehicle, REQUIRE=(human_input, isInVehicle))]
def human_input_enter_exit(evt : Event; var human_input__standState : int&)
  human_input__standState = 0

[es(on_event=EventEntityRevived)]
def human_set_revived_es(evt : Event; var human_net_phys : HumanActor)
  human_phys_state_set_is_downed(human_net_phys.phys.currentState, false)
