require ecs
require app
require DagorSystem
require DagorRandom
require math.base
require DagorMath
require GeomNodeTree
require RendInst
require AnimV20
require Dacoll
require soundSystem
require sound_utils_net.modules.sound_utils_net_events


[es(tag=sound, no_order)]
def sound_occlusion_update(info : ParallelUpdateFrameDelayed;
                           var sound_occlusion__targetId : int&)
  var targetId = -1
  var nextTargetId = 0
  let from = get_listener_pos()
  query() <| $ [es] (occluded_sound__nearFarRange : float2;
                     occluded_sound__radius : float;
                     occluded_sound__occlusionToVolume : float2;
                     occluded_sound__volumeMinMax : float2;
                     occluded_sound__enabled : bool;
                     occluded_sound__localOffset : float3;
                     transform : float3x4 const? = null;
                     animchar : AnimcharBaseComponent const? = null;
                     var occluded_sound__volume : float&;
                     var occluded_sound__volumeSumSamplesTime : float4&;
                     ri_extra__handle : riex_handle_t = RIEX_HANDLE_NULL)

    if !occluded_sound__enabled || (transform == null && animchar == null)
      occluded_sound__volume = 1.
      occluded_sound__volumeSumSamplesTime = float4(1., 0., 0., 0.)
      return

    ++targetId
    if targetId == sound_occlusion__targetId
      nextTargetId = sound_occlusion__targetId + 1

      var pos = float3(0., 0., 0.)
      if transform != null
        pos = *transform * occluded_sound__localOffset
      else
        var tm : float3x4
        geomtree_getNodeWtmScalar(*animchar.nodeTree, 0, tm)
        pos = tm * occluded_sound__localOffset

      var dist = length_sq(pos - from)
      if dist > square(occluded_sound__nearFarRange.y)
        occluded_sound__volumeSumSamplesTime.y += 1.
      else
        var offset = float3(rnd_float(-occluded_sound__radius, occluded_sound__radius),
                            rnd_float(-occluded_sound__radius, occluded_sound__radius),
                            rnd_float(-occluded_sound__radius, occluded_sound__radius))
        if dot(offset, from - pos) < 0.
          offset = -offset
        pos += offset
        dist = sqrt(length_sq(pos - from))
        let dir = (pos - from) / dist
        var t = dist
        var norm : float3
        var pmid : int
        var riDesc = RendInstDesc()
        if traceray_normalized(from, dir, t, pmid, norm, ETF_FRT | ETF_RI | ETF_STRUCTURES, riDesc, -1)
          if riDesc.isRiExtra == false || ri_extra__handle != riDesc.riExtraHandle // ignore ri associated with current entity
            occluded_sound__volumeSumSamplesTime.y += 1.

      occluded_sound__volumeSumSamplesTime.z += 1.
      if occluded_sound__radius == 0. || info.curTime > occluded_sound__volumeSumSamplesTime.w + 0.5
        // occlusion: 0=unoccluded,1=occluded
        occluded_sound__volumeSumSamplesTime.x = cvt(dist,
                                                     occluded_sound__nearFarRange.x,
                                                     occluded_sound__nearFarRange.y,
                                                     occluded_sound__volumeSumSamplesTime.y / occluded_sound__volumeSumSamplesTime.z,
                                                     1.)
        // volume [min..max]
        occluded_sound__volumeSumSamplesTime.x = cvt(occluded_sound__volumeSumSamplesTime.x,
                                                     occluded_sound__occlusionToVolume.x, occluded_sound__occlusionToVolume.y,
                                                     occluded_sound__volumeMinMax.y, occluded_sound__volumeMinMax.x)
        if occluded_sound__volumeSumSamplesTime.w == 0.
          occluded_sound__volume = occluded_sound__volumeSumSamplesTime.x
        occluded_sound__volumeSumSamplesTime.y = 0.
        occluded_sound__volumeSumSamplesTime.z = 0.
        occluded_sound__volumeSumSamplesTime.w = info.curTime

    occluded_sound__volume = approach(occluded_sound__volume, occluded_sound__volumeSumSamplesTime.x, info.dt, 0.1)

  sound_occlusion__targetId = nextTargetId
