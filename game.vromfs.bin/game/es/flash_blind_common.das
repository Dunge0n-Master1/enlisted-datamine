module flash_blind_common shared
require ecs
require app
require ecs.common
require game.utils.hero

def stop_flash_blind_affect(owner_eid : EntityId)
  find_query() <| $ [es(REQUIRE=flashBlindScreenEffect)] (eid : EntityId; game_effect__attachedTo : EntityId)
    if game_effect__attachedTo != owner_eid
      return false
    destroyEntity(eid)
    return true

def fire_flash_blind_affect(owner_eid : EntityId; intensity : float)
  stop_flash_blind_affect(owner_eid)
  createEntity("flash_blind_affect") <| $(var init : ComponentsInitializer)
    set(init, "game_effect__attachedTo", owner_eid)
    set(init, "flash_blind__intensity", intensity)
