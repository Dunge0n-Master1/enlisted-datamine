module mm_events shared
require ecs

//may be moved this event in daNetGameLibs. Not enlisted only
[cpp_event(broadcast)]
struct ParallelUpdateFrameDelayed
  curTime : float
  dt : float

[cpp_event(broadcast)]
struct InvalidateAnimationDataBase {}