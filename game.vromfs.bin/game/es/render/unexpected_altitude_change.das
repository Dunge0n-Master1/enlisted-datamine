require ecs
require danetlibs.renderer.includes.render_events

[es(tag=render, REQUIRE=(heroVehicle, airplane))]
def in_airplane_es(var evt : QueryUnexpectedAltitudeChange&)
  evt.enabled = true

[es(tag=render, REQUIRE=(vehicleWithWatched, airplane))]
def spectating_airplane_es(var evt : QueryUnexpectedAltitudeChange&)
  evt.enabled = true
