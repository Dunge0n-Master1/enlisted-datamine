require ecs
require EnlistedHuman
require game.events_game


let VERTICAL_VELOCITY_MULT = 0.666667f // Reduce players velocity relative to the vehicle


[es]
def gain_vehicle_velocity_es(evt : GainVehicleVelocity; var human_net_phys : HumanActor)
  query(evt.vehicleEid) <| $ [es] (net_phys__currentStateVelocity : float3)
    assume vehicleVel = net_phys__currentStateVelocity

    // only vertical velocity, so the player will get killed when hit by the ground
    let addVelY = VERTICAL_VELOCITY_MULT * vehicleVel.y

    // Human in vehicle has velocity of the vehicle, currently to aid server-side hit verification
    // But if the velocity is preserved when leaving a plane at high speed, it looks silly (confirmed by designers)
    human_net_phys.phys.currentState.velocity = float3(0.f, addVelY, 0.f)
    human_net_phys.phys.previousState.velocity = float3(0.f, addVelY, 0.f)
