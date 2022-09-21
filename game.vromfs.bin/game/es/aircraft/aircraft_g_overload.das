require ecs
require math.base
require game.es.events
require game.es.vehicle.vehicle_seats_common
require vehicle
require EnlistedPlane
require EnlistedHuman
require DagorMath
require GamePhys

def apply_stamina_delta(var stamina : float&; delta : float)
  stamina = max(0.0, stamina + delta)

def restore_stamina(var stamina : float&;
                    is_controls_lost : bool;
                    stamina_recovery_per_sec : float;
                    stamina_after_out_recovery_per_sec : float;
                    max_stamina_mult : float;
                    stamina_recovery_mult : float;
                    dt : float)
  let maxStamina = max_stamina_mult
  let recoverSpeed = stamina_recovery_mult * (is_controls_lost ? (stamina_after_out_recovery_per_sec * max_stamina_mult) : stamina_recovery_per_sec)
  stamina = min(maxStamina, stamina + recoverSpeed * dt)

def approach_g(value, g_force, dt, plus_viscosity, minus_viscosity, release_viscosity)
  var viscosity = release_viscosity
  if (g_force > 1.0 && value < g_force) || (g_force < 1.0 && value > g_force)
    viscosity = (g_force > 0.0 ? plus_viscosity : minus_viscosity)
  return approach(value, g_force, dt, viscosity)

def scale_g(val, mult : float)
  return 1.0 + (val - 1.0) * mult

def get_adapted_g_force(g_force_acting, g_force_adaptable_min, g_force_adaptable_max, stamina : float)
  let adaptableGForceMin = scale_g(g_force_adaptable_min, stamina)
  let adaptableGForceMax = scale_g(g_force_adaptable_max, stamina)

  return clamp(g_force_acting, adaptableGForceMin, adaptableGForceMax)

def get_overload(delta_g_force;
                 positive_g_force_overload_start, positive_g_force_overload_end : float;
                 negative_g_force_overload_start, negative_g_force_overload_end : float)
  if delta_g_force > 0.0
    return cvt(delta_g_force, positive_g_force_overload_start, positive_g_force_overload_end, 0.0, 1.0)
  else
    return -cvt(-delta_g_force, negative_g_force_overload_start, negative_g_force_overload_end, 0.0, 1.0)

def get_stamina_delta(overload, stamina_usage_threshold, stamina_positive_usage_speed, stamina_negative_usage_speed, dt)
  if overload > stamina_usage_threshold
    return -(overload - stamina_usage_threshold) * stamina_positive_usage_speed * dt
  if -overload > stamina_usage_threshold
    return -(-overload - stamina_usage_threshold) * stamina_negative_usage_speed * dt
  return 0.0

[es(tag=server, no_order)]
def aircraft_g_overload_control_loss(info : UpdateStageInfoAct;
                                     vehicle_seats__seatEids : EidList;
                                     var plane_net_phys : PlaneActor)
  var controlSensitivity = 1.0
  let pilotEid = get_vehicle_driver(vehicle_seats__seatEids)
  query(pilotEid) <| $ [es] (aircraft_crew__isLoseControlsByStamina : bool;
                             aircraft_crew__lostControlsSensetivityMult : float;
                             entity_mods__pilotLostControlsSensetivityAddMult : float = 0.0)
    if aircraft_crew__isLoseControlsByStamina
      controlSensitivity = clamp(aircraft_crew__lostControlsSensetivityMult + entity_mods__pilotLostControlsSensetivityAddMult, 0.0, 1.0)
  plane_net_phys.phys.currentState.pilotControlSensitivity = controlSensitivity

[es(tag=server, on_appear)]
def aircraft_crew_init_head_pos(evt : Event; eid : EntityId; human_anim__vehicleSelected : EntityId; var aircraft_crew__headPos : float3&)
  query(human_anim__vehicleSelected) <| $ [es(REQUIRE=airplane)] (vehicle_seats__seatEids : EidList)
    for seatEid in vehicle_seats__seatEids
      query(seatEid) <| $ [es] (seat__cameraPos : float3; seat__ownerEid : EntityId)
        if eid == seat__ownerEid
          aircraft_crew__headPos = seat__cameraPos

[es(tag=server, REQUIRE=airplane, on_event=EventOnSeatOwnersChanged)]
def aircraft_crew_init_head_pos_seats_changed(evt : Event;
                                              vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__cameraPos : float3; seat__ownerEid : EntityId)
      query(seat__ownerEid) <| $ [es] (var aircraft_crew__headPos : float3&)
        aircraft_crew__headPos = seat__cameraPos

[es(tag=server)]
def aircraft_g_force(evt : CmdPostPhysUpdate;
                     plane_net_phys : PlaneActor;
                     vehicle_seats__seatEids : EidList)
  let ACC_TO_G = 0.102

  var planeAccel = float3(plane_net_phys.phys.accel) * ACC_TO_G

  let planeOmega = float3(plane_net_phys.phys.currentState.omega)
  planeAccel.y += 1.0
  orient_transformInv(plane_net_phys.phys.currentState.location.O, planeAccel)
  let linearG = planeAccel.y

  for eid in vehicle_seats__seatEids
    query(eid) <| $ [es] (seat__ownerEid : EntityId)
      query(seat__ownerEid) <| $ [es] (aircraft_crew__headPos : float3; var g_force__g : float&)
        let angularG = cross(cross(aircraft_crew__headPos, planeOmega), planeOmega).y * ACC_TO_G
        g_force__g = linearG + angularG

