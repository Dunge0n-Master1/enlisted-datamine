require ecs
require ecs.common
require DagorSystem

def get_shells_ammo_by_distribution(eid : EntityId; distribution : Array; slot_count : int; total : int)
  var fillSlots : array<int>
  for distributionElement in distribution
    let distributionObj = get_ecs_object(distributionElement)
    if distributionObj == null
      logerr("{getEntityTemplateName(eid)}: Cannot read object from gun.initAmmoDistribution")
      continue
    let slotId = get_int(distributionObj, "slot") ?? -1
    if slotId < 0
      logerr("{getEntityTemplateName(eid)}: Wrong format of gun.initAmmoDistribution element, 'slot' should be >= 0: {slotId}")
      continue
    let fill = get_bool(distributionObj, "fill") ?? false
    if fill && slotId < slot_count
      push(fillSlots, slotId)

  var resultShellsAmmo : array<int>
  resize(resultShellsAmmo, slot_count)

  let fillSlotCount = length(fillSlots)
  if fillSlotCount > 0
    let fillAmount = total / fillSlotCount
    let remainder = total - fillAmount * fillSlotCount
    var minSlot = fillSlots[0]
    for slot in fillSlots
      resultShellsAmmo[slot] = fillAmount
      if slot < minSlot
        minSlot = slot
    resultShellsAmmo[minSlot] += remainder

  return <- resultShellsAmmo

def set_ammo_by_distribution(eid : EntityId; ammo_distribution : Array; var gun__shellsAmmo : Array&)
  let slotCount = length(gun__shellsAmmo)

  var totalAmmo = 0
  for shellsAmmo in gun__shellsAmmo
    totalAmmo += get_int(shellsAmmo) ?? 0

  let resultShellsAmmo <- get_shells_ammo_by_distribution(eid, ammo_distribution, slotCount, totalAmmo)

  clear(gun__shellsAmmo)
  for shellCount in resultShellsAmmo
    push(gun__shellsAmmo, shellCount)

[es(tag=server, on_appear, before=turret_gun_es, REQUIRE=(turretWithSeveralTypeOfShells, isTurret))]
def turret_ammo_distribution(evt : Event;
                             eid : EntityId;
                             turret__owner : EntityId;
                             var gun__shellsAmmo : Array&)
  query(turret__owner) <| $ [es] (turrets__initAmmoDistribution : Array)
    set_ammo_by_distribution(eid, turrets__initAmmoDistribution, gun__shellsAmmo)

[es(tag=server, on_appear, before=turret_gun_es, REQUIRE=isTurret, REQUIRE_NOT=turretWithSeveralTypeOfShells)]
def turret_ammo_distribution_for_machineguns(evt : Event;
                                             eid : EntityId;
                                             turret__owner : EntityId;
                                             var gun__shellsAmmo : Array&)
  query(turret__owner) <| $ [es] (turrets__initAmmoDistributionMachineguns : Array)
    set_ammo_by_distribution(eid, turrets__initAmmoDistributionMachineguns, gun__shellsAmmo)
