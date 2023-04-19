require ecs
require ecs.common
require vehicle
require game.es.turrets_common
require DngWeapon
require ecs.safe

struct TurretLoaderPerks
  reloadMult : float = 1e9f
  canChangeShellInReload : bool = false

struct TurretAimerPerks
  pitchMult : float = 0.0

def set_default_perk_values(turret_control__gunEids : EidList; turret_control__missingLoaderReloadTimeMult : float)
  let defaultPerks = TurretLoaderPerks()
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (var turret__perksReloadMult : float&;
                             var turret__canChangeShellDuringReload : bool&;
                             turret__hasLoaderSeatInVehicle : bool = false)
      turret__perksReloadMult = defaultPerks.reloadMult * (turret__hasLoaderSeatInVehicle ? turret_control__missingLoaderReloadTimeMult : 1.0)
      turret__canChangeShellDuringReload = defaultPerks.canChangeShellInReload

def apply_loader_perks(turret_eid : EntityId;
                       perks : TurretLoaderPerks;
                       vehicle_reload_mult : float;
                       turret_control__missingLoaderReloadTimeMult : float = 1.0)
  query(turret_eid) <| $ [es] (var turret__perksReloadMult : float&;
                               var turret__canChangeShellDuringReload : bool&;
                               turret__hasLoaderSeatInVehicle : bool = false)
    let loaderMult = perks.reloadMult * (turret__hasLoaderSeatInVehicle ? turret_control__missingLoaderReloadTimeMult : 1.0) * vehicle_reload_mult
    if loaderMult <= turret__perksReloadMult
      turret__perksReloadMult = loaderMult
      turret__canChangeShellDuringReload = perks.canChangeShellInReload

def get_loader_perks(sitter_eid : EntityId) : TurretLoaderPerks
  var perks = TurretLoaderPerks()
  query(sitter_eid) <| $ [es] (entity_mods__vehicleReloadMult : float = 1.0;
                               entity_mods__canChangeShellDuringVehicleGunReload : bool = false)
    perks.reloadMult = entity_mods__vehicleReloadMult
    perks.canChangeShellInReload = entity_mods__canChangeShellDuringVehicleGunReload
  return perks

def apply_sitter_loader_perks(sitter_eid : EntityId;
                              sitter_controls : VehicleControlsState;
                              affected_turret_ids : IntList;
                              turret_control__gunEids : EidList;
                              vehicle_reload_mult : float;
                              turret_control__missingLoaderReloadTimeMult : float)
  let loaderPerks = get_loader_perks(sitter_eid)
  for turretId, turretEid in iter_range(turret_control__gunEids), turret_control__gunEids
    if can_control_turret(sitter_controls, turretId)
      apply_loader_perks(turretEid, loaderPerks, vehicle_reload_mult, turret_control__missingLoaderReloadTimeMult)

  for turretInd in affected_turret_ids
    apply_loader_perks(turret_control__gunEids[turretInd], loaderPerks, vehicle_reload_mult)

def apply_vehicle_reload_perks(vehicle_seats__seatEids : EidList;
                               turret_control__gunEids : EidList;
                               turret_control__missingLoaderReloadTimeMult : float)
  set_default_perk_values(turret_control__gunEids, turret_control__missingLoaderReloadTimeMult)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId;
                              seat__availableControls : VehicleControlsState;
                              seat__isInHatch : bool = false;
                              seat__canLoadInHatch : bool;
                              seat__loaderTurretIds : IntList;
                              seat_perks__vehicleReloadMult : float = 1f)
      let ownerEid = seat__ownerEid
      if !!ownerEid && (seat__canLoadInHatch || !seat__isInHatch) && get_bool(ownerEid, "isAlive") ?? true
        apply_sitter_loader_perks(ownerEid, seat__availableControls, seat__loaderTurretIds, turret_control__gunEids,
                                  seat_perks__vehicleReloadMult, turret_control__missingLoaderReloadTimeMult)

def apply_aimer_perks(turret_eid : EntityId; perks : TurretAimerPerks)
  query(turret_eid) <| $ [es] (var turret_guidance__pitchMultWhenAimingYaw : float&)
    turret_guidance__pitchMultWhenAimingYaw = min(1.0, perks.pitchMult)

def set_default_aimer_perk_values(turret_control__gunEids : EidList)
  let defaultPerks = TurretAimerPerks()
  for gunEid in turret_control__gunEids
    apply_aimer_perks(gunEid, defaultPerks)

def get_aimer_perks(sitter_eid : EntityId) : TurretAimerPerks
  var perks = TurretAimerPerks()
  query(sitter_eid) <| $ [es] (entity_mods__turretPitchMultWhenAimingYaw : float)
    perks.pitchMult = entity_mods__turretPitchMultWhenAimingYaw
  return perks

def apply_sitter_aimer_perks(sitter_eid : EntityId;
                             turret_eids : EidList;
                             controls_state : VehicleControlsState)
  let perks = get_aimer_perks(sitter_eid)
  for turretNo, turretEid in iter_range(turret_eids), turret_eids
    if can_control_turret(controls_state, turretNo)
      apply_aimer_perks(turretEid, perks)

