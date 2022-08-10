module render_events shared
require ecs
require DagorDriver3D
require DagorMath


[cpp_event(broadcast)]
struct SetResolutionEvent
  type_ : int
  displayResolution : int2
  renderingResolution : int2
  postFxResolution : int2

[cpp_event(broadcast)]
struct QueryUnexpectedAltitudeChange
  enabled : bool = false

[cpp_event(broadcast)]
struct RenderEventUI
  viewTm : TMatrix
  viewItm : TMatrix
  globtm : mat44f
  persp : Driver3dPerspective

[cpp_event(broadcast)]
struct RenderEventAfterUI
  viewTm : TMatrix
  viewItm : TMatrix
  globtm : mat44f
  persp : Driver3dPerspective
