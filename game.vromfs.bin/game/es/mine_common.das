module mine_common shared
require ecs

def detonate_mine(mine_eid : EntityId; mineActivatorTemplate : string; owner : EntityId; tm : float3x4; delay = 0.)
  createEntity(mineActivatorTemplate) <| $(var init : ComponentsInitializer)
    set(init, "ownerEid", owner)
    set(init, "transform", tm)
    set(init, "activator__weaponEid", mine_eid)
    set(init, "activator__spawnShellDelay", delay)
