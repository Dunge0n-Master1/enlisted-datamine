require ecs
require ecs.common
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common

[es(tag=sound, track=(human_inventory__entityToUse, isAlive), REQUIRE=humanSound)]
def human_using_item_sound(evt : Event;
                           [[shared_comp]] net_sound__descs : Object;
                           human_inventory__entityToUse : EntityId;
                           var sound_event_group : SoundEventGroup&;
                           is_watched_sound : bool;
                           transform : float3x4;
                           isAlive : bool)
  reject_sound(sound_event_group, sound_hash("loot"))
  if human_inventory__entityToUse != INVALID_ENTITY_ID && isAlive
    if should_play(transform[3])
      ecs::query(human_inventory__entityToUse) <| $ [es] (item__usingSoundType : string = ""; item__lootSoundType : string)
        let hash = item__usingSoundType != "" ? sound_hash(item__usingSoundType) : sound_hash("using_{item__lootSoundType}")
        for it in net_sound__descs
          if sound_hash(it.key) == hash
            let objPtr = get_ecs_object(it.value)
            assume obj = *objPtr
            let nameRef = is_watched_sound ? (has(obj, "hero") ? obj["hero"] : obj["path"]) : (has(obj, "enemy") ? obj["enemy"] : obj["path"])
            if nameRef != null
              let name = get_string(nameRef, "")
              sound_player_common::play_name_path(name, "", sound_hash("loot"), transform[3], sound_event_group)
            return
