require ecs
require Dacoll

[es(REQUIRE=destroyUnderwater, tag=server, after=(node_attached_pos, node_attached_itm))]
def destroy_underwater(info : UpdateStageInfoAct;
                       eid : EntityId;
                       transform : float3x4;
                       var destroy_underwater__nextCheckTime : float&;
                       destroy_underwater__checkPeriod : float = 1.f)
  if info.curTime < destroy_underwater__nextCheckTime
    return
  destroy_underwater__nextCheckTime = info.curTime + destroy_underwater__checkPeriod
  var isUnderwater = false
  traceht_water_at_time(transform[3], 5.0, info.curTime, isUnderwater)
  if isUnderwater
    destroyEntity(eid)
