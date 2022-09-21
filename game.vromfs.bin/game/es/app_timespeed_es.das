require ecs
require app

[es(on_appear, track=app__timeSpeed)]
def app_timespeed_es(evt : Event; app__timeSpeed : float)
  set_timespeed(app__timeSpeed)

[es(on_disappear, REQUIRE=app__timeSpeed)]
def app_reset_timespeed_es(evt : Event)
  set_timespeed(1.0)
