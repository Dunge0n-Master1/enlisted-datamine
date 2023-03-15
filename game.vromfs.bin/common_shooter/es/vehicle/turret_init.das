require ecs
require ecs.common
require common_shooter.events_common_shooter
require vehicle
require turrets
require dm
require DagorSystem
require PhysVars
require AnimV20
require GeomNodeTree
require AnimatedPhys


def find_node_index(animchar, arr, index)
  let size = length(arr)
  if index < 0 || index >= size
    logerr("Turret init node index out of bounds. index: {index} , array size: {size}")
    return -1
  let nodeName = get_ecs_string(arr, index)
  return nodeName == null ? -1 : geomtree_findNodeIndex(*animchar.nodeTree, "{nodeName}")


def registerVar_impl(anim_vars : ecs::Object; key : string; blk : block<(name : string) : int>) : int
  let name = get_string(anim_vars, key, "")
  if name != ""
    return invoke(blk, name)
  return -1


def registerVar(var phys_vars : PhysVars; anim_vars : ecs::Object; key : string; def_val = 0.0) : int
  return registerVar_impl(anim_vars, key) <| $(name) { return registerVar(phys_vars, name, def_val); }


def registerPullVar(var phys_vars : PhysVars; anim_vars : ecs::Object; key : string; def_val = 0.0) : int
  return registerVar_impl(anim_vars, key) <| $(name) { return registerPullVar(phys_vars, name, def_val); }

[es(tag=netClient, on_appear, REQUIRE=resolvedTurret)]
def validate_resolved_turret(evt : Event; eid : EntityId; turret__resolved : bool)
  // We've got replicated turrets with resolvedTurret but the turret is not resolved on the client yet
  if !turret__resolved
    removeSubTemplate(eid, "resolved_turret")


[es(on_appear)]
def resolve_turrets(evt : Event; turret_control__gunEids : EidList)
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE_NOT=resolvedTurret)] (eid : EntityId)
      sendEventImmediate(eid, [[CmdResolveTurrets]])

[es(on_appear, on_event=CmdResolveTurrets, REQUIRE_NOT=resolvedTurret)]
def turret_init_aim_node(evt : Event;
                         turret__owner : EntityId;
                         turret__aimNodeName : string;
                         var turret__aimNodeId : int&)
  if !empty(turret__aimNodeName) && turret__aimNodeId < 0
    query(turret__owner) <| $ [es] (animchar : AnimcharBaseComponent)
      turret__aimNodeId = geomtree_findNodeIndex(*animchar.nodeTree, turret__aimNodeName)

