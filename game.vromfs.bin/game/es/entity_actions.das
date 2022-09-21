require ecs
require Action
require game.es.action_common
require enlisted.events_enlisted

[es(no_order)]
def track_active_action_es(info : ParallelUpdateFrameDelayed;
                           actions : EntityActions;
                           var action__running : bool&)

  action__running = actions.anyActionRunning


[es(on_event=EventEntityDied, REQUIRE=actions)]
def interrup_actions_es(evt : Event; eid : EntityId)
  interrupt_actions(eid)
