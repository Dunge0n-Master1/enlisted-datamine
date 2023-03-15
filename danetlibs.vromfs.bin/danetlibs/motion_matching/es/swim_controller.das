require ecs
require math.base
require strings
require DagorMath
require DagorSystem
require %danetlibs/motion_matching/es/mm_events
require %danetlibs/motion_matching/es/tags_common


[es(tag=gameClient, track=(human_net_phys__isSwimming, human_net_phys__isUnderwater))]
def motion_matching_watch_swim(event : Event;
                               var motion_matching__goalTags : StringList;
                               var motion_matching__optionalTags : StringList;
                               human_net_phys__isSwimming : bool;
                               human_net_phys__isUnderwater : bool;
                               var motion_matching__enabled : bool&)

  motion_matching__enabled = human_net_phys__isSwimming
  set_tag(motion_matching__goalTags, human_net_phys__isSwimming, "swim")
  set_tag(motion_matching__optionalTags, human_net_phys__isUnderwater, "swim_underwater")


[es(tag=gameClient, before=motion_matching_job_es)]
def update_mm_progress(act : ParallelUpdateFrameDelayed;
                       var motion_matching__blendProgressToAnimtree : float&;
                       motion_matching__blendTimeToAnimtree : float;
                       motion_matching__enabled : bool)
  let dt = motion_matching__enabled ? act.dt : -act.dt
  motion_matching__blendProgressToAnimtree = saturate(motion_matching__blendProgressToAnimtree + dt / motion_matching__blendTimeToAnimtree)


[es(tag=gameClient, before=mm_lod_selector)]
def update_mm_trajectory(act : ParallelUpdateFrameDelayed;
                         transform : float3x4;
                         var motion_matching__goalTags : StringList;
                         var motion_matching__prevTransform : float3x4&;
                         var motion_matching__linearVelocity, motion_matching__angularVelocity : float3&;
                         motion_matching__idleVelocityBarrier : float;
                         human_net_phys__velocity : float3;
                         motion_matching__enabled : bool)
  if motion_matching__enabled
    var instantOmega : float3
    let quaternion = inverse(quat(motion_matching__prevTransform)) * quat(transform)
    quat_to_euler(quaternion, instantOmega.x, instantOmega.y, instantOmega.z)
    motion_matching__linearVelocity = rotate(inverse(transform), human_net_phys__velocity)
    let CONPATIBLE_ROTATION = quat(float3(0, 1, 0), deg_to_rad(90.f))
    motion_matching__linearVelocity = CONPATIBLE_ROTATION * motion_matching__linearVelocity
    motion_matching__angularVelocity = float3(0.0, safediv(instantOmega.x, act.dt), 0.0)
    let isIdle = abs(motion_matching__angularVelocity.y) < PI * 0.01 && length(motion_matching__linearVelocity) < motion_matching__idleVelocityBarrier

    set_tag(motion_matching__goalTags, isIdle, "idle")
    motion_matching__prevTransform = transform
