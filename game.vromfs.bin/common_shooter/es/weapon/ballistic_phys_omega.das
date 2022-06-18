require ecs
require DagorMath

[es(no_order)]
def ballistic_phys_omega(info : UpdateStageInfoAct;
                         ballistic_phys__omega : float3;
                         var transform : float3x4)
  let orientInc = ballistic_phys__omega * info.dt
  let rotQuat = quat(orientInc, length(orientInc))
  var tm : float3x4
  make_tm(rotQuat, tm)
  transform = transform * tm
