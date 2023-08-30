require ecs
require ecs.safe
require PhysMat
require DngCamera
require RendInst
require enlisted.events_enlisted
require common_shooter.events_common_shooter
require game.es.render.weaponry_fx_render_common
require fx

[es(tag=render, after=(trace_scene_after_update_projectile_es), REQUIRE_NOT=projectile__inactive, parallel_for=2)]
def trace_scene_after_update_projectile_canopy_es(info : ParallelUpdateFrameDelayed;
                                                  projectile__prevPos : float3;
                                                  projectile_trace_info__dir : float3;
                                                  projectile_trace_info__len : float;
                                                  projectile__maxAllowedCanopyIntersectionsForFx : int;
                                                  var projectile__canopyIntersectionCount : int&;
                                                  projectile__maxDistSqFromCamForCanopyFx = 400.0;
                                                  projectile__minDistSqFromCamForCanopyFxVisibilityCheck = 9.0)
  if int(get_fx_target()) <= int(FxQuality FX_QUALITY_LOW)
    return

  let traceLenOffset = 0.01
  if projectile__canopyIntersectionCount >= projectile__maxAllowedCanopyIntersectionsForFx || projectile_trace_info__len < traceLenOffset
    return

  let approxPos = projectile__prevPos + projectile_trace_info__dir * projectile_trace_info__len
  let camTm = get_cur_cam_entity() |> get_TMatrix("transform")
  if camTm == null
    return
  let distSqToCam = length_sq(approxPos - (*camTm)[3])

  if distSqToCam > projectile__maxDistSqFromCamForCanopyFx
    return

  if distSqToCam > projectile__minDistSqFromCamForCanopyFxVisibilityCheck
    let approxPosInCamCs = inverse(*camTm) * approxPos
    if approxPosInCamCs.z < 0.0
      return

  //We subtract traceLenOffset from t so that we don't get the same position as trace_scene_after_update_projectile_es
  //If we didn't do that, we'd get two effects playing when the bullet hits a tree trunk
  var t = projectile_trace_info__len - traceLenOffset
  var transparency = 0.0
  using() <| $(var riDesc : RendInstDesc#)
    var pmid = -1
    let canopyTraceThreshold = 0.01
    let res = traceTransparencyRayRIGenNormalized(projectile__prevPos, projectile_trace_info__dir, t, canopyTraceThreshold,
      riDesc, pmid, transparency, -1, /*check_canopy*/ true)

    if res
      projectile__canopyIntersectionCount += 1
      //We send immediate event so that event handlers are executed in ParallelUpdateFrameDelayed
      find_query() <| $ [es] (global_hit_fx__canopyEffects : Object)
        let fxName = global_hit_fx__canopyEffects[get_material_name(get_material(pmid))] ?? ""
        spawn_hit_effect(projectile_trace_info__dir, projectile__prevPos + projectile_trace_info__dir * t, fxName, /*allow_paint_from_biome*/ false, riDesc.pool)
        return true
