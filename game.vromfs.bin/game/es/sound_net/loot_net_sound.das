require ecs
require ecs.common
require app
require EnlistedNet
require soundHash
require game.es.events
require game.es.sound_net.sound_net_events
require game.utils.net_utils
require game.utils.sound_utils

let DEF_LOOT_RANGE : float = 20.

[es(tag=server)]
def loot_net_sound_on_loot_pickup(evt : EventOnLootPickup; eid : EntityId)
  let lootSoundType = get_string(evt.itemEid, "item__lootSoundType", "other")
  send_net_event(eid, [[CmdPlayLootSoundForEnemy hash=sound_hash("pick_{lootSoundType}"), time=get_sync_time()]],
                 target_entity_pos_range_except_hero(eid, /*range*/ DEF_LOOT_RANGE, /*is_player_relative*/ true))

[es(tag=server)]
def loot_net_sound_on_loot_use(evt : EventOnLootUse; eid : EntityId)
  let lootSoundType = get_string(evt.itemEid, "item__lootSoundType", "other")
  send_net_event(eid, [[CmdPlayLootSound hash=sound_hash("use_{lootSoundType}"), time=get_sync_time()]],
                 target_entity_pos_range(eid, /*range*/ DEF_LOOT_RANGE, /*is_player_relative*/ true))
