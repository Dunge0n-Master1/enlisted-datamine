require ecs
require ecs.common
require soundHash

[es(tag=server, after=human_sound_tags_es, track=human_equipment__slots, on_appear, on_event=CmdTrackHeroWeapons)]
def human_sound_net_tags_track_equipment(evt : Event;
                                         human_equipment__slots : Object;
                                         var human_sound_net_tags__equipmentList : StringList&)
  human_sound_net_tags__equipmentList |> clear()
  for it in human_equipment__slots
    let slot = get_ecs_object(it.value)
    if slot != null
      if (get_Eid(*slot, "item") ?? INVALID_ENTITY_ID) != INVALID_ENTITY_ID
        let tag = get_string(*slot, "soundTag", "")
        if tag != "" && find_index(human_sound_net_tags__equipmentList, tag) == -1
          human_sound_net_tags__equipmentList |> push(tag)
