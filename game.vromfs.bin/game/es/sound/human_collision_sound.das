require ecs
require soundHash
require soundEvent
require sound_utils.modules.sound_player_common
require game.es.events
require EnlistedHuman
require DagorSystem
require DagorMath
require PhysMat

[es(tag=sound)]
def human_collision_sound(evt : CmdPostPhysUpdate;
                          human_net_phys : HumanActor;
                          human_net_phys__isClimbing : bool;
                          var human_collision_sound__time : float&;
                          var human_collision_sound__force : float&;
                          human_collision_sound__spdDiffMinMax : float2;
                          human_collision_sound__torsoContactVelocityMinMax : float2;
                          human_collision_sound__vertSpeedThreshold = 0.25;
                          human_collision_sound__timeThreshold = 0.5;
                          sound_tags : Object;
                          var sound_event_group : SoundEventGroup&;
                          [[shared_comp]] sound_paths : Object;
                          is_watched_sound : bool;
                          transform : float3x4)

  assume currentState = human_net_phys.phys.currentState
  if !is_watched_sound || human_net_phys__isClimbing || currentState.isAttachedToLadder
    return

  var force = 0.
  var descName = "collision"
  if (length_sq(currentState.spdSummaryDiff) >= human_collision_sound__spdDiffMinMax.x * human_collision_sound__spdDiffMinMax.x && abs(normalize(currentState.spdSummaryDiff).y) < human_collision_sound__vertSpeedThreshold)
    force = cvt(length(currentState.spdSummaryDiff), human_collision_sound__spdDiffMinMax.x, human_collision_sound__spdDiffMinMax.y, 0., 1.)

  let torsoContactMatId = currentState.torsoContactMatId
  if torsoContactMatId != PHYSMAT_INVALID
    let overrideForce = cvt(length(currentState.velocity), human_collision_sound__torsoContactVelocityMinMax.x, human_collision_sound__torsoContactVelocityMinMax.y, 0., 1.)
    if overrideForce > force
      let overrideDescName = "collision_{get_material_name(get_material(torsoContactMatId))}"
      if sound_player_common::get_desc(sound_paths, overrideDescName) != null
        force = overrideForce
        descName = overrideDescName

  human_collision_sound__force = force
  force = max(force, human_collision_sound__force)
  if force <= 0.
    return

  human_collision_sound__time += evt.dt
  if human_collision_sound__time > human_collision_sound__timeThreshold
    human_collision_sound__time = 0.
    human_collision_sound__force = 0.
    reject_sound(sound_event_group, sound_hash("collision"))

  var handle = get_sound(sound_event_group, sound_hash("collision"))
  if !is_playing(handle)
    handle = sound_player_common::play_path(descName, sound_paths, sound_tags, is_watched_sound, transform[3], sound_hash("collision"), sound_event_group)
    //logerr("play {descName} force={force}")

  set_var_optional(handle, "force", force)
  if read_sound_tag("armored", sound_tags)
    set_var_optional(handle, "armored", 1.)
