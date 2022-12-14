require ecs
require ecs.safe
require ecs.common
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common
require strings


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
      ecs::query(human_inventory__entityToUse) <| $ [es] (item__lootSoundType : string; item__usingSoundType : string = "")
        let lootSoundType = empty(item__usingSoundType) ? item__lootSoundType : item__usingSoundType
        let path = "using_{lootSoundType}"
        let objPtr = net_sound__descs[path] ?as Object
        if objPtr != null
          assume obj = *objPtr
          let nameRef = is_watched_sound ? (has(obj, "hero") ? obj["hero"] : obj["path"]) : (has(obj, "enemy") ? obj["enemy"] : obj["path"])
          if nameRef != null
            let name = (*nameRef) ?? ""
            sound_player_common::play_name_path(name, "", sound_hash("loot"), transform[3], sound_event_group)
          return
