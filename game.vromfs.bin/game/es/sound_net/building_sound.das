require app
require ecs
require game.utils.sound_utils
require strings


[es(on_appear, tag=server, REQUIRE_NOT=builder_preview)]
def building_sound(evt : Event;
                   buildingSoundTag : string;
                   buildByEngineerEid : EntityId;
                   transform : float3x4)
  if !empty(buildingSoundTag) && buildByEngineerEid != INVALID_ENTITY_ID
    play_net_sound_pos(buildByEngineerEid, "createBuilding_{buildingSoundTag}", transform[3])
