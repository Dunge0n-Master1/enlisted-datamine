require ecs
require game.events_game
require game.utils.team
require HumanPhys
require inventory
require enlisted.events_enlisted

[es(tag=server, after=human_inventory_fill_guns_custom_props_on_death)]
def drop_held_weapon_on_death(evt : EventEntityDied;
                              eid : EntityId;
                              human_weap__gunEids : EidList)
  let isDropRestricted = is_teams_friendly(evt.victimTeam, evt.offenderTeam) && find_query() <| $ [es(REQUIRE=disableTeamkillWeaponDrops)] () => true
  if !isDropRestricted && !has(human_weap__gunEids[int(HUWeaponSlots EWS_PRIMARY)], "disableItemDrop")
    drop_weap_from_slot(eid, int(HUWeaponSlots EWS_PRIMARY), /*reset_weap*/true, /*can_drop_from_dead*/true)


[es(tag=server, REQUIRE_NOT=deadEntity)]
def human_inventory_use_flask(evt : CmdFlaskUse;
                              eid : EntityId;
                              itemContainer : EidList;
                              isPassenger : bool;
                              isInVehicle : bool;
                              burning__isBurning : bool = false;
                              isDowned : bool = false)
  if length(itemContainer) == 0 || isDowned || (isInVehicle && !isPassenger) || burning__isBurning
    return

  for item in itemContainer
    if has(item, "flask")
      sendEvent(eid, [[EventUseItem item=item, target=INVALID_ENTITY_ID]])
      return


[es(tag=server, REQUIRE_NOT=deadEntity)]
def human_inventory_use_flask_cancel(evt : CmdFlaskUseCancel; eid : EntityId)
  inventory::stop_use_item(eid)
