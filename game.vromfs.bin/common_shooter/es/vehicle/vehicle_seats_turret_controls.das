require ecs
require ecs.common
require ecs.safe
require strings
require DngNet
require game.es.events
require game.es.vehicle.vehicle_events
require DagorSystem
require game.utils.hero
require game.utils.team
require game.utils.net_utils
require DngActor
require DngHuman
require DngWeapon
require vehicle
require app


def find_turret(turret_name, turret_info)
  return find_index_if(each(turret_info)) <| $(item)
    let turret = get_ecs_object(item)
    return turret != null && get_string(*turret, "turretName", "") == turret_name

def set_common_controls(turret_control__turretInfo : Array; var controls : VehicleControlsState&; var mask : uint&)
  for turretNo, it in iter_range(turret_control__turretInfo), turret_control__turretInfo
    let turret = it as Object
    if turret != null && !(get_bool(*turret, "needsAssignedGunner") ?? true)
      mask = mask | uint(1 << turretNo)
      set_control_turret(controls, turretNo, true)

[es(tag=server, on_appear)]
def init_vehicle_seats_controls(evt : Event;
                                seat__id : int;
                                seat__vehicleEid : EntityId;
                                var seat__commonTurretControlMask : uint&;
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

    set_common_controls(turret_control__turretInfo, seat__availableControls, seat__commonTurretControlMask)

[es(tag=server, on_appear)]
def init_vehicle_seats_hatch_controls(evt : Event;
                                      seat__id : int;
                                      seat__vehicleEid : EntityId;
                                      var seat__commonTurretControlMask : uint&;
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

    set_common_controls(turret_control__turretInfo, seat__availableHatchControls, seat__commonTurretControlMask)

[es(on_appear)]
def seat_direct_turret_control_init(evt : Event; seat__id : int; seat__vehicleEid : EntityId; var seat__directTurretControl : bool&)
  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array)
    let seat = get_ecs_object(vehicle_seats__seats, seat__id)
    if seat != null
      seat__directTurretControl = get_bool(*seat, "directTurretControl") ?? false