require ecs
require ecs.common
require ecs.soa_template
require EnlistedCamera
require vehicle
require math
require math.base
require dm
require Dacoll
require DagorSystem
require DagorMath
require game.es.vehicle.vehicle_events
require AnimV20
require GeomNodeTree
require fx
require ecs.safe
require strings
require enlisted.events_enlisted
require PhysMat

[soa_template]
struct trackDirtFxFromBlk
  track_dirt_fx__node : string
  track_dirt_fx__chassis : string
  track_dirt_fx__physmatFxType : string
  track_dirt_fx__minSpeed : float
  track_dirt_fx__maxSpeed : float
  track_dirt_fx__speedMult : float
  track_dirt_fx__driven : bool
  track_dirt_fx__atGround : bool

[soa_template]
struct trackDirtFxForStore
  track_dirt_fx__nodeId : int
  track_dirt_fx__matFxTypeId : int
  track_dirt_fx__effectsEid : EntityId
  track_dirt_fx__matId : int

struct TrackDirtFxTemporaries
  dirtSpawnRateMult : float
  wheelSideCount : int
  furthestWheelIndex : int
  furthestX : double
  matName : string
  matId : int

[es(on_appear)]
def global_track_fx_info_init(evt : Event;
                              global_track_fx__materialGroups : Object;
                              var global_track_fx__materialToGroupMap : Object&)
  for elem in global_track_fx__materialGroups
    let matGroupName = elem.key
    let mats = get_ecs_StringList(elem.value)
    if mats == null
      logerr("global_track_fx_info_init: wrong value type for element in global_track_fx__materialGroups; should be 'list<t>'")
      continue
    for mat in *mats
      global_track_fx__materialToGroupMap |> set(string(mat), matGroupName)


def get_effect_name(eid : EntityId; mat_name : string; mat_fx_type_id : int; chassis : string)
  var matGroup : string

  find_query() <| $ [es] (global_track_fx__materialToGroupMap : Object)
    matGroup = global_track_fx__materialToGroupMap[mat_name] ?? ""
    if !empty(matGroup)
      matGroup = "group__" + matGroup
    return true

  var fxName : string
  query(eid) <| $ [es] (track_fx__info : Object; track_fx__default : Object)
    let matFxType = mat_fx_type_id == 1 ? "fx_top" : "fx_bottom"
    var fxInfoByChassis = track_fx__info[chassis] ?as Object
    var fxInfoByMat = fxInfoByChassis?[mat_name] ?as Object
    if fxInfoByMat == null && !empty(matGroup)
      fxInfoByMat = fxInfoByChassis?[matGroup] ?as Object
    fxName = fxInfoByMat?[matFxType] ?? ""
    if empty(fxName)
      fxInfoByChassis = track_fx__default[chassis] ?as Object
      fxName = fxInfoByChassis?[matFxType] ?? ""
  return fxName

def spawn_effect(fx_name : string; emm_tm : float3x4&)
  if empty(fx_name)
    return INVALID_ENTITY_ID
  return createEntity("hit_fx_readback_info") <| $(init)
    init |> set("transform", emm_tm)
    init |> set("hit_fx_name", fx_name)

[es(tag = render, on_disappear, REQUIRE=track_fx__info, REQUIRE=track_fx__default)]
def das_clear_vehicle_dirt_fx_es(evt : Event;
                                 track_dirt_fx__effectsEid : EidList)
  for eid in track_dirt_fx__effectsEid
    destroyEntity(eid)

[es(tag = render, on_appear, REQUIRE=deadEntity, REQUIRE=track_fx__info, REQUIRE=track_fx__default)]
def das_clear_vehicle_dirt_fx_on_die_es(evt : Event;
                                        track_dirt_fx__effectsEid : EidList)
  for eid in track_dirt_fx__effectsEid
    destroyEntity(eid)

