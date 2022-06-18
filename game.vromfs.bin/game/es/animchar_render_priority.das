require ecs

[es(REQUIRE=cockpitEntity, on_appear)]
def animchar_cockpit_priority_es(evt : Event; var animchar__renderPriority : bool&)
  animchar__renderPriority = true