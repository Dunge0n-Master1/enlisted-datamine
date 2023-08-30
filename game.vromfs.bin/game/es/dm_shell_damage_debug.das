options no_aot
require ecs
require DagorMath
require game.es.events
require DagorDebug3D
require DagorConsole
require app

[console_cmd(name="shell.clear_debug_info")]
def shell_clear_debug_info()
  query() <| $ [es(REQUIRE=shellDamageDebugInfo)] (eid : EntityId)
    destroyEntity(eid)


[es(tag=(dev, render))]
def debug_shell_explosion_received(evt : EventShellExplosionDebug)
  createEntity("shell_damage_explosion_info_debug") <| $(var init : ComponentsInitializer)
    set(init, "shell_damage_debug__pos", evt.pos)
    set(init, "shell_damage_debug__splashExplosiveRadius", evt.splashExplosiveRadius)
    set(init, "shell_damage_debug__splashInnerRadius", evt.splashInnerRadius)
    set(init, "shell_damage_debug__splashOuterRadius", evt.splashOuterRadius)
    set(init, "shell_damage_debug__splashDamage", evt.splashDamage)
    set(init, "shell_damage_debug__shatterRadius", evt.shatterRadius)
    set(init, "shell_damage_debug__shatterCount", evt.shatterCount)
    set(init, "shell_damage_debug__shatterDamage", evt.shatterDamage)

[es(tag=(dev, render), no_order)]
def debug_draw_shell_explosion(info : UpdateStageInfoRenderDebug;
                               shell_damage_debug__pos : float3;
                               shell_damage_debug__splashExplosiveRadius : float;
                               shell_damage_debug__splashInnerRadius : float;
                               shell_damage_debug__splashOuterRadius : float;
                               shell_damage_debug__splashDamage : float;
                               shell_damage_debug__shatterRadius : float;
                               shell_damage_debug__shatterCount : int;
                               shell_damage_debug__shatterDamage : float)
  let pos = shell_damage_debug__pos
  if shell_damage_debug__splashExplosiveRadius > 0.0
    draw_cached_debug_sphere(pos, shell_damage_debug__splashExplosiveRadius, E3DCOLOR(0xFFFF0000), 32)
  draw_cached_debug_sphere(pos, shell_damage_debug__splashInnerRadius, E3DCOLOR(0xFFFF6600), 32)
  draw_cached_debug_sphere(pos, shell_damage_debug__splashOuterRadius, E3DCOLOR(0xFFFFcc99), 32)

  draw_cached_debug_sphere(pos, shell_damage_debug__shatterRadius, E3DCOLOR(0xFF00ccFF), 32)

  add_debug_text_mark(pos, "splash: {shell_damage_debug__splashDamage}", -1, -1.0, E3DCOLOR(0xFFFFFFFF))
  add_debug_text_mark(pos, "splash radius: {shell_damage_debug__splashInnerRadius} - {shell_damage_debug__splashOuterRadius}", -1, 0.0, E3DCOLOR(0xFFFFFFFF))
  add_debug_text_mark(pos, "shatter: {shell_damage_debug__shatterCount} X {shell_damage_debug__shatterDamage}", -1, 1.0, E3DCOLOR(0xFFFFFFFF))
  add_debug_text_mark(pos, "shatter radius: {shell_damage_debug__shatterRadius}", -1, 2.0, E3DCOLOR(0xFFFFFFFF))

[es(tag=(dev, render))]
def debug_shell_explosion_damage_received(evt : EventShellExplosionDamageDebug; transform : float3x4)
  createEntity("shell_damage_info_debug") <| $(var init : ComponentsInitializer)
    set(init, "shell_damage_debug__damageToParts", evt.damageToParts)
    set(init, "shell_damage_debug__dist", evt.dist)
    set(init, "shell_damage_debug__pos", transform[3])
    set(init, "shell_damage_debug__splashMaxDamage", evt.splashMaxDamage)
    set(init, "shell_damage_debug__splashDamage", evt.splashDamage)
    set(init, "shell_damage_debug__shatterSingleDamage", evt.shatterSingleDamage)
    set(init, "shell_damage_debug__shatterDamage", evt.shatterDamage)

[es(tag=(dev, render), no_order)]
def debug_draw_shell_damage(info : UpdateStageInfoRenderDebug;
                            shell_damage_debug__pos : float3;
                            shell_damage_debug__dist : float;
                            shell_damage_debug__damageToParts : float;
                            shell_damage_debug__splashMaxDamage : float;
                            shell_damage_debug__splashDamage : float;
                            shell_damage_debug__shatterSingleDamage : float;
                            shell_damage_debug__shatterDamage : float)
  let pos = shell_damage_debug__pos
  add_debug_text_mark(pos, "damage to parts: {shell_damage_debug__damageToParts} dist:{shell_damage_debug__dist}", -1, -2.0, E3DCOLOR(0xFFFFFFFF))
  add_debug_text_mark(pos, "splash: {shell_damage_debug__splashDamage}/{shell_damage_debug__splashMaxDamage}", -1, -1.0, E3DCOLOR(0xFFFF0000))
  add_debug_text_mark(pos, "shatter: {shell_damage_debug__shatterDamage} (count x {shell_damage_debug__shatterSingleDamage})", -1, 0.0, E3DCOLOR(0xFF0000FF))
