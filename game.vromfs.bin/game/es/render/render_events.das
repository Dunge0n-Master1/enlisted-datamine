module render_events shared
require ecs

[cpp_event(broadcast)]
struct SetResolutionEvent
  type_ : int
  displayResolution : int2
  renderingResolution : int2
  postFxResolution : int2

[cpp_event(broadcast)]
struct QueryUnexpectedAltitudeChange
  enabled : bool = false
