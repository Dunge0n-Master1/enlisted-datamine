require ecs
require game.es.events
require game.events_game
require common_shooter.events_common_shooter
require app
require math
require DaWeaponProps
require EnlistedDm
require strings
require game.es.stat_bq_common
require daslib/strings_boost
require matching

[event(unicast)]
struct CommitHumanStat {}

let
  BOT_OWNER = 0
  PLAYER_OWNER = 1

def get_weapon_name_with_shell(base_name : string; shell_id : int)
  var resName = ""
  if int(shell_id) >= 0
    shell_entity_get_props(shell_id) <| $(entProps : ShellEntityTypeProps)
      let templName = entProps.templName
      resName = "{base_name}_{templName}"
  return resName

def get_weapon_name_by_props_shell_id(human_weap__gunEids : EidList; human_weap__currentGunEid : EntityId; gun_props_id, shell_id : int)
  if gun_props_id == -1 && shell_id == -1
    return remove_sub_template_name(getEntityTemplateName(human_weap__currentGunEid), "attached_to_parent")

  for gun in human_weap__gunEids
    if get_int(gun, "gun__propsId") ?? -1 == gun_props_id
      let res = remove_sub_template_name(getEntityTemplateName(gun), "attached_to_parent")
      if gun |> has("grenade_thrower")
        return get_weapon_name_with_shell(res, shell_id)
      return res
  return ""

def try_inc_object_value(var map : Object?; field : string; delta : int = 1)
  if map != null
    let count = get_int(*map, field) ?? 0
    set(*map, field, count + delta)

def try_inc_object_value(var map : Object?; field : string; delta : float)
  if map != null
    let count = get_float(*map, field) ?? 0f
    set(*map, field, count + delta)

[es(tag=server)]
def human_stat_on_kill(evt : EventAnyEntityDied)
  query(evt.offender) <| $ [es] (isInVehicle : bool; human_anim__vehicleSelected : EntityId;
                                 human_weap__gunEids : EidList; human_weap__currentGunEid : EntityId;
                                 var human_stat_tracking__killsPerWeapon : Object?;
                                 var human_stat_tracking__inVehicleKillsPerWeapon : Object?;
                                 var human_stat_tracking__killsDistancePerWeapon : Object?;
                                 var human_stat_tracking__botsKillsPerWeapon : Object?;
                                 var human_stat_tracking__killsDistance, human_stat_tracking__maxKillsDistance : float&;
                                 var human_stat_tracking__killsCount, human_stat_tracking__botsKillsCount, human_stat_tracking__inVehicleKillsCount : int&)
    var dist = -1f
    let offenderTransform = get_TMatrix(!!human_anim__vehicleSelected ? human_anim__vehicleSelected : evt.offender, "transform")
    let victimTransform = get_TMatrix(evt.victim, "transform")
    if offenderTransform != null && victimTransform != null
      dist = distance((*offenderTransform)[3], (*victimTransform)[3])

    let botTarget = get_int(evt.victim, "human_stat_tracking__ownedBy") ?? -1 == BOT_OWNER
    if (human_stat_tracking__killsPerWeapon != null || human_stat_tracking__botsKillsPerWeapon != null
        || human_stat_tracking__killsDistancePerWeapon != null || human_stat_tracking__inVehicleKillsPerWeapon != null)
      let weaponName = get_weapon_name_by_props_shell_id(human_weap__gunEids, human_weap__currentGunEid, evt.gunPropsId, evt.shellId)
      if !empty(weaponName)
        if isInVehicle
          try_inc_object_value(human_stat_tracking__inVehicleKillsPerWeapon, weaponName)
        else
          try_inc_object_value(human_stat_tracking__killsPerWeapon, weaponName)
          if dist >= 0f
            try_inc_object_value(human_stat_tracking__killsDistancePerWeapon, weaponName, dist)
        if botTarget
          try_inc_object_value(human_stat_tracking__botsKillsPerWeapon, weaponName)

    if isInVehicle
      human_stat_tracking__inVehicleKillsCount++
    else
      human_stat_tracking__killsCount++
      if dist >= 0f
        human_stat_tracking__killsDistance += dist
        if dist > human_stat_tracking__maxKillsDistance
          human_stat_tracking__maxKillsDistance = dist

    if botTarget
      human_stat_tracking__botsKillsCount++

