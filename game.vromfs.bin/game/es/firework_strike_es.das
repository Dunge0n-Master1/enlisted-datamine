require ecs
require math.base

[es(tag=server, no_order)]
def firework_strike_es(info : UpdateStageInfoAct;
                       eid : EntityId;
                       fireworks__effectTemplate : string;
                       fireworks__effectOffset : float3;
                       artillery__targetPos : float3;
                       artillery__timeBetweenShots : float;
                       artillery__shotsCount : int;
                       var artillery__shotsDone : int&;
                       var artillery__nextShotTime : float&)
  if artillery__shotsDone >= artillery__shotsCount
    destroyEntity(eid)

  if info.curTime < artillery__nextShotTime
    return

  var tm = IDENT_TM
  tm[3] = artillery__targetPos + fireworks__effectOffset
  createEntity(fireworks__effectTemplate) <| $(init)
    init |> set("transform", tm)

  artillery__nextShotTime = info.curTime + artillery__timeBetweenShots
  artillery__shotsDone++
