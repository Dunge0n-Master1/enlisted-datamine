require ecs
require math.base
require debug.logerr_once
require AnimV20
require GeomNodeTree
require CapsuleApproximation
require Dacoll
require game.es.camera_common
require enlisted.events_enlisted


[es(tag=render, on_appear)]
def swim_spash_fx_on_appear(evt : Event;
                            [[shared_comp]] capsule_approximation : CapsuleApproximation;
                            animchar : AnimcharBaseComponent;
                            var swimsplash__nodeIds : IntList;
                            var swimsplash__prevPositions : Point3List;
                            var swimsplash__timeSinceLastSplashes : FloatList)
  reserve(swimsplash__prevPositions, length(capsule_approximation.capsuleDatas) + 1) // reserve bytes for safe v_ldu
  for capsule in capsule_approximation.capsuleDatas
    push(swimsplash__nodeIds, capsule.nodeIndex)
    push(swimsplash__prevPositions, geomtree_getNodeWpos(*animchar.nodeTree, capsule.nodeIndex))
    push(swimsplash__timeSinceLastSplashes, 100000.0)


def update_trace(curr_pos : float3;
                 dt : float;
                 min_t : float;
                 var prev_pos : float3&;
                 var time_since_last_splash : float&;
                 var intersect : float3&;
                 var speed : float&)
  time_since_last_splash += dt

  let deltaPos = curr_pos - prev_pos

  var prevHeight = 0.0
  var currHeight = 0.0
  var doSwimSplash = (dt > 1e-5 &&
                      abs(deltaPos.y) > 1e-5 &&
                      time_since_last_splash > min_t &&
                      traceht_water(prev_pos, prevHeight) &&
                      traceht_water(curr_pos, currHeight))

  if doSwimSplash
    prevHeight = prev_pos.y - prevHeight
    currHeight = curr_pos.y - currHeight
    doSwimSplash = sign(prevHeight) != sign(currHeight)

    if doSwimSplash
      speed = length(deltaPos) / dt
      intersect = curr_pos - float3(0.0, currHeight, 0.0)
      time_since_last_splash = 0.0

  prev_pos = curr_pos

  return doSwimSplash


// after start_async_phys_sim_es to start phys sim job earlier
[es(tag=render, REQUIRE_NOT=deadEntity, after=start_async_phys_sim_es)]
def swimsplash_on_update(evt : ParallelUpdateFrameDelayed;
                         transform : float3x4;
                         animchar : AnimcharBaseComponent;
                         swimsplash__offset : float3;
                         swimsplash__scaleMul : float;
                         swimsplash__fxTemplate : string;
                         swimsplash__maxRenderingSpeed : float;
                         swimsplash__minTimeBetweenSplashes : float;
                         swimsplash__maxDistanceFromCameraToUpdateSq : float;
                         animchar__visible : bool = true;
                         var swimsplash__nodeIds : IntList;
                         var swimsplash__prevPositions : Point3List;
                         var swimsplash__timeSinceLastSplashes : FloatList)
  if !animchar__visible
    return

  if swimsplash__maxDistanceFromCameraToUpdateSq > 0.0
    let camPos = get_cam_itm()[3]
    let distSqToCam = distance_sq(camPos, transform[3])
    if distSqToCam > swimsplash__maxDistanceFromCameraToUpdateSq
      return

  for nodeId, prevPos, timeSinceLastSplash in swimsplash__nodeIds, swimsplash__prevPositions, swimsplash__timeSinceLastSplashes
    let wpos = geomtree_getNodeWpos(*animchar.nodeTree, nodeId)

    if is_nan(wpos) || length_sq(wpos) >= 1e10
      let nodeName = geomtree_getNodeName(*animchar.nodeTree, nodeId)
      let animcharResName = animchar_get_res_name(animchar)
      logerr_once("Bad node {nodeId}({nodeName}) pos={wpos} of animchar '{animcharResName}'")
      continue

    var intersect : float3
    var speed : float
    if update_trace(wpos, evt.dt, swimsplash__minTimeBetweenSplashes, prevPos, timeSinceLastSplash, intersect, speed)
      if speed >= swimsplash__maxRenderingSpeed
        return

      let scale = pow(speed, 2.0 / 3.0) * swimsplash__scaleMul // energy of impact scales with speed^2 and water mass with scale^3
      let worldPos = intersect + swimsplash__offset * scale

      var tm = IDENT_TM
      tm[3] = worldPos

      createEntity(swimsplash__fxTemplate) <| $ [es] (init)
        set(init, "transform", tm)
