require ecs
require ecs.safe
require app
require DagorMath
require GamePhys
require ecs.common
require enlisted.events_enlisted

struct TimeData
  aliveTime : float
  expanseStartTime : float
  expanseFullTime : float
  fadeStartTime : float
  totalTime : float

def occluder_cvt(timeData : TimeData; data : float3)
  with timeData
    if aliveTime < expanseStartTime
      return data[0]
    if aliveTime < expanseFullTime
      return cvt(aliveTime, expanseStartTime, expanseFullTime, data[0], data[1])
    return cvt(aliveTime, fadeStartTime, totalTime, data[1], data[2])

def init_comp(var init : ComponentsInitializer; occluder_template : Template; template_field : string; template_field_hash : uint; obj : Object const?&; object_field : string; default_value : float)
  let value = obj?[object_field] ?? getTemplateComponent(occluder_template, template_field, template_field_hash) ?? default_value
  set(init, template_field, value)

def init_comp(var init : ComponentsInitializer; occluder_template : Template; template_field : string; template_field_hash : uint; obj : Object const?&; object_field : string; default_value : float3)
  let value = obj?[object_field] ?? getTemplateComponent(occluder_template, template_field, template_field_hash) ?? default_value
  set(init, template_field, value)

[es(on_appear)]
def init_smoke_occluders(evt : Event; [[shared_comp]] smoke_occluders__info : Array; transform : float3x4; smoke_occluders__updateInterval : float = 1.0; var smoke_occluders__eids : EidList&)
  for occluderInfo in smoke_occluders__info
    let occluder = get_ecs_object(occluderInfo)
    if occluder == null
      continue
    let occluderTemplateName = get_string(occluder, "template", "smoke_occluder")
    let occluderTemplate = getTemplateByName(occluderTemplateName)
    if occluderTemplate == null
      continue

    let occluderEid = createEntity(occluderTemplateName) <| $(var init : ComponentsInitializer)
      init_comp(init, *occluderTemplate, "smoke_occluder__windScale", ecs_hash("smoke_occluder__windScale"), occluder, "windScale", 1.2)
      init_comp(init, *occluderTemplate, "smoke_occluder__expanseStartTime", ecs_hash("smoke_occluder__expanseStartTime"), occluder, "expanseStartTime", 6.0)
      init_comp(init, *occluderTemplate, "smoke_occluder__expanseFullTime", ecs_hash("smoke_occluder__expanseFullTime"), occluder, "expanseFullTime", 12.0)
      init_comp(init, *occluderTemplate, "smoke_occluder__fadeStartTime", ecs_hash("smoke_occluder__fadeStartTime"), occluder, "fadeStartTime", 50.0)
      init_comp(init, *occluderTemplate, "smoke_occluder__totalTime", ecs_hash("smoke_occluder__totalTime"), occluder, "totalTime", 180.0)
      init_comp(init, *occluderTemplate, "smoke_occluder__upSpeed", ecs_hash("smoke_occluder__upSpeed"), occluder, "upSpeed", float3(0.0, 2.0, 0.0))
      init_comp(init, *occluderTemplate, "smoke_occluder__normalSpeed", ecs_hash("smoke_occluder__normalSpeed"), occluder, "normalSpeed", float3(0.8, 0.8, 0.0))
      init_comp(init, *occluderTemplate, "smoke_occluder__radius", ecs_hash("smoke_occluder__radius"), occluder, "radius", float3(0.0, 2.0, 0.3))
      set(init, "smoke_occluder__createdAtTime", get_sync_time())
      set(init, "transform", transform)
      set(init, "smoke_occluder__updateInterval", smoke_occluders__updateInterval)
    push(smoke_occluders__eids, occluderEid)

[es(on_appear)]
def smoke_occluders_on_appear(evt : Event;
                              smoke_occluders__destroyDelay : float;
                              var smoke_occluders__destroyAtTime : float&)
  smoke_occluders__destroyAtTime += smoke_occluders__destroyDelay


