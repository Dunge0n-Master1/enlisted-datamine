require ecs
require DngDm
require DagorMath
require common_shooter.events_common_shooter
require common_shooter.es.concussion_common
require DaWeaponProps
require BallisticsProps
require DaWeapons
require GridCollision
require AnimV20
require GeomNodeTree
require Grid

[es(tag=server, no_order)]
def concussion_timer(info : UpdateStageInfoAct;
                     concussion__endTime : float;
                     var concussion__isActive : bool&)
  if concussion__isActive && info.curTime > concussion__endTime
    concussion__isActive = false

[es(tag=server, track=isAlive)]
def on_death_disable_concussion(evt : Event; isAlive : bool; var concussion__isActive : bool&)
  if !isAlive
    concussion__isActive = false // TODO: just remove from dead soldier

[es(tag=server, track=concussion__isActive, on_appear)]
def concussion_screen_effect_toggle(evt : Event; concussion__isActive : bool; var hasConcussedVision : bool&)
  hasConcussedVision = concussion__isActive

[es(tag=server, track=concussion__isActive, on_appear)]
def concussion_sound_toggle(evt : Event; concussion__isActive : bool; var hasConcussedSound : bool&)
  hasConcussedSound = concussion__isActive

def apply_concussion_in_radius(pos : float3; radius : float)
  if radius > 0.
    for_each_entity_in_grid(ecs_hash("humans"), BSphere3(pos, radius), GridEntCheck BOUNDING) <| $(eid : EntityId)
      query(eid) <| $ [es(REQUIRE_NOT=deadEntity)] (concussion__duration : float; isInVehicleHidden : bool = false)
        if !isInVehicleHidden
          enable_concussion_affect(eid, concussion__duration)

[es(tag=server, REQUIRE_NOT=launch_desc)]
def on_explosion_concussion(evt : EventShellExplodedServer;
                            shell__shell_id__shell_id : int;
                            shell__shell_id__damage_id : int;
                            shell__shell_id__ballistics_id : int;
                            shell__concussionMinRadius : float = 0.0;
                            shell__concussionMaxRadius : float = -1.0)
  let damageRadius = get_shell_max_radius(shell__shell_id__shell_id, shell__shell_id__damage_id, shell__shell_id__ballistics_id)
  let concussionRadius = clamp(damageRadius, shell__concussionMinRadius, shell__concussionMaxRadius >= 0. ? shell__concussionMaxRadius : damageRadius)
  apply_concussion_in_radius(evt.pos, concussionRadius)

[es(tag=server)]
def on_explosion_concussion_launch_desc(evt : EventShellExplodedServer;
                                        launch_desc : LaunchDesc;
                                        shell__concussionMinRadius : float = 0.0;
                                        shell__concussionMaxRadius : float = -1.0)
  assume shellId = launch_desc.shellId
  let damageRadius = get_shell_max_radius(int(shellId.shellId), int(shellId.damageId), int(shellId.ballisticsId))
  let concussionRadius = clamp(damageRadius, shell__concussionMinRadius, shell__concussionMaxRadius >= 0. ? shell__concussionMaxRadius : damageRadius)
  apply_concussion_in_radius(evt.pos, concussionRadius)

[es(tag=server, REQUIRE=human)]
def on_hit_concussion(evt : EventOnEntityHit; eid : EntityId; isAlive : bool; concussion__duration : float)
  if evt.victim != eid || !isAlive
    return
  if evt.damageType == int(DamageType DM_MELEE) || evt.damageType == int(DamageType DM_BACKSTAB)
    let actionPropId = evt.actionPropsId
    if actionPropId >= 0
      melee_get_props(actionPropId) <| $(meleeProps : MeleeProps)
        if meleeProps.concussion
          enable_concussion_affect(eid, concussion__duration)

[es(tag=server, on_appear)]
def turret_shot_concussion_on_shell_create(evt : Event; launch_desc : LaunchDesc; gunEid : EntityId)
  projectile_get_props(int(launch_desc.shellId.shellId)) <| $(props : ProjectileProps)
    if props.caliber <= 0.01
      return
    query(gunEid) <| $ [es(REQUIRE=isTurret)] (turret__owner : EntityId; gun__onShotConcussionRadiusCaliberCoeff : float = 70.0; turret__flashNodeId : int = -1)
      let radius = gun__onShotConcussionRadiusCaliberCoeff * props.caliber
      let radiusSq = radius * radius
      var shotPos = launch_desc.tm[3]
      if turret__flashNodeId >= 0
        query(turret__owner) <| $ [es] (animchar : AnimcharBaseComponent)
          shotPos = geomtree_getNodeWpos(*animchar.nodeTree, turret__flashNodeId)

      for_each_entity_in_grid(ecs_hash("humans"), BSphere3(shotPos, radius), GridEntCheck BOUNDING) <| $(eid : EntityId)
        query(eid) <| $ [es(REQUIRE_NOT=deadEntity)] (animchar : AnimcharBaseComponent; human_use_object__nodeId : int; concussion__duration : float; isInVehicle : bool = false)
          let headPos = geomtree_getNodeWpos(*animchar.nodeTree, human_use_object__nodeId)
          if !isInVehicle && distance_sq(headPos, shotPos) < radiusSq
            enable_concussion_affect(eid, concussion__duration)

[es(tag=server, on_appear)]
def apply_concussion_duration_mult(evt : Event;
                                   entity_mods__concussionDurationMult : float;
                                   var concussion__duration : float&;
                                   var concussion__handsShakeFadeTime : float&)
  concussion__duration = max(0., concussion__duration * entity_mods__concussionDurationMult)
  concussion__handsShakeFadeTime = max(0., concussion__handsShakeFadeTime * entity_mods__concussionDurationMult)

[es(tag=server, on_appear)]
def apply_concussion_shake_mult(evt : Event;
                                entity_mods__concussionShakeMult : float;
                                var concussion__handsShakeMagnitude : float&;
                                var concussion__handsShakeSpeedMult : float&)
  concussion__handsShakeMagnitude = max(0., concussion__handsShakeMagnitude * entity_mods__concussionShakeMult)
  concussion__handsShakeSpeedMult = max(0., concussion__handsShakeSpeedMult * entity_mods__concussionShakeMult)