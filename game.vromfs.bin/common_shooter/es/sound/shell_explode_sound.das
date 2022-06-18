require ecs
require soundEvent
require soundProps
require common_shooter.events_common_shooter


[es(tag=sound, REQUIRE=msg_sink)]
def shell_explode_sound(evt : EventOnShellExploded)
  let shellExplSoundProps = shell_expl_sound_try_get_props(int(evt.shellId))
  if shellExplSoundProps != null
    if shellExplSoundProps.explSoundPath != ""
      oneshot(shellExplSoundProps.explSoundPath, evt.explPos) // shell explosion sound
