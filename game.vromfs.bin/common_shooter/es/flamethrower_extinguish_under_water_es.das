require ecs
require Dacoll
require AnimV20
require GeomNodeTree

[es(no_order, tag=server)]
def flamethrower_extinguish_under_water_es(info : UpdateStageInfoAct;
                                           animchar : AnimcharBaseComponent;
                                           flamethrower__streamEffectNodeIdx : int;
                                           flamethrower__underwaterCheckTime : float;
                                           var flamethrower__underwaterCheckTimer : float&;
                                           var flamethrower__underwater : bool&)
  if info.curTime < flamethrower__underwaterCheckTimer || flamethrower__streamEffectNodeIdx < 0
    return

  let pos = geomtree_getNodeWpos(*animchar.nodeTree, flamethrower__streamEffectNodeIdx)
  traceht_water_at_time(pos, 0.2f, info.curTime, flamethrower__underwater)
  flamethrower__underwaterCheckTimer = info.curTime + flamethrower__underwaterCheckTime
