require ecs
require game.es.player_common
require game.es.client.spectator_common
require game.events_game


[es(tag=input)]
def change_spectator_target_after_death(evt : EventAnyEntityDied;
                                        eid : EntityId;
                                        spectator__teamId : int;
                                        var spectator__target : EntityId&)
  if spectator__target == evt.victim
    set_spectated(eid, spectator__target, find_next_spec_target(spectator__teamId, spectator__target, +1))
