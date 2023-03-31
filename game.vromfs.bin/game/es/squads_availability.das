require ecs
require ecs.safe

[es(tag=server, on_appear, track=isArmiesReceived)]
def init_squads_score_prices(evt : Event;
                             isArmiesReceived : bool;
                             armies : Object;
                             army : string;
                             var respawner__scorePricePerSquad : IntList&;
                             var respawner__scorePricePerSquadPerSpawn : Object&)
  if !isArmiesReceived
    return
  assume squads = (armies[army] ?as Object)?.squads ?as Array
  if squads == null
    return

  for ind, obj in iter_range(*squads), *squads
    let squad = obj as Object
    let prices = squad?.spawnCostPerSpawnPersonalScore ?as Array
    var firstSpawnPrice = 0
    if prices != null
      respawner__scorePricePerSquadPerSpawn |> set("{ind}", *prices)
      firstSpawnPrice = prices?[0] ?? firstSpawnPrice
    respawner__scorePricePerSquad |> push(firstSpawnPrice)

[es(tag=server, after=track_squads_spawn_count, on_appear)]
def track_squad_spawn_price(evt : Event; squad__id : int; squad__ownerPlayer : EntityId)
  query(squad__ownerPlayer) <| $ [es] (respawner__spawnCountPerSquad : IntList;
                                       respawner__scorePricePerSquadPerSpawn : Object;
                                       var respawner__scorePricePerSquad : IntList&)
    if squad__id < length(respawner__scorePricePerSquad)
      let prevPrice = respawner__scorePricePerSquad[squad__id]
      let pricePerSpawn = (respawner__scorePricePerSquadPerSpawn["{squad__id}"] ?as Array)
      if pricePerSpawn != null
        let spawnCount = min(respawner__spawnCountPerSquad?[squad__id] ?? 0, length(*pricePerSpawn) - 1)
        respawner__scorePricePerSquad[squad__id] = pricePerSpawn?[spawnCount] ?? prevPrice

[es(tag=ui, on_appear, track=(respawner__scorePricePerSquad, respawner__spawnScore))]
def track_squads_affordability(evt : Event;
                               respawner__spawnScore : int;
                               respawner__scorePricePerSquad : IntList;
                               var squads__affordabilityList : BoolList&)
  squads__affordabilityList |> resize(length(respawner__scorePricePerSquad))
  for isAvailable, price in squads__affordabilityList, respawner__scorePricePerSquad
    isAvailable = respawner__spawnScore >= price
