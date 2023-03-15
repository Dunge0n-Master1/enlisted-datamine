require ecs
require ecs.common
require sound_utils.modules.sound_player_common


[es(tag=sound, track=human_sound_net_tags__equipmentList, on_appear)]
def human_sound_tags_track_equipment(evt : Event;
                                     human_sound_net_tags__equipmentList : StringList;
                                     var human_sound__allEquipmentTags : StringList&;
                                     var sound_tags : Object&)
  for tag in human_sound_net_tags__equipmentList
    if find_index(human_sound__allEquipmentTags, tag) == -1
      human_sound__allEquipmentTags |> push(tag)
  for tag in human_sound__allEquipmentTags
    clear_sound_tag(string(tag), sound_tags)
  for tag in human_sound_net_tags__equipmentList
    raise_sound_tag(string(tag), sound_tags)


[es(tag=sound, on_appear)]
def human_sound_tags_on_appear(evt : Event;
                               human_voice_sound__voiceTag : string;
                               var sound_tags : Object&)
  raise_sound_tag(human_voice_sound__voiceTag, sound_tags)
