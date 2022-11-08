require ecs
require EnlistedPlane
require Plane

[es(tag=server, no_order)]
def aircraft_state_update(info : UpdateStageInfoAct;
                          var aircraft__isCapableOfTakeOff : bool&;
                          plane_net_phys : PlaneActor)
  aircraft__isCapableOfTakeOff = plane_net_phys.phys.isCapableOfTakeOff
