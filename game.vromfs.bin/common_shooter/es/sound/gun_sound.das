require ecs
require app
require ecs.common
require soundEvent
require soundHash
require soundSystem
require game.es.events
require sound_utils.modules.sound_utils_events
require sound_utils.modules.sound_player_common
require common_human_sounds.modules.common_human_sounds_events
require DagorMath
require DagorSystem
require Gun
require DaWeapons
require common_shooter.events_common_shooter
require strings
require enlisted.events_enlisted

def try_shot_loop(gun_owner : EntityId; pos : float3; shot_path : Object; tags : Object; is_watched : bool)
  var handle = invalid_sound_event_handle()
  let name = "shot_loop"
  var path = ""
  if !get_option_path(shot_path, tags, is_watched, path)
    return handle
  if should_apply_watched_prefix(path)
    path = is_watched ? "player{path}" : "enemy{path}"

  var hasGroup = false
  query(gun_owner) <| $ [es] (var gun_owner_sound_event_group : SoundEventGroup&)
    hasGroup = true
    if !has_sound(gun_owner_sound_event_group, name, path)
      handle = sound_player_common::play_name_path_impl(name, path, pos, false)
      if get_num_sounds(gun_owner_sound_event_group) < get_max_capacity(gun_owner_sound_event_group)
        add_sound(gun_owner_sound_event_group, sound_hash(""), float3(0., 0., 0.), handle, 0)
      else
        sound_debug("gun_owner_sound_event_group max capacity reached ({get_num_sounds(gun_owner_sound_event_group)}), sound will flange")
  if !hasGroup
    handle = sound_player_common::play_name_path_impl(name, path, pos, false)
  return handle


def is_oneshot(gun : Gun; firing_mode : uint)
  return gun_getFiringMode(gun, int(firing_mode)).modeType != EFiringModeType EFM_AUTOMATIC

def get_pos(animchar_bbox : bbox3f) // TODO: move to module
  return (animchar_bbox.bmin.xyz + animchar_bbox.bmax.xyz) * 0.5


def on_launch(tm : float3x4;
              firing_mode : uint;
              gun : Gun;
              gun_sound__isWatched : bool;
              time_between_shots : float;
              force_oneshot, force_oneshot_enemy : bool;
              start_loop_with_n_oneshots : int;
              var num_shots_in_loop : int&;
              var sound_event : SoundEvent&;
              time_between_shots_mad : float2;
              var shot_loop_timeout : float&;
              turret__owner : EntityId;
              shot_path : Object;
              tags : Object)

  assume launchPos = tm[3]
  let forceOneshot = gun_sound__isWatched ? force_oneshot : force_oneshot_enemy
  var isOneshot = forceOneshot || is_oneshot(gun, firing_mode)
  var isLoop = false

  // force N oneshots on loop start
  if !isOneshot && gun_sound__isWatched && start_loop_with_n_oneshots > 0
    if num_shots_in_loop == -1
      num_shots_in_loop = start_loop_with_n_oneshots
    if num_shots_in_loop > 0
      --num_shots_in_loop
      isOneshot = true

  if isOneshot
    abandon(sound_event.handle)

    let name = "shot_single"
    var path = ""
    if !get_option_path(shot_path, tags, gun_sound__isWatched, path)
      return
    if should_apply_watched_prefix(path)
      path = gun_sound__isWatched ? "player{path}" : "enemy{path}"

    sound_player_common::play_name_path(name, path, launchPos)
  else
    isLoop = sound_event.handle != invalid_sound_event_handle()
    if sound_event.handle == invalid_sound_event_handle()
      sound_event.handle = try_shot_loop(turret__owner, launchPos, shot_path, tags, gun_sound__isWatched)
    if sound_event.handle != invalid_sound_event_handle()
      set_pos(sound_event.handle, launchPos)

  broadcastEvent([[EventOnWeaponSound pos=launchPos, isLoop=isLoop]])
  shot_loop_timeout = (time_between_shots * time_between_shots_mad.x + time_between_shots_mad.y)



[es(tag=sound, REQUIRE=gunSound)]
def gun_sound_on_shot(evt : EventShot;
                      gun : Gun;
                      gun_sound__isWatched : bool;
                      gun__timeBetweenShots : float = 0.;
                      gun_sound__forceOneshot : bool;
                      gun_sound__forceOneshotEnemy : bool;
                      gun_sound__startLoopWithNOneshots : int;
                      var gun_sound__numShotsInLoop : int&;
                      var gun_sound__event : SoundEvent&;
                      gun_sound__playerTimeBetweenShotsMad : float2;
                      var gun_sound__shotLoopTimeout : float&;
                      turret__owner = INVALID_ENTITY_ID;
                      [[shared_comp]] gun_sound__shotPath : Object;
                      sound_tags : Object;
                      gun_sound__isEnabled : bool;
                      sound_bank_preset_state__isValid : bool)
  if gun_sound__isEnabled && sound_bank_preset_state__isValid
    on_launch(evt.launchDesc.tm,
              evt.launchDesc.firingMode,
              gun,
              gun_sound__isWatched,
              gun__timeBetweenShots,
              gun_sound__forceOneshot,
              gun_sound__forceOneshotEnemy,
              gun_sound__startLoopWithNOneshots,
              gun_sound__numShotsInLoop,
              gun_sound__event,
              gun_sound__playerTimeBetweenShotsMad,
              gun_sound__shotLoopTimeout,
              turret__owner,
              gun_sound__shotPath,
              sound_tags)


