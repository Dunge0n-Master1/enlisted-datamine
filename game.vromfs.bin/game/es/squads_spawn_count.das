require ecs
require ecs.safe

[es(tag=server, on_appear, track=isArmiesReceived)]
def init_squad_spawn_count(evt : Event;
                           isArmiesReceived : bool;
                           armies : Object;
                           army : string;
                           var respawner__spawnCountPerSquad : IntList&)
  if !isArmiesReceived
    return

  assume squads = (armies[army] ?as Object)?.squads ?as Array
  if squads == null
    return

  let squadsCount = length(*squads)
  respawner__spawnCountPerSquad |> resize(squadsCount)
  for spawnCount in respawner__spawnCountPerSquad
    spawnCount = 0

[es(tag=server, on_appear)]
def track_squads_spawn_count(evt : Event; squad__id : int; squad__ownerPlayer : EntityId)
  query(squad__ownerPlayer) <| $ [es] (var respawner__spawnCountPerSquad : IntList&)
    if squad__id < length(respawner__spawnCountPerSquad)
      respawner__spawnCountPerSquad[squad__id] += 1
