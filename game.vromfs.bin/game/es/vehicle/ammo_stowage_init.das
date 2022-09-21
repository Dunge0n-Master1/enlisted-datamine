require ecs
require dm
require ecs.common
require DagorSystem
require common_shooter.events_common_shooter

[es(tag=server, on_appear, before=turret_control_create_guns_es)]
def ammo_stowage_init_stowages(evt : Event;
                               eid : EntityId;
                               [[shared_comp]] ammo_stowage__stowageTemplates : StringList;
                               var ammo_stowage__stowages : EidList&)
  for stowageTemplate in ammo_stowage__stowageTemplates
    let stowageEid = createEntity(string(stowageTemplate)) <| $(var init)
      init |> set("ammo_stowage__vehicleEid", eid)
    ammo_stowage__stowages |> push(stowageEid)

[es(tag=server, on_appear)]
def ammo_stowage_init_clusters(evt : Event;
                               [[shared_comp]] ammo_stowage__clusterTemplates : StringList;
                               ammo_stowage__vehicleEid : EntityId;
                               var ammo_stowage__clusters : EidList&)
  for clusterTemplate in ammo_stowage__clusterTemplates
    let clusterEid = createEntity(string(clusterTemplate)) <| $(var init)
      init |> set("ammo_cluster__vehicleEid", ammo_stowage__vehicleEid)
    ammo_stowage__clusters |> push(clusterEid)

[es(tag=server, on_disappear)]
def delete_ammo_stowages(evt : Event; ammo_stowage__stowages : EidList)
  for stowageEid in ammo_stowage__stowages
    destroyEntity(stowageEid)

[es(tag=server, on_disappear)]
def delete_ammo_clusters(evt : Event; ammo_stowage__clusters : EidList)
  for clusterEid in ammo_stowage__clusters
    destroyEntity(clusterEid)

[es(tag=server, on_appear)]
def ammo_cluster_init(evt : Event;
                      eid : EntityId;
                      ammo_cluster__vehicleEid : EntityId;
                      [[shared_comp]] ammo_cluster__slotNames : StringList;
                      var ammo_cluster__slotsAmmo : IntList&;
                      var ammo_cluster__slotsMaxAmmo : IntList&;
                      var ammo_cluster__slotsEnabled : BoolList&;
                      var ammo_cluster__mapSlotToPartId : IntList&)
  let slotNum = length(ammo_cluster__slotNames)
  ammo_cluster__mapSlotToPartId |> resize(slotNum)
  ammo_cluster__slotsEnabled |> resize(slotNum)
  ammo_cluster__slotsAmmo |> resize(slotNum)

  for i in iter_range(ammo_cluster__slotsEnabled)
    ammo_cluster__slotsEnabled[i] = true
  if length(ammo_cluster__slotsMaxAmmo) != slotNum
    logerr("Invalid ammo_cluster format in template {getEntityTemplateName(eid)}: ammo_cluster__slotsMaxAmmo should have same number of elements as ammo_cluster__slotNames")
    ammo_cluster__slotsMaxAmmo |> resize(slotNum)

  for i in iter_range(ammo_cluster__mapSlotToPartId)
    ammo_cluster__mapSlotToPartId[i] = -1

  query(ammo_cluster__vehicleEid) <| $ [es] (damage_model : DamageModel)
    for i, partName in iter_range(ammo_cluster__slotNames), ammo_cluster__slotNames
      if partName != ""
        let partId = find_part_id_by_name(damage_model, string(partName))
        ammo_cluster__mapSlotToPartId[i] = partId
        if partId < 0
          logerr("ammo stowage: ammo part {partName} not found in template {getEntityTemplateName(ammo_cluster__vehicleEid)}")


def connect_gun_to_ammo_stowage(ammo_stowage__stowages : EidList; gun_eid : EntityId)
  query(gun_eid) <| $ [es] (turret__name : string)
    var isStowageFound = false
    for stowageEid in ammo_stowage__stowages
      query(stowageEid) <| $ [es] ([[shared_comp]] ammo_stowage__turretNames : StringList; var ammo_stowage__gunEids : EidList&)
        isStowageFound = find_index(ammo_stowage__turretNames, turret__name) >= 0
        if isStowageFound
          ammo_stowage__gunEids |> push(gun_eid)
          addSubTemplate(gun_eid, "turret_with_ammo_stowage") <| $(var init)
            set(init, "turret__ammoStowageEid", stowageEid)
      if isStowageFound
        return

[es(tag=server, after=ammo_stowage_init_stowages)]
def connect_gun_to_ammo_stowage_on_gun_created(evt : EventOnGunCreated; ammo_stowage__stowages : EidList)
  ammo_stowage__stowages |> connect_gun_to_ammo_stowage(evt.gunEid)
