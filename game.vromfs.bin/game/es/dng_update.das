require ecs
require enlisted.events_enlisted

//This event's will be removed after all enlsited based game's will use ParallelUpdateFrameDelayed for dng system's
[cpp_event(broadcast)] // here for inability to use anywhere
struct UpdatePhysEvent
  curTime : float
  dt : float

[cpp_event(broadcast)]
struct UpdateAnimcharEvent
  curTime : float
  dt : float

[cpp_event(broadcast)]
struct UpdateActionsEvent
  dt : float


[es(after=before_net_phys_sync, before=(after_net_phys_sync, start_async_phys_sim_es))]
def update_phys_es(info : ParallelUpdateFrameDelayed)
  broadcastEventImmediate([[UpdatePhysEvent curTime=info.curTime, dt=info.dt]]);

[es(after=before_animchar_update_sync, before=after_animchar_update_sync)]
def animchar_es(info : ParallelUpdateFrameDelayed) // same name for save order of es
  broadcastEventImmediate([[UpdateAnimcharEvent curTime=info.curTime, dt=info.dt]]);

[es(before=start_async_phys_sim_es)]
def actions_es(info : ParallelUpdateFrameDelayed) // same name for save order of es (it was actions_es in Cpp)
  broadcastEventImmediate([[UpdateActionsEvent dt=info.dt]]);
