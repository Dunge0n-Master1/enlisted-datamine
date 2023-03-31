require ecs
require sound_utils.modules.sound_player_common
require sound_utils_net.modules.sound_utils_net_events
require soundEvent
require DagorMath
require mech


[es(tag=sound)]
def mech_collision_sound_update(evt : ParallelUpdateFrameDelayed;
                                var mech_collision_sound__isFallen : bool&;
                                var mech_collision_sound__prevSoundShockSummary : float&;
                                var mech_collision_sound__mayPlayFallAt : float&;
                                var mech_collision_sound__mayPlayCollAt : float&;
                                mech_collision_sound__fallCooldown : float;
                                mech_collision_sound__collCooldown : float;
                                mech_collision_sound__collMinMax : float2;
                                [[shared_comp]] mech_collision_sound__fallStartPath : Object;
                                [[shared_comp]] mech_collision_sound__fallPath : Object;
                                [[shared_comp]] mech_collision_sound__collPath : Object;
                                sound_tags : Object;
                                transform : float3x4;
                                is_watched_sound : bool;
                                walker_net_phys : WalkerPhysActor)

  if mech_collision_sound__isFallen != walker_net_phys.phys.currentState.isFallenDown
    mech_collision_sound__isFallen = walker_net_phys.phys.currentState.isFallenDown
    if mech_collision_sound__isFallen
      mech_collision_sound__mayPlayFallAt = evt.curTime + mech_collision_sound__fallCooldown
      sound_player_common::play_path(mech_collision_sound__fallStartPath, sound_tags, is_watched_sound, transform[3])

  let delta = walker_net_phys.phys.currentState.soundShockSummary - mech_collision_sound__prevSoundShockSummary
  if delta > 0.
    if mech_collision_sound__mayPlayFallAt > 0. && evt.curTime >= mech_collision_sound__mayPlayFallAt
      mech_collision_sound__mayPlayFallAt = 0.
      sound_player_common::play_path(mech_collision_sound__fallPath, sound_tags, is_watched_sound, transform[3])

    if evt.curTime >= mech_collision_sound__mayPlayCollAt
      mech_collision_sound__mayPlayCollAt = evt.curTime + mech_collision_sound__collCooldown
      if delta > mech_collision_sound__collMinMax.x
        var handle = sound_player_common::play_path(mech_collision_sound__collPath, sound_tags, is_watched_sound, transform[3], false)
        set_var(handle, "force", cvt(delta, mech_collision_sound__collMinMax.x, mech_collision_sound__collMinMax.y, 0., 1.))
        abandon(handle)

  mech_collision_sound__prevSoundShockSummary = walker_net_phys.phys.currentState.soundShockSummary
