require ecs
require ecs.common
require WeapHelpers
require EnlistedHuman
require common_shooter.events_common_shooter
require enlisted.events_enlisted


[es(tag=server)]
def gun_on_next_shell_type_request(evt : RequestNextGunAmmoHolderType;
                                   eid : EntityId;
                                   human_net_phys : HumanActor;
                                   human_weap__currentGunEid : EntityId)
  query(human_weap__currentGunEid) <| $ [es] (gun__ammoHolderIds : IntList;
                                              gun__ammoByHolders : IntList;
                                              gun__itemIdByHolders : IntList;
                                              gun__curAmmoHolderIndex : int)
    let ammoHoldersCount = length(gun__ammoHolderIds)
    if ammoHoldersCount > 0
      for i in range(0, ammoHoldersCount - 1)
        let wishAmmoHolderType = (gun__curAmmoHolderIndex + i + 1) % ammoHoldersCount
        if gun__ammoByHolders[wishAmmoHolderType] > 0
          if wishAmmoHolderType != gun__curAmmoHolderIndex
            sendEvent(eid, [[CmdSetWishAmmoItemType
              slot_id=int(human_net_phys.phys.appliedCT.chosenWeapon),
              item_id=gun__itemIdByHolders[wishAmmoHolderType]
            ]])
          return


[es(on_appear, track=(gun__ammoHolderEid, gun__ammoHolderIds))]
def gun_track_cur_ammo_type(evt : Event;
                            gun__ammoHolderIds : IntList;
                            gun__ammoHolderEid : EntityId;
                            var gun__curAmmoHolderIndex : int&)
  gun__curAmmoHolderIndex = -1
  query(gun__ammoHolderEid) <| $ [es] (ammo_holder__id : int)
    gun__curAmmoHolderIndex = find_index(gun__ammoHolderIds, ammo_holder__id)


def fill_info_about_ammoholder(item_eid : EntityId;
                               is_count_ammo : bool;
                               var ammo_by_holder : table<int; int>&;
                               var icon_by_holder : table<int; string>&;
                               var item_id_by_holders : table<int; int>&)
  query(item_eid) <| $ [es] (item__id : int;
                             ammo_holder__id : int;
                             ammo_holder__ammoCount : int;
                             ammo_holder__iconName : string = "")
    if is_count_ammo
      ammo_by_holder[ammo_holder__id] += ammo_holder__ammoCount
    icon_by_holder[ammo_holder__id] = ammo_holder__iconName
    item_id_by_holders[ammo_holder__id] = item__id


[es(on_appear, track=(itemContainer, human_weap__currentGunEid))]
def gun_track_ammo_holders(evt : Event;
                           itemContainer : EidList;
                           human_weap__currentGunEid : EntityId)
  query(human_weap__currentGunEid) <| $ [es] (gun__ammoHolderIds : IntList;
                                              gun__ammoHolderEid : EntityId;
                                              gun__shell_prop_ids : GunShellPropIds;
                                              var gun__ammoByHolders : IntList&;
                                              var gun__iconByHolders : StringList&;
                                              var gun__itemIdByHolders : IntList&)
    clear(gun__ammoByHolders)
    clear(gun__iconByHolders)
    clear(gun__itemIdByHolders)
    resize(gun__ammoByHolders, length(gun__ammoHolderIds))
    resize(gun__iconByHolders, length(gun__ammoHolderIds))
    resize(gun__itemIdByHolders, length(gun__ammoHolderIds))

    var ammoByHolder : table<int; int>
    var iconByHolder : table<int; string>
    var itemIdByHolders : table<int; int>
    for itemEid in itemContainer
      if is_item_ammo_for_gun(itemEid, gun__ammoHolderIds, gun__shell_prop_ids)
        fill_info_about_ammoholder(itemEid, true, ammoByHolder, iconByHolder, itemIdByHolders)
    fill_info_about_ammoholder(gun__ammoHolderEid, false, ammoByHolder, iconByHolder, itemIdByHolders)

    for i, ammoHolderId in iter_range(gun__ammoHolderIds), gun__ammoHolderIds
      gun__ammoByHolders[i] = ammoByHolder[ammoHolderId]
      gun__iconByHolders[i] := iconByHolder[ammoHolderId]
      gun__itemIdByHolders[i] = itemIdByHolders[ammoHolderId]
