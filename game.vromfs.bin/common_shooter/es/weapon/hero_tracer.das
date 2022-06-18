require ecs
require strings
require NetPropsRegistry

[es(tag=server, on_appear)]
def hero_tracer(evt : Event;
                hero_tracer__shellName : string;
                var hero_tracer__shellId : int&)
  if hero_tracer__shellId < 0
    hero_tracer__shellId = register_net_props(hero_tracer__shellName, "shell")
    register_net_props(hero_tracer__shellName, "damage")
    register_net_props(hero_tracer__shellName, "ballistics")
