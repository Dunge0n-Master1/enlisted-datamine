require app
require ecs
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common


[es(tag=sound, track=building_action__target)]
def building_disassemble_sound(evt : Event;
                               building_action__target : EntityId;
                               var sound_event_group : SoundEventGroup&;
                               transform : float3x4)
  reject_sound(sound_event_group, sound_hash("buildingDisassemble"))
  query(building_action__target) <| $ [es] (building_destroy__disassembleSound : string)
    sound_player_common::play_name_path("", building_destroy__disassembleSound, sound_hash("buildingDisassemble"), transform[3], sound_event_group)
