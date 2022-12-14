require ecs
require soundEvent
require sound_utils.modules.sound_player_common
require HumanPhys


[es(tag=sound, track=(human_net_phys__curMoveState, sleep_mode__isActivated), on_appear)]
def human_idle_sound_is_idle(evt : Event;
                             var human_idle_sound__isActive : bool&;
                             human_net_phys__curMoveState : int = int(HUMoveState EMS_SPRINT);
                             sleep_mode__isActivated : bool = true)
  human_idle_sound__isActive = sleep_mode__isActivated && (human_net_phys__curMoveState == int(HUMoveState EMS_SPRINT) ||
                                                           human_net_phys__curMoveState == int(HUMoveState EMS_RUN))


[es(tag=sound, REQUIRE=humanIdleSound, track=(human_idle_sound__isActive, sound_control__shouldPlay), on_appear)]
def human_idle_sound(evt : Event;
                     sound_control__shouldPlay : bool;
                     human_idle_sound__isActive : bool = false;
                     sound_tags : Object;
                     [[shared_comp]] human_idle_sound__paths : Object;
                     var human_idle_sound__event : SoundEvent&;
                     is_watched_sound : bool;
                     transform : float3x4;
                     isAlive : bool;
                     isDowned : bool)
  abandon(human_idle_sound__event.handle)
  if sound_control__shouldPlay && isAlive && !isDowned
    let path = human_idle_sound__isActive ? "activeState" : "idleState"
    human_idle_sound__event.handle = sound_player_common::play_path(path, human_idle_sound__paths, sound_tags, is_watched_sound, transform[3], false)
