require ecs
require ecs.safe
require ecs.common
require soundHash

[es(tag=server, after=human_sound_tags_es, track=human_equipment__slots, on_appear, on_event=CmdTrackHeroWeapons)]
def human_sound_net_tags_track_equipment(evt : Event;
                                         human_equipment__slots : Object;
                                         var human_sound_net_tags__equipmentList : StringList&)
  human_sound_net_tags__equipmentList |> clear()
  for it in human_equipment__slots
    let slot = it.value as Object
    if slot != null
      if ((*slot).item ?? INVALID_ENTITY_ID) != INVALID_ENTITY_ID
        let tag = (*slot).soundTag ?? ""
        if tag != "" && find_index(human_sound_net_tags__equipmentList, tag) == -1
          human_sound_net_tags__equipmentList |> push(tag)
