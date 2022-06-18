require ecs
require game.utils.sound_utils

[es(tag=server, on_event=EventOnDestroyBuilding)]
def building_destroy_net_sound(evt : Event;
                               transform : float3x4)
  play_scene_net_sound("fortificationBuildingDestroy", transform[3])
