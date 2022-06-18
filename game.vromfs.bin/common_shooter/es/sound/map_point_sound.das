require ecs
require soundEvent

[es(tag=sound, on_event=CmdCreateMapPoint, REQUIRE=player)]
def map_point_sound_on_point_create(evt : Event)
  oneshot("ui/map_command")
