require ecs
require game.events_game

[es(tag=gameClient)]
def reset_camera_relative_dir_es(evt : CmdSwitchCamera; possessed : ecs::EntityId)
  let vehicleEid = get_Eid(possessed, "human_anim__vehicleSelected") ?? INVALID_ENTITY_ID
  if vehicleEid != INVALID_ENTITY_ID
    if has(vehicleEid, "camera__relative_angle")
      set(vehicleEid, "camera__relative_angle", float2())
    if has(vehicleEid, "camera__wish_relative_angle")
      set(vehicleEid, "camera__wish_relative_angle", float2())
