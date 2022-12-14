require ecs
require game.es.events
require EnlistedDm

[es(tag=server, after=net_phys_update_es)]
def kill_fall_through(info : UpdateStageInfoAct;
                      eid : EntityId;
                      transform : float3x4;
                      isAlive : bool;
                      kill_fall_through__floorY : float = -100.0)
  if isAlive && transform[3].y < kill_fall_through__floorY
    sendEvent(eid, [[CmdKill offender=eid, damageType=uint16(int(DamageType DM_MELEE)), gunPropsId=-1, shellId=-1]])
