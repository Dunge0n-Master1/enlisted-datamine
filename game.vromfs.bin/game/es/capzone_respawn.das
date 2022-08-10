require ecs
require app
require game.utils.team
require enlisted.events_enlisted
require DagorSystem

def get_first_spawn_time()
  var res = -1.
  query() <| $ [es] (firstPlayerSpawnTime : float)
    res = firstPlayerSpawnTime
  return res

def create_respawn_base(templ : string; transform : float3x4; group_name : string; team : int)
  return createEntity(templ) <| $(var init : ComponentsInitializer)
    init |> set("active", true)
    init |> set("transform", transform)
    init |> set("groupName", group_name)
    init |> set("team", team)

def create_respawn_base_group_activator(templ : string; group_name : string; groupId : int; team : int)
  return createEntity(templ) <| $(var init : ComponentsInitializer)
    init |> set("respawn_activator__active", true)
    init |> set("respawn_activator__groupId", groupId)
    init |> set("respawn_activator__groupName", group_name)
    init |> set("respawn_activator__team", team)

def start_respawn_timout_timer(respawn_base : EntityId; timeout : float)
  addSubTemplate(respawn_base, "respawn_base_timeout") <| $(var init : ComponentsInitializer)
    init |> set("respawn_base_timeout__destroyTime", get_sync_time() + timeout)


[es(tag=server, no_order)]
def respawn_base_timeout(info : UpdateStageInfoAct; eid : EntityId; respawn_base_timeout__destroyTime : float)
  if info.curTime > respawn_base_timeout__destroyTime
    destroyEntity(eid)

[es(tag=server, on_appear, track=active)]
def capzone_create_respbase(evt : Event;
                            active : bool;
                            transform : float3x4;
                            groupName : string;
                            capzone__createRespawnBase : string;
                            capzone__createRespawnBaseForTeam : int;
                            capzone__spawnAtZoneTimeout : float;
                            capzone__createdRespawnBaseGroup : int;
                            var capzone__respawnBaseEid : EntityId&)
  if !active || capzone__spawnAtZoneTimeout <= 0.
    return
  let templName = capzone__createRespawnBase
  let team = capzone__createRespawnBaseForTeam
  if team == TEAM_UNASSIGNED
    logerr("capzone__createRespawnBaseForTeam must be set in the mission. Or capzone__spawnAtZoneTimeout must be removed.")
    return
  if capzone__respawnBaseEid != INVALID_ENTITY_ID
    destroyEntity(capzone__respawnBaseEid)
  let respawnBaseGroupId = capzone__createdRespawnBaseGroup
  capzone__respawnBaseEid = (respawnBaseGroupId < 0
    ? create_respawn_base(add_sub_template_name(templName, "temporary_respawn_base"), transform, groupName, team)
    : create_respawn_base_group_activator(templName, groupName, respawnBaseGroupId, team))
  let startTime = get_first_spawn_time()
  if startTime >= 0.
    let timerTime = max(capzone__spawnAtZoneTimeout, startTime + capzone__spawnAtZoneTimeout - get_sync_time())
    start_respawn_timout_timer(capzone__respawnBaseEid, timerTime)

[es(tag=server)]
def capzone_respbase_destruction_timer_after_first_spawn(evt : EventFirstPlayerSpawned;
                                                         active : bool;
                                                         capzone__spawnAtZoneTimeout : float;
                                                         capzone__respawnBaseEid : EntityId)
  if active && capzone__spawnAtZoneTimeout > 0.
    start_respawn_timout_timer(capzone__respawnBaseEid, capzone__spawnAtZoneTimeout)

[es(tag=server)]
def capzone_respbase_after_capture(evt : EventZoneIsAboutToBeCaptured)
  query(evt.zone) <| $ [es] (transform : float3x4;
                             groupName : string;
                             capzone__createRespawnBase : string;
                             capzone__createdRespawnBaseGroup : int;
                             capzone__createRespawnBaseForAttackTeam : bool = false;
                             var capzone__respawnBaseEid : EntityId&)
    let capTeam = evt.team
    if capzone__respawnBaseEid != INVALID_ENTITY_ID
      destroyEntity(capzone__respawnBaseEid)
    if capzone__createRespawnBaseForAttackTeam
      let respawnBaseGroupId = capzone__createdRespawnBaseGroup
      let templName = capzone__createRespawnBase
      capzone__respawnBaseEid = (respawnBaseGroupId < 0
        ? create_respawn_base(templName, transform, groupName, capTeam)
        : create_respawn_base_group_activator(templName, groupName, respawnBaseGroupId, capTeam))
