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


[soa_template]
struct trackDirtFxFromBlk
  track_dirt_fx__node : string
  track_dirt_fx__physmatFxType : string
  track_dirt_fx__minSpeed : float
  track_dirt_fx__maxSpeed : float
  track_dirt_fx__speedMult : float
  track_dirt_fx__driven : bool
  track_dirt_fx__atGround : bool
  node_emitter_offsets : float3

[soa_template]
struct trackDirtFxForStore
  track_dirt_fx__nodeId : int
  track_dirt_fx__matFxTypeId : int
  track_dirt_fx__effectsEid : EntityId
  track_dirt_fx__fxId : int

def private spawn_effect(eid : EntityId; emm_tm : float3x4&; matName : string&; matFxTypeId : int)
  var result = INVALID_ENTITY_ID
  query(eid) <| $ [es] (track_fx__info : Object; track_fx__default : Object)
    var fxName = matFxTypeId == 1 ? get_string(track_fx__default, "fx_front", "") : get_string(track_fx__default, "fx_back", "")
    var fxObj = get_ecs_object(track_fx__info, matName)
    if fxObj != null
      fxName = matFxTypeId == 1 ? get_string(fxObj, "fx_front", "") : get_string(fxObj, "fx_back", "")
    result = createEntity("hit_fx_readback_info") <| $(init)
      init |> set("transform", emm_tm)
      init |> set("hit_fx_name", fxName)
  return result

[es(tag = render, on_disappear, REQUIRE=track_fx__info, REQUIRE=track_fx__default)]
def das_clear_vehicle_dirt_fx_es(evt : Event;
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
          track_dirt_fx__nodeId=geomtree_findNodeIndex(animchar.nodeTree, string(elem.track_dirt_fx__node)),
          track_dirt_fx__matFxTypeId= get_mat_fx_type_id(string(elem.track_dirt_fx__physmatFxType)),
          track_dirt_fx__effectsEid=INVALID_ENTITY_ID,
          track_dirt_fx__fxId= -1
        ]]

