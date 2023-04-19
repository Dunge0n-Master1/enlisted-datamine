require ecs
require DngPlane
require DagorMath

[es(tag=server, no_order)]
def is_safe_to_get_out_of_plane(info : UpdateStageInfoAct;
                                plane_net_phys : PlaneActor;
                                plane__safeSpeedToGetOut : float;
                                var vehicle__isSafeToGetOut : bool&)
  vehicle__isSafeToGetOut = length_sq(plane_net_phys.phys.currentState.velocity) < plane__safeSpeedToGetOut * plane__safeSpeedToGetOut