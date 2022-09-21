require ecs
require ecs.common

def add_watched_by_player_tag(eid : EntityId; add_tag : bool)
  if eid == INVALID_ENTITY_ID
    return
  let itemHasTag = has(eid, "watchedPlayerItem")
  if add_tag && !itemHasTag
    addSubTemplate(eid, "watched_by_player_item")
  elif !add_tag && itemHasTag
    removeSubTemplate(eid, "watched_by_player_item")


def set_watched_by_player_components(items_list : EidList; add_tag : bool)
  for itemEid in items_list
    add_watched_by_player_tag(itemEid, add_tag)


def set_watched_by_player_components(mods_array : Array; add_tag : bool)
  for mod in mods_array
    let gunMods = mod |> get_ecs_EidList()
    if gunMods != null
      for gunModEid in *gunMods
        add_watched_by_player_tag(gunModEid, add_tag)


def has_eid_in_mods_list(mods_array : Array; eid : EntityId)
  for mod in mods_array
    let gunMods = mod |> get_ecs_EidList()
    if gunMods != null
      if find_index(*gunMods, eid) != -1
        return true
  return false


[es(tag=gameClient, track=(human_weap__gunEids, itemContainer, human_weap__gunMods), REQUIRE=watchedByPlr)]
def watched_by_player_change_inventory(evt : Event;
                                       itemContainer : EidList;
                                       human_weap__gunMods : Array;
                                       human_weap__gunEids : EidList)
  query() <| $ [es(REQUIRE=watchedPlayerItem)] (eid : EntityId)
    let isWatchedByPlayerItem = (find_index(itemContainer, eid) != -1 ||
                                 find_index(human_weap__gunEids, eid) != -1 ||
                                 has_eid_in_mods_list(human_weap__gunMods, eid))
    if !isWatchedByPlayerItem
      removeSubTemplate(eid, "watched_by_player_item")
  set_watched_by_player_components(itemContainer, true)
  set_watched_by_player_components(human_weap__gunEids, true)
  set_watched_by_player_components(human_weap__gunMods, true)


//gun created after owner
[es(tag=gameClient, on_appear, REQUIRE_NOT=watchedPlayerItem)]
def watched_by_player_gun_created(evt : Event;
                                  eid : EntityId;
                                  gun__owner : EntityId)
  if has(gun__owner, "watchedByPlr")
    addSubTemplate(eid, "watched_by_player_item")


//item created after owner
[es(tag=gameClient, on_appear, REQUIRE_NOT=watchedPlayerItem)]
def watched_by_player_item_created(evt : Event;
                                   eid : EntityId;
                                   item__ownerEid : EntityId)
  if has(item__ownerEid, "watchedByPlr")
    addSubTemplate(eid, "watched_by_player_item")


//mod created after gun
[es(tag=gameClient, on_appear, REQUIRE=weaponMod, REQUIRE_NOT=watchedPlayerItem)]
def watched_by_player_mod_created(evt : Event;
                                  eid : EntityId;
                                  slot_attach__attachedTo : EntityId)
  query(slot_attach__attachedTo) <| $ [es] (gun__owner : EntityId)
    if has(gun__owner, "watchedByPlr")
      addSubTemplate(eid, "watched_by_player_item")


//gun created after mod
[es(tag=gameClient, on_appear, REQUIRE=watchedPlayerItem)]
def watched_by_player_mod_gun_created(evt : Event;
                                      eid aka gun_eid : EntityId)
  query() <| $ [es(REQUIRE=weaponMod)] (eid : EntityId;
                                        slot_attach__attachedTo : EntityId)
    if gun_eid == slot_attach__attachedTo
      addSubTemplate(eid, "watched_by_player_item")


[es(tag=gameClient, on_appear, REQUIRE=watchedByPlr)]
def watched_by_player_inventory(evt : Event;
                                itemContainer : EidList;
                                human_weap__gunMods : Array;
                                human_weap__gunEids : EidList)
  set_watched_by_player_components(itemContainer, true)
  set_watched_by_player_components(human_weap__gunEids, true)
  set_watched_by_player_components(human_weap__gunMods, true)


[es(tag=gameClient, on_disappear, REQUIRE=watchedByPlr)]
def watched_by_player_inventory_remove_tag(evt : Event;
                                           itemContainer : EidList;
                                           human_weap__gunMods : Array;
                                           human_weap__gunEids : EidList)
  set_watched_by_player_components(itemContainer, false)
  set_watched_by_player_components(human_weap__gunEids, false)
  set_watched_by_player_components(human_weap__gunMods, false)