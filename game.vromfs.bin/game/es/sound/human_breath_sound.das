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

[es(tag=sound, track=human_net_phys__isHoldBreath, REQUIRE=humanSound)]
def human_breath_sound_hold(evt : Event;
                            human_net_phys__isHoldBreath : bool;
                            human_breath__isUnderWater : bool;
                            human_net_phys : HumanActor;
                            sound_tags : Object;
                            human_breath_sound__holdBreathEndDelay : float;
                            var human_breath_sound__breathStart : float&;
                            var sound_event_group : SoundEventGroup&;
                            [[shared_comp]] human_voice_sound__path : Object;
                            [[shared_comp]] human_voice_sound__descs : Object;
                            is_watched_sound : bool;
                            transform : float3x4;
                            isAlive : bool)
  if human_breath__isUnderWater || !isAlive
    return
  if human_net_phys__isHoldBreath
    sound_player_common::play("holdBreathStart", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash(""), sound_event_group)
  else
    let handle = sound_player_common::play("holdBreathEnd", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash(""), sound_event_group)
    set_var_optional(handle, "noairtime", human_net_phys.phys.currentState.breathShortness)
    human_breath_sound__breathStart = get_sync_time() + human_breath_sound__holdBreathEndDelay

[es(tag=sound, REQUIRE=humanSound, after=(update_sound_group_es, animchar_render_es))]
def human_breath_sound_update(info : UpdateStageInfoAct;
                              human_net_phys__states : int;
                              human_net_phys : HumanActor;
                              human_net_phys__isHoldBreath : bool;
                              human_breath__isUnderWater : bool;
                              human_net_phys__curMoveState : int;

                              human_breath_sound__breathStart : float;
                              var human_breath_sound__isBreath : bool&;
                              var human_breath_sound__breathShortness : float&;
                              var human_breath_sound__goodBreathNextTime : float&;

                              human_breath_sound__inhaleThreshold : float;
                              human_breath_sound__breathoutThreshold : float;
                              human_breath_sound__breathShortnessStart : float;
                              human_breath_sound__goodBreathDelay : float;
                              human_breath_sound__jumpDelay : float;
                              human_breath_sound__loHealthRel : float;
                              human_breath_sound__minBreathShortness : float;

                              sound_tags : Object;
                              var sound_event_group : SoundEventGroup&;
                              [[shared_comp]] human_voice_sound__path : Object;
                              [[shared_comp]] human_voice_sound__descs : Object;
                              is_watched_sound : bool;
                              transform : float3x4;
                              isAlive : bool;
                              isDowned : bool;
                              hitpoints__hp : float;
                              hitpoints__maxHp : float)

  if !isAlive || !is_watched_sound || isDowned || human_net_phys__isHoldBreath || human_breath__isUnderWater || info.curTime < human_breath_sound__breathStart
    human_breath_sound__isBreath = false
    release_sound(sound_event_group, sound_hash("breath"))
    release_sound(sound_event_group, sound_hash("inhale"))
    release_sound(sound_event_group, sound_hash("breathOut"))
    return

  let isOnGround = (human_net_phys__states & int(StateFlag ST_ON_GROUND)) != 0
  let isSprint = human_net_phys__curMoveState == int(HUMoveState EMS_SPRINT)
  let isLowHealth = hitpoints__hp < human_breath_sound__loHealthRel * hitpoints__maxHp
  let maxStamina = human_net_phys.phys.maxStamina * human_net_phys.phys.currentState.maxStaminaMult * human_net_phys.phys.currentState.staminaBoostMult
  let curStamina = cvt(human_net_phys.phys.currentState.stamina, 0., maxStamina, 0., 1.)
  var breathShortness = isLowHealth ? 1. : (1. - curStamina)

  if isSprint || breathShortness > human_breath_sound__breathShortness
    human_breath_sound__goodBreathNextTime = max(human_breath_sound__goodBreathNextTime, info.curTime + human_breath_sound__goodBreathDelay)

  if !isOnGround
    human_breath_sound__goodBreathNextTime = max(human_breath_sound__goodBreathNextTime, info.curTime + human_breath_sound__jumpDelay)

  var isPoorBreath = breathShortness >= human_breath_sound__breathShortnessStart && info.curTime < human_breath_sound__goodBreathNextTime

  if human_breath_sound__minBreathShortness > 0.
    breathShortness = max(breathShortness, human_breath_sound__minBreathShortness)
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
    if max(human_breath_sound__breathShortness, breathShortness) > human_breath_sound__breathoutThreshold
      sound_player_common::play("sprintBreathOut", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash("breathOut"), sound_event_group)

  if isPoorBreath && human_breath_sound__breathShortness < human_breath_sound__inhaleThreshold && breathShortness >= human_breath_sound__inhaleThreshold
    sound_player_common::play("inhale", human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, transform[3], sound_hash("inhale"), sound_event_group)

  human_breath_sound__breathShortness = breathShortness
