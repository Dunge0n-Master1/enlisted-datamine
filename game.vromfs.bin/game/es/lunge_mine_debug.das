options no_aot
require ecs
require DagorMath
require game.events_game
require danetlibs.render_debug.main.net_draw_debug_common
require ecs.ecs_template
require game.es.net_console_macro

[ecs_template]
struct lunge_mine_debug
  lunge_mine_debug : Tag

[net_console_cmd(name="lunge_mine.debug", hint="Show lung mine hit position")]
def lunge_mine_debug_cmd()
  let exist = find_query() <| $ [es(REQUIRE=lunge_mine_debug)] (eid : EntityId)
    destroyEntity(eid)
    return true
  if !exist
    createEntity("lunge_mine_debug")
  console_print("Lunge mine debug {exist ? "disabled" : "enabled"}")

[es(tag=dev)]
def lunge_mine_hit_ri_debug_es(evt : CmdRendinstDamage; human_weap__currentGunEid : EntityId)
  query() <| $ [es(REQUIRE=lunge_mine_debug)] ()
    query(human_weap__currentGunEid) <| $ [es(REQUIRE=lunge_mine)] (lunge_mine__active : bool)
      if lunge_mine__active
        net_draw_debug_sphere_buffered(evt.pos, 0.2, E3DCOLOR(0xFF00FF00), 24, 5000)

[es(tag=dev)]
def lunge_mine_hit_target_debug_es(evt : EventMeleeAttackHit; human_weap__currentGunEid : EntityId)
  query() <| $ [es(REQUIRE=lunge_mine_debug)] ()
    query(human_weap__currentGunEid) <| $ [es(REQUIRE=lunge_mine)] (lunge_mine__active : bool)
      if lunge_mine__active
        net_draw_debug_sphere_buffered(evt.pos, 0.2, E3DCOLOR(0xFF00FF00), 24, 5000)

