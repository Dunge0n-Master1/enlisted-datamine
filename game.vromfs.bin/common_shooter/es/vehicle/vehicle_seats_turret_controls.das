require ecs
require ecs.common
require strings
require EnlistedNet
require game.es.events
require game.es.vehicle.vehicle_events
require DagorSystem
require game.utils.hero
require game.utils.team
require game.utils.net_utils
require EnlistedActor
require EnlistedHuman
require EnlistedWeapon
require vehicle
require app


def find_turret(turret_name, turret_info)
  return find_index_if(each(turret_info)) <| $(item)
    let turret = get_ecs_object(item)
    return turret != null && get_string(*turret, "turretName", "") == turret_name

[es(tag=server, on_appear)]
def init_vehicle_seats_controls(evt : Event;
                                seat__id : int;
                                seat__vehicleEid : EntityId;
                                var seat__availableControls : VehicleControlsState)
  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array)
    let seat = get_ecs_object(vehicle_seats__seats, seat__id)
    if seat == null
      return

    seat__availableControls.canControlVehicle = get_bool(*seat, "seatOwnsEntityControl") ?? false

  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array;
                                     [[shared_comp]] turret_control__turretInfo : Array)
    let seat = get_ecs_object(vehicle_seats__seats, seat__id)
    if seat == null
      return

    let seatTurretName = get_string(*seat, "turretName", "")
    if seatTurretName != ""
      let turretNo = find_turret(seatTurretName, turret_control__turretInfo)
      if turretNo >= 0
        set_control_turret(seat__availableControls, turretNo, true)

    let turretNames = get_ecs_array(*seat, "turretNames")
    if turretNames != null
      for item in *turretNames
        let turretNo = find_turret(get_string(item, ""), turret_control__turretInfo)
        if turretNo >= 0
          set_control_turret(seat__availableControls, turretNo, true)

[es(tag=server, on_appear)]
def init_vehicle_seats_hatch_controls(evt : Event;
                                      seat__id : int;
                                      seat__vehicleEid : EntityId;
                                      var seat__availableHatchControls : VehicleControlsState)
  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array)
    let seat = get_ecs_object(vehicle_seats__seats, seat__id)
    if seat == null
      return

    seat__availableHatchControls.canControlVehicle = get_bool(*seat, "seatOwnsEntityControl") ?? false

  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array;
                                     [[shared_comp]] turret_control__turretInfo : Array)
    let seat = get_ecs_object(vehicle_seats__seats, seat__id)
    if seat == null
      return

    let turretNames = get_ecs_array(*seat, "hatchTurretNames")
    if turretNames != null
      for item in *turretNames
        let turretNo = find_turret(get_string(item, ""), turret_control__turretInfo)
        if turretNo >= 0
          set_control_turret(seat__availableHatchControls, turretNo, true)

[es(on_appear)]
def seat_direct_turret_control_init(evt : Event; seat__id : int; seat__vehicleEid : EntityId; var seat__directTurretControl : bool&)
  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array)
    let seat = get_ecs_object(vehicle_seats__seats, seat__id)
    if seat != null
      seat__directTurretControl = get_bool(*seat, "directTurretControl") ?? false