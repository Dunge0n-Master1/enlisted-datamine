require ecs
require math.base
require EnlistedHuman

[es(tag=server, REQUIRE=seat_anim__lowerMove, no_order)]
def seat_movable_set_walk_dir_server(info : UpdateStageInfoAct;
                                     seat__vehicleEid : EntityId;
                                     seat__ownerEid : EntityId)
  query(seat__ownerEid) <| $ [es] (var human_net_phys : HumanActor)
    query(seat__vehicleEid) <| $ [es] (net_phys__currentStateVelocity : float3)
      human_net_phys.phys.currentState.walkDir = net_phys__currentStateVelocity.xz

[es(tag=netClient, REQUIRE=seat_anim__lowerMove, no_order)]
def seat_movable_set_walk_dir_local(info : UpdateStageInfoAct;
                                    seat__vehicleEid : EntityId;
                                    seat__ownerEid : EntityId)
  query(seat__ownerEid) <| $ [es(REQUIRE=hero)] (var human_net_phys : HumanActor)
    query(seat__vehicleEid) <| $ [es] (net_phys__currentStateVelocity : float3)
      human_net_phys.phys.currentState.walkDir = net_phys__currentStateVelocity.xz

[es(tag=gameClient, no_order)]
def seat_set_walk_anim(info : UpdateStageInfoAct;
                       seat__vehicleEid : EntityId;
                       seat_anim__lowerMove : das_string;
                       seat_anim__lowerIdle : das_string;
                       seat_anim_movable__minVelocity : float = 0.3;
                       var seat_anim__lower : das_string)
  query(seat__vehicleEid) <| $ [es] (net_phys__currentStateVelocity : float3)
    let isMoving = length_sq(net_phys__currentStateVelocity) > square(seat_anim_movable__minVelocity)
    seat_anim__lower := isMoving ? seat_anim__lowerMove : seat_anim__lowerIdle
