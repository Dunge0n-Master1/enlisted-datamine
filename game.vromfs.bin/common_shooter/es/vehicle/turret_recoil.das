require ecs
require ecs.common
require DagorMath
require PhysVars

[es(on_appear, REQUIRE=resolvedTurret)]
def turret_recoil_init_es(evt : Event;
                          turret__owner : EntityId;
                          turret__id : int;
                          var turret_recoil__duration : float&)
  query(turret__owner) <| $ [es] ([[shared_comp]] turret_control__turretInfo : Array)
    let turretObj = get_ecs_object(turret_control__turretInfo, turret__id)
    if turretObj == null
      return
    turret_recoil__duration = get_float(*turretObj, "gunRecoilDuration") ?? 0.5f

[es(tag=gameClient, REQUIRE_NOT=deadEntity)]
def turret_recoil_move_barrel_es(info : UpdateStageInfoAct; turret_control__gunEids : EidList; var phys_vars : PhysVars)
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE=(resolvedTurret, gun))] (turret__gunRecoilVarId : int; turret_recoil__startTime, turret_recoil__duration : float)
      if turret__gunRecoilVarId < 0
        return
      let shotTime = turret_recoil__startTime
      let duration = turret_recoil__duration
      let recoil = cvt(info.curTime - shotTime, 0.f, duration, -1.f, 0.f)
      setVar(phys_vars, turret__gunRecoilVarId, recoil)