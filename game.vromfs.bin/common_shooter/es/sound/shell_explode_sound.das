require ecs
require soundEvent
require shellSoundProps
require common_shooter.events_common_shooter
require strings


[es(tag=sound, REQUIRE=msg_sink)]
def shell_explode_sound(evt : EventOnShellExploded)
  let shellSoundProps = shell_sound_try_get_props(int(evt.shellId))
  if shellSoundProps != null && !empty(shellSoundProps.explSoundPath)
    oneshot(shellSoundProps.explSoundPath, evt.explPos) // shell explosion sound
