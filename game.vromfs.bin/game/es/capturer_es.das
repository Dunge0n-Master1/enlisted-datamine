require ecs
require zones
require EnlistedNet
require danetlibs.native_dasevents.main.native_events
require enlisted.events_enlisted
require ecs.common
require strings

[es(tag=server, track=isAlive)]
def capturer_died_es(evt : Event; eid : EntityId; isAlive : bool;
                     var capturer__capZonesIn : EidList;
                     var capturer__capZonesInBlocked : EidList)
  if ! isAlive
    leave_capzones_if(eid, capturer__capZonesIn) <| $(zoneEid : EntityId)
      return !(get_bool(zoneEid, "zone__keepDead") ?? false)
    clear(capturer__capZonesInBlocked)

[es(tag=server, after=after_net_phys_sync)]
def capturer_es(info : UpdateStageInfoAct;
                eid : EntityId;
                capturer__updatePeriod : float;
                var capturer__nextUpdateAt : float&;
                var capturer__capZonesIn : EidList;
                var capturer__capZonesInBlocked : EidList;
                possessedByPlr : EntityId;
                zones_visitor__triggerTag : string;
                transform : float3x4;
                shouldUpdateZonesInBlocked : Tag const?;
                isAlive : bool = true;
                isDowned : bool = false;
                human_anim__vehicleSelected : EntityId = INVALID_ENTITY_ID;
                isInVehicle : bool = false)
  if info.curTime < capturer__nextUpdateAt || !isAlive
    return
  let updateTimeOveflow = info.curTime - capturer__nextUpdateAt
  if updateTimeOveflow < capturer__updatePeriod
    capturer__nextUpdateAt += capturer__updatePeriod
  else // either initial update, huge dt or small interval
    capturer__nextUpdateAt = info.curTime + capturer__updatePeriod * eid_frnd(eid)

  get_active_capzones_on_pos(transform[3], zones_visitor__triggerTag) <| $(newZones)
    var oldZoneIdx = 0
    while oldZoneIdx < length(capturer__capZonesIn)
      let oldZoneEid = capturer__capZonesIn[oldZoneIdx]
      if has_value(newZones, oldZoneEid)
        oldZoneIdx++
      else
        send_net_event(oldZoneEid, [[EventCapZoneLeave visitor=eid]])
        erase(capturer__capZonesIn, oldZoneIdx)
        let blockedIdx = find_index(capturer__capZonesInBlocked, oldZoneEid)
        if blockedIdx >= 0
          erase(capturer__capZonesInBlocked, blockedIdx)

    if shouldUpdateZonesInBlocked != null
      var inZoneNo = 0
      while inZoneNo < length(capturer__capZonesInBlocked)
        if has_value(newZones, capturer__capZonesInBlocked[inZoneNo])
          inZoneNo++
        else
          erase(capturer__capZonesInBlocked, inZoneNo)

    for zoneEid in newZones
      let zonesInIdx = find_index(capturer__capZonesIn, zoneEid)
      let newZone = zonesInIdx < 0

      var blockedText = ""
      if isDowned && has(zoneEid, "zone__excludeDowned")
        blockedText = "capture/BlockedCaptureDowned"
      elif isInVehicle && !(get_bool(zoneEid, "capzone__canCaptureOnVehicle") ?? true) && !(has(human_anim__vehicleSelected, "capturer__allowCaptureOnVehicle"))
        blockedText = "capture/BlockedCaptureVehicle"

      var canEnterZone = empty(blockedText)
      query(possessedByPlr) <| $ [es] (capturer__cannotEnterCapZones : EidList)
        if find_index(capturer__cannotEnterCapZones, zoneEid) >= 0
          canEnterZone = false
          blockedText = ""

      if !canEnterZone
        if !newZone
          send_net_event(zoneEid, [[EventCapZoneLeave visitor=eid]])
          erase(capturer__capZonesIn, zonesInIdx)
        if !has_value(capturer__capZonesInBlocked, zoneEid)
          if !empty(blockedText)
            sendEvent(eid, [[CmdHeroLogEvent event="zone_capture_blocked_log", text=blockedText]])
          push(capturer__capZonesInBlocked, zoneEid)
        continue

      if newZone
        let blockedIdx = find_index(capturer__capZonesInBlocked, zoneEid)
        if blockedIdx >= 0
          erase(capturer__capZonesInBlocked, blockedIdx)
        push(capturer__capZonesIn, zoneEid)
        send_net_event(zoneEid, [[EventCapZoneEnter visitor=eid]])

def leave_capzones_if(eid : EntityId; var zones_in : EidList; condition)
  var zoneIdx = 0
  while zoneIdx < length(zones_in)
    let zoneEid = zones_in[zoneIdx]
    if invoke(condition, zoneEid)
      send_net_event(zoneEid, [[EventCapZoneLeave visitor=eid]])
      erase(zones_in, zoneIdx)
    else
      zoneIdx++

[es(tag=server, on_disappear)]
def capturer_destroyed_es(evt : Event; eid : EntityId; capturer__capZonesIn : EidList)
  for zoneEid in capturer__capZonesIn
    send_net_event(zoneEid, [[EventCapZoneLeave visitor=eid]])
