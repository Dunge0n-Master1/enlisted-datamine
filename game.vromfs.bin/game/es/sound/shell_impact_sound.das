require ecs
require soundEvent

[es(on_disappear, tag=sound, REQUIRE_NOT=clientSide)]
def shell_impact_sound(evt : Event;
                       shell_impact_sound__path : string;
                       transform : float3x4)
  oneshot(shell_impact_sound__path, transform[3])