def apply_vehicle_aimer_perks(vehicle_seats__seatEids : EidList;
                              turret_control__gunEids : EidList)
  set_default_aimer_perk_values(turret_control__gunEids)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__availableControls : VehicleControlsState; seat__ownerEid : EntityId)
      if !!seat__ownerEid && (get_bool(seat__ownerEid, "isAlive") ?? true)
        apply_sitter_aimer_perks(seat__ownerEid, turret_control__gunEids, seat__availableControls)


[es(tag=server, on_appear)]
def init_loader_seat_turret_ids(evt : Event;
                                seat__vehicleEid : EntityId;
                                seat__id : int;
                                var seat__canLoadInHatch : bool&;
                                var seat__loaderTurretIds : IntList&)
  query(seat__vehicleEid) <| $ [es] ([[shared_comp]] turret_control__turretInfo : Array;
                                     [[shared_comp]] vehicle_seats__seats : Array)
    let seatInfo = vehicle_seats__seats[seat__id] as Object
    seat__canLoadInHatch = seatInfo?.canLoadInHatch ?? false
    let turretNames = seatInfo?.loaderTurretNames ?as Array
    if turretNames != null
      for turretNameObj in *turretNames
        let turretName = turretNameObj ?? ""
        let turretInd = find_turret_index_by_name(turret_control__turretInfo, turretName)
        if turretInd >= 0
          seat__loaderTurretIds |> push(turretInd)

[es(tag=server, on_event=EventOnSeatOwnersChanged, REQUIRE=vehicle_seats__applyPerks)]
def vehicle_apply_sitter_reload_perks(evt : Event;
                                      vehicle_seats__seatEids : EidList;
                                      turret_control__missingLoaderReloadTimeMult : float = 1.;
                                      turret_control__gunEids : EidList)
  apply_vehicle_reload_perks(vehicle_seats__seatEids, turret_control__gunEids, turret_control__missingLoaderReloadTimeMult)
  apply_vehicle_aimer_perks(vehicle_seats__seatEids, turret_control__gunEids)

[es(tag=server, on_event=EventEntityDied)]
def vehicle_recalculate_perks_on_sitter_death(evt : Event; human_anim__vehicleSelected : EntityId)
  query(human_anim__vehicleSelected) <| $ [es(REQUIRE=vehicle_seats__applyPerks)] (vehicle_seats__seatEids : EidList;
                                                                                   turret_control__missingLoaderReloadTimeMult : float = 1.;
                                                                                   turret_control__gunEids : EidList)
    apply_vehicle_reload_perks(vehicle_seats__seatEids, turret_control__gunEids, turret_control__missingLoaderReloadTimeMult)
    apply_vehicle_aimer_perks(vehicle_seats__seatEids, turret_control__gunEids)

[es(tag=server, track=seat__isInHatch, REQUIRE=seat__isInHatch)]
def vehicle_recalculate_perks_on_sitter_use_hatch(evt : Event; seat__vehicleEid : EntityId)
  query(seat__vehicleEid) <| $ [es(REQUIRE=vehicle_seats__applyPerks)] (vehicle_seats__seatEids : EidList;
                                                                        turret_control__missingLoaderReloadTimeMult : float = 1.;
                                                                        turret_control__gunEids : EidList)
    apply_vehicle_reload_perks(vehicle_seats__seatEids, turret_control__gunEids, turret_control__missingLoaderReloadTimeMult)
    apply_vehicle_aimer_perks(vehicle_seats__seatEids, turret_control__gunEids)

[es(tag=server, on_appear, REQUIRE=resolvedTurret)]
def sitter_perks_init_turret(evt : Event;
                             turret__owner : EntityId;
                             turret__id : int;
                             var turret__hasLoaderSeatInVehicle : bool&)
  query(turret__owner) <| $ [es] ([[shared_comp]] turret_control__turretInfo : Array;
                                  [[shared_comp]] vehicle_seats__seats : Array)
    for seat in vehicle_seats__seats
      let turretNames = (seat as Object)?.loaderTurretNames ?as Array
      if turretNames != null
        for turretName in *turretNames
          if turret__id == find_turret_index_by_name(turret_control__turretInfo, turretName ?? "")
            turret__hasLoaderSeatInVehicle = true
            return

[es(tag=server, track=vehicle_seats__seatEids)]
def vehicle_seats_perks_init(evt : Event;
                             [[shared_comp]] vehicle_seats__seats : Array;
                             vehicle_seats__seatEids : EidList)
  for i in iter_range(vehicle_seats__seatEids)
    let seat = get_ecs_object(vehicle_seats__seats[i])
    if seat == null
      continue

    query(vehicle_seats__seatEids[i]) <| $ [es] (var seat_perks__vehicleReloadMult : float&)
      seat_perks__vehicleReloadMult = seat?.vehicleReloadMult ?? 1.
