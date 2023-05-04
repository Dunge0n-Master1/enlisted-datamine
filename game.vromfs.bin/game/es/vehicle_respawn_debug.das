options no_aot
require ecs
require ecs.ecs_template
require game.utils.team
require DagorConsole
require DagorDebug3D


[ecs_template]
struct respbase_debug
  respbase_debug : Tag

[ecs_template]
struct respbase_only_active_debug
  respbase_only_active_debug : Tag

[console_cmd(name="respbase.respbase_debug", hint="Draw respawn bases for humans and vehicles")]
def respbase_debug_command(toggle : int = -1)
  var found = false
  query() <| $ [es(REQUIRE=respbase_debug)] (eid : EntityId)
    destroyEntity(eid)
    found = true
  if (!found && toggle < 0) || toggle >= 1
    createEntity("respbase_debug")


[console_cmd(name="respbase.respbase_only_active_debug", hint="Draw active respawn bases for humans and vehicles")]
def respbase_only_active_debug_command(toggle : int = -1)
  var found = false
  query() <| $ [es(REQUIRE=respbase_only_active_debug)] (eid : EntityId)
    destroyEntity(eid)
    found = true
  if (!found && toggle < 0) || toggle >= 1
    createEntity("respbase_only_active_debug")


def draw_debug_respawn_info(transform : float3x4;
                            message : string;
                            team : int;
                            active : bool;
                            radius : float)
  var color = active ? E3DCOLOR(0xFFDDDDDD) : E3DCOLOR(0xFF555555)
  if team == 1
    color = active ? E3DCOLOR(0xFF2222FF) : E3DCOLOR(0xFF000055)
  elif team == 2
    color = active ? E3DCOLOR(0xFFFF2222) : E3DCOLOR(0xFF550000)

  begin_draw_cached_debug_lines(false, false, false)

  draw_cached_debug_sphere(transform[3], radius, color, 24)
  add_debug_text_mark(transform[3], message, -1, 0., E3DCOLOR(0x00000000))

  end_draw_cached_debug_lines()


def draw_debug_respbase_infos(only_active : bool)
  query() <| $ [es(REQUIRE=respbase)] (transform : float3x4;
                                       active : bool;
                                       team = TEAM_UNASSIGNED;
                                       respawnbaseType = "";
                                       groupName = "";
                                       respawnBaseGroup = -1;
                                       vehicleRespbase : Tag const?)
    if active || !only_active
      let message = "{active ? "+" : "-"} {respawnbaseType}({team}) {groupName} #{respawnBaseGroup}"
      let radius = vehicleRespbase == null ? 1. : 2.
      draw_debug_respawn_info(transform, message, team, active, radius)


[es(no_order, REQUIRE=respbase_debug)]
def respawn_draw_debug_es(evt : UpdateStageInfoRenderDebug)
  draw_debug_respbase_infos(false)


[es(no_order, REQUIRE=respbase_only_active_debug, REQUIRE_NOT=respbase_debug)]
def respawn_draw_only_active_debug_es(evt : UpdateStageInfoRenderDebug)
  draw_debug_respbase_infos(true)
