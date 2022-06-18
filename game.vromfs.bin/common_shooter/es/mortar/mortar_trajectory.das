require ecs
require player
require game.utils.hero
require game.es.events
require DaWeaponProps
require Gun
require EnlistedWeapon
require common_shooter.es.mortar.mortar_common
require common_shooter.events_common_shooter


[es(tag=render, REQUIRE=mortar)]
def mortar_trajectory_calculation(evt : CmdWeapPhysUpdate;
                                  gun__curShellId : ShellPropIds;
                                  gun__owner : ecs::EntityId;
                                  gun : Gun;
                                  var trajectory__enabled : bool&;
                                  var trajectory__start : float3&;
                                  var trajectory__vel : float3&)
  if !evt.isForReal || int(gun__curShellId.shellId) < 0
    return
  trajectory__enabled = false
  ecs::query(gun__owner) <| $ [es(REQUIRE=hero)] (human_weap__mortarMode : bool)
    if !human_weap__mortarMode
      return
    trajectory__enabled = true
    let speed = get_shell_speed(gun__curShellId)
    trajectory__start = get_shoot_pos(gun, evt.gloc)
    let gunDir = evt.gloc.gunDir
    trajectory__vel = gunDir * speed

[es(tag=render, REQUIRE=mortar)]
def disable_trajectory_on_mortar_detach(evt : CmdWeapAttach; var trajectory__enabled : bool&)
  if !evt.isAttached
    trajectory__enabled = false
