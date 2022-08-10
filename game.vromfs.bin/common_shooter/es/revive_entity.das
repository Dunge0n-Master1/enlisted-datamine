require ecs
require math
require math.base
require enlisted.events_enlisted
require game.es.events
require game.utils.hero
require inventory
require game.es.use_item_on_object_common
require game.events_game


[es(tag=server)]
def revive_at_object_used_es(evt : EventOnLootItemUsed; playerItemOwner : EntityId; item__lastOwner : EntityId)
  let reviverAimTmPtr = get_TMatrix(item__lastOwner, "human__aimTm")
  assume reviverAimTm = *reviverAimTmPtr

  ecs::query(evt.target) <| $ [es(REQUIRE=reviveEntity)] (transform : float3x4; reviveOffset : float3&; revive_entity__respawnsDist : float)
    let reviveEntPos = transform[3]
    var respawnTm = transform
    var maxAimDot = 0.0
    let maxRespawnsDistSq = square(revive_entity__respawnsDist)
    ecs::query() <| $ [es(REQUIRE=respawnForReviveEntity)] (transform : float3x4)
      let distToRespawnSq = length_sq(transform[3] - reviveEntPos)
      if distToRespawnSq > maxRespawnsDistSq
        return
      let aimDot = dot(reviverAimTm[0], normalize(transform[3] - reviverAimTm[3]))
      if aimDot > maxAimDot
        maxAimDot = aimDot
        respawnTm = transform

    ecs::query(playerItemOwner) <| $ [es] (team : int)
      respawnTm[3] = respawnTm * reviveOffset
      sendEvent(playerItemOwner, [[CmdSpawnEntity team=team, tm=respawnTm, reason="reviveByHeart"]])

[es(tag=gameClient, REQUIRE=hero, REQUIRE_NOT=deadEntity,
    after=hero_human_pre_use_object_es,
    after=hero_human_use_downed_human_object_es,
    before=hero_human_final_use_object_sync)]
def hero_human_use_revive_object_es(act : ParallelUpdateFrameDelayed;
                                    itemContainer : EidList;
                                    var human_use_object__selectedObject : EntityId&;
                                    var human_use_object__lookAtObject : EntityId&;
                                    var human_use_object__lookAtSelected : bool&;
                                    var customUsePrompt : das_string?)
  use_item_on_object(itemContainer,
                      human_use_object__selectedObject,
                      human_use_object__lookAtObject,
                      human_use_object__lookAtSelected,
                      customUsePrompt,
                      $(i_eid : EntityId) => has(i_eid, "itemForResurrection"),
                      $ [unused_argument(i_eid)] (e_eid, i_eid : EntityId) => has(e_eid, "reviveEntity"))

[es(tag=server, REQUIRE=reviveEntity)]
def human_inventory_revive_object_es(evt : CmdUse; eid : EntityId)
  query(evt.requesterEid) <| $ [es] (itemContainer : EidList; human_inventory__entityToUse : EntityId)
    if human_inventory__entityToUse != INVALID_ENTITY_ID
      return
    var fallbackItem = INVALID_ENTITY_ID
    for itemEid in itemContainer
      if has(itemEid, "itemForResurrection")
        fallbackItem = itemEid
        let resurrectedPlayer = get_Eid(itemEid, "playerItemOwner") ?? INVALID_ENTITY_ID
        if !(get_bool(resurrectedPlayer, "disconnected") ?? false)
          sendEvent(evt.requesterEid, [[EventUseItem item=itemEid, target=eid]])
          return
    if fallbackItem != INVALID_ENTITY_ID
      sendEvent(evt.requesterEid, [[EventUseItem item=fallbackItem, target=eid]])
