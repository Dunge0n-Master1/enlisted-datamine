require ecs
require enlisted.events_enlisted
require DaWeapons
require PhysVars

[es(tag=gameClient, before=clear_gun_launch_events_es, after=after_guns_update_sync)]
def shoot_rotate_turret_es(info : ParallelUpdateFrameDelayed;
                           turret__owner : EntityId;
                           rotate_turret__physVarName : string;
                           rotate_turret__lastEventMaxDt : float;
                           rotate_turret__omegaMax : float;
                           rotate_turret__omegaAcc : float;
                           gun_launch_events : GunLaunchEvents;
                           var rotate_turret__curAngle : float&;
                           var rotate_turret__curOmega : float&;
                           var rotate_turret__lastEventAtTime : float&;
                           var rotate_turret__physVarId : int&)
  if length(gun_launch_events.launchEvents) > 0
    rotate_turret__lastEventAtTime = info.curTime
  query(turret__owner) <| $ [es] (var phys_vars : PhysVars&)
    if rotate_turret__physVarId < 0
      rotate_turret__physVarId = registerVar(phys_vars, rotate_turret__physVarName, 0.f)
    let accMul = info.curTime - rotate_turret__lastEventAtTime < rotate_turret__lastEventMaxDt ? 1. : -1.
    rotate_turret__curOmega = clamp(rotate_turret__curOmega + rotate_turret__omegaAcc * info.dt * accMul, 0., rotate_turret__omegaMax)
    if rotate_turret__curOmega < FLT_EPSILON
      return
    rotate_turret__curAngle = (rotate_turret__curAngle + rotate_turret__curOmega * info.dt) % 360.
    setVar(phys_vars, rotate_turret__physVarId, rotate_turret__curAngle)
