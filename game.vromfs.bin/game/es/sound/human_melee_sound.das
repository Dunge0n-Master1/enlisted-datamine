require ecs
require app
require ecs.safe
require ecs.common
require soundEvent
require soundHash
require sound_utils.modules.sound_player_common
require game.es.sound.sound_events
require DagorRandom


def play_sound(name : string;
               path_obj : Object;
               sound_tags : Object;
               delay : float;
               is_watched_sound : bool;
               var sound_event_group : SoundEventGroup&;
               transform : float3x4)
  var path : string
  if sound_player_common::get_option_path(path_obj, sound_tags, is_watched_sound, path)
    if should_apply_watched_prefix(path)
      path = is_watched_sound ? "player{path}" : "enemy{path}"
    let handle = soundEvent::delayed_play(name, path, transform[3], delay)
    add_sound(sound_event_group, sound_hash(""), handle)


[es(tag=sound, REQUIRE=humanSound)]
def human_melee_sound_irq(evt : CmdSoundMeleeIrq;
                          human_melee_sound__repeatThreshold : float;
                          var human_melee_sound__repeatTime : float&;
                          [[shared_comp]] human_voice_sound__path : Object;
                          [[shared_comp]] human_melee_sound__irqs : Object;
                          sound_tags : Object;
                          var sound_event_group : SoundEventGroup&;
                          is_watched_sound : bool;
                          human_weap__gunEids : EidList const?;
                          human_weap__currentGunSlot : int const?;
                          transform : float3x4)
  if get_sync_time() < human_melee_sound__repeatTime + human_melee_sound__repeatThreshold
    return
  human_melee_sound__repeatTime = get_sync_time()

  if !is_watched_sound && !should_play(transform[3])
    return
  let gun = human_weap__gunEids != null && human_weap__currentGunSlot != null && *human_weap__currentGunSlot >= 0 ? (*human_weap__gunEids)[*human_weap__currentGunSlot] : INVALID_ENTITY_ID
  let meleeType : string = get_string(gun, "meleeSoundType", "hands")
  if meleeType == ""
    return

  let irqObj = get_ecs_object(human_melee_sound__irqs, evt.irq)
  let groups = irqObj != null ? get_ecs_array(*irqObj, "groups") : null
  if groups == null
    return

  for it in *groups
    let group = it as Object
    let weapon = (group?.weapons ?as Object)?[meleeType] ?as Object
    if weapon == null
      continue

    let groupId = (*group).id ?? ""

/*
    // tweak and debug sound delay

    let meleeDelay = 500
    let secondaryMeleeDelay = 500

    let voiceDelay = 1000
    let voiceChance = 100

    if groupId == "weapon_melee"
      play_sound("", *weapon, sound_tags, float(meleeDelay) * 0.001, is_watched_sound, sound_event_group, transform)

    if groupId == "weapon_secondary_melee"
      play_sound("", *weapon, sound_tags, float(secondaryMeleeDelay) * 0.001, is_watched_sound, sound_event_group, transform)

    if groupId == "voice_melee"
      if rnd_int(0, 100) <= voiceChance
        play_sound(get_string(*weapon, "name", "hands/whoosh"), human_voice_sound__path, sound_tags, float(voiceDelay) * 0.001, is_watched_sound, sound_event_group, transform)

    continue
*/

    if rnd_int(0, 100) <= ((*weapon).chance ?? 100)
      let delayMs = (*weapon).delay ?? 0
      if groupId == "voice_melee"
        play_sound(get_string(*weapon, "name", "hands/whoosh"), human_voice_sound__path, sound_tags, float(delayMs) * 0.001, is_watched_sound, sound_event_group, transform)
      else
        play_sound("", *weapon, sound_tags, float(delayMs) * 0.001, is_watched_sound, sound_event_group, transform)
