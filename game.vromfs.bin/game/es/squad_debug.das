options no_aot
require ecs
require ecs.common
require player
require game.utils.hero
require game.es.stat_bq_common
require DngDm
require game.events_game
require enlisted.events_enlisted
require DagorConsole
require DagorMath
require Dacoll
require enlisted.game.es.enlisted_squad_common
require DngNet
require game.es.server_debug_common
require game.es.net_console_macro


def get_squad_eid(squad = 0u; eid = 0u)
  var squadEid = EntityId(squad)
  if squadEid == INVALID_ENTITY_ID
    let heroEid = get_controlled_hero_eid(eid)
    squadEid = get_Eid(heroEid, "squad_member__squad") ?? INVALID_ENTITY_ID
  return squadEid


[console_cmd(name="squad.info", hint="Displays information about all soldiers in given hero's squad")]
def squad_info_debug(hero_eid = 0u)
  console_print(" ")
  let heroEid = get_controlled_hero_eid(hero_eid)
  console_print("SQUAD of hero_eid={heroEid}")
  let squadEid = get_squad_eid(0u, hero_eid)
  query() <| $ [es] (eid : EntityId; squad_member__squad : EntityId; isAlive : bool; squad_member__memberIdx : int; isInVehicle : bool; name : string; surname : string)
    if squad_member__squad == squadEid
      console_print("squad member: eid={eid} isAlive={isAlive} isInVehicle={isInVehicle} index={squad_member__memberIdx} name={name} {surname}")
  console_print(" ")

[net_console_cmd(name="squad.suicide")]
def squad_suicide_debug([[net_hero]] hero_eid : EntityId)
  let squadEid = get_Eid(hero_eid, "squad_member__squad") ?? INVALID_ENTITY_ID
  kill_squad(squadEid)

[net_console_cmd(name="squad.kill")]
def squad_kill_debug(index : int; [[net_hero]] hero_eid : EntityId)
  let squadEid = get_Eid(hero_eid, "squad_member__squad") ?? INVALID_ENTITY_ID
  query(squadEid) <| $ [es] (squad__allMembers : EidList)
    if uint(index) < uint(length(squad__allMembers))
      suicide_kill(squad__allMembers[index])


def suicideBots(squad_eid : EntityId)
  let squadLeaderEid = get_squad_leader(squad_eid)
  kill_squad(squad_eid) <| $(memberEid)
    return squadLeaderEid != memberEid

[net_console_cmd(name="squad.suicide_bots")]
def squad_suicide_bots_debug([[net_hero]] hero_eid : EntityId)
  let squadEid = get_Eid(hero_eid, "squad_member__squad") ?? INVALID_ENTITY_ID
  suicideBots(squadEid)

[net_console_cmd(name="squad.changeTeam")]
def squad_change_team([[net_player]] playerEid : EntityId)
  let possessed = get_Eid(playerEid, "possessed") ?? INVALID_ENTITY_ID
  let squadEid = get_Eid(possessed, "squad_member__squad") ?? INVALID_ENTITY_ID
  let team = get_int(playerEid, "team") ?? 1
  let newTeam = team == 1 ? 2 : 1

  kill_squad(squadEid)
  broadcastEvent([[EventTeamMemberLeave eid=playerEid, team = team]])
  broadcastEvent([[EventTeamMemberJoined eid=playerEid, team = newTeam]])
  set(playerEid, "team", newTeam)
  set(playerEid, "armiesReceivedTeam", newTeam)
  sendEvent(playerEid, [[CmdSpawnSquad team=newTeam, possessed=possessed, squadId=0, memberId=0, respawnGroupId=-1, existedVehicleEid=INVALID_ENTITY_ID]])

def spawn_soldiers_at_pos(pos : float3; count, team : int; spawn_template : string; cell_size : float)
  query() <| $ [es(REQUIRE=devSoldier)] (eid : EntityId) { destroyEntity(eid); }
  var offset = float3(0.f, 0.f, 0.f)
  for _j in range(0, count)
    for _i in range(0, count)
      createEntity(spawn_template) <| $(var init : ComponentsInitializer)
        var tm : float3x4
        tm[0] = float3(1., 0., 0.)
        tm[1] = float3(0., 1., 0.)
        tm[2] = float3(0., 0., 1.)
        tm[3] = pos + offset - float3(float(count) * 0.5f, 0.f, float(count) * 0.5f)
        set(init, "transform", tm)
        set(init, "team", team)
        set(init, "spawn_immunity__timer", 0.f)

        offset += float3(0.f, 0.f, cell_size)
    offset += float3(cell_size, 0.f, 0.f)
    offset.z = 0.f

[console_cmd(name="squad.spawnMoreSoldiers")]
def squad_spawnMoreSoldiers(count = 7; isAlive = true; team = 0; cellSize = 1.f)
  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    var tm : float3x4
    if !camera__active
      return false
    var len = 100.0
    var norm = float3()
    tm = transform
    let dir = tm[2]
    let pos = tm[3]
    traceray_normalized(pos, dir, len, norm)
    let center = pos + dir * len
    if is_server()
      spawn_soldiers_at_pos(center, count, team, isAlive ? "dev_soldier+dev_soldier_tag" : "dead_dev_soldier+dev_soldier_tag", cellSize)
    else
      exec_server_cmd("squad.spawnMoreSoldiersPos {count} {center[0]} {center[1]} {center[2]} {isAlive}")
    return true

[console_cmd(name="squad.spawnMoreSoldiersPos")]
def squad_spawnMoreSoldiers(count = 7; x, y, z : float = 0.f; isAlive = true; team = 0; cellSize = 1.f)
  if is_server()
    spawn_soldiers_at_pos(float3(x, y, z), count, team, isAlive ? "dev_soldier+dev_soldier_tag" : "dead_dev_soldier+dev_soldier_tag", cellSize)
  else
    exec_server_cmd("squad.spawnMoreSoldiersPos {count} {x} {y} {z} {isAlive}")


def spawnSquadById(squadId : string; squadForUserid : uint64; memberId : int)
  print("spawnSquadById '{squadId}' for '{int(squadForUserid)}'")
  find_query() <| $ [es] (eid : EntityId; armies : Object; userid : uint64; team : int; var shouldValidateSpawnRules : bool&)
    if squadForUserid != uint64(0) && userid != squadForUserid
      return false

    for armyData in armies
      let squadsPtr = get_ecs_array(*get_ecs_object(armyData.value), "squads")
      assume squads = *squadsPtr
      for squad, squadNo in squads, range(length(squads))
        let id = get_string(get_ecs_object(squad), "squadId", "")
        if id == squadId
          query(eid) <| $ [es] (var army : das_string)
            army := armyData.key

          shouldValidateSpawnRules = false

          kill_squad(get_squad_eid(0u, 0u))

          sendEvent(eid, [[CmdSpawnSquad team=team, possessed=INVALID_ENTITY_ID, squadId=squadNo, memberId=memberId, respawnGroupId=-1, existedVehicleEid=INVALID_ENTITY_ID]])

          return true

    print("Squad with squadId '{squadId}' not found!")

    return true

[console_cmd(name="squad.spawn")]
def squad_debug_spawn(squadId : string; userid : int = 0; memberId : int = 0)
  spawnSquadById(squadId, uint64(userid), memberId)