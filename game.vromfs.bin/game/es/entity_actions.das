require ecs
require Action
require enlisted.events_enlisted

[es]
def track_active_action_es(
                           info : ParallelUpdateFrameDelayed;
                           eid : EntityId;
                           var action__running : bool&)

  action__running = is_action_running(eid)


[es(on_event=EventEntityDied, REQUIRE=actions)]
def interrup_actions_es(evt : Event; eid : EntityId)
  interrupt_actions(eid)
