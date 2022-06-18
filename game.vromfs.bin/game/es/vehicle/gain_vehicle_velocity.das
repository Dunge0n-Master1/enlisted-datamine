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

    human_net_phys.phys.currentState.velocity.y  += addVelY
    human_net_phys.phys.previousState.velocity.y += addVelY
