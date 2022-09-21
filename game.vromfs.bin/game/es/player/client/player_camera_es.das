require ecs
require EnlistedCamera
require game.es.camera_common
require game.es.events
require game.events_game


def enable_spectator_camera(target : EntityId;
                            possessed : EntityId;
                            team : int;
                            var activeCamEid : EntityId&;
                            var activeCamName : das_string&;
                            waitingForRespawn = false)
  if waitingForRespawn && (possessed |> get_bool("isAlive") ?? false)
    return
  print("Enable spectator camera for camera entity {int(uint(activeCamEid))}")
  if possessed != INVALID_ENTITY_ID
    removeSubTemplate(possessed, "observed_local")
  let camTm = get_TMatrix(get_cur_cam_entity(), "transform")
  if camTm == null
    return
  var spectatedTeam = team
  query(target) <| $ [es] (team : int)
    spectatedTeam = team
  let specCam : EntityId = enable_spectator_camera(*camTm, spectatedTeam, target)
  if activeCamEid != specCam
    destroyEntity(activeCamEid)
  activeCamEid = specCam
  activeCamName := ""

[es(tag=gameClient)]
def target_enable_spectator_camera(evt : EnableSpectatorForTarget; eid : EntityId)
  query(evt.player) <| $ [es] (possessed : EntityId;
                               team : int;
                               var activeCamEid : EntityId&;
                               var activeCamName : das_string&;
                               waitingForRespawn = false)
    enable_spectator_camera(eid, possessed, team, activeCamEid, activeCamName, waitingForRespawn)

[es(tag=gameClient)]
def player_enable_spectator_camera(evt : EnableSpectatorForPlayer;
                                   possessed : EntityId;
                                   team : int;
                                   var activeCamEid : EntityId&;
                                   var activeCamName : das_string&;
                                   waitingForRespawn = false)
  enable_spectator_camera(evt.target, possessed, team, activeCamEid, activeCamName, waitingForRespawn)

def player_switch_camera(player_eid : EntityId; target_eid : EntityId; activeCamEid : EntityId; idx : int = -1;
                         cam_names_eid : EntityId = INVALID_ENTITY_ID)
  query(target_eid) <| $ [es] (activeCamIdx : int; human__lockSwitchCamera : bool = false)
    if !human__lockSwitchCamera && activeCamEid == get_cur_cam_entity()
      possess_entity_camera_smooth(target_eid, (idx != -1) ? idx : (activeCamIdx + 1), player_eid, cam_names_eid)

[es(on_event=CmdSwitchCamera, tag=gameClient)]
def player_switch_camera_next(evt : Event; eid : EntityId; possessed : EntityId; activeCamEid : EntityId)
  if possessed |> has("bindedCamera")
    player_switch_camera(eid, possessed, activeCamEid);

[es(tag=gameClient)]
def player_switch_camera_by_index(evt : CmdSwitchCameraByIndex; eid : EntityId; possessed : EntityId; activeCamEid : EntityId)
  if possessed |> has("bindedCamera")
    player_switch_camera(eid, possessed, activeCamEid, evt.index);

[es(tag=gameClient)]
def player_switch_camera_by_entity(evt : CmdSwitchCameraByEntity; eid : EntityId; possessed : EntityId; activeCamEid : EntityId)
  if possessed |> has("bindedCamera")
    player_switch_camera(eid, possessed, activeCamEid, evt.index, evt.camNamesEid);