[es(tag=server)]
def human_stat_on_hit(evt : EventOnEntityHit)
  let damage = evt.damageType
  if damage != int(DamageType DM_COLLISION) && damage != int(DamageType DM_DISCONNECTED)
    query(evt.offender) <| $ [es] (isInVehicle : bool; human_weap__gunEids : EidList; human_weap__currentGunEid : EntityId;
                                   var human_stat_tracking__hitsPerWeapon : Object?;
                                   var human_stat_tracking__inVehicleHitsPerWeapon : Object?;
                                   var human_stat_tracking__botsHitsPerWeapon : Object?;
                                   var human_stat_tracking__hitsDistance : float&;
                                   var human_stat_tracking__hitsCount, human_stat_tracking__botsHitsCount, human_stat_tracking__inVehicleHitsCount : int&)
      let botTarget = get_int(evt.victim, "human_stat_tracking__ownedBy") ?? -1 == BOT_OWNER
      if human_stat_tracking__hitsPerWeapon != null || human_stat_tracking__botsHitsPerWeapon != null
        let weaponName = get_weapon_name_by_props_shell_id(human_weap__gunEids, human_weap__currentGunEid, evt.gunPropsId, evt.shellId)
        if !empty(weaponName)
          if isInVehicle
            try_inc_object_value(human_stat_tracking__inVehicleHitsPerWeapon, weaponName)
          else
            try_inc_object_value(human_stat_tracking__hitsPerWeapon, weaponName)
          if botTarget
            try_inc_object_value(human_stat_tracking__botsHitsPerWeapon, weaponName)

      if isInVehicle
        human_stat_tracking__inVehicleHitsCount ++
      else
        human_stat_tracking__hitsCount++
        let offenderTransform = get_TMatrix(evt.offender, "transform")
        let victimTransform = get_TMatrix(evt.victim, "transform")
        if offenderTransform != null && victimTransform != null
          human_stat_tracking__hitsDistance += distance((*offenderTransform)[3], (*victimTransform)[3])

      if botTarget
        human_stat_tracking__botsHitsCount++

[es(tag=server, no_order)]
def human_stat_on_shoot(info : UpdateStageInfoAct; human_weap__lastShotAtTime : float; isInVehicle : bool;
                        human_weap__currentGunEid : EntityId;
                        var human_stat_tracking__shotsPerWeapon : Object?;
                        var human_stat_tracking__inVehicleShotsPerWeapon : Object?;
                        var human_stat_tracking__prevShootAtTime : float&;
                        var human_stat_tracking__shotsCount, human_stat_tracking__inVehicleShotsCount : int&)
  if human_stat_tracking__prevShootAtTime != human_weap__lastShotAtTime
    human_stat_tracking__prevShootAtTime = human_weap__lastShotAtTime

    if (human_stat_tracking__shotsPerWeapon != null || human_stat_tracking__inVehicleShotsPerWeapon != null) && !!human_weap__currentGunEid
      let weaponName = remove_sub_template_name(getEntityTemplateName(human_weap__currentGunEid), "attached_to_parent")
      if !empty(weaponName)
        try_inc_object_value(human_stat_tracking__shotsPerWeapon, weaponName)
        if isInVehicle
          try_inc_object_value(human_stat_tracking__inVehicleShotsPerWeapon, weaponName)

    if isInVehicle
      human_stat_tracking__inVehicleShotsCount++
    else
      human_stat_tracking__shotsCount++

