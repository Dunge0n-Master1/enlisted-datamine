require ecs
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common
require DngHuman
require DagorSystem
require DagorMath
require math.base


[es(tag=sound, REQUIRE=watchedByPlr, on_event=CmdPostPhysUpdate)]
def human_collision_hit_sound(evt : Event;
                              human_net_phys : HumanActor;
                              human_net_phys__isClimbing : bool;
                              var human_collision_hit_sound__forceMax : float&;
                              human_collision_hit_sound__spdSummaryToForce : float4;
                              human_collision_hit_sound__vertSpeedThreshold : float;
                              sound_tags : Object;
                              var sound_event_group : SoundEventGroup&;
                              [[shared_comp]] sound_paths : Object;
                              is_watched_sound : bool;
                              transform : float3x4)

  assume currentState = human_net_phys.phys.currentState
  if !human_net_phys__isClimbing && !currentState.isAttachedToLadder
    assume spdToForce = human_collision_hit_sound__spdSummaryToForce
    if (length_sq(currentState.spdSummaryDiff) > square(spdToForce.x) && abs(normalize(currentState.spdSummaryDiff).y) < human_collision_hit_sound__vertSpeedThreshold)
      let force = cvt(length(currentState.spdSummaryDiff), spdToForce.x, spdToForce.y, spdToForce.z, spdToForce.w)
      var handle = get_sound(sound_event_group, sound_hash("collision"))
      if !is_playing(handle)
        reject_sound(sound_event_group, sound_hash("collision"))
        handle = sound_player_common::play_path("collision", sound_paths, sound_tags, is_watched_sound, transform[3], sound_hash("collision"), sound_event_group)
        if read_sound_tag("armored", sound_tags)
          set_var_optional(handle, "armored", 1.)
        human_collision_hit_sound__forceMax = force
      human_collision_hit_sound__forceMax = max(human_collision_hit_sound__forceMax, force)
      set_var_optional(handle, "force", human_collision_hit_sound__forceMax)
