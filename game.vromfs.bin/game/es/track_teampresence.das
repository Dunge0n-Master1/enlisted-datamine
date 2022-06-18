require ecs
require DagorSystem
require DagorRandom

[es(tag=server, no_order)]
def track_team_presence_es(act : ecs::UpdateStageInfoAct; var trackedLastTime : float&; trackInterval : float2; var teamPresence : ecs::Object)
  if act.curTime > trackedLastTime
    trackedLastTime = act.curTime + rnd_float(trackInterval.x, trackInterval.y)
    for it in teamPresence
      var eidListPtr = getRW_ecs_array(it.value)
      if eidListPtr == null
        return
      assume eidList = *eidListPtr
      let size = length(eidList)
      for i in range(0, size)
        let eid = get_Eid(eidList[i]) ?? INVALID_ENTITY_ID
        if !!eid && !doesEntityExist(eid)
          logerr("Entity with eid {eid} does not exist in teamPresence. Deleting it from there")
          erase(eidList, i)
          return