[es(on_appear, on_event=CmdResolveTurrets, REQUIRE_NOT=resolvedTurret)]
def turret_control_init_es(evt : Event;
                           eid : EntityId;
                           turret__owner : EntityId;
                           turret__id : int;
                           turret__name : string;
                           turret__yawSpeed : float = -1.0;
                           turret__pitchSpeed : float = -1.0;
                           turret__yawAccel : float = -1.0;
                           turret__pitchAccel : float = -1.0;
                           turret__fireFxOn : bool = true;
                           turret__limit : float4 const? = null;
                           var turret__resolved : bool&;
                           var turret__wishYawVarId : int&;
                           var turret__wishPitchVarId : int&;
                           var turret__curYawVarId : int&;
                           var turret__curWorldYawVarId : int&;
                           var turret__curPitchVarId : int&;
                           var turret__curWorldPitchVarId : int&;
                           var turret__yawSpeedVarId : int&;
                           var turret__pitchSpeedVarId : int&;
                           var turret__yawSpeedMulVarId : int&;
                           var turret__pitchSpeedMulVarId : int&;
                           var turret__yawAccelVarId : int&;
                           var turret__pitchAccelVarId : int&;
                           var turret__minYawAngleVarId : int&;
                           var turret__maxYawAngleVarId : int&;
                           var turret__minPitchAngleVarId : int&;
                           var turret__maxPitchAngleVarId : int&;
                           var turret__gunRecoilVarId : int&;
                           var turret__emitterNodeId : int&;
                           var turret__turretAimActiveVarId : int&)
  if !turret__owner
    // Turret without owner is not attached to any vehicle.
    // So, such turret do not need to be resoved.
    return

  if turret__id < 0
    logerr("Cannot resolve turret '{turret__name}' for '{turret__owner}' ({getEntityTemplateName(turret__owner)})")
    return

  query(turret__owner) <| $ [es] ([[shared_comp]] turret_control__animVars : Array;
                                  [[shared_comp]] turret_control__emitterNodes : Array;
                                  animchar : AnimcharBaseComponent;
                                  var anim_phys : AnimatedPhys;
                                  var phys_vars : PhysVars)
    turret__emitterNodeId = find_node_index(animchar, turret_control__emitterNodes, turret__id)

    let animVars = get_ecs_object(turret_control__animVars, turret__id)
    if animVars != null
      turret__curYawVarId          = registerPullVar(phys_vars, *animVars, "curYawParamName")
      turret__curPitchVarId        = registerPullVar(phys_vars, *animVars, "curPitchParamName")
      turret__curWorldYawVarId     = registerPullVar(phys_vars, *animVars, "curWorldYawParamName")
      turret__curWorldPitchVarId   = registerPullVar(phys_vars, *animVars, "curWorldPitchParamName")
      turret__wishYawVarId         = registerVar(phys_vars, *animVars, "wishYawParamName")
      turret__wishPitchVarId       = registerVar(phys_vars, *animVars, "wishPitchParamName")
      turret__yawSpeedMulVarId     = registerVar(phys_vars, *animVars, "paramYawSpeedMul")
      turret__pitchSpeedMulVarId   = registerVar(phys_vars, *animVars, "paramPitchSpeedMul")
      turret__yawSpeedVarId        = registerVar(phys_vars, *animVars, "paramYawSpeed")
      turret__pitchSpeedVarId      = registerVar(phys_vars, *animVars, "paramPitchSpeed")
      turret__yawAccelVarId        = registerVar(phys_vars, *animVars, "paramYawAccel")
      turret__pitchAccelVarId      = registerVar(phys_vars, *animVars, "paramPitchAccel")
      turret__gunRecoilVarId       = registerVar(phys_vars, *animVars, "gunRecoilParamName")
      turret__turretAimActiveVarId = registerVar(phys_vars, *animVars, "aimActiveParamName", 1.f)
      if turret__limit != null
        turret__minYawAngleVarId     = registerVar(phys_vars, *animVars, "paramMinYawAngle")
        turret__maxYawAngleVarId     = registerVar(phys_vars, *animVars, "paramMaxYawAngle")
        turret__minPitchAngleVarId   = registerVar(phys_vars, *animVars, "paramMinPitchAngle")
        turret__maxPitchAngleVarId   = registerVar(phys_vars, *animVars, "paramMaxPitchAngle")
        if turret__minYawAngleVarId >= 0
          setVar(phys_vars, turret__minYawAngleVarId, (*turret__limit).x)
        if turret__maxYawAngleVarId >= 0
          setVar(phys_vars, turret__maxYawAngleVarId, (*turret__limit).y)
        if turret__minPitchAngleVarId >= 0
          setVar(phys_vars, turret__minPitchAngleVarId, (*turret__limit).z)
        if turret__maxPitchAngleVarId >= 0
          setVar(phys_vars, turret__maxPitchAngleVarId, (*turret__limit).w)
      if turret__yawSpeedVarId >= 0
        setVar(phys_vars, turret__yawSpeedVarId, turret__yawSpeed)
      if turret__pitchSpeedVarId >= 0
        setVar(phys_vars, turret__pitchSpeedVarId, turret__pitchSpeed)
      if turret__yawAccelVarId >= 0
        setVar(phys_vars, turret__yawAccelVarId, turret__yawAccel)
      if turret__pitchAccelVarId >= 0
        setVar(phys_vars, turret__pitchAccelVarId, turret__pitchAccel)
      if turret__fireFxOn
        registerVar(phys_vars, "fire_on", 1.0);
      anim_phys_init(anim_phys, animchar, phys_vars)

    turret__resolved = true

    addSubTemplate(eid, "resolved_turret")

[es(on_appear)]
def turret_control_init_flash_nodes(evt : Event; turret__owner : EntityId; turret__id : int; var turret__flashNodeId : int&)
  query(turret__owner) <| $ [es] (animchar : AnimcharBaseComponent;
                                  [[shared_comp]] turret_gun_flash_fx__flashNodes : Array)
    turret__flashNodeId = find_node_index(animchar, turret_gun_flash_fx__flashNodes, turret__id)


def find_dm_part_id(turret, key, damage_model)
  let partName = get_string(turret, key, "")
  if partName == ""
    return -1

  let partId = find_part_id_by_name(damage_model, partName)
  if partId >= 0
    return partId

  logerr("Part '{partName}' not found!")

  return -1

[es(tag=server, on_appear, REQUIRE=resolvedTurret)]
def turret_dm_part_es(evt : Event;
                      turret__owner : EntityId;
                      turret__id : int;
                      var turret_dm_part__barrelDm : int&;
                      var turret_dm_part__breechDm : int&;
                      var turret_drive_dm_part__horDriveDm : int&;
                      var turret_drive_dm_part__verDriveDm : int&)
  query(turret__owner) <| $ [es] ([[shared_comp]] turret_control__turretInfo : Array; damage_model : DamageModel)
    let turretObj = get_ecs_object(turret_control__turretInfo, turret__id)
    turret_dm_part__barrelDm         = find_dm_part_id(turretObj, "barrelDm", damage_model)
    turret_dm_part__breechDm         = find_dm_part_id(turretObj, "breechDm", damage_model)
    turret_drive_dm_part__horDriveDm = find_dm_part_id(turretObj, "horDriveDm", damage_model)
    turret_drive_dm_part__verDriveDm = find_dm_part_id(turretObj, "verDriveDm", damage_model)

[es(tag=gameClient, on_appear, REQUIRE=resolvedTurret)]
def turret_can_zoom_init_es(evt : Event;
                            turret__owner : EntityId;
                            turret__id : int;
                            var turret__canZoom : bool&)
  query(turret__owner) <| $ [es] ([[shared_comp]] turret_control__turretInfo : Array)
    let turretObj = get_ecs_object(turret_control__turretInfo, turret__id)
    turret__canZoom = get_bool(turretObj, "canZoom") ?? true