[es(tag=server, after=aircraft_g_force)]
def aircraft_crew_g_force(info : UpdateStageInfoAct;
                          aircraft_crew__stamina : float;
                          g_force__g : float;
                          var g_force__percieved : float&;
                          var g_force__acting : float&;
                          var g_force__adapted : float&;
                          var g_force__unadapted : float&;
                          var g_force__isPositive : bool&;
                          g_force__plusPercievedViscosity : float;
                          g_force__minusPercievedViscosity : float;
                          g_force__releasePercievedViscosity : float;
                          g_force__plusActingViscosity : float;
                          g_force__minusActingViscosity : float;
                          g_force__releaseActingViscosity : float;
                          g_force__adaptedViscosity : float;
                          g_force__unadaptedViscosity : float;
                          g_force__adaptableMin : float;
                          g_force__adaptableMax : float;
                          entity_mods__aircraftCrewMaxStaminaMult : float = 1.0;
                          entity_mods__negativeGToleranceMult : float = 1.0;
                          entity_mods__positiveGToleranceMult : float = 1.0)
  let dt = info.dt
  let stamina = safediv(aircraft_crew__stamina, entity_mods__aircraftCrewMaxStaminaMult)

  g_force__percieved = approach_g(g_force__percieved, g_force__g, dt,
                                     g_force__plusPercievedViscosity, g_force__minusPercievedViscosity, g_force__releasePercievedViscosity)

  g_force__acting = approach_g(g_force__acting, g_force__percieved, dt,
                                  g_force__plusActingViscosity, g_force__minusActingViscosity, g_force__releaseActingViscosity)

  let adaptedG = get_adapted_g_force(g_force__acting,
                                     scale_g(g_force__adaptableMin, entity_mods__negativeGToleranceMult),
                                     scale_g(g_force__adaptableMax, entity_mods__positiveGToleranceMult),
                                     stamina)
  g_force__adapted = approach(g_force__adapted, adaptedG, dt, g_force__adaptedViscosity)

  let unadaptedG = g_force__percieved - g_force__adapted
  g_force__unadapted = approach(g_force__unadapted, unadaptedG, dt, g_force__unadaptedViscosity)
  g_force__isPositive = g_force__unadapted >= 0.0

[es(tag=server, on_appear)]
def init_max_stamina(evt : Event;
                     var aircraft_crew__stamina : float&;
                     entity_mods__aircraftCrewMaxStaminaMult : float = 1.0)
  aircraft_crew__stamina = entity_mods__aircraftCrewMaxStaminaMult

[es(tag=server, after=aircraft_crew_g_force)]
def aircraft_crew_stamina(info : UpdateStageInfoAct;
                          var aircraft_crew__stamina : float&;
                          var aircraft_crew__isLoseControlsByStamina : bool&;
                          entity_mods__aircraftCrewMaxStaminaMult : float = 1.0;
                          entity_mods__aircraftCrewRestoreStaminaMult : float = 1.0;
                          entity_mods__negativeGToleranceMult : float = 1.0;
                          entity_mods__positiveGToleranceMult : float = 1.0;
                          g_force__unadapted : float;
                          g_force__blackoutStart : float;
                          g_force__blackoutEnd : float;
                          g_force__redoutStart : float;
                          g_force__redoutEnd : float;
                          aircraft_crew__staminaRecoveryPerSec : float;
                          aircraft_crew__staminaAfterOutRecoveryPerSec : float;
                          aircraft_crew__staminaUsageThreshold : float;
                          aircraft_crew__staminaPositiveUsageSpeed : float;
                          aircraft_crew__staminaNegativeUsageSpeed : float)
  let overload = get_overload(g_force__unadapted,
                              g_force__blackoutStart * entity_mods__positiveGToleranceMult, g_force__blackoutEnd * entity_mods__positiveGToleranceMult,
                              g_force__redoutStart * entity_mods__negativeGToleranceMult, g_force__redoutEnd * entity_mods__negativeGToleranceMult)
  var isStaminaDraining = false
  if !aircraft_crew__isLoseControlsByStamina
    let staminaBefore = aircraft_crew__stamina
    let staminaDelta = get_stamina_delta(overload, aircraft_crew__staminaUsageThreshold,
                                         aircraft_crew__staminaPositiveUsageSpeed, aircraft_crew__staminaNegativeUsageSpeed, info.dt)
    apply_stamina_delta(aircraft_crew__stamina, staminaDelta)
    isStaminaDraining = aircraft_crew__stamina < staminaBefore

  let stamina = aircraft_crew__stamina
  if stamina <= 0.0
    aircraft_crew__isLoseControlsByStamina = true
  if stamina >= 1.0
    aircraft_crew__isLoseControlsByStamina = false

  if !isStaminaDraining || aircraft_crew__isLoseControlsByStamina
    restore_stamina(aircraft_crew__stamina, aircraft_crew__isLoseControlsByStamina,
                    aircraft_crew__staminaRecoveryPerSec, aircraft_crew__staminaAfterOutRecoveryPerSec,
                    entity_mods__aircraftCrewMaxStaminaMult, entity_mods__aircraftCrewRestoreStaminaMult, info.dt)