[es(tag=server, on_appear)]
def human_stat_create_track(evt : Event; var human_stat_tracking__ownedBy : int&;
                            var human_stat_tracking__spawnTime, human_stat_tracking__ownerTime : float&)
  human_stat_tracking__spawnTime = get_sync_time()
  human_stat_tracking__ownerTime = human_stat_tracking__spawnTime
  human_stat_tracking__ownedBy = BOT_OWNER

[es(tag=server, track=possessedByPlr, after=switch_ai_on_possess_unpossess)]
def human_stat_hero_change(evt : Event; eid : EntityId; possessedByPlr : EntityId; isAlive : bool; beh_tree__enabled : bool;
                           var human_stat_tracking__spawnTime, human_stat_tracking__ownerTime : float&;
                           var human_stat_tracking__ownedBy : int&)
  if !isAlive
    return
  let atTime = get_sync_time()
  let owner = possessedByPlr != INVALID_ENTITY_ID && !beh_tree__enabled ? PLAYER_OWNER : BOT_OWNER
  let justSpawned = atTime - human_stat_tracking__spawnTime < 1.0
  let shortBattleTime = atTime - human_stat_tracking__ownerTime < 1.0
  if human_stat_tracking__ownedBy != owner && !justSpawned && !shortBattleTime
    human_stat_tracking__spawnTime = -1.
    sendEventImmediate(eid, [[CommitHumanStat]])
  human_stat_tracking__ownedBy = owner
  human_stat_tracking__ownerTime = atTime

def update_weapon_use_time(human_weap__currentGunEid : EntityId;
                           human_stat_tracking__spawnTime : float;
                           var human_stat_tracking__lastWeaponName : das_string;
                           var human_stat_tracking__lastWeaponTime : float&;
                           var human_stat_tracking__battleTimePerWeapon : Object)
  var weaponName = remove_sub_template_name(getEntityTemplateName(human_weap__currentGunEid), "attached_to_parent")
  query(human_weap__currentGunEid) <| $ [es(REQUIRE=grenade_thrower)] (gun__curShellId : ShellPropIds)
    weaponName = get_weapon_name_with_shell(weaponName, int(gun__curShellId.shellId))
  let curTime = get_sync_time()
  human_stat_tracking__lastWeaponName |> peek() <| $(lastWeaponName)
    let battleTime = curTime - max(human_stat_tracking__lastWeaponTime, human_stat_tracking__spawnTime)
    if !empty(lastWeaponName) && battleTime > 0.
      let prevTime = human_stat_tracking__battleTimePerWeapon |> get_float(lastWeaponName) ?? 0f
      human_stat_tracking__battleTimePerWeapon |> set(lastWeaponName, prevTime + battleTime)
  human_stat_tracking__lastWeaponTime = curTime
  human_stat_tracking__lastWeaponName := weaponName

[es(tag=server, REQUIRE=(grenade_thrower, gun__curShellId), track=gun__curShellId)]
def track_grenade_type_use_time(evt : Event; gun__owner : EntityId)
  query(gun__owner) <| $ [es] (human_weap__currentGunEid : EntityId;
                               human_stat_tracking__spawnTime : float;
                               var human_stat_tracking__lastWeaponName : das_string;
                               var human_stat_tracking__lastWeaponTime : float&;
                               var human_stat_tracking__battleTimePerWeapon : Object)
    update_weapon_use_time(human_weap__currentGunEid, human_stat_tracking__spawnTime,
                           human_stat_tracking__lastWeaponName, human_stat_tracking__lastWeaponTime,
                           human_stat_tracking__battleTimePerWeapon)

[es(tag=server, on_appear)]
def weapon_use_time_on_create(evt : Event; gun__owner : EntityId)
  query(gun__owner) <| $ [es] (human_weap__currentGunEid : EntityId;
                               human_stat_tracking__spawnTime : float;
                               var human_stat_tracking__lastWeaponName : das_string;
                               var human_stat_tracking__lastWeaponTime : float&;
                               var human_stat_tracking__battleTimePerWeapon : Object)
    update_weapon_use_time(human_weap__currentGunEid, human_stat_tracking__spawnTime,
                           human_stat_tracking__lastWeaponName, human_stat_tracking__lastWeaponTime,
                           human_stat_tracking__battleTimePerWeapon)

