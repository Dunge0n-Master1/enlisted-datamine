require ecs
require net
require app
require enlisted.events_enlisted
require game.utils.net_utils

[es(tag=gameClient, on_appear, track=cockpit__nextSlit)]
def client_sync_cockpit_slit_es(evt : Event;
                                cockpit__vehicleEid : EntityId;
                                cockpit__prevSlit : int;
                                cockpit__nextSlit : int)
  find_query() <| $ [es(REQUIRE=(human_input, hero))] (eid : EntityId;
                                                       human_anim__vehicleSelected : EntityId)
    if human_anim__vehicleSelected == cockpit__vehicleEid
      send_net_event(eid, [[ClientSetVisualCockpitSlit nextSlit=cockpit__nextSlit, prevSlit=cockpit__prevSlit]])
    return true

[es(tag=(server, recordingReplay), REQUIRE=human_anim__vehicleSelected)]
def server_sync_cockpit_slit_es(evt : ClientSetVisualCockpitSlit; eid : EntityId)
  // send this event tp blackholl(e.g. replay connection)
  send_net_event(eid, [[ServerSetVisualCockpitSlit nextSlit=evt.nextSlit, prevSlit=evt.prevSlit]], target_entity_conn(INVALID_ENTITY_ID))

[es(tag=playingReplay)]
def replay_sync_cockpit_slit_es(evt : ServerSetVisualCockpitSlit;
                                var human_cockpit__nextSlit : int&;
                                var human_cockpit__prevSlit : int&)
  human_cockpit__nextSlit = evt.nextSlit
  human_cockpit__prevSlit = evt.prevSlit

[es(tag=playingReplay, on_appear, track=human_cockpit__nextSlit, REQUIRE=watchedByPlr)]
def replay_sync_cockpit_on_appear_es(evt : Event;
                                     human_anim__vehicleSelected : EntityId;
                                     human_cockpit__nextSlit : int)
  find_query() <| $ [es] (cockpit__vehicleEid : EntityId;
                          cockpit__slitNodes : IntList;
                          cockpit__cameraTime : float;
                          var cockpit__prevSlit : int&;
                          var cockpit__nextSlit : int&)
    if human_anim__vehicleSelected != cockpit__vehicleEid || cockpit__cameraTime < 1.0
      return false
    let viewsCount = length(cockpit__slitNodes)
    if viewsCount <= 0
      return true
    cockpit__prevSlit = cockpit__nextSlit
    cockpit__nextSlit = human_cockpit__nextSlit
    return true

[es(tag=playingReplay, on_appear, after=vehicle_cockpit_slits_init, track=cockpit__isAttached, REQUIRE=cockpit__isAttached)]
def sync_human_cockpit_with_vehicle_es(evt : Event;
                                       cockpit__vehicleEid : EntityId;
                                       cockpit__slitNodes : IntList;
                                       cockpit__cameraTime : float;
                                       var cockpit__currentSlit : int&;
                                       var cockpit__prevSlit : int&;
                                       var cockpit__nextSlit : int&)
  find_query() <| $ [es(REQUIRE=watchedByPlr)] (human_anim__vehicleSelected : EntityId;
                                                human_cockpit__nextSlit : int;
                                                human_cockpit__prevSlit : int)
    if human_anim__vehicleSelected != cockpit__vehicleEid || cockpit__cameraTime < 1.0
      return false
    let viewsCount = length(cockpit__slitNodes)
    if viewsCount <= 0
      return true
    cockpit__nextSlit = human_cockpit__nextSlit
    cockpit__prevSlit = human_cockpit__prevSlit
    cockpit__currentSlit = human_cockpit__nextSlit
    return true