[soa_es, es(tag = render, after=das_fill_vehicle_dirt_fx_es, REQUIRE=track_fx__info, REQUIRE=track_fx__default)]
def das_vehicle_dirt_fx_es(info : UpdateStageInfoAct;
                           eid : EntityId;
                           transform : float3x4&;
                           animchar__updatable : bool;
                           vehicle_net_phys : VehiclePhysActor;
                           animchar : AnimcharBaseComponent;
                           track_dirt_fx__thresholdDist : float = 250.f;
                           trackDirtFxFromBlk : trackDirtFxFromBlk_SOA;
                           var trackDirtFxForStore : trackDirtFxForStore_SOA)
  if (int(vehicle_net_phys.phys.currentState.wheelCount) == 0)
    return
  let camItm = get_TMatrix(get_cur_cam_entity(), "transform")
  if camItm == null
    return
  let camPos = (*camItm)[3]
  let vehiclePos = transform[3]
  if (!animchar__updatable || distance_sq(vehiclePos, camPos) > (track_dirt_fx__thresholdDist * track_dirt_fx__thresholdDist))
    // reset effects if we're too far away
    for elem in trackDirtFxForStore
      if (elem.track_dirt_fx__fxId < 0)
        continue
      elem.track_dirt_fx__fxId = -1
      destroyEntity(elem.track_dirt_fx__effectsEid)
    return
  var dirtSpawnRateMult = 0.f
  var matName = "sand"
  var lastWheelId = -1
  for i in range(int(vehicle_net_phys.phys.currentState.wheelCount))
    let wheel = vehicle_phys_get_wheel(vehicle_net_phys.phys, i)
    var spawnRateMult = 1.f
    if (wheel.lastMatId >= 0)
      lastWheelId = wheel.lastMatId
      track_dirt_mat_fx_get_props(int(wheel.lastMatId)) <| $(matProps : TrackDirtMatFxProps)
        spawnRateMult = matProps.spawnRateMult
        matName = string(matProps.matName)
    dirtSpawnRateMult += spawnRateMult
  dirtSpawnRateMult /= float(vehicle_net_phys.phys.currentState.wheelCount)

  let velocity = vehicle_net_phys.phys |> vehicle_phys_getCurrentStateVelocity()
  let omega = vehicle_net_phys.phys |> vehicle_phys_getCurrentStateOmega()
  let leftTrackSpeed = vehicle_net_phys.phys.currentState.leftTrack.speed
  let rightTrackSpeed = vehicle_net_phys.phys.currentState.rightTrack.speed
  let isOnGroundLeft = vehicle_net_phys.phys.currentState.leftTrack.isOnGround
  let isOnGroundRight = vehicle_net_phys.phys.currentState.rightTrack.isOnGround

  for elemBlk, elemStore in trackDirtFxFromBlk, trackDirtFxForStore
    var emmTm : float3x4 = IDENT_TM
    geomtree_getNodeWtmScalar(animchar.nodeTree, elemStore.track_dirt_fx__nodeId, emmTm)
    let dir = emmTm[1]
    emmTm[1] = emmTm[0]
    emmTm[0] = dir
    emmTm[2] = -emmTm[2]
    emmTm[3] = emmTm[3] + elemBlk.node_emitter_offsets
    let effTm = inverse(transform) * emmTm

    let pointVel = velocity + rotate(emmTm, cross(omega, effTm[3]))
    let groundSpd = dot(pointVel, transform[0])
    let isLeft = effTm[3].z > 0.f
    let isOnGround = isLeft ? isOnGroundLeft : isOnGroundRight
    let trackSpd = elemBlk.track_dirt_fx__driven ? float(isLeft ? leftTrackSpeed : rightTrackSpeed) : groundSpd
    var effectSpd = trackSpd * elemBlk.track_dirt_fx__speedMult
    let trackDir = transform[0]
    var spawnRate = dirtSpawnRateMult
    let matFxTypeId = int(elemStore.track_dirt_fx__matFxTypeId)
    var effectType : int = -1
    if (lastWheelId >= 0)
      let getPropsRes = track_dirt_mat_fx_get_props(int(lastWheelId)) <| $(matProps : TrackDirtMatFxProps)
        if matFxTypeId < length(matProps.effects)
          effectType = matProps.effects[matFxTypeId]
    if elemBlk.track_dirt_fx__atGround
      let mult = cvt(1.1f * trackSpd - groundSpd, elemBlk.track_dirt_fx__minSpeed, elemBlk.track_dirt_fx__maxSpeed, 0.f, 1.f)
      spawnRate *= isOnGround ? mult * saturate(abs(groundSpd)) : 0.f
      effectSpd *= mult
    else
      spawnRate *= isOnGround ? saturate(cvt(trackSpd, elemBlk.track_dirt_fx__minSpeed, elemBlk.track_dirt_fx__maxSpeed, 0.f, 1.f)) : 0.f

    let vel = pointVel + trackDir * abs(effectSpd)

    if (elemStore.track_dirt_fx__fxId >= 0 && elemStore.track_dirt_fx__fxId != effectType)
      elemStore.track_dirt_fx__fxId = -1
      destroyEntity(elemStore.track_dirt_fx__effectsEid)
    if (!doesEntityExist(elemStore.track_dirt_fx__effectsEid)  && effectType >= 0)
      elemStore.track_dirt_fx__effectsEid = spawn_effect(eid, emmTm, matName, matFxTypeId)
      if (doesEntityExist(elemStore.track_dirt_fx__effectsEid))
        elemStore.track_dirt_fx__fxId = effectType
    query(elemStore.track_dirt_fx__effectsEid) <| $ [es] (var transform : float3x4&;
                                                          var effect__velocity : float3&;
                                                          var effect__spawnRate : float&)
      effect__velocity = vel
      transform = emmTm
      effect__spawnRate = spawnRate