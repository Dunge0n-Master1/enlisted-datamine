options no_aot
require ecs
require math
require math.base
require game.utils.hero
require game.es.events
require Gun
require Dacoll
require AnimV20
require GeomNodeTree
require Grid
require GridCollision
require DagorDebug3D
require DagorMath
require DagorConsole
require common_shooter.events_common_shooter


def draw_cylinder(start, dir : float3; len, radius : float; num_lines : int; color : E3DCOLOR; frames : int)
  var transform : float3x4
  identity(transform)
  transform[0] = dir
  if abs(dir.y) > 0.707 // more than 45 degrees up/down, choose another basis
    transform[2] = normalize(cross(dir, float3(1, 0, 0)))
  else
    transform[2] = normalize(cross(dir, float3(0, 1, 0)))

  transform[1] = normalize(cross(dir, transform[2]))
  let invNumCasts = safeinv(float(num_lines))
  for i in 0 .. num_lines
    let from = start + rotate(transform, float3(0., cos(TWOPI * invNumCasts * float(i)), sin(TWOPI * invNumCasts * float(i)))) * radius
    draw_debug_line_buffered(from, from + dir * len, color, frames)

def draw_debug_flame(gloc : GunLocation; start_offset, distance, radius, cloud_offset, cloud_radius : float)
  if gloc.gunPos == null
    return
  let gunPos = *(gloc.gunPos)
  let gunDir = gloc.gunDir
  let end = gunPos + gunDir * distance
  let start = gunPos + gunDir * start_offset
  let humanRadius = 0.4

  if (distance_sq(end, start) > 0.0)
    draw_debug_line_buffered(start, end, E3DCOLOR(0xFF00FF00), 1)
    draw_cylinder(start, gunDir, distance, radius, 10, E3DCOLOR(0xFF00FF00), 1)

  let fireLen = max(0.0, distance - cloud_radius)
  let fireCloudStart = start + gunDir * cloud_offset
  let fireCloudEnd = start + gunDir * fireLen
  draw_debug_capsule_buffered(fireCloudStart, fireCloudEnd, cloud_radius, E3DCOLOR(0xFF00FF00), 8, 1)

  for_each_entity_in_grid(ecs_hash("humans"), fireCloudStart, gunDir, fireLen, cloud_radius, GridEntCheck BOUNDING) <| $(humanEid : EntityId)
    query(humanEid) <| $ [es(REQUIRE=human)] (animchar : AnimcharBaseComponent;
                                              transform : float3x4;
                                              human_use_object__nodeId : int)
      let headPos = geomtree_getNodeWpos(*animchar.nodeTree, human_use_object__nodeId)
      let lowestPos = transform[3]
      draw_debug_capsule_buffered(lowestPos, headPos, humanRadius, E3DCOLOR(0xFFFFFFFF), 8, 1)

[es(tag=(gameClient, dev))]
def flamethrower_debug_phys(evt : CmdWeapPhysUpdate;
                            gun__ammo : int;
                            flamethrower__flameCurrentLength : float;
                            flamethrower__debug : bool;
                            flamethrower__flameStartOffset : float;
                            flamethrower__cloudStartOffset : float;
                            flamethrower__flameStreamRadius : float;
                            flamethrower__flameCloudRadius : float)
  if !flamethrower__debug || !evt.isForReal
    return

  if gun__ammo != 0 && evt.gctrl.shoot
    draw_debug_flame(evt.gloc, flamethrower__flameStartOffset, flamethrower__flameCurrentLength,
                     flamethrower__flameStreamRadius, flamethrower__cloudStartOffset, flamethrower__flameCloudRadius)

[es(tag=(gameClient, dev))]
def flamethrower_debug_turret_phys(evt : CmdGunUpdate;
                                   gun__ammo : int;
                                   flamethrower__flameCurrentLength : float;
                                   flamethrower__debug : bool;
                                   flamethrower__flameStartOffset : float;
                                   flamethrower__cloudStartOffset : float;
                                   flamethrower__flameStreamRadius : float;
                                   flamethrower__flameCloudRadius : float)
  if !flamethrower__debug || !evt.isForReal
    return

  if gun__ammo != 0 && evt.gctrl.shoot
    draw_debug_flame(evt.gloc, flamethrower__flameStartOffset, flamethrower__flameCurrentLength,
                     flamethrower__flameStreamRadius, flamethrower__cloudStartOffset, flamethrower__flameCloudRadius)

[console_cmd(name="flameThrower.debug")]
def switch_flamethrower_debug()
  let hero = get_controlled_hero()
  query() <| $ [es] (gun__owner : EntityId; var flamethrower__debug : bool&)
    if gun__owner == hero
      flamethrower__debug = !flamethrower__debug
  query() <| $ [es(REQUIRE=flamethrower__fireTemplate, REQUIRE_NOT=flamethrower__debug)] (eid : EntityId; gun__owner : EntityId)
    if gun__owner == hero
      addSubTemplate(eid, "flamethrower_debug")
