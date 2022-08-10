module ai_custom_nav_common shared

require ecs
require app
require game.events_game
require EnlistedWalkerai

require pathfinder

def remove_tile_cache_tiles()
  query() <| $ [es] (var walker_agent : EntityAgent)
    if walker_agent.customNav != null
      walk_removed_tile_cache_tiles() <| $(removedTiles)
        for tile in removedTiles
          walker_agent_nav_removeTile(walker_agent, tile)

  clear_removed_tile_cache_tiles()

def remove_builded_tile_cache_tiles()
  query() <| $ [es] (var walker_agent : EntityAgent)
    if walker_agent.customNav != null
      walk_removed_rebuild_tile_cache_tiles() <| $(removedTiles)
        for tile in removedTiles
          walker_agent_nav_removeTile(walker_agent, tile)

  clear_removed_rebuild_tile_cache_tiles()