[soa_es, es(tag = render, on_appear, REQUIRE=track_fx__info, REQUIRE=track_fx__default)]
def das_fill_vehicle_dirt_fx_es(evt : Event;
                                animchar : AnimcharBaseComponent;
                                trackDirtFxFromBlk : trackDirtFxFromBlk_SOA;
                                var trackDirtFxForStore : trackDirtFxForStore_SOA)
  for elem in trackDirtFxFromBlk
    trackDirtFxForStore |> push() <| [[trackDirtFxForStore
          track_dirt_fx__nodeId=geomtree_findNodeIndex(*animchar.nodeTree, string(elem.track_dirt_fx__node)),
          track_dirt_fx__matFxTypeId=(elem.track_dirt_fx__physmatFxType == "front" ? 1 : 0),
          track_dirt_fx__effectsEid=INVALID_ENTITY_ID,
          track_dirt_fx__matId=-1
        ]]


[soa_es, es(tag = render, after=das_fill_vehicle_dirt_fx_es, REQUIRE=track_fx__info, REQUIRE_NOT=deadEntity, REQUIRE=track_fx__default)]
def das_vehicle_dirt_fx_es(info : ParallelUpdateFrameDelayed;
                           eid : EntityId;
                           transform : float3x4&;
                           animchar__updatable : bool;
                           vehicle_net_phys : VehiclePhysActor;
                           animchar : AnimcharBaseComponent;
                           animchar__visible : bool = true;
                           trackDirtFxFromBlk : trackDirtFxFromBlk_SOA;
                           track_dirt_fx__updateInterval : float;
                           track_dirt_fx__thresholdDist : float = 250.f;
                           track_dirt_fx__waterLevelOffsetForWheel : float = 0.3;
                           track_dirt_fx__waterLevelOffsetForEmitter : float = -0.1;
                           var trackDirtFxForStore : trackDirtFxForStore_SOA;
                           var track_dirt_fx__updateAtTime : float&)
  if (int(vehicle_net_phys.phys.currentState.wheelCount) == 0)
    return
  let camItm = get_TMatrix(get_cur_cam_entity(), "transform")
  if camItm == null
    return
  let camPos = (*camItm)[3]
  let vehiclePos = transform[3]
  if (!animchar__visible || !animchar__updatable || distance_sq(vehiclePos, camPos) > (track_dirt_fx__thresholdDist * track_dirt_fx__thresholdDist))
    // reset effects if we're too far away
    for elem in trackDirtFxForStore
      if elem.track_dirt_fx__matId < 0
        continue
      elem.track_dirt_fx__matId = -1
      destroyEntity(elem.track_dirt_fx__effectsEid)
    return

  let velocity = vehicle_net_phys.phys |> vehicle_phys_getCurrentStateVelocity()
  let omega = vehicle_net_phys.phys |> vehicle_phys_getCurrentStateOmega()
  let leftTrackSpeed = vehicle_net_phys.phys.currentState.leftTrack.speed
  let rightTrackSpeed = vehicle_net_phys.phys.currentState.rightTrack.speed
  let isOnGroundLeft = vehicle_net_phys.phys.currentState.leftTrack.isOnGround
  let isOnGroundRight = vehicle_net_phys.phys.currentState.rightTrack.isOnGround

  assume sideCount = 2 //right (0) and left (1) sides
  var trackDirtFxTemporaries : TrackDirtFxTemporaries[sideCount]

  for i in range(int(vehicle_net_phys.phys.currentState.wheelCount))
    let wheel = vehicle_phys_get_wheel(vehicle_net_phys.phys, i)
    let isLeft = float(wheel.pos.z) > 0.
    let trackSpd = isLeft ? leftTrackSpeed : rightTrackSpeed
    let sideIndex = isLeft ? 1 : 0
    assume curInfo = trackDirtFxTemporaries[sideIndex]

    curInfo.wheelSideCount += 1

    var spawnRateMult = 1.f
    if (wheel.lastMatId >= 0)
      track_dirt_mat_fx_get_props(int(wheel.lastMatId)) <| $(matProps : TrackDirtMatFxProps)
        spawnRateMult = matProps.spawnRateMult

        let adjustedX = trackSpd < 0.0 ? wheel.pos.x : -wheel.pos.x
        if adjustedX > curInfo.furthestX
          curInfo.furthestWheelIndex = i
          curInfo.furthestX = adjustedX
          curInfo.matName = string(matProps.matName)
          curInfo.matId = wheel.lastMatId
    curInfo.dirtSpawnRateMult += spawnRateMult

  for curInfo in trackDirtFxTemporaries
    let wheel = vehicle_phys_get_wheel(vehicle_net_phys.phys, curInfo.furthestWheelIndex)
    var waterLevel = 0.0
    let wheelWorldPos = transform * float3(wheel.pos)
    let isUnderWater = (traceht_water(wheelWorldPos, waterLevel) &&
                        wheelWorldPos.y < waterLevel + track_dirt_fx__waterLevelOffsetForWheel)
    if isUnderWater
      curInfo.matName = "water3d"
      curInfo.matId = get_material_id(curInfo.matName)
      track_dirt_mat_fx_get_props(curInfo.matId) <| $(waterMatProps : TrackDirtMatFxProps)
        curInfo.dirtSpawnRateMult = waterMatProps.spawnRateMult
    else
      curInfo.dirtSpawnRateMult = safediv(curInfo.dirtSpawnRateMult, float(curInfo.wheelSideCount))

  for elemBlk, elemStore in trackDirtFxFromBlk, trackDirtFxForStore
    if elemStore.track_dirt_fx__nodeId < 0
      continue
    var emmTm : float3x4 = IDENT_TM
    geomtree_getNodeWtmScalar(*animchar.nodeTree, elemStore.track_dirt_fx__nodeId, emmTm)
    let dir = emmTm[1]
    emmTm[1] = emmTm[0]
    emmTm[0] = dir
    emmTm[2] = -emmTm[2]
    emmTm[3] = emmTm[3]
    let effTm = inverse(transform) * emmTm
    let matFxTypeId = elemStore.track_dirt_fx__matFxTypeId
    let pointVel = velocity + rotate(emmTm, cross(omega, effTm[3]))
    let groundSpd = dot(pointVel, transform[0])
    let isLeft = effTm[3].z > 0.f
    let isOnGround = isLeft ? isOnGroundLeft : isOnGroundRight
    let trackSpd = elemBlk.track_dirt_fx__driven ? float(isLeft ? leftTrackSpeed : rightTrackSpeed) : groundSpd
    var effectSpd = trackSpd * elemBlk.track_dirt_fx__speedMult
    let trackDir = transform[0]
    let sideIndex = isLeft ? 1 : 0
    assume curInfo = trackDirtFxTemporaries[sideIndex]

    if info.curTime > track_dirt_fx__updateAtTime && elemStore.track_dirt_fx__matId != curInfo.matId
      elemStore.track_dirt_fx__matId := curInfo.matId
      destroyEntity(elemStore.track_dirt_fx__effectsEid)
    if !doesEntityExist(elemStore.track_dirt_fx__effectsEid)
      let fxName = get_effect_name(eid, curInfo.matName, matFxTypeId, string(elemBlk.track_dirt_fx__chassis))
      elemStore.track_dirt_fx__effectsEid = spawn_effect(fxName, emmTm)

    var spawnRate = curInfo.dirtSpawnRateMult
    if curInfo.matName == "water3d"
      var waterLevel = 0.0
      let pos = emmTm[3]
      traceht_water(pos, waterLevel)
      if pos.y < waterLevel + track_dirt_fx__waterLevelOffsetForEmitter
        spawnRate = 0.0
    elif !isOnGround
      spawnRate = 0.0
    if elemBlk.track_dirt_fx__atGround
      let mult = cvt(1.1f * trackSpd - groundSpd, elemBlk.track_dirt_fx__minSpeed, elemBlk.track_dirt_fx__maxSpeed, 0.f, 1.f)
      spawnRate *= mult * saturate(abs(groundSpd))
      effectSpd *= mult
    else
      spawnRate *= saturate(cvt(trackSpd, elemBlk.track_dirt_fx__minSpeed, elemBlk.track_dirt_fx__maxSpeed, 0.f, 1.f))

    let vel = pointVel + trackDir * abs(effectSpd)

    query(elemStore.track_dirt_fx__effectsEid) <| $ [es] (var transform : float3x4&;
                                                          var effect__velocity : float3&;
                                                          var effect__spawnRate : float&)
      effect__velocity = vel
      transform = emmTm
      effect__spawnRate = spawnRate

  if info.curTime > track_dirt_fx__updateAtTime
    track_dirt_fx__updateAtTime = info.curTime + track_dirt_fx__updateInterval