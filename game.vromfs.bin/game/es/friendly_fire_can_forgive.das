require ecs
require ecs.safe

[es(tag=server, on_appear, track=friendly_fire__forgivableStats)]
def friendly_fire_track_players_can_forgive_server(evt : Event;
                                                   friendly_fire__forgivableStats : Object;
                                                   var friendly_fire__canForgivePlayers : Object&)
  clear(friendly_fire__canForgivePlayers)
  for it in friendly_fire__forgivableStats
    let val = it.value as Array
    friendly_fire__canForgivePlayers |> set(it.key, val != null && !empty(*val))
