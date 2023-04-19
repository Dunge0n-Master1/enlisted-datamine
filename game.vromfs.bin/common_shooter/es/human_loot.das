require ecs
require DngNet
require game.es.events
require inventory
require common_shooter.events_common_shooter


[es(tag=server)]
def heal_item_used_es(evt : EventOnLootItemUsed; item__healAmount : float)
  let targetEid = evt.target
  query(targetEid) <| $ [es] (isDowned : bool;
                              isAlive : bool)
    if isDowned || !isAlive // codegen bug fix
      return
    if item__healAmount > 0f
      send_net_event(targetEid, [[CmdRestoreEntityHp restoreHp=item__healAmount]])

[es(tag=server)]
def stamina_restore_item_used_es(evt : EventOnLootItemUsed;
                                 item__staminaRestoreAmount : float)
  // we send an event to set stamina on both client and server instead of setting it directly on the server to avoid human phys sync delay
  // it is slow enough that a player can notice a delay between flask use and stamina increase even with a really small ping
  send_net_event(evt.target, [[CmdRestoreStamina restoreStamina=item__staminaRestoreAmount]])

