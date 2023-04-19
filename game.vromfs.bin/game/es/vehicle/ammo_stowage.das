require ecs
require app
require dm
require ecs.common
require DagorMath
require game.es.vehicle.vehicle_events
require common_shooter.events_common_shooter

def set_part_rel_hp(var part : DamagePart&; hp : float)
  part.relHpFixed = rel_hp_float_to_fixed_floor(hp)
  part.state = uint(part.relHpFixed) > uint(HP_DAMAGED_STATE_TRESHOLD_FIXED) ? (DamagePartState DP_STATE_NORMAL) : (DamagePartState DP_STATE_DAMAGED)

def restore_slot_part(part_id : int; var damage_model : DamageModel&)
  if uint(part_id) >= uint(length(damage_model.dmData.parts))
    return
  damage_model.dmData.parts[part_id] |> set_part_rel_hp(1.0)

def restore_slots(cluster_eids : EidList)
  for clusterEid in cluster_eids
    query(clusterEid) <| $ [es] (var ammo_cluster__slotsEnabled : BoolList&; ammo_cluster__mapSlotToPartId : IntList; ammo_cluster__vehicleEid : EntityId)
      query(ammo_cluster__vehicleEid) <| $ [es] (var damage_model : DamageModel&)
        for slotEnabledIndex, slotPartId in iter_range(ammo_cluster__slotsEnabled), ammo_cluster__mapSlotToPartId
          if !ammo_cluster__slotsEnabled[slotEnabledIndex]
            ammo_cluster__slotsEnabled[slotEnabledIndex] = true
            restore_slot_part(slotPartId, damage_model)

def setup_ammo_cluster(cluster_eid : EntityId; var ammo_to_distribute : int&)
  var canReloadFromThisCluster = false
  query(cluster_eid) <| $ [es] (ammo_cluster__vehicleEid : EntityId;
                                ammo_cluster__restoreAfterDead : bool;
                                ammo_cluster__mapSlotToPartId : IntList;
                                ammo_cluster__slotsMaxAmmo : IntList;
                                var ammo_cluster__slotsEnabled : BoolList&;
                                var ammo_cluster__slotsAmmo : IntList&)
    query(ammo_cluster__vehicleEid) <| $ [es] (var damage_model : DamageModel&)
      let numSlots = length(ammo_cluster__slotsEnabled)
      for i in iter_range(ammo_cluster__slotsEnabled)
        let invIndex = numSlots - i - 1
        assume isSlotEnabled = ammo_cluster__slotsEnabled[invIndex]
        assume slotAmmo = ammo_cluster__slotsAmmo[invIndex]
        let slotMaxAmmo = ammo_cluster__slotsMaxAmmo[invIndex]
        let partId = ammo_cluster__mapSlotToPartId[invIndex]
        canReloadFromThisCluster ||= slotAmmo > 0

        if ammo_cluster__restoreAfterDead && !isSlotEnabled && ammo_to_distribute > 0
          isSlotEnabled = true
          restore_slot_part(partId, damage_model)

        if isSlotEnabled && ammo_to_distribute > slotMaxAmmo
          slotAmmo = slotMaxAmmo
          ammo_to_distribute -= slotMaxAmmo
        elif isSlotEnabled && ammo_to_distribute > 0
          if slotAmmo == 0
            restore_slot_part(partId, damage_model)
          slotAmmo = ammo_to_distribute
          ammo_to_distribute = 0
        else
          slotAmmo = 0

        let shouldPartBeEnabled = slotAmmo > 0
        if uint(partId) < uint(length(damage_model.dmData.parts)) && damage_model.dmData.parts[partId].enabled != shouldPartBeEnabled
          damage_model.dmData.parts[partId].enabled = shouldPartBeEnabled

  return canReloadFromThisCluster

def count_gun_ammo(eid)
  var totalAmmo = 0
  query(eid) <| $ [es] (gun__ammo_by_shell : IntList)
    for ammo in gun__ammo_by_shell
      totalAmmo += ammo
  return max(0, totalAmmo - 1) // remove loaded

def count_ammo(gun_eids : EidList)
  var ammo = 0
  for gunEid in gun_eids
    ammo += count_gun_ammo(gunEid)
  return ammo

