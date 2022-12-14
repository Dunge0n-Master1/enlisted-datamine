options no_aot
require ecs
require ecs.common
require game.utils.hero
require DagorConsole
require common_shooter.es.concussion_common
require common_shooter.events_common_shooter
require DagorDebug3D
require BallisticsProps
require DaWeaponProps
require DaWeapons
require AnimV20
require GeomNodeTree
require EnlistedDm

[console_cmd(name="affect.concussion")]
def console_activate_concussion()
  find_query() <| $ [es(REQUIRE=hero)] (eid : EntityId; concussion__duration : float; var concussion__isActive : bool&)
    if concussion__isActive
      concussion__isActive = false
    else
      enable_concussion_affect(eid, concussion__duration)
    return true

[console_cmd(name="affect.concussion.all")]
def console_activate_concussion_all()
  query() <| $ [es(REQUIRE=human)] (eid : EntityId; concussion__duration : float; var concussion__isActive : bool&)
    if concussion__isActive
      concussion__isActive = false
    else
      enable_concussion_affect(eid, concussion__duration)

[console_cmd(name="debug.showShotConcussionRadius")]
def debug_concussion_on_shell_create()
  query() <| $ [es(REQUIRE=isTurret)] (gun__curShellId : ShellPropIds;
                                       turret__owner : EntityId;
                                       turret__emitterNodeId : int;
                                       gun__onShotConcussionRadiusCaliberCoeff : float = 70.0;
                                       turret__flashNodeId : int = -1)
    projectile_get_props(int(gun__curShellId.shellId)) <| $(props : ProjectileProps)
      if props.caliber <= 0.01
        return
      let radius = gun__onShotConcussionRadiusCaliberCoeff * props.caliber
      query(turret__owner) <| $ [es] (animchar : AnimcharBaseComponent)
        let nodeId = turret__flashNodeId >= 0 ? turret__flashNodeId : turret__emitterNodeId
        let shotPos = geomtree_getNodeWpos(*animchar.nodeTree, nodeId)
        draw_debug_sphere_buffered(shotPos, radius, E3DCOLOR(0xFFFF0000), 12, 10000)

[es(tag=server, REQUIRE_NOT=launch_desc, REQUIRE=debugConcussion)]
def on_explosion_concussion_debug(evt : EventShellExplodedServer;
                                  shell__shell_id__shell_id : int;
                                  shell__shell_id__damage_id : int;
                                  shell__shell_id__ballistics_id : int;
                                  concussion_debug__frames : int = 10000;
                                  shell__concussionMinRadius : float = 0.0;
                                  shell__concussionMaxRadius : float = -1.0)
  let damageRadius = get_shell_max_radius(shell__shell_id__shell_id, shell__shell_id__damage_id, shell__shell_id__ballistics_id)
  let concussionRadius = clamp(damageRadius, shell__concussionMinRadius, shell__concussionMaxRadius >= 0. ? shell__concussionMaxRadius : damageRadius)
  draw_debug_sphere_buffered(evt.pos, concussionRadius, E3DCOLOR(0xFFFF0000), concussion_debug__frames)

[es(tag=server, REQUIRE=debugConcussion)]
def on_explosion_concussion_launch_desc_debug(evt : EventShellExplodedServer;
                                              launch_desc : LaunchDesc;
                                              concussion_debug__frames : int = 10000;
                                              shell__concussionMinRadius : float = 0.0;
                                              shell__concussionMaxRadius : float = -1.0)
  assume shellId = launch_desc.shellId
  let damageRadius = get_shell_max_radius(int(shellId.shellId), int(shellId.damageId), int(shellId.ballisticsId))
  let concussionRadius = clamp(damageRadius, shell__concussionMinRadius, shell__concussionMaxRadius >= 0. ? shell__concussionMaxRadius : damageRadius)
  draw_debug_sphere_buffered(evt.pos, concussionRadius, E3DCOLOR(0xFFFF0000), concussion_debug__frames)
