module navmesh_rebuild_events shared
require ecs

[event(broadcast)]
struct CmdNavMeshRebuildStart {}

[event(broadcast)]
struct CmdNavMeshRebuildCancel {}

[event(broadcast)]
struct EventNavMeshRebuildStarted {}

[event(broadcast)]
struct EventNavMeshRebuildProgress
  progress : float
  totalTime : float
  totalTiles : int
  numErrors : int

[event(broadcast)]
struct EventNavMeshRebuildComplete
  totalTime : float
  totalTiles : int
  numErrors : int

[event(broadcast)]
struct EventNavMeshRebuildCancelled {}
