require ecs
require ecs.common
require app
require soundHash
require soundEvent
require game.es.events
require game.es.sound_net.sound_net_events
require sound_utils.modules.sound_utils_events
require game.utils.hero

def play_sound(human_eid : EntityId; hash : uint; transform : float3x4; var loot_sound__time : float&)
  if get_sync_time() > loot_sound__time + 0.1
    loot_sound__time = get_sync_time()
    if should_play(transform[3])
      sendEvent(human_eid, [[CmdPlaySound hash=hash, pos=transform[3]]])

[es(tag=sound)]
def loot_sound(cmd : CmdPlayLootSound; eid : EntityId; transform : float3x4; var loot_sound__time : float&)
  if get_sync_time() < cmd.time + 5.
    play_sound(eid, cmd.hash, transform, loot_sound__time)

[es(tag=sound)]
def loot_sound_enemy(cmd : CmdPlayLootSoundForEnemy; eid : EntityId; transform : float3x4; var loot_sound__time : float&)
  if get_sync_time() < cmd.time + 5.
    play_sound(eid, cmd.hash, transform, loot_sound__time)

[es(tag=sound)]
def loot_sound_pickup(evt : EventOnLootPickup; eid : EntityId; transform : float3x4; var loot_sound__time : float&)
  let lootSoundType = get_string(evt.itemEid, "item__lootSoundType", "other")
  play_sound(eid, sound_hash("pick_{lootSoundType}"), transform, loot_sound__time)

[es(tag=sound)]
def loot_sound_drop(evt : EventOnLootDrop; eid : EntityId; transform : float3x4; is_watched_sound : bool; var loot_sound__time : float&)
  if is_watched_sound
    let lootSoundType = get_string(evt.itemEid, "item__lootSoundType", "other")
    play_sound(eid, sound_hash("drop_{lootSoundType}"), transform, loot_sound__time)

[es(tag=sound, REQUIRE=hero)]
def loot_sound_inventory_pickup(evt : CmdInventoryPickup)
  query(evt.itemEid) <| $ [es] (item__isInUse = false)
    if !item__isInUse
      sendEvent(evt.itemEid, [[CmdPlaySoundSimple hash=sound_hash("inventoryPickup")]])
