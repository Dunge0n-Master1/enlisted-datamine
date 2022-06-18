require ecs
require soundEvent

[es(tag=sound, before=burst_fx_player)]
def burst_fx_sound(act : UpdateStageInfoAct;
                   burst_fx__soundPath : string;
                   transform, burst_fx__transform : float3x4;
                   burst_fx__nextUpdate : float)
  if act.curTime < burst_fx__nextUpdate && act.curTime + act.dt >= burst_fx__nextUpdate
    let resTm = transform * burst_fx__transform
    oneshot(burst_fx__soundPath, resTm[3])