[es(tag=sound, REQUIRE=gunSound)]
def gun_sound_on_net_shot(evt : CmdNetShot;
                          gun : Gun;
                          gun_sound__isWatched : bool;
                          gun__timeBetweenShots : float = 0.;
                          gun_sound__forceOneshot : bool;
                          gun_sound__forceOneshotEnemy : bool;
                          gun_sound__startLoopWithNOneshots : int;
                          var gun_sound__numShotsInLoop : int&;
                          var gun_sound__event : SoundEvent&;
                          gun_sound__netTimeBetweenShotsMad : float2;
                          var gun_sound__shotLoopTimeout : float&;
                          turret__owner = INVALID_ENTITY_ID;
                          [[shared_comp]] gun_sound__shotPath : Object;
                          sound_tags : Object;
                          gun_sound__isEnabled : bool;
                          sound_bank_preset_state__isValid : bool)
  if gun_sound__isEnabled && sound_bank_preset_state__isValid
    on_launch(evt.tm,
              evt.firingMode,
              gun,
              gun_sound__isWatched,
              gun__timeBetweenShots,
              gun_sound__forceOneshot,
              gun_sound__forceOneshotEnemy,
              gun_sound__startLoopWithNOneshots,
              gun_sound__numShotsInLoop,
              gun_sound__event,
              gun_sound__netTimeBetweenShotsMad,
              gun_sound__shotLoopTimeout,
              turret__owner,
              gun_sound__shotPath,
              sound_tags)


def is_shooting(gun_sound__shotLoopTimeout : float)
  return gun_sound__shotLoopTimeout > 0.

[es(tag=sound, REQUIRE=gunSound, no_order)]
def gun_sound_update(info : ParallelUpdateFrameDelayed;
                     var gun_sound__shotLoopTimeout : float&;
                     var gun_sound__deltaTime : float4&;
                     var gun_sound__numShotsInLoop : int&;
                     var gun_sound__event : SoundEvent&;
                     gun_sound__isEnabled : bool;
                     sound_bank_preset_state__isValid : bool;
                     gun__overheat : float = 0.;
                     turret__owner = INVALID_ENTITY_ID)

  if gun_sound__event.handle != invalid_sound_event_handle()
    set_var_optional(gun_sound__event.handle, "heat", gun__overheat)
    if !gun_sound__isEnabled || !sound_bank_preset_state__isValid || !is_shooting(gun_sound__shotLoopTimeout)
      query(turret__owner) <| $ [es] (var gun_owner_sound_event_group : SoundEventGroup&)
        remove_sound(gun_owner_sound_event_group, gun_sound__event.handle)
      abandon(gun_sound__event.handle)
      //logerr("abandon gun_sound__event at {info.curTime} ---------------------------------")

  if gun_sound__numShotsInLoop != -1 && !is_shooting(gun_sound__shotLoopTimeout)
    gun_sound__numShotsInLoop = -1

  gun_sound__deltaTime.w = gun_sound__deltaTime.z
  gun_sound__deltaTime.z = gun_sound__deltaTime.y
  gun_sound__deltaTime.y = gun_sound__deltaTime.x
  gun_sound__deltaTime.x = info.dt
  gun_sound__shotLoopTimeout -= min(min(min(gun_sound__deltaTime.x, gun_sound__deltaTime.y), gun_sound__deltaTime.z), gun_sound__deltaTime.w)


[es(tag=sound, REQUIRE=gunSound)]
def gun_sound_on_irq(evt : CmdSoundGenIrq;
                     animchar_bbox : bbox3f;
                     gun_sound__isEnabled : bool;
                     sound_bank_preset_state__isValid : bool;
                     gun_sound__isWatched : bool;
                     sound_tags : Object;
                     [[shared_comp]] sound_irqs : Object;
                     sound_max_irq_dist = 40.)
  if gun_sound__isEnabled && sound_bank_preset_state__isValid
    if gun_sound__isWatched || should_play(get_pos(animchar_bbox), sound_max_irq_dist)
      sound_player_common::play_path(evt.irq, sound_irqs, sound_tags, gun_sound__isWatched, get_pos(animchar_bbox))


[es(tag=sound, track=sound_bank_preset_state__isValid, REQUIRE=gunSound)]
def gun_sound_toggle(evt : Event;
                     sound_bank_preset_state__isValid : bool;
                     var gun_sound__event : SoundEvent&)
  if !sound_bank_preset_state__isValid
    release_immediate(gun_sound__event.handle)


[es(tag=sound, after=animchar_render_es)]
def gun_owner_sound_event_group_update(info : ParallelUpdateFrameDelayed;
                                       var gun_owner_sound_event_group : SoundEventGroup&)
  update_sounds(gun_owner_sound_event_group)
