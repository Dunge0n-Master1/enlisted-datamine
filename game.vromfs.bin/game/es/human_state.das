require ecs
require DngHuman
require HumanPhys

[es(on_event=EventEntityRevived)]
def human_set_revived_es(evt : Event; var human_net_phys : HumanActor)
  human_phys_state_set_is_downed(human_net_phys.phys.currentState, false)
