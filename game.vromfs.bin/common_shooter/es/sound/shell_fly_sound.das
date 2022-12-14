require ecs
require ecs.safe
require soundEvent
require Ballistics
require DagorMath
require DaWeapons
require DagorSystem
require game.utils.hero
require game.utils.team
require soundSystem
require EnlistedDm
require math.base


def update_shell_fly_sound(enable : bool; var event : SoundEvent&; path : string; pos : float3)
  if enable
    if !event.enabled
      event.enabled = true
      event |> play(path, pos)
    else
      set_pos(event.handle, pos)
  elif event.enabled
    event.enabled = false
    release(event.handle)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=animchar_render_es, REQUIRE_NOT=(projectile_ballistics, shell_fly_sound__isLoud))]
def shell_fly_sound_with_transform(evt : Event;
                                   active : bool = true;
                                   shell_fly_sound__path : string;
                                   var shell_fly_sound__event : SoundEvent&;
                                   transform : float3x4;
                                   projectile__stopped : bool = false)
  update_shell_fly_sound(active && !projectile__stopped, shell_fly_sound__event, shell_fly_sound__path, transform[3])


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=animchar_render_es, REQUIRE_NOT=shell_fly_sound__isLoud)]
def shell_fly_sound_with_ballistics(evt : Event;
                                    active : bool = true;
                                    shell_fly_sound__path : string;
                                    var shell_fly_sound__event : SoundEvent&;
                                    projectile_ballistics : ProjectileBallistics;
                                    projectile__stopped : bool = false)
  update_shell_fly_sound(active && !projectile__stopped, shell_fly_sound__event, shell_fly_sound__path, projectile_ballistics.state.pos)


def is_loud(launch_desc : LaunchDesc; pos : float3; radius_mul : float; owner_eid : EntityId; shouldPlayForAllTeams : bool)
  let maxRadius = radius_mul * get_shell_max_radius(int(launch_desc.shellId.shellId), int(launch_desc.shellId.damageId), int(launch_desc.shellId.ballisticsId))
  //logerr("pos={pos}, maxRadius={maxRadius}, dist={length(get_listener_pos().xz - pos.xz)}, offenderTeam={offenderTeam} {owner_eid}")
  return maxRadius > 0. && length_sq(get_listener_pos().xz - pos.xz) < square(maxRadius) && (shouldPlayForAllTeams || should_shell_damage(get_watched_entity(), owner_eid, TEAM_UNASSIGNED))

[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=animchar_render_es)]
def loud_shell_fly_sound_update(evt : Event;
                                active : bool = true;
                                shell_fly_sound__path : string;
                                shell_fly_sound__loudPath : string;
                                shell_fly_sound__isLoudMaxRadiusMul : float;
                                var shell_fly_sound__isLoud : bool&;
                                var shell_fly_sound__event : SoundEvent&;
                                launch_desc : LaunchDesc;
                                projectile_ballistics : ProjectileBallistics;
                                projectile__stopped : bool = false;
                                ownerEid = INVALID_ENTITY_ID;
                                shell_fly_sound__shouldPlayForAllTeams : bool = false)
  let enable = active && !projectile__stopped
  if enable && !shell_fly_sound__isLoud && is_loud(launch_desc, projectile_ballistics.state.pos,
                                                   shell_fly_sound__isLoudMaxRadiusMul, ownerEid, shell_fly_sound__shouldPlayForAllTeams)
    shell_fly_sound__isLoud = true
    shell_fly_sound__event.enabled = false
    release(shell_fly_sound__event.handle)
  let path = shell_fly_sound__isLoud ? shell_fly_sound__loudPath : shell_fly_sound__path
  update_shell_fly_sound(enable, shell_fly_sound__event, path, projectile_ballistics.state.pos)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=(shell_fly_sound_with_ballistics_es, shell_fly_sound_with_transform_es, loud_shell_fly_sound_es))]
def shell_fly_sound_apply_speed(evt : Event;
                                shell_fly_sound__event : SoundEvent&;
                                shell_fly_sound_speed_to_volume : float4;
                                projectile_ballistics : ProjectileBallistics)
  if shell_fly_sound__event.enabled
    let vol = cvt(length(projectile_ballistics.state.vel), shell_fly_sound_speed_to_volume.x, shell_fly_sound_speed_to_volume.y, shell_fly_sound_speed_to_volume.z, shell_fly_sound_speed_to_volume.w)
    set_volume(shell_fly_sound__event.handle, vol)
