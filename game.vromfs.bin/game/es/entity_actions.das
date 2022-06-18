require ecs
require Action

[es(no_order)]
def track_active_action_es(
                           info : UpdateStageInfoAct;
                           eid : EntityId;
                           var action__running : bool&)

  action__running = is_action_running(eid)


[es(on_event=EventEntityDied, REQUIRE=actions)]
def interrup_actions_es(evt : Event; eid : EntityId)
  interrupt_actions(eid)
