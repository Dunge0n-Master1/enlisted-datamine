require ecs
require enlisted.game.es.ai_custom_nav_common

[es(tag=server, after=navigation_tilecache_es, before=(beh_tree_update_es, turret_avoid_nav_update_es))]
def custom_nav_tile_remove(act : UpdateStageInfoAct)
  remove_tile_cache_tiles()