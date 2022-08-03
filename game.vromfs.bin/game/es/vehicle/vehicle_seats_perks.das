require ecs
require ecs.common
require vehicle
require game.es.turrets_common
require EnlistedWeapon

struct TurretLoaderPerks
  reloadMult : float = 1.0
  canChangeShellInReload : bool = false

struct TurretAimerPerks
  pitchMult : float = 0.0

def push_affected_turrets(var vehicle_seats__applyLoaderModsToTurrets : Array;
                          turret_control__turretInfo : Array;
                          turret_names : Array const? const&)
  using() <| $(var arr : Array#)
    if turret_names != null
      for turretNameObj in *turret_names
        let turretName = get_string(turretNameObj, "")
        let turretInd = find_turret_index_by_name(turret_control__turretInfo, turretName)
        if turretInd >= 0
          push(arr, turretInd)
    push(vehicle_seats__applyLoaderModsToTurrets, arr)

def set_default_perk_values(turret_control__gunEids : EidList)
  let defaultPerks = TurretLoaderPerks()
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (var gun__timeBetweenShotMult : float&;
                             var turret__canChangeShellDuringReload : bool&)
      gun__timeBetweenShotMult = defaultPerks.reloadMult
      turret__canChangeShellDuringReload = defaultPerks.canChangeShellInReload

def apply_loader_perks(turret_eid : EntityId; perks : TurretLoaderPerks; vehicle_reload_mult : float)
  query(turret_eid) <| $ [es] (var gun__timeBetweenShotMult : float&;
                               var turret__canChangeShellDuringReload : bool&)
    gun__timeBetweenShotMult = min(gun__timeBetweenShotMult, perks.reloadMult) * vehicle_reload_mult
    turret__canChangeShellDuringReload ||= perks.canChangeShellInReload

def get_loader_perks(sitter_eid : EntityId) : TurretLoaderPerks
  var perks = TurretLoaderPerks()
  query(sitter_eid) <| $ [es] (entity_mods__vehicleReloadMult : float = 1.0;
                               entity_mods__canChangeShellDuringVehicleGunReload : bool = false)
    perks.reloadMult = entity_mods__vehicleReloadMult
    perks.canChangeShellInReload = entity_mods__canChangeShellDuringVehicleGunReload
  return perks

def apply_sitter_loader_perks(sitter_eid : EntityId;
                              affected_turret_ids : Array const? const;
                              turret_control__gunEids : EidList;
                              vehicle_reload_mult : float)
  if affected_turret_ids == null
    return
  for turretIndObj in *affected_turret_ids
    let turretInd = get_int(turretIndObj) ?? -1
    if turretInd >= 0
      apply_loader_perks(turret_control__gunEids[turretInd], get_loader_perks(sitter_eid), vehicle_reload_mult)

def apply_vehicle_reload_perks(vehicle_seats__seatEids : EidList;
                               vehicle_seats__applyLoaderModsToTurrets : Array;
                               turret_control__gunEids : EidList)
  set_default_perk_values(turret_control__gunEids)
  for seatEid, turretIds in vehicle_seats__seatEids, vehicle_seats__applyLoaderModsToTurrets
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId; seat_perks__vehicleReloadMult : float = 1f)
      let ownerEid = seat__ownerEid
      if ownerEid != ecs::INVALID_ENTITY_ID && get_bool(ownerEid, "isAlive") ?? true
        apply_sitter_loader_perks(ownerEid, get_ecs_array(turretIds), turret_control__gunEids, seat_perks__vehicleReloadMult)

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
def init_turret_loaders(evt : Event;
                        [[shared_comp]] turret_control__turretInfo : Array;
                        [[shared_comp]] vehicle_seats__seats : Array;
                        var vehicle_seats__applyLoaderModsToTurrets : Array)
  for seatObj in vehicle_seats__seats
    let seat = get_ecs_object(seatObj)
    let turretNames = get_ecs_array(seat, "loaderTurretNames")
    push_affected_turrets(vehicle_seats__applyLoaderModsToTurrets, turret_control__turretInfo, turretNames)

[es(tag=server, on_event=EventOnSeatOwnersChanged)]
def vehicle_apply_sitter_reload_perks(evt : Event;
                                      vehicle_seats__seatEids : EidList;
                                      vehicle_seats__applyLoaderModsToTurrets : Array;
                                      turret_control__gunEids : EidList)
  apply_vehicle_reload_perks(vehicle_seats__seatEids, vehicle_seats__applyLoaderModsToTurrets, turret_control__gunEids)
  apply_vehicle_aimer_perks(vehicle_seats__seatEids, turret_control__gunEids)

[es(tag=server, on_event=EventEntityDied)]
def vehicle_recalculate_perks_on_sitter_death(evt : Event; human_anim__vehicleSelected : EntityId)
  query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList;
                                                vehicle_seats__applyLoaderModsToTurrets : Array;
                                                turret_control__gunEids : EidList)
    apply_vehicle_reload_perks(vehicle_seats__seatEids, vehicle_seats__applyLoaderModsToTurrets, turret_control__gunEids)
    apply_vehicle_aimer_perks(vehicle_seats__seatEids, turret_control__gunEids)

[es(tag=server, track=vehicle_seats__seatEids)]
def vehicle_seats_perks_init(evt : Event;
                             [[shared_comp]] vehicle_seats__seats : Array;
                             vehicle_seats__seatEids : EidList)
  for i in iter_range(vehicle_seats__seatEids)
    let seat = get_ecs_object(vehicle_seats__seats[i])
    if seat == null
      continue

    query(vehicle_seats__seatEids[i]) <| $ [es] (var seat_perks__vehicleReloadMult : float&)
      let mult = get_float(seat, "vehicleReloadMult") ?? 1f
      seat_perks__vehicleReloadMult = saturate(2.f - mult)
