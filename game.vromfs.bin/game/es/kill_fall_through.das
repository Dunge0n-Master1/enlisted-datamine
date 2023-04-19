require ecs
require game.es.events
require enlisted.events_enlisted
require DngDm

[es(tag=server, after=net_phys_update_es)]
def kill_fall_through(info : UpdateStageInfoAct;
                      eid : EntityId;
                      transform : float3x4;
                      isAlive : bool;
                      kill_fall_through__floorY : float = -100.0)
  if isAlive && transform[3].y < kill_fall_through__floorY
    sendEvent(eid, [[CmdKill offender=eid, damageType=uint16(int(DamageType DM_MELEE)), gunPropsId=-1, shellId=-1]])

[es(after=update_projectile_es)]
def kill_fall_through_projectile(info : ParallelUpdateFrameDelayed;
                                 eid : EntityId;
                                 projectile__prevPos : float3;
                                 kill_fall_through_projectile__floorY : float = -100.0)
  if projectile__prevPos.y < kill_fall_through_projectile__floorY
    sendEvent(eid, [[CmdDestoyProjectileEntity]])