def setup_ammo_stowage(ammo_stowage_eid : EntityId)
  var ammoStowageReloadMult = 1.0
  query(ammo_stowage_eid) <| $ [es] (ammo_stowage__gunEids : EidList;
                                     ammo_stowage__clusters : EidList;
                                     ammo_stowage__maxAmmoFirstStage : int;
                                     var ammo_stowage__numAmmoFirstStage : int&;
                                     var ammo_stowage__numAmmo : int&)
    let stowageAmmo = count_ammo(ammo_stowage__gunEids)
    ammoStowageReloadMult = VERY_BIG_NUMBER

    if stowageAmmo > ammo_stowage__numAmmo
      restore_slots(ammo_stowage__clusters)
    let ammoDelta = stowageAmmo - ammo_stowage__numAmmo
    ammo_stowage__numAmmo = stowageAmmo

    ammo_stowage__numAmmoFirstStage = max(0,
      min(ammo_stowage__numAmmoFirstStage + ammoDelta,
          ammo_stowage__maxAmmoFirstStage))

    var numShellsFirstStage = ammo_stowage__numAmmoFirstStage
    var numChargesFirstStage = ammo_stowage__numAmmoFirstStage
    var numShells = max(0, ammo_stowage__numAmmo - ammo_stowage__numAmmoFirstStage)
    var numCharges = max(0, ammo_stowage__numAmmo - ammo_stowage__numAmmoFirstStage)

    let numClusters = length(ammo_stowage__clusters)

    if ammo_stowage__maxAmmoFirstStage > 0
      for i in iter_range(ammo_stowage__clusters)
        let clusterEid = ammo_stowage__clusters[numClusters - i - 1]
        query(clusterEid) <| $ [es(REQUIRE=ammo_cluster__isFirstStage)] (ammo_cluster__reloadTimeMult : float;
                                                                         ammo_cluster__isShell : bool)
          let hadAmmo = setup_ammo_cluster(clusterEid, ammo_cluster__isShell ? numShellsFirstStage : numChargesFirstStage)
          if hadAmmo
            ammoStowageReloadMult = min(ammoStowageReloadMult, ammo_cluster__reloadTimeMult)

    for i in iter_range(ammo_stowage__clusters)
      let clusterEid = ammo_stowage__clusters[numClusters - i - 1]
      query(clusterEid) <| $ [es(REQUIRE_NOT=ammo_cluster__isFirstStage)] (ammo_cluster__reloadTimeMult : float;
                                                                           ammo_cluster__isShell : bool)
        let hadAmmo = setup_ammo_cluster(clusterEid, ammo_cluster__isShell ? numShells : numCharges)
        if hadAmmo
          ammoStowageReloadMult = min(ammoStowageReloadMult, ammo_cluster__reloadTimeMult)

  return ammoStowageReloadMult

[es(tag=server, on_appear, track=gun__ammo_by_shell, REQUIRE=gun__ammo_by_shell)]
def setup_ammo_stowage_on_ammo_changed(evt : Event; turret__ammoStowageEid : EntityId; var turret__ammoStowageReloadMult : float&)
  turret__ammoStowageReloadMult = setup_ammo_stowage(turret__ammoStowageEid)


def disable_cluster_for_part(ammo_stowage__stowages : EidList; part_id : int)
  for stowageEid in ammo_stowage__stowages
    query(stowageEid) <| $ [es] (ammo_stowage__clusters : EidList)
      for clusterEid in ammo_stowage__clusters
        query(clusterEid) <| $ [es] (ammo_cluster__mapSlotToPartId : IntList; var ammo_cluster__slotsEnabled : BoolList&)
          let slotId = find_index(ammo_cluster__mapSlotToPartId, part_id)
          if slotId >= 0
            ammo_cluster__slotsEnabled[slotId] = false
            return

[es(tag=server, after=damage_model_es, REQUIRE_NOT=deadEntity)]
def ammo_stowage_disable_damaged_parts(evt : EventOnPartDamaged; ammo_stowage__stowages : EidList)
  if int(evt.hpFixed) == 0
    ammo_stowage__stowages |> disable_cluster_for_part(evt.partId)

[es(tag=server, after=damage_model_es, REQUIRE_NOT=deadEntity)]
def ammo_stowage_disable_damaged_parts_volumetric(evt : EventOnVolumetricDamage; ammo_stowage__stowages : EidList)
  for partIt in evt.damagedParts
    let part = get_ecs_object(partIt)
    let partId = get_int(part, "partId") ?? -1
    let hpFixed = get_int(part, "hpFixed") ?? 1
    if partId >= 0 && hpFixed == 0
      ammo_stowage__stowages |> disable_cluster_for_part(partId)

[es(tag=server, no_order)]
def ammo_stowage_first_stage_replenishment(info : UpdateStageInfoAct;
                                           eid : EntityId;
                                           ammo_stowage__isReloading : bool;
                                           ammo_stowage__replenishmentDelay : float;
                                           ammo_stowage__replenishmentTime : float;
                                           ammo_stowage__maxAmmoFirstStage : int;
                                           ammo_stowage__numAmmo : int;
                                           ammo_stowage__replenishmentTimeMult : float;
                                           var ammo_stowage__numAmmoFirstStage : int&;
                                           var ammo_stowage__replenishmentStartTime : float&;
                                           var ammo_stowage__nextReplenishmentAtTime : float&)
  let maxAmmo = min(ammo_stowage__maxAmmoFirstStage, ammo_stowage__numAmmo)
  if ammo_stowage__numAmmoFirstStage >= maxAmmo || ammo_stowage__replenishmentTimeMult < 0. || ammo_stowage__isReloading
    ammo_stowage__replenishmentStartTime = -1.0
    ammo_stowage__nextReplenishmentAtTime = -1.0
    return

  if ammo_stowage__replenishmentStartTime < 0.
    ammo_stowage__replenishmentStartTime = info.curTime + ammo_stowage__replenishmentDelay
    return

  let replenishmentTime = ammo_stowage__replenishmentTime * ammo_stowage__replenishmentTimeMult
  if ammo_stowage__replenishmentStartTime >= info.curTime && ammo_stowage__nextReplenishmentAtTime < 0.0
    ammo_stowage__nextReplenishmentAtTime = ammo_stowage__replenishmentStartTime + replenishmentTime

  if info.curTime > ammo_stowage__nextReplenishmentAtTime
    ammo_stowage__numAmmoFirstStage = min(ammo_stowage__numAmmoFirstStage + 1, maxAmmo)
    if ammo_stowage__numAmmoFirstStage < maxAmmo
      ammo_stowage__replenishmentStartTime = ammo_stowage__nextReplenishmentAtTime
      ammo_stowage__nextReplenishmentAtTime += replenishmentTime

    setup_ammo_stowage(eid)

[es(tag=server, track=ammo_stowage__replenishmentTimeMult)]
def ammo_stowage_recalculate_replenish_time_mult_changed(evt : Event;
                                                         ammo_stowage__replenishmentTime : float;
                                                         ammo_stowage__replenishmentTimeMult : float;
                                                         ammo_stowage__replenishmentStartTime : float;
                                                         var ammo_stowage__nextReplenishmentAtTime : float&)
  if ammo_stowage__replenishmentStartTime < 0. || ammo_stowage__replenishmentTimeMult < 0.
    return
  let replenishmentTime = ammo_stowage__replenishmentTime * ammo_stowage__replenishmentTimeMult
  let progress = cvt(get_sync_time(), ammo_stowage__replenishmentStartTime, ammo_stowage__nextReplenishmentAtTime, 0., 1.)
  ammo_stowage__nextReplenishmentAtTime = ammo_stowage__replenishmentStartTime + progress * replenishmentTime

[es(tag=server, track=(ammo_stowage__replenishmentStartTime, ammo_stowage__nextReplenishmentAtTime))]
def ammo_stowage_set_replenishment_time_to_turret(evt : Event;
                                                  ammo_stowage__gunEids : EidList;
                                                  ammo_stowage__replenishmentStartTime : float;
                                                  ammo_stowage__nextReplenishmentAtTime : float)
  for gun in ammo_stowage__gunEids
    query(gun) <| $ [es] (var turret__replenishmentStartTime : float&;
                          var turret__replenishmentFinishTime : float&)
      turret__replenishmentStartTime = ammo_stowage__replenishmentStartTime
      turret__replenishmentFinishTime = ammo_stowage__nextReplenishmentAtTime

[es(tag=server, on_appear, track=ammo_stowage__numAmmoFirstStage)]
def ammo_stowage_set_first_stage_ammo_to_turret(evt : Event;
                                                ammo_stowage__numAmmoFirstStage : int;
                                                ammo_stowage__maxAmmoFirstStage : int;
                                                ammo_stowage__gunEids : EidList)
  for gun in ammo_stowage__gunEids
    query(gun) <| $ [es] (var turret__numAmmoFirstStage : int&)
      turret__numAmmoFirstStage = ammo_stowage__maxAmmoFirstStage > 0 ? ammo_stowage__numAmmoFirstStage : -1

[es(tag=server, track=turret__perksReloadMult, REQUIRE=turret__perksReloadMult)]
def ammo_stowage_track_loader_mult(evt : Event; turret__ammoStowageEid : EntityId)
  query(turret__ammoStowageEid) <| $ [es] (ammo_stowage__gunEids : EidList;
                                           ammo_stowage__replenishmentMaxMult : float = 1000.;
                                           var ammo_stowage__replenishmentTimeMult : float&)
    ammo_stowage__replenishmentTimeMult = VERY_BIG_NUMBER
    for gunEid in ammo_stowage__gunEids
      let turretReloadMult = get_float(gunEid, "turret__perksReloadMult") ?? ammo_stowage__replenishmentTimeMult
      ammo_stowage__replenishmentTimeMult = min(ammo_stowage__replenishmentTimeMult, turretReloadMult)
    if ammo_stowage__replenishmentTimeMult > ammo_stowage__replenishmentMaxMult
      ammo_stowage__replenishmentTimeMult = -1.

[es(tag=server, track=gun__isReloading, REQUIRE=gun__isReloading)]
def ammo_stowage_replenishment_interrupt_by_reload(evt : Event; turret__ammoStowageEid : EntityId)
  query(turret__ammoStowageEid) <| $ [es] (ammo_stowage__gunEids : EidList;
                                           var ammo_stowage__isReloading : bool&)
    let reloadingTurretIndex = find_index_if(each(ammo_stowage__gunEids)) <| $(gunEid)
      return get_bool(gunEid, "gun__isReloading") ?? false
    ammo_stowage__isReloading = reloadingTurretIndex >= 0
