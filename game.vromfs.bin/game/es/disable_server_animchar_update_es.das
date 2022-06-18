require ecs

[es(tag=(server, net),
    on_appear,
    track=animchar__updatable,
    REQUIRE_NOT = animchar_render,
    REQUIRE = noDedicatedUpdate)]
def disable_server_animchar_updates(evt : Event;
                                    var animchar__updatable : bool&)
  animchar__updatable = false