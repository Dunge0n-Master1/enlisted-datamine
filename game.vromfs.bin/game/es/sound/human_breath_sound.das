require ecs
require app
require HumanPhys
require EnlistedHuman
require soundEvent
require soundHash
require sound_utils.modules.sound_player_common
require math
require math.base
require DagorMath
require enlisted.events_enlisted


[es(tag=sound, track=human_net_phys__isHoldBreath, REQUIRE=humanSound)]
def human_breath_sound_hold(evt : Event;
                            human_net_phys__isHoldBreath : bool;
                            human_net_phys : HumanActor;
                            sound_tags : Object;
                            human_breath_sound__canBreath : bool;
                            human_breath_sound__holdBreathEndDelay : float;
                            var human_breath_sound__breathStart : float&;
                            var sound_event_group : SoundEventGroup&;
                            [[shared_comp]] human_voice_sound__path : Object;
                            [[shared_comp]] human_voice_sound__descs : Object;
                            is_watched_sound : bool;
                            transform : float3x4)
  if !human_breath_sound__canBreath
    return
  if human_net_phys__isHoldBreath
    sound_player_common::play("holdBreathStart", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash(""), sound_event_group)
  else
    let handle = sound_player_common::play("holdBreathEnd", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash(""), sound_event_group)
    set_var_optional(handle, "noairtime", human_net_phys.phys.currentState.breathShortness)
    human_breath_sound__breathStart = get_sync_time() + human_breath_sound__holdBreathEndDelay


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=(update_sound_group_using_animchar_es, animchar_render_es, human_voice_enable))]
def human_breath_sound_base_update(evt : Event;
                                   var human_breath_sound__canBreath : bool&;
                                   human_voice_enable : bool;
                                   human_voice_effect__type : string;
                                   human_breath_sound__baseBreathShortness : float;
                                   var human_breath_sound__breathShortness : float&)
  human_breath_sound__canBreath = human_voice_enable && human_voice_effect__type == ""
  human_breath_sound__breathShortness = human_breath_sound__baseBreathShortness


[es(tag=sound, after=human_breath_sound_base_update)]
def human_breath_sound_update(info : ParallelUpdateFrameDelayed;
                              human_net_phys__states : int;
                              human_net_phys : HumanActor;
                              human_net_phys__isHoldBreath : bool;
                              human_net_phys__curMoveState : int;

                              human_breath_sound__canBreath : bool;
                              human_breath_sound__breathStart : float;
                              var human_breath_sound__isBreath : bool&;
                              var human_breath_sound__prevBreathShortness : float&;
                              var human_breath_sound__goodBreathNextTime : float&;

                              human_breath_sound__inhaleThreshold : float;
                              human_breath_sound__breathoutThreshold : float;
                              human_breath_sound__breathShortnessStart : float;
                              human_breath_sound__goodBreathDelay : float;
                              human_breath_sound__jumpDelay : float;
                              human_breath_sound__loHealthRel : float;
                              human_breath_sound__breathShortness : float;

                              human__totalMaxStamina : float;
                              sound_tags : Object;
                              var sound_event_group : SoundEventGroup&;
                              [[shared_comp]] human_voice_sound__path : Object;
                              [[shared_comp]] human_voice_sound__descs : Object;
                              is_watched_sound : bool;
                              transform : float3x4;
                              isDowned : bool;
                              hitpoints__hp : float;
                              hitpoints__maxHp : float)

  if !is_watched_sound || isDowned || human_net_phys__isHoldBreath || !human_breath_sound__canBreath || info.curTime < human_breath_sound__breathStart
    human_breath_sound__isBreath = false
    release_sound(sound_event_group, sound_hash("breath"))
    release_sound(sound_event_group, sound_hash("inhale"))
    release_sound(sound_event_group, sound_hash("breathOut"))
    return

  let isOnGround = (human_net_phys__states & int(StateFlag ST_ON_GROUND)) != 0
  let isSprint = human_net_phys__curMoveState == int(HUMoveState EMS_SPRINT)
  let isLowHealth = hitpoints__hp < human_breath_sound__loHealthRel * hitpoints__maxHp
  let curStamina = cvt(human_net_phys.phys.currentState.stamina, 0., human__totalMaxStamina, 0., 1.)
  var breathShortness = isLowHealth ? 1. : (1. - curStamina)
  if isSprint || breathShortness > human_breath_sound__prevBreathShortness
    human_breath_sound__goodBreathNextTime = max(human_breath_sound__goodBreathNextTime, info.curTime + human_breath_sound__goodBreathDelay)

  if !isOnGround
    human_breath_sound__goodBreathNextTime = max(human_breath_sound__goodBreathNextTime, info.curTime + human_breath_sound__jumpDelay)

  var isPoorBreath = breathShortness >= human_breath_sound__breathShortnessStart && info.curTime < human_breath_sound__goodBreathNextTime

  if human_breath_sound__breathShortness > 0.
    breathShortness = max(breathShortness, human_breath_sound__breathShortness)
    isPoorBreath = true // always have poor breath

  if isPoorBreath || isLowHealth
    if !human_breath_sound__isBreath
      human_breath_sound__isBreath = true
      sound_player_common::play("sprintBreath", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash("breath"), sound_event_group)
    let handle = get_sound(sound_event_group, sound_hash("breath"))
    set_var(handle, "Stamina", (1. - saturate(breathShortness)) * 100.)
  elif human_breath_sound__isBreath
    human_breath_sound__isBreath = false
    reject_sound(sound_event_group, sound_hash("breath"))
    if max(human_breath_sound__prevBreathShortness, breathShortness) > human_breath_sound__breathoutThreshold
      sound_player_common::play("sprintBreathOut", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash("breathOut"), sound_event_group)

  if isPoorBreath && human_breath_sound__prevBreathShortness < human_breath_sound__inhaleThreshold && breathShortness >= human_breath_sound__inhaleThreshold
    sound_player_common::play("inhale", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash("inhale"), sound_event_group)

  human_breath_sound__prevBreathShortness = breathShortness
