require ecs
require sound_utils.modules.sound_player_common

[es(tag=sound, track=building_action__target)]
def human_sound_building_action_tag(evt : Event;
                                    building_action__target : EntityId;
                                    var sound_tags : Object&;
                                    var human_sound__buildingTag : das_string&)
  clear_sound_tag(string(human_sound__buildingTag), sound_tags)
  query(building_action__target) <| $ [es] (buildingSoundTag : string)
    human_sound__buildingTag := "build_{buildingSoundTag}"
  raise_sound_tag(string(human_sound__buildingTag), sound_tags)
