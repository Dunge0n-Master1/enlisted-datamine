require game.es.events
require ecs
require DngNet
require inventory
require DngDm
require common_shooter.events_common_shooter
require game.events_game

[es]
def human_inventory_revive_es(evt : CmdUse;
                              eid : EntityId;
                              isDowned : bool)
  if !isDowned
    return

  let reviver = evt.requesterEid
  query(reviver) <| $ [es(REQUIRE=human_inventory)] (itemContainer : EidList)
    var nonTargetUseOnlyItem = INVALID_ENTITY_ID
    for itemEid in itemContainer
      var itemUsed = false
      query(itemEid) <| $ [es] (item__reviveAmount : float;
                                item__useTimeToTarget : float;
                                item__targetUseOnly : Tag const?)
        if item__reviveAmount > 0.0f && item__useTimeToTarget > 0.0f
          // prioritize items whicn can only be used on others.
          // if found, use it immidiately and we are done.
          // otherwise find an item which can be used on anyone and use at in the end.
          if item__targetUseOnly != null
            sendEvent(reviver, [[EventUseItem item=itemEid, target=eid]])
            itemUsed = true
          else
            nonTargetUseOnlyItem = itemEid

      if itemUsed
        return

    if nonTargetUseOnlyItem != INVALID_ENTITY_ID
      sendEvent(reviver, [[EventUseItem item=nonTargetUseOnlyItem, target=eid]])


[es(tag=server)]
def revive_item_used_es(evt : EventOnLootItemUsed;
                        item__reviveAmount : float)
  let targetEid = evt.target
  query(targetEid) <| $ [es] (isDowned : bool)
    if item__reviveAmount > 0.0f && isDowned
      send_net_event(targetEid, [[CmdRestoreEntityHp restoreHp=item__reviveAmount]])
