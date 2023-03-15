require ecs
require inventory
require ecs.common
require EnlistedCamera
require EnlistedHuman
require HumanPhys
require DagorMath
require DagorMathUtils
require game.es.inventory_common
require math.base
require GridCollision
require Grid
require DagorSystem
require enlisted.events_enlisted


[es(tag=gameClient, REQUIRE=hero, track=human_inventory__selectedItem)]
def toggle_ui_visible(evt : Event; human_inventory__selectedItem : EntityId)
  query() <| $ [es(REQUIRE=ui_visible)] (eid : EntityId)
    removeSubTemplate(eid, "ui_visible")
  if human_inventory__selectedItem != INVALID_ENTITY_ID
    addSubTemplate(human_inventory__selectedItem, "ui_visible")

[es(tag=gameClient, after=before_human_inventory_use_update, REQUIRE=hero, REQUIRE_NOT=deadEntity)]
def human_inventory_hero_es(info : ParallelUpdateFrameDelayed;
                            eid : EntityId;
                            itemsAround : EidList;
                            human__aimTm : float3x4;
                            var human_inventory__selectedItem : EntityId&;
                            human_inventory__selectConvex : Point4List;
                            human_inventory__selectTpsConvex : Point4List;
                            human_inventory__pickupDistance : float = 2.5;
                            human_inventory__pickupItemMinBox : float3 = float3(0.1f, 0.1f, 0.1f);
                            human__canPickupItems : bool = true;
                            human_net_phys : HumanActor;
                            isTpsView : bool = false)
  if !human__canPickupItems
    return

  var bestScore = FLT_MIN
  var bestEntity = ecs::INVALID_ENTITY_ID
  var isBestUseful = false

  let camTmComp = get_TMatrix(get_cur_cam_entity(), "transform")
  if camTmComp == null
    return
  var camTm := *camTmComp
  camTm[0] = camTm[2]
  camTm |> orthonormalize()

  let tps = isTpsView && human_net_phys.phys.currentState.zoomPosition == 0.0
  let viewTm & = camTm
  let viewItm = inverse(viewTm)

  let projToChar = dot(human__aimTm[3] - viewTm[3], viewTm[0])
  let pickupDistance = human_inventory__pickupDistance
  let aimDir = viewTm[0]
  let aimFrom = viewTm[3] + projToChar * aimDir
  let aimTo = aimFrom + aimDir * pickupDistance

  for itemEid in itemsAround
    if itemEid == eid
      continue

    var isInteractionBlockedByLastOwner = false
    query(itemEid) <| $ [es] (item__lastOwner : EntityId = INVALID_ENTITY_ID; canItemPickedUpOnlyByLastOwner : Tag const?)
      isInteractionBlockedByLastOwner = canItemPickedUpOnlyByLastOwner != null && item__lastOwner != eid
    if isInteractionBlockedByLastOwner
      continue

    let pickupScore = get_item_pickup_score(eid, itemEid, tps ? human_inventory__selectTpsConvex : human_inventory__selectConvex,
                                            viewItm, aimDir, aimFrom, aimTo, human_inventory__pickupItemMinBox, human_inventory__selectedItem == itemEid)
    if pickupScore.score > bestScore
      isBestUseful = pickupScore.useful
      bestScore = pickupScore.score
      bestEntity = itemEid

  human_inventory__selectedItem = bestEntity
