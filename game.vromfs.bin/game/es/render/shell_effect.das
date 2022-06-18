require ecs
require fx
require math.base

[es(on_disappear, tag=render, REQUIRE_NOT=clientSide)]
def shell_impact_effect_es(evt : Event;
                           shell_impact_effect__name : string;
                           transform : float3x4)
  start_effect(shell_impact_effect__name, transform, IDENT_TM)
