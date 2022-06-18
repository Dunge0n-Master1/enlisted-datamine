require ecs
require app
require math.base
require GamePhys
require EnlistedHuman
require game.es.events
require game.events_game


[es(tag=server)]
def save_vehicle_velocity_on_leaving_es(evt : GainVehicleVelocity;
                                        eid : EntityId;
                                        collision_damage__lethalSpeed : float;
                                        collision_damage__damageOnLeavingVehicleTemplate : string)
  query(evt.vehicleEid) <| $ [es] (net_phys__currentStateVelocity : float3)
    if length_sq(net_phys__currentStateVelocity) >= square(collision_damage__lethalSpeed)
      addSubTemplate(eid, collision_damage__damageOnLeavingVehicleTemplate) <| $(var init)
        init |> set("collision_damage__vehicleVelocityOnLeaving", net_phys__currentStateVelocity)
        init |> set("collision_damage__vehicleLeavingAtTime", get_sync_time())


[es(tag=server, before=human_collider_damage)]
def human_damage_on_leaving_vehicle(evt : CmdPostPhysUpdate;
                                    eid : EntityId;
                                    collision_damage__damageOnLeavingVehicleTemplate : string;
                                    var human_net_phys : HumanActor;
                                    var collision_damage__vehicleLeavingAtTime : float&;
                                    collision_damage__lethalHeight : float;
                                    collision_damage__vehicleVelocityOnLeaving : float3)
  let isSpdDiffExists = length_sq(human_net_phys.phys.currentState.spdSummaryDiff) > FLT_EPSILON
  let notInAir = (uint(human_net_phys.phys.currentState.isInAirHistory) & 1u) == 0u
  if collision_damage__vehicleLeavingAtTime > 0. && (isSpdDiffExists || notInAir)
    let dt = float(evt.tick) * evt.dt - collision_damage__vehicleLeavingAtTime

    let freeFallTimeFromLethalHeight = sqrt(2. * collision_damage__lethalHeight / gravity())
    if dt <= freeFallTimeFromLethalHeight
      human_net_phys.phys.currentState.spdSummaryDiff.x += collision_damage__vehicleVelocityOnLeaving.x
      human_net_phys.phys.currentState.spdSummaryDiff.z += collision_damage__vehicleVelocityOnLeaving.z

    collision_damage__vehicleLeavingAtTime = -1.

    removeSubTemplate(eid, collision_damage__damageOnLeavingVehicleTemplate)
