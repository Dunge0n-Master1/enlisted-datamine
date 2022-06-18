module spectator_common shared
require ecs
require ecs.common
require EnlistedNet
require DagorMath
require strings
require EnlistedCamera
require player
require game.events_game


def set_spectated(cam_eid : EntityId; var spectatedEid : EntityId&; new_eid : EntityId; initial : bool = false) : void
  if initial == false
    if spectatedEid == new_eid
      return
    if spectatedEid != INVALID_ENTITY_ID
      removeSubTemplate(spectatedEid, "observed_local")
  spectatedEid = new_eid
  if new_eid == INVALID_ENTITY_ID
    return
  if find(getEntityTemplateName(new_eid), "+observed_local") == -1
    let bind_camera_to_entity <- @ <| (spec_target : EntityId)
      bind_camera_to_entity(cam_eid, spec_target)
    addSubTemplate(new_eid, "observed_local", bind_camera_to_entity) <| $(var init : ComponentsInitializer)
      init |> set("watchedByPlr", get_local_player_eid())
      init |> set("bindedCamera", cam_eid)
  else
    bind_camera_to_entity(cam_eid, new_eid)
  send_net_event(get_local_player_eid(), [[EventSpectateTarget target_eid=new_eid]])
