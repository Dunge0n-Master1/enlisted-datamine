require ecs
require game.events_game
require game.es.action_common

[es(tag=netClient, REQUIRE=actions)]
def actions_run_es(evt : RunActionCmd; eid : EntityId)
  run_action_by_id(eid, evt.id, evt.overridePropsId, -1, evt.overrideTime,
    evt.overrideAt, evt.actionPeriod, evt.progress, evt.timeMult)
