options no_aot
require ecs
require ecs.ecs_template
require DagorConsole
require DagorDebug3D
require enlisted.events_enlisted
require player
require DngNet
require game.es.server_debug_common
require game.utils.team
require game.es.net_console_macro

[ecs_template]
struct capzone_debug_draw
  capzoneDebug : Tag

[console_cmd(name="capzone.debug")]
def capzone_debug()
  query() <| $ [es(REQUIRE=capzone, REQUIRE_NOT=capzoneDebug)] (eid : EntityId)
    addSubTemplate(eid, "capzone_debug_draw")
  query() <| $ [es(REQUIRE=(capzone, capzoneDebug))] (eid : EntityId)
    removeSubTemplate(eid, "capzone_debug_draw")

[es(no_order, REQUIRE=capzoneDebug)]
def draw_box_capzones(info : UpdateStageInfoRenderDebug;
                      active : bool;
                      transform : float3x4)
  if active
    let box = transform * BBox3(-float3(0.5), float3(0.5))
    draw_debug_box_buffered(box, E3DCOLOR(0xFF00FF00), 1)

[console_cmd(name="capzone.show_nearest_navmesh_pos")]
def show_nearest_navmesh_pos()
  query() <| $ [es] (transform : float3x4; capzone__hasNearestNavmeshPos : bool; capzone__nearestNavmeshPos : float3)
    if capzone__hasNearestNavmeshPos
      draw_debug_sphere_buffered(capzone__nearestNavmeshPos, 0.4f, E3DCOLOR(0xFFFFFFFF), 24, 3000)
    else
      draw_debug_sphere_buffered(transform[3], 10f, E3DCOLOR(0xFFFF0000), 24, 3000)

[console_cmd(name="capzone.show_min_radius")]
def show_min_radius()
  query() <| $ [es] (transform : float3x4; capzone__minRadius : float;
                     capzone__hasNearestNavmeshPos : bool; capzone__nearestNavmeshPos : float3)
    let pos = capzone__hasNearestNavmeshPos ? capzone__nearestNavmeshPos : transform[3]
    draw_debug_sphere_buffered(pos, capzone__minRadius, E3DCOLOR(0xFF00FF00), 24, 3000)


def capture_zones(capzone_eid : EntityId; team : int)
  if !capzone_eid
    find_query() <| $ [es(REQUIRE=capzone)] (eid : EntityId; active : bool; capzone__owningTeam : int)
      if active && capzone__owningTeam != team
        sendEvent(eid, [[EventForceCapture team=team]])
        return true
      return false
    return
  sendEvent(capzone_eid, [[EventForceCapture team=team]])

[net_console_cmd(name="capzone.forcecap_player")]
def debug_console_forcecap_player([[net_player]] player_eid : EntityId; capzone_eid = 0u)
  query(player_eid) <| $ [es] (team : int)
    capture_zones(EntityId(capzone_eid), team)

[console_cmd(name="capzone.forcecap_team")]
def debug_console_forcecap_team(team : int; capzone_eid = 0u)
  if is_server()
    capture_zones(EntityId(capzone_eid), team)
  else
    exec_server_cmd("capzone.forcecap_team {team} {capzone_eid}")

def is_near_any_zone(pos)
  return find_query() <| $ [es(REQUIRE=capzone)] (active : bool; transform : float3x4)
    return active && length_sq(transform[3] - pos) < 10000.0

def teleport_to_spawn(eid : EntityId; soldier_team : int)
  find_query() <| $ [es] (respawnbaseType : string; team : int; active : bool = true; transform : float3x4)
    if active && respawnbaseType == "human" && team == soldier_team
      let pos = transform[3]
      exec_server_cmd("phys.teleport {pos.x} {pos.y} {pos.z} {eid}")
      return true
    return false

def put_soldiers(pos : float3; team_to_add : int; count : int)
  var placed = 0
  find_query() <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (eid : EntityId; possessedByPlr : EntityId; isDowned : bool; team : int; transform : float3x4)
    if !possessedByPlr && !isDowned && team == team_to_add && !is_near_any_zone(transform[3])
      exec_server_cmd("phys.teleport {pos.x} {pos.y} {pos.z} {eid}")
      ++placed
    return placed == count

def remove_soldiers(pos : float3; remove_team : int)
  query() <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (eid : EntityId; possessedByPlr : EntityId; team : int; transform : float3x4)
    if (!possessedByPlr || has(possessedByPlr, "playerIsBot")) && (team == remove_team || remove_team == TEAM_UNASSIGNED) && length_sq(transform[3] - pos) < 10000.0
      teleport_to_spawn(eid, team)

[console_cmd(name="capzone.put_soldiers")]
def put_soldiers_in_zone(zone_title : string; team_to_add : int = 1; count : int = 1)
  find_query() <| $ [es] (capzone__title : string; active : bool; transform : float3x4)
    if !active || capzone__title != zone_title
      return false
    put_soldiers(transform[3], team_to_add, count)
    return true

[console_cmd(name="capzone.put_soldiers_index")]
def put_soldiers_in_zone(zone_index : int; team_to_add : int = 1; count : int = 1)
  find_query() <| $ [es] (ui_order : int; active : bool; transform : float3x4)
    if !active || (ui_order + 1) != zone_index
      return false
    put_soldiers(transform[3], team_to_add, count)
    return true

[console_cmd(name="capzone.remove_soldiers")]
def remove_soldiers_from_zone(zone_title : string; remove_team : int = TEAM_UNASSIGNED)
  find_query() <| $ [es] (active : bool; capzone__title : string; transform : float3x4)
    if !active || capzone__title != zone_title
      return false
    remove_soldiers(transform[3], remove_team)
    return true

[console_cmd(name="capzone.remove_soldiers_index")]
def remove_soldiers_from_zone(zone_index : int; remove_team : int = TEAM_UNASSIGNED)
  find_query() <| $ [es] (active : bool; ui_order : int; transform : float3x4)
    if !active || (ui_order + 1) != zone_index
      return false
    remove_soldiers(transform[3], remove_team)
    return true
