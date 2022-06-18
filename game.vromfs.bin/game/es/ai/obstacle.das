require ecs
require game.es.events
require pathfinder

[es(tag=server, on_disappear)]
def obstacle_destroyed_es(evt : Event; var obstacle__handle : int&)
  tilecache_obstacle_remove(obstacle__handle)
  obstacle__handle = 0
