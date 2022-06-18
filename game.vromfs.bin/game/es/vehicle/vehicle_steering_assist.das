require ecs
require math.base
require vehicle
require DagorMath
require DagorMathUtils
require game.es.events


[es(tag=input, REQUIRE=input__enabled, on_appear)]
def vehicle_steering_assist_init(evt : Event;
                                 var vehicle_steering_assist__error : float&;
                                 var vehicle_steering_assist__prevError : float&)
  vehicle_steering_assist__error = 0.
  vehicle_steering_assist__prevError = 0.


[es(tag=input, REQUIRE=input__enabled, after=vehicle_input_driver_es)]
def vehicle_steering_assist(info : UpdateStageUpdateInput;
                            transform : float3x4;
                            vehicle_steering_assist__pidK : float3;
                            vehicle_steering_assist__brakingPidK : float3;
                            vehicle_steering_assist__errorReduceViscocity : float;
                            vehicle_steering_assist__steeringThreshold : float;
                            var vehicle_steering_assist__error : float&;
                            var vehicle_steering_assist__prevError : float&;
                            var vehicle_net_phys : VehiclePhysActor&)
  let dt = vehicle_net_phys.phys.timeStep

  let wasSteeringError = vehicle_steering_assist__error
  vehicle_steering_assist__error = approach(wasSteeringError, 0., dt, vehicle_steering_assist__errorReduceViscocity)

  assume producedCT = vehicle_net_phys.phys.producedCT
  let wasSteering = ground_control_state_getAxisValue(producedCT, EGroundControlAxis GCA_STEERING)
  let isAssistDenied = abs(wasSteering) > vehicle_steering_assist__steeringThreshold

  let speed = dot(float3(vehicle_net_phys.phys.currentState.velocity), transform[0])
  let omegaY = float(vehicle_net_phys.phys.currentState.omega.y)
  let curError = (abs(omegaY) < 1e-2f || speed <= 0. || isAssistDenied) ? 0. : omegaY
  let deltaError = (curError - vehicle_steering_assist__prevError) / dt

  vehicle_steering_assist__error += curError
  vehicle_steering_assist__prevError = curError

  let throttle  = ground_control_state_getAxisValue(producedCT, EGroundControlAxis GCA_THROTTLE)
  let isSpeedUp = throttle > 0.
  let pidK = isSpeedUp ? vehicle_steering_assist__pidK : vehicle_steering_assist__brakingPidK
  let pidSteering = dot(pidK, float3(curError, vehicle_steering_assist__error, deltaError))

  let steering = clamp(wasSteering + pidSteering, -1., 1.)
  producedCT |> ground_control_state_setAxisValue(EGroundControlAxis GCA_STEERING, steering)
