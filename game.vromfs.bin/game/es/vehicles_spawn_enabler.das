require ecs
require ecs.common
require ecs.safe
require ecs.extra_set
require app
require strings
require daslib/strings_boost
require game.es.respawn_base_common
require DagorSystem

struct RespawnBaseData
  respType : string
  subtypes : array<string>
  squadIndices : array<int>

struct TypeHash
  typ : table<string; int>
  subtype : table<string; int>

def make_type_hash(var type_hash : table<string; int>; key : string)
  if !type_hash |> key_exists(key)
    type_hash[key] = length(type_hash) + 1
  return type_hash[key]

def make_respawn_key(var type_hash : TypeHash&; respawn : RespawnBaseType)
  if length(respawn.canUseRespawnbaseSubtypes) == 0
    return type_hash.typ |> make_type_hash(respawn.canUseRespawnbaseType)
  let mainTypeHash = type_hash.typ |> make_type_hash(respawn.canUseRespawnbaseType)
  var subTypeHash = 0
  for subtype in respawn.canUseRespawnbaseSubtypes
    subTypeHash |= type_hash.subtype |> make_type_hash(subtype)
  return (mainTypeHash << 16) + int(int16(subTypeHash))

def gather_respawnbase_types(squads : Array)
  var respTypes : table<int; RespawnBaseData>
  var typeHash : TypeHash
  for i, it in iter_range(squads), squads
    assume squad = it as Object
    let squadVehicleTemplate = (squad?.curVehicle ?as Object)?.gametemplate ?? ""
    if !empty(squadVehicleTemplate)
      var respawnBaseType <- get_can_use_respawnbase_type(squadVehicleTemplate)
      assume canUseRespawnbaseType = respawnBaseType.canUseRespawnbaseType
      assume canUseRespawnbaseSubtypes = respawnBaseType.canUseRespawnbaseSubtypes
      if !empty(canUseRespawnbaseType)
        let key = typeHash |> make_respawn_key(respawnBaseType)
        if !(respTypes |> key_exists(key))
          respTypes[key] <- [[RespawnBaseData respType=canUseRespawnbaseType, subtypes <- canUseRespawnbaseSubtypes]]
        respTypes[key].squadIndices |> push(i)
  return <- respTypes

def update_vehicle_respawner(team : int;
                             squads__count : int;
                             respawner__vehicleSquadRespawnTypes : Array;
                             respawner__firstSpawnThresholdBySquad : IntList;
                             respawner__lastSpawnTimeBySquad : IntList;
                             var respawner__nextSpawnOnVehicleTimeBySquad : IntList&;
                             var respawner__vehiclesLimitBySquad : IntList&)
  let curTimeSecond = int(get_sync_time())

  respawner__nextSpawnOnVehicleTimeBySquad |> resize(squads__count)
  respawner__vehiclesLimitBySquad |> resize(squads__count)
  for nextTime, vehicles in respawner__nextSpawnOnVehicleTimeBySquad, respawner__vehiclesLimitBySquad
    nextTime = -1
    vehicles = -1

  for it in respawner__vehicleSquadRespawnTypes
    assume respawn = it as Object
    let respType = respawn?.respType ?? ""
    let subtypesList = respawn?.subtypes |> get_ecs_StringList()
    let squadIndices = respawn?.squadIndices |> get_ecs_IntList()
    if squadIndices == null
      continue
    var subtypes : array<string>
    if subtypesList != null
      for subtype in *subtypesList
        subtypes |> push(string(subtype))
    let baseEid = find_respawn_base_for_team_with_type(team, respType, subtypes)
    query(baseEid) <| $ [es] (respTime : int = 0; maxVehicleOnSpawn : int = 0)
      var spawnFreq = respTime
      var maxSpawnVehiclesOnPoint = maxVehicleOnSpawn

      if count_vehicles_of_type(team, respType) < maxSpawnVehiclesOnPoint
        maxSpawnVehiclesOnPoint = -1

      for i in *squadIndices
        let firstSpawnAtTime = respawner__firstSpawnThresholdBySquad?[i] ?? 0
        let firstSpawnDelay = firstSpawnAtTime - curTimeSecond
        let isFirstSpawn = firstSpawnDelay > 0
        if isFirstSpawn
          spawnFreq = firstSpawnDelay

        let lastSpawnOnVehicleAtTime = isFirstSpawn ? curTimeSecond : respawner__lastSpawnTimeBySquad?[i] ?? 0
        let timeToSpawn = spawnFreq != 0 && lastSpawnOnVehicleAtTime > 0 ? lastSpawnOnVehicleAtTime + spawnFreq : -1

        respawner__vehiclesLimitBySquad[i] = maxSpawnVehiclesOnPoint
        respawner__nextSpawnOnVehicleTimeBySquad[i] = timeToSpawn

[es(tag=server, on_appear, track=(isArmiesReceived, respawner__respEndTime, respawner__respStartTime, respawner__canRespawnTime),
                           REQUIRE=(isArmiesReceived, respawner__respEndTime, respawner__respStartTime, respawner__canRespawnTime),
                           after=(vehicle_first_spawn_delay_init, respawner_init_squad_respawn_types))
]
def vehicles_spawn_enabler_es(evt : Event;
                              team : int;
                              squads__count : int;
                              respawner__vehicleSquadRespawnTypes : Array;
                              isArmiesReceived : bool;
                              respawner__firstSpawnThresholdBySquad : IntList;
                              respawner__lastSpawnTimeBySquad : IntList;
                              var respawner__nextSpawnOnVehicleTimeBySquad : IntList&;
                              var respawner__vehiclesLimitBySquad : IntList&)
  if isArmiesReceived
    update_vehicle_respawner(team, squads__count, respawner__vehicleSquadRespawnTypes, respawner__firstSpawnThresholdBySquad, respawner__lastSpawnTimeBySquad,
      respawner__nextSpawnOnVehicleTimeBySquad, respawner__vehiclesLimitBySquad)

[es(tag=server, on_appear, track=isAlive, REQUIRE=(vehicle, isAlive, vehicleSpawnRestriction, canUseRespawnbaseType))]
def vehicles_count_changed_es(evt : Event; team aka vehicle_team : int)
  query() <| $ [es] (team : int;
                     squads__count : int;
                     respawner__vehicleSquadRespawnTypes : Array;
                     isArmiesReceived : bool;
                     respawner__firstSpawnThresholdBySquad : IntList;
                     respawner__lastSpawnTimeBySquad : IntList;
                     var respawner__nextSpawnOnVehicleTimeBySquad : IntList&;
                     var respawner__vehiclesLimitBySquad : IntList&)
    if isArmiesReceived && team == vehicle_team
      update_vehicle_respawner(team, squads__count, respawner__vehicleSquadRespawnTypes, respawner__firstSpawnThresholdBySquad, respawner__lastSpawnTimeBySquad,
        respawner__nextSpawnOnVehicleTimeBySquad, respawner__vehiclesLimitBySquad)

def calc_first_spawn_delay(squad : Object const?; delay_by_type : Object)
  let vehicleTemplate = (squad?.curVehicle ?as Object)?.gametemplate ?? ""
  if empty(vehicleTemplate)
    return 0.0

  var templ = getTemplateByName(vehicleTemplate)
  if templ == null
    templ = buildTemplateByName(vehicleTemplate)
  if templ == null
    logerr("Template '{vehicleTemplate}' not found in templates")
    return 0.0

  let canUseRespawnbaseType := getTemplateComponent(*templ, "canUseRespawnbaseType") ?? ""
  return !empty(canUseRespawnbaseType) ? delay_by_type[canUseRespawnbaseType] ?? 0.0 : 0.0

[es(tag=server, track=isArmiesReceived)]
def respawner_init_squad_respawn_types(evt : Event;
                                       army : string;
                                       armies : Object;
                                       isArmiesReceived : bool;
                                       var respawner__vehicleSquadRespawnTypes : Array&)
  if !isArmiesReceived
    return
  assume armyData = armies[army] ?as Object
  assume squads = armyData?.squads ?as Array

  if squads == null
    return

  for respawn in values(gather_respawnbase_types(*squads))
    respawner__vehicleSquadRespawnTypes |> push_to_array() <| $(var obj : Object)
      obj |> set("respType", respawn.respType)
      obj |> set("subtypes", respawn.subtypes)
      obj |> set("squadIndices", respawn.squadIndices)

[es(tag=server, track=isArmiesReceived)]
def vehicle_first_spawn_delay_init(evt : Event;
                                   army : string;
                                   armies : Object;
                                   isArmiesReceived : bool;
                                   squads__firstSpawnDelayByType : Object;
                                   var respawner__firstSpawnThresholdBySquad : IntList&)
  if !isArmiesReceived
    return

  let disableVehicleSpawnDelay = find_query() <| $ [es(REQUIRE=disableVehicleSpawnDelay)] => true
  if disableVehicleSpawnDelay
    return

  var firstConnecitonTime = get_sync_time()
  query() <| $ [es] (firstPlayerConnectionTime : float)
    firstConnecitonTime = firstPlayerConnectionTime

  assume armyData = armies[army] ?as Object
  assume squads = armyData?.squads ?as Array
  if squads != null
    respawner__firstSpawnThresholdBySquad |> clear()
    for squad in *squads
      let firstSpawnTime = int(firstConnecitonTime + calc_first_spawn_delay(squad as Object, squads__firstSpawnDelayByType))
      respawner__firstSpawnThresholdBySquad |> push(firstSpawnTime)

[es(tag=server, on_appear)]
def register_last_vehicle_spawn_timer_for_squad(evt : Event; squad__id : int; squad__ownerPlayer : EntityId)
  query(squad__ownerPlayer) <| $ [es] (squads__count : int; var respawner__lastSpawnTimeBySquad : IntList&)
    respawner__lastSpawnTimeBySquad |> resize(squads__count)
    if squad__id >= 0 && squad__id < length(respawner__lastSpawnTimeBySquad)
      respawner__lastSpawnTimeBySquad[squad__id] = int(get_sync_time())
