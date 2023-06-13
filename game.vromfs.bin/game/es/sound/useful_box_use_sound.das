require ecs
require soundEvent
require game.es.events


[es(tag=sound, REQUIRE=hero)]
def useful_box_play_complete_sound(evt : CmdUsefulBoxCompleteUse)
  let sound = get_string(evt.box, "useful_box__useSound", "")
  if !empty(sound)
    oneshot(sound)
