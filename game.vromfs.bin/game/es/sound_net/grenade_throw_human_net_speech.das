require ecs
require common_shooter.events_common_shooter
require game.es.sound_net.sound_net_events
require soundNetProps
require strings


[es(tag=server)]
def grenade_throw_human_net_speech(evt : EventOnGrenadeThrow; eid : EntityId)
  let shellSoundNetProps = shell_sound_net_try_get_props(evt.gun_props_id)
  if shellSoundNetProps != null
    let phrase : string = (*shellSoundNetProps).throwPhrase
    if !empty(phrase)
      sendEvent(eid, [[CmdRequestHumanSpeech phrase=phrase]])