[es(no_order)]
def smoke_occluders_destroy_by_timer(info : ParallelUpdateFrameDelayed; eid : EntityId; smoke_occluders__destroyAtTime : float)
  if info.curTime > smoke_occluders__destroyAtTime
    destroyEntity(eid)


[es(on_disappear)]
def destroy_smoke_occluders(evt : Event; smoke_occluders__eids : EidList)
  for eid in smoke_occluders__eids
    destroyEntity(eid)

[es(no_order, REQUIRE_NOT=smoke_occluders__isStatic)]
def move_smoke_occluders(info : ParallelUpdateFrameDelayed;
                         eid : EntityId;
                         transform aka smoke_transform : float3x4;
                         smoke_occluders__eids : EidList;
                         smoke_occluders__moveInterval : float = 3.0;
                         var smoke_occluders__nextMoveTime : float&)
  if info.curTime < smoke_occluders__nextMoveTime
    return
  let updateTimeOveflow = info.curTime - smoke_occluders__nextMoveTime
  if updateTimeOveflow < smoke_occluders__moveInterval
    smoke_occluders__nextMoveTime += smoke_occluders__moveInterval
  else // either initial update, huge dt or small interval
    smoke_occluders__nextMoveTime = info.curTime + smoke_occluders__moveInterval * eid_frnd(eid)

  for occluder_eid in smoke_occluders__eids
    query(occluder_eid) <| $ [es] (var transform : float3x4&)
      transform = smoke_transform

[es(no_order)]
def smoke_occluder_update(info : ParallelUpdateFrameDelayed;
                          eid : EntityId;
                          transform : float3x4;
                          smoke_occluder__windScale : float;
                          smoke_occluder__createdAtTime : float;
                          smoke_occluder__expanseStartTime : float;
                          smoke_occluder__expanseFullTime : float;
                          smoke_occluder__fadeStartTime : float;
                          smoke_occluder__totalTime : float;
                          smoke_occluder__upSpeed : float3;
                          smoke_occluder__normalSpeed : float3;
                          smoke_occluder__radius : float3;
                          smoke_occluder__updateInterval : float = 1.0;
                          var smoke_occluder__nextUpdateTime : float&;
                          var smoke_occluder__sphere : float4&)
  if info.curTime < smoke_occluder__nextUpdateTime
    return
  let updateTimeOveflow = info.curTime - smoke_occluder__nextUpdateTime
  if updateTimeOveflow < smoke_occluder__updateInterval
    smoke_occluder__nextUpdateTime += smoke_occluder__updateInterval
  else // either initial update, huge dt or small interval
    smoke_occluder__nextUpdateTime = info.curTime + smoke_occluder__updateInterval * eid_frnd(eid)

  let aliveTime = smoke_occluder__createdAtTime >= 0.0 ? info.curTime - smoke_occluder__createdAtTime : 0.0
  let timeData = [[TimeData aliveTime=aliveTime, expanseStartTime=smoke_occluder__expanseStartTime, expanseFullTime=smoke_occluder__expanseFullTime,
                            fadeStartTime=smoke_occluder__fadeStartTime, totalTime=smoke_occluder__totalTime]]

  let upSpeed = occluder_cvt(timeData, smoke_occluder__upSpeed)
  let wind = get_wind()
  let startSpeedNormal = occluder_cvt(timeData, smoke_occluder__normalSpeed)
  let normalDir = transform[1]
  var velocity = normalDir * startSpeedNormal
  velocity.y += upSpeed
  velocity += wind * smoke_occluder__windScale
  let startPos = transform[3] + normalDir * startSpeedNormal

  let radius = occluder_cvt(timeData, smoke_occluder__radius)

  let pos = startPos + velocity
  smoke_occluder__sphere = float4(pos.x, pos.y, pos.z, radius)
