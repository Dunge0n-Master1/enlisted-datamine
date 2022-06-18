require ecs
require EnlistedNet
require game.es.events
require inventory
require common_shooter.events_common_shooter

[es(tag=server)]
def container_item_used_es(evt : EventOnLootItemUsed; containerContents : StringList)
  let entityEid = evt.target
  for str in containerContents
    let callback <- @ <| (eid : EntityId)
      insert_item(entityEid, eid)
    createEntity(string(str), callback) <| $ [unused_argument(init)] (init){}

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

[es(tag=server, REQUIRE=item__restoreBreath)]
def restore_breath_item_used_es(evt : EventOnLootItemUsed)
  query(evt.target) <| $ [es] (var human_breath__timer : float&)
    human_breath__timer = 0f
