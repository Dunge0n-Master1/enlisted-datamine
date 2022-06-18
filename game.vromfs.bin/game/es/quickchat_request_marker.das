require ecs
require app
require enlisted.events_enlisted

[es(tag=server)]
def quickchat_request_ammo_box_enable_es(evt : CmdRequestAmmoBoxMarker;
                                         possessedByPlr : EntityId;
                                         human_quickchat__requestAmmoBoxMarkerShowTime : float;
                                         var human_quickchat__requestAmmoBoxMarkerShowUpTo : float&)
  if possessedByPlr != INVALID_ENTITY_ID
    human_quickchat__requestAmmoBoxMarkerShowUpTo = get_sync_time() + human_quickchat__requestAmmoBoxMarkerShowTime

[es(tag=server)]
def quickchat_request_rally_point_enable_es(evt : CmdRequestRallyPointMarker;
                                            possessedByPlr : EntityId;
                                            human_quickchat__requestRallyPointMarkerShowTime : float;
                                            var human_quickchat__requestRallyPointMarkerShowUpTo : float&)
  if possessedByPlr != INVALID_ENTITY_ID
    human_quickchat__requestRallyPointMarkerShowUpTo = get_sync_time() + human_quickchat__requestRallyPointMarkerShowTime

[es(tag=server, no_order)]
def quickchat_request_disable_timer_es(evt : UpdateStageInfoAct;
                                       possessedByPlr : EntityId;
                                       var human_quickchat__requestAmmoBoxMarkerShowUpTo : float&;
                                       var human_quickchat__requestRallyPointMarkerShowUpTo : float&)
  if possessedByPlr != INVALID_ENTITY_ID
    let syncedTime = get_sync_time()
    if syncedTime > human_quickchat__requestAmmoBoxMarkerShowUpTo
      human_quickchat__requestAmmoBoxMarkerShowUpTo = -1.0
    if syncedTime > human_quickchat__requestRallyPointMarkerShowUpTo
      human_quickchat__requestRallyPointMarkerShowUpTo = -1.0

[es(tag=server, track=possessedByPlr, no_order)]
def quickchat_need_ammo_box_disable_unpossess_es(evt : Event;
                                                 possessedByPlr : EntityId;
                                                 var human_quickchat__requestAmmoBoxMarkerShowUpTo : float&;
                                                 var human_quickchat__requestRallyPointMarkerShowUpTo : float&)
  if !possessedByPlr
    human_quickchat__requestAmmoBoxMarkerShowUpTo = -1.0
    human_quickchat__requestRallyPointMarkerShowUpTo = -1.0