[es(tag=server, on_appear, track=human_weap__currentGunEid)]
def track_weapon_use_time(evt : Event;
                          human_weap__currentGunEid : EntityId;
                          human_stat_tracking__spawnTime : float;
                          var human_stat_tracking__lastWeaponName : das_string;
                          var human_stat_tracking__lastWeaponTime : float&;
                          var human_stat_tracking__battleTimePerWeapon : Object)
  update_weapon_use_time(human_weap__currentGunEid, human_stat_tracking__spawnTime,
                         human_stat_tracking__lastWeaponName, human_stat_tracking__lastWeaponTime,
                         human_stat_tracking__battleTimePerWeapon)

[es(tag=server, on_event=CommitHumanStat, on_event=EventEntityDied)]
def human_stat_died_track(evt : Event; eid, possessedByPlr : EntityId; team : int; isAlive : bool;
                          human_stat_tracking__spawnTime : float;
                          human_stat_tracking__ownerTime : float;
                          human_stat_tracking__ownedBy : int;
                          var human_stat_tracking__targetTracesCount : int&;
                          var human_stat_tracking__killsCount : int&;
                          var human_stat_tracking__botsKillsCount : int&;
                          var human_stat_tracking__inVehicleKillsCount : int&;
                          var human_stat_tracking__hitsCount : int&;
                          var human_stat_tracking__inVehicleHitsCount : int&;
                          var human_stat_tracking__killsPerWeapon : Object?;
                          var human_stat_tracking__inVehicleKillsPerWeapon : Object?;
                          var human_stat_tracking__killsDistancePerWeapon : Object?;
                          var human_stat_tracking__botsKillsPerWeapon : Object?;
                          var human_stat_tracking__hitsPerWeapon : Object?;
                          var human_stat_tracking__inVehicleHitsPerWeapon : Object?;
                          var human_stat_tracking__botsHitsPerWeapon : Object?;
                          var human_stat_tracking__shotsPerWeapon : Object?;
                          var human_stat_tracking__inVehicleShotsPerWeapon : Object?;
                          var human_stat_tracking__battleTimePerWeapon : Object?;
                          var human_stat_tracking__lastWeaponName : das_string?;
                          var human_stat_tracking__shotsCount : int&;
                          var human_stat_tracking__botsHitsCount : int&;
                          var human_stat_tracking__inVehicleShotsCount : int&;
                          var human_stat_tracking__maxKillsDistance : float&;
                          var human_stat_tracking__killsDistance : float&;
                          var human_stat_tracking__hitsDistance : float&;
                          var human_stat_tracking__totalDangers : float&;
                          soldier__sClass : string = "")
  let curTime = get_sync_time()
  let liveTime = human_stat_tracking__spawnTime < 0. ? -1. : curTime - human_stat_tracking__spawnTime
  let battleTime = curTime - human_stat_tracking__ownerTime
  let name = human_stat_tracking__ownedBy == PLAYER_OWNER ? "human" : "bot"
  let offenderType = human_stat_tracking__ownedBy == PLAYER_OWNER ? "human" : "human_bot"
  var userId = get_uint64(possessedByPlr, "userid") ?? uint64(0)
  if userId == INVALID_USER_ID
    userId = uint64(0)
  // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
  send_event_bq_with_header("unit_stat") <| $(var jw : JsonWriter)
    add_user_id(jw, userId)
    jw_key_value(jw, "offender_type", offenderType)
    jw_key_value(jw, "live_time", liveTime)
    jw_key_value(jw, "battle_time", battleTime)
    jw_key_value(jw, "shots", human_stat_tracking__shotsCount)
    jw_key_value(jw, "hits", human_stat_tracking__hitsCount)
    jw_key_value(jw, "kills", human_stat_tracking__killsCount)
    jw_key_value(jw, "hits_bots", human_stat_tracking__botsHitsCount)
    jw_key_value(jw, "kills_bots", human_stat_tracking__botsKillsCount)
    jw_key_value(jw, "shots_in_vehicle", human_stat_tracking__inVehicleShotsCount)
    jw_key_value(jw, "hits_in_vehicle", human_stat_tracking__inVehicleHitsCount)
    jw_key_value(jw, "kills_in_vehicle", human_stat_tracking__inVehicleKillsCount)
    jw_key_value(jw, "traces", human_stat_tracking__targetTracesCount)
    jw_key_value(jw, "distance", human_stat_tracking__hitsDistance)
    jw_key_value(jw, "kill_distance", human_stat_tracking__killsDistance)
    jw_key_value(jw, "max_kill_distance", human_stat_tracking__maxKillsDistance)
    if !empty(soldier__sClass)
      jw_key_value(jw, "soldier_class", soldier__sClass)

  print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} live time {liveTime} battle time {battleTime}"
      + " Traces {human_stat_tracking__targetTracesCount} Kills {human_stat_tracking__killsCount} Hits {human_stat_tracking__hitsCount}"
      + " Shots {human_stat_tracking__shotsCount} HDistance {human_stat_tracking__hitsDistance}"
      + " KDistance {human_stat_tracking__killsDistance} MaxKDistance {human_stat_tracking__maxKillsDistance}"
      + " TotalDangers {human_stat_tracking__totalDangers} VehicleShots {human_stat_tracking__inVehicleShotsCount} VehicleHits {human_stat_tracking__inVehicleHitsCount}"
      + " VehicleKills {human_stat_tracking__inVehicleKillsCount} BotsHits {human_stat_tracking__botsHitsCount} BotsKills {human_stat_tracking__botsKillsCount}")

  if (human_stat_tracking__shotsPerWeapon != null && human_stat_tracking__hitsPerWeapon != null && human_stat_tracking__killsPerWeapon != null
      && human_stat_tracking__killsDistancePerWeapon != null && human_stat_tracking__inVehicleKillsPerWeapon != null
      && human_stat_tracking__inVehicleHitsPerWeapon != null && human_stat_tracking__inVehicleShotsPerWeapon != null
      && human_stat_tracking__botsHitsPerWeapon != null && human_stat_tracking__botsKillsPerWeapon != null && human_stat_tracking__battleTimePerWeapon != null)
    for it in *human_stat_tracking__battleTimePerWeapon
      let key = it.key
      let weaponBattleTime = get_float(it.value) ?? 0f
      print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} weapon battle time {it.key} {weaponBattleTime}")
      var shots = 0
      var hits = 0
      var inVehicleHits = 0
      var botsHits = 0
      var kills = 0
      var inVehicleKills = 0
      var botsKills = 0
      var killsDistance = 0f
      var shotsInVehicle = 0

      for shotData in *human_stat_tracking__shotsPerWeapon
        if shotData.key == key
          shots = get_int(shotData.value) ?? 0
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} shot per weapon {key} {shots}")

      for hitData in *human_stat_tracking__inVehicleShotsPerWeapon
        if hitData.key == key
          shotsInVehicle = get_int(hitData.value) ?? 0
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} in vehicle shot per weapon {key} {shotsInVehicle}")

      for hitData in *human_stat_tracking__hitsPerWeapon
        if hitData.key == key
          hits = get_int(hitData.value) ?? 0
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} hit per weapon {key} {hits}")

      for hitData in *human_stat_tracking__inVehicleHitsPerWeapon
        if hitData.key == key
          inVehicleHits = get_int(hitData.value) ?? 0
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} in vehicle hit per weapon {key} {inVehicleHits}")

      for hitData in *human_stat_tracking__botsHitsPerWeapon
        if hitData.key == key
          botsHits = get_int(hitData.value) ?? 0
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} bots hit per weapon {key} {botsHits}")

      for killData in *human_stat_tracking__killsPerWeapon
        if killData.key == key
          kills = get_int(killData.value) ?? 0
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} kill per weapon {it.key} {kills}")

      for killData in *human_stat_tracking__inVehicleKillsPerWeapon
        if killData.key == key
          inVehicleKills = get_int(killData.value) ?? 0
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} in vehicle kill per weapon {it.key} {inVehicleKills}")

      for killDistanceData in *human_stat_tracking__killsDistancePerWeapon
        if killDistanceData.key == key
          killsDistance = get_float(killDistanceData.value) ?? 0f
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} kills distance per weapon {it.key} {killsDistance / float(kills)}")

      for killData in *human_stat_tracking__botsKillsPerWeapon
        if killData.key == key
          botsKills = get_int(killData.value) ?? 0
          print("human stat: {int(uint(eid))} {getEntityTemplateName(eid)} {name} team {team} bots kill per weapon {it.key} {kills}")

      // CHANGES TO THIS SCHEME SHOULD BE REFLECTED IN BQ TABLE (ask devops if you don't know what it means)
      send_event_bq_with_header("unit_weapon_stat") <| $(var jw : JsonWriter)
        add_user_id(jw, userId)
        jw_key_value(jw, "offender_type", offenderType)
        jw_key_value(jw, "weapon_template", key)
        jw_key_value(jw, "shots", shots - shotsInVehicle) // because we store all shots in shotsPerWeapon to get actual weapons list
        jw_key_value(jw, "hits", hits)
        jw_key_value(jw, "hits_bots", botsHits)
        jw_key_value(jw, "kills", kills)
        jw_key_value(jw, "kills_bots", botsKills)
        jw_key_value(jw, "kill_distance", killsDistance)
        jw_key_value(jw, "shots_in_vehicle", shotsInVehicle)
        jw_key_value(jw, "kills_in_vehicle", inVehicleKills)
        jw_key_value(jw, "hits_in_vehicle", inVehicleHits)
        jw_key_value(jw, "battle_time", weaponBattleTime)
        if !empty(soldier__sClass)
          jw_key_value(jw, "soldier_class", soldier__sClass)

    if isAlive
      clear(*human_stat_tracking__shotsPerWeapon)
      clear(*human_stat_tracking__inVehicleShotsPerWeapon)
      clear(*human_stat_tracking__hitsPerWeapon)
      clear(*human_stat_tracking__inVehicleHitsPerWeapon)
      clear(*human_stat_tracking__botsHitsPerWeapon)
      clear(*human_stat_tracking__killsPerWeapon)
      clear(*human_stat_tracking__inVehicleKillsPerWeapon)
      clear(*human_stat_tracking__killsDistancePerWeapon)
      clear(*human_stat_tracking__botsKillsPerWeapon)
      clear(*human_stat_tracking__battleTimePerWeapon)
      if human_stat_tracking__lastWeaponName != null
        *human_stat_tracking__lastWeaponName := ""
  if isAlive
    human_stat_tracking__targetTracesCount = 0
    human_stat_tracking__killsCount = 0
    human_stat_tracking__botsKillsCount = 0
    human_stat_tracking__inVehicleKillsCount = 0
    human_stat_tracking__hitsCount = 0
    human_stat_tracking__botsHitsCount = 0
    human_stat_tracking__inVehicleHitsCount = 0
    human_stat_tracking__shotsCount = 0
    human_stat_tracking__inVehicleShotsCount = 0
    human_stat_tracking__killsDistance = 0f
    human_stat_tracking__maxKillsDistance = 0f
    human_stat_tracking__hitsDistance = 0f
    human_stat_tracking__totalDangers = 0f
