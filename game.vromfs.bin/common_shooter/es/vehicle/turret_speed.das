require ecs
require PhysVars

[es(on_appear, track=(turret__yawSpeed, turret__pitchSpeed))]
def turret_set_speed(evt : Event;
                     turret__owner : EntityId;
                     turret__yawSpeed : float;
                     turret__pitchSpeed : float;
                     turret__yawSpeedVarId : int;
                     turret__pitchSpeedVarId : int)
  query(turret__owner) <| $ [es] (var phys_vars : PhysVars)
    if turret__yawSpeedVarId >= 0
      setVar(phys_vars, turret__yawSpeedVarId, turret__yawSpeed)
    if turret__pitchSpeedVarId >= 0
      setVar(phys_vars, turret__pitchSpeedVarId, turret__pitchSpeed)

[es(on_appear, track=(turret__yawAccel, turret__pitchAccel))]
def turret_set_accel(evt : Event;
                     turret__owner : EntityId;
                     turret__yawAccel : float;
                     turret__pitchAccel : float;
                     turret__yawAccelVarId : int;
                     turret__pitchAccelVarId : int)
  query(turret__owner) <| $ [es] (var phys_vars : PhysVars)
    if turret__yawAccelVarId >= 0
      setVar(phys_vars, turret__yawAccelVarId, turret__yawAccel)
    if turret__pitchAccelVarId >= 0
      setVar(phys_vars, turret__pitchAccelVarId, turret__pitchAccel)