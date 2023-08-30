require ecs
require player
require soundEvent


[es(tag=sound, on_appear)]
def vote_to_kick_start_sound(evt : Event; kick_voting__accused : EntityId)
  if get_local_player_eid() != kick_voting__accused
    query(get_local_player_eid()) <| $ [es] (team aka player__team : int)
      query(kick_voting__accused) <| $ [es] (team : int)
        if player__team == team
          oneshot("ui/vote_to_kick")
