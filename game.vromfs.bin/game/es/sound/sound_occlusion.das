require ecs
require app
require soundSystem
require DagorSystem
require Dacoll
require math.base
require DagorMath
require AnimV20
require GeomNodeTree
require DagorRandom
require RendInst
require enlisted.events_enlisted

[es(tag=sound, no_order)]
def sound_occlusion_update(info : ParallelUpdateFrameDelayed;
                           var sound_occlusion__targetId : int&)

  var targetId = -1
  var nextTargetId = 0
  let from = get_listener_pos()
  query() <| $ [es] (occluded_sound__nearFarAttenuation : float2;
                     occluded_sound__radius : float;
                     occluded_sound__occlusionToVolume : float4;
                     occluded_sound__enabled : bool;
                     transform : float3x4? = null;
                     animchar : AnimcharBaseComponent? = null;
                     var occluded_sound__volume : float&;
                     var occluded_sound__volumeSumSamplesTime : float4&;
                     ri_extra__handle : riex_handle_t = RIEX_HANDLE_NULL)

    if !occluded_sound__enabled || (transform == null && animchar == null)
      occluded_sound__volume = 1.
      occluded_sound__volumeSumSamplesTime = float4(1., 0., 0., 0.)
      return

    var pos = transform != null ? (*transform)[3] : geomtree_getNodeWpos((*animchar).nodeTree, 0)
    var dist = length_sq(pos - from)
    if dist < square(occluded_sound__radius + 0.1) || dist > square(occluded_sound__nearFarAttenuation.y)
      occluded_sound__volumeSumSamplesTime = float4(occluded_sound__occlusionToVolume.x, 0., 0., 0.)
    else
      ++targetId
      if targetId == sound_occlusion__targetId
        nextTargetId = sound_occlusion__targetId + 1

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
            occluded_sound__volumeSumSamplesTime.y += cvt(dist, occluded_sound__nearFarAttenuation.x, occluded_sound__nearFarAttenuation.y, 1., 0.)
        occluded_sound__volumeSumSamplesTime.z += 1.

        if occluded_sound__radius == 0. || info.curTime > occluded_sound__volumeSumSamplesTime.w + 0.5
          let otv = occluded_sound__occlusionToVolume
          occluded_sound__volumeSumSamplesTime.x = cvt(occluded_sound__volumeSumSamplesTime.y / occluded_sound__volumeSumSamplesTime.z, otv.x, otv.y, otv.z, otv.w)
          if occluded_sound__volumeSumSamplesTime.w == 0.
            occluded_sound__volume = occluded_sound__volumeSumSamplesTime.x
          occluded_sound__volumeSumSamplesTime.y = 0.
          occluded_sound__volumeSumSamplesTime.z = 0.
          occluded_sound__volumeSumSamplesTime.w = info.curTime

    occluded_sound__volume = approach(occluded_sound__volume, occluded_sound__volumeSumSamplesTime.x, info.dt, 0.1)

  sound_occlusion__targetId = nextTargetId
