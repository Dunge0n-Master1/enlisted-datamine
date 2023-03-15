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

[cpp_event(broadcast)]
struct UpdateStageInfoBeforeRender
  viewTm : TMatrix
  projTm : mat44f
  globTm : mat44f
  dt : float
  actDt : float
  realDt : float
  mainCullingFrustum : Frustum
  froxelFogCullingFrustum : Frustum
  mainOcclusion : void?
  mainInvHkSq : float
  camPos : float3
  dirFromSun : float3
  negRoundedCamPos : float4
  negRemainderCamPos : float4


[cpp_event(broadcast)]
struct AfterDeviceReset
  fullReset : bool