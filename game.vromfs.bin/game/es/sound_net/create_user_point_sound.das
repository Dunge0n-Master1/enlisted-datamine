require app
require ecs
require game.utils.sound_utils

[es(on_appear, tag=server)]
def create_user_point_sound_es(evt : Event;
                               userPointOwner : EntityId;
                               userPointType : string;
                               silentAppearance : bool;
                               transform : float3x4)
  if userPointType != "" && !silentAppearance
    query(userPointOwner) <| $ [es] (possessed : EntityId)
      play_net_sound_pos(possessed, "uiMap_{userPointType}", transform[3])