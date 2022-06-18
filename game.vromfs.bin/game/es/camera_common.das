module camera_common shared
require ecs
require math.base
require EnlistedCamera


def get_cam_itm(var tm : float3x4)
  query(get_cur_cam_entity()) <| $ [es] (transform : float3x4)
    tm = transform


def get_cam_itm()
  var tm : float3x4
  get_cam_itm(tm)
  return tm


def get_cam_pos()
  var tm = IDENT_TM
  get_cam_itm(tm)
  return tm[3]


def get_player_cam_name(player_eid : EntityId)
  var out_name = ""
  query(player_eid) <| $ [es] (activeCamEid : EntityId; activeCamName : string)
    if !!activeCamEid
      out_name = activeCamName
  return out_name

def possess_entity_camera_smooth(actor_eid : EntityId; cam_idx : int; player_eid : EntityId; cam_names_eid : EntityId)
  unsafe
    let wasCamName = clone_string(get_player_cam_name(player_eid))

    possess_entity_camera(actor_eid, cam_idx, player_eid, cam_names_eid)

    let newCamName = get_player_cam_name(player_eid)

    if wasCamName != newCamName
      query(player_eid) <| $ [es] (activeCamEid : EntityId)
        query(activeCamEid) <| $ [es] (camera__smoothFromCams : ecs::Array; var shooter_cam__tauInc : float&; shooter_cam__tauOnChange : float)
          for camobj in camera__smoothFromCams
            let cam = get_ecs_object(camobj)
            let camName = get_string(cam, "camName", "")
            if camName == wasCamName
              let tau = get_float(cam, "fadeTau") ?? shooter_cam__tauOnChange
              shooter_cam__tauInc = max(shooter_cam__tauInc, tau)
              return
