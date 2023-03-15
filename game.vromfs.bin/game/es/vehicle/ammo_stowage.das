require ecs
require dm
require ecs.common
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

def setup_ammo_cluster(cluster_eid : EntityId; setup_ammo : int)
  var ammoToDistribute = setup_ammo
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

        if ammo_cluster__restoreAfterDead && !isSlotEnabled && ammoToDistribute > 0
          isSlotEnabled = true
          restore_slot_part(partId, damage_model)

        if isSlotEnabled && ammoToDistribute > slotMaxAmmo
          slotAmmo = slotMaxAmmo
          ammoToDistribute -= slotMaxAmmo
        elif isSlotEnabled && ammoToDistribute > 0
          if slotAmmo == 0
            restore_slot_part(partId, damage_model)
          slotAmmo = ammoToDistribute
          ammoToDistribute = 0
        else
          slotAmmo = 0

        let shouldPartBeEnabled = slotAmmo > 0
        if uint(partId) < uint(length(damage_model.dmData.parts)) && damage_model.dmData.parts[partId].enabled != shouldPartBeEnabled
          damage_model.dmData.parts[partId].enabled = shouldPartBeEnabled

  return ammoToDistribute

def count_gun_ammo(eid)
  var totalAmmo = 0
  query(eid) <| $ [es] (gun__ammo_by_shell : IntList)
    for ammo in gun__ammo_by_shell
      totalAmmo += ammo
  return totalAmmo

def count_ammo(gun_eids : EidList)
  var ammo = 0
  for gunEid in gun_eids
    ammo += count_gun_ammo(gunEid)
  return ammo

def setup_ammo_stowage(ammo_stowage_eid : EntityId)
  query(ammo_stowage_eid) <| $ [es] (ammo_stowage__gunEids : EidList;
                                     ammo_stowage__clusters : EidList;
                                     var ammo_stowage__numAmmo : int&)
    let stowageAmmo = count_ammo(ammo_stowage__gunEids)

    if stowageAmmo > ammo_stowage__numAmmo
      restore_slots(ammo_stowage__clusters)
    ammo_stowage__numAmmo = stowageAmmo

    var numShells = ammo_stowage__numAmmo
    var numCharges = ammo_stowage__numAmmo

    let numClusters = length(ammo_stowage__clusters)
    for i in iter_range(ammo_stowage__clusters)
      let clusterEid = ammo_stowage__clusters[numClusters - i - 1]
      let isShell = get_bool(clusterEid, "ammo_cluster__isShell") ?? true
      if isShell
        numShells = setup_ammo_cluster(clusterEid, numShells)
      else
        numCharges = setup_ammo_cluster(clusterEid, numCharges)

[es(tag=server, on_appear, track=gun__ammo_by_shell, REQUIRE=gun__ammo_by_shell)]
def setup_ammo_stowage_on_ammo_changed(evt : Event; turret__ammoStowageEid : EntityId)
  setup_ammo_stowage(turret__ammoStowageEid)


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
