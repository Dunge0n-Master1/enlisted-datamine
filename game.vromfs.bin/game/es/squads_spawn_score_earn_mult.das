require ecs
require ecs.safe

[es(tag=server, on_appear, track=isArmiesReceived)]
def init_squads_spawn_score_gain_multiplier(evt : Event;
                                            isArmiesReceived : bool;
                                            armies : Object;
                                            army : string;
                                            var respawner__spawnScoreGainMultBySquad : FloatList&)
  if !isArmiesReceived
    return
  assume squads = (armies[army] ?as Object)?.squads ?as Array
  if squads == null
    return
  respawner__spawnScoreGainMultBySquad |> resize(length(*squads))
  for mult, obj in respawner__spawnScoreGainMultBySquad, *squads
    let squad = obj as Object
    mult = squad?.spawnScoreGainMult ?? 1.0
