options no_aot
require ecs
require ecs.ecs_template
require Gun
require DagorDebug3D
require DagorConsole


[ecs_template]
struct gun_spread_debug_draw
  gunSpreadDebug : Tag


[console_cmd(name="gun.debug_spread", hint="Draw cone for hero's gun where bullets can go")]
def gun_spread_debug()
  var exists = false
  query() <| $ [es(REQUIRE=gunSpreadDebug)] (eid : EntityId)
    destroyEntity(eid)
    exists = true
  if !exists
    createEntity("gun_spread_debug_draw")


[es(no_order, REQUIRE=gunSpreadDebug)]
def draw_gun_spread(evt : UpdateStageInfoRenderDebug)
  query() <| $ [es(REQUIRE=hero)] (human_weap__currentGunEid : EntityId)
    query(human_weap__currentGunEid) <| $ [es] (gun : Gun&)
      let spreadConusLength = 100.0
      let projectileSpread = gun_calcSpread(gun).x // currently in Enlisted x and y spread is the same for all weapons
      draw_debug_cone_buffered(gun.gunTm[3], gun.gunTm[3] + gun.gunTm[0] * spreadConusLength,
                               projectileSpread, E3DCOLOR(0xFFFFFFFF), 16, 1)
