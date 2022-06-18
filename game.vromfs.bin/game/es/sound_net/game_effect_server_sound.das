require ecs
require game.utils.sound_utils

[es(tag=server, on_appear)]
def game_effect_server_sound__appear(evt : Event;
                                     game_effect__attachedTo : EntityId;
                                     game_effect_server_sound__appear : string)
  play_net_sound(game_effect__attachedTo, game_effect_server_sound__appear)
