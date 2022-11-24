options no_aot
require ecs
require sandbox.es.navmesh_rebuild_events
require DagorConsole

[console_cmd(name="navmesh.rebuild_start")]
def navmesh_rebuild_start_cmd()
  broadcastEventImmediate([[CmdNavMeshRebuildStart]])

[console_cmd(name="navmesh.rebuild_cancel")]
def navmesh_rebuild_cancel_cmd
  broadcastEventImmediate([[CmdNavMeshRebuildCancel]])
