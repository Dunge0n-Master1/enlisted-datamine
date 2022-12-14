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

let
  DEFAULT_USEFUL_COLOR = E3DCOLOR(0xFF8A2BE2) // 0xARGB
  DEFAULT_OVERWEIGHT_COLOR = E3DCOLOR(0xFFC80000)


[es(tag=gameClient, on_appear, REQUIRE=outlinedItem, REQUIRE_NOT=transform)]
def remove_item_outline_on_pickup_es(evt : Event; eid : EntityId)
  removeSubTemplate(eid, "outlined_item")


[es(tag=gameClient, after=human_inventory_hero_es, REQUIRE=hero)]
def item_outline_color_update(info : UpdateStageInfoAct; eid : EntityId; human_inventory__selectedItem : EntityId; //ParallelUpdateFrameDelayed
                              human_item_outline__visibilityRadius : float)
  let camTmComp = get_TMatrix(get_cur_cam_entity(), "transform")
  if camTmComp == null
    return
  let curPos = (*camTmComp)[3]
  let humanEid = eid
  for_each_entity_in_grid(ecs_hash("loot"), BSphere3(curPos, human_item_outline__visibilityRadius), GridEntCheck POS) <| $(lootEid : EntityId)
    if !has(lootEid, "outlinedItem")
      addSubTemplate(lootEid, "outlined_item")
  query() <| $ [es(REQUIRE=outlinedItem)] (eid : EntityId; var outline__chosenColor : E3DCOLOR&;
                                           outline__baseColor : E3DCOLOR;
                                           outline__usefulColor : E3DCOLOR;
                                           outline__overweightColor : E3DCOLOR;
                                           var item_outline__recalcColorAt : float&;
                                           item_outline__recalcColorTimer : float)
    if item_outline__recalcColorAt > info.curTime
      return
    if !can_pickup_item(eid, humanEid)
      outline__chosenColor = outline__overweightColor
    elif is_item_useful(humanEid, eid)
      outline__chosenColor = outline__usefulColor
    else
      outline__chosenColor = outline__baseColor
    item_outline__recalcColorAt = info.curTime + item_outline__recalcColorTimer

  query() <| $ [es(REQUIRE=outlinedItem)] (eid : EntityId; transform : float3x4; var outline__color : E3DCOLOR&;
                                           outline__chosenColor : E3DCOLOR;
                                           outline__selectedMult : float = 1.0;
                                           outline__unselectedMult : float = 0.4;
                                           item_outline__posMult : float = 0.7;
                                           item_outline__timeMult : float = 8.0)
    let distSq = length_sq(transform[3] - curPos)
    if distSq > square(human_item_outline__visibilityRadius)
      removeSubTemplate(eid, "outlined_item")
      return
    let posTimeOffset = (transform[3].x + transform[3].z) * item_outline__posMult
    let timeInput = (info.curTime + posTimeOffset) * item_outline__timeMult
    let sinMult = cvt(sin(timeInput), -1.0, 1.0, 0.5, 1.0)
    let distMult = cvt(sqrt(distSq) / human_item_outline__visibilityRadius, 0.5, 1.0, outline__unselectedMult, 0.0)
    var mult : float = distMult * square(sinMult)
    if eid == human_inventory__selectedItem
      mult = outline__selectedMult
    else
      // make only 10 different gradations, to reduce number of different outline colors
      mult = floor(mult / outline__unselectedMult * 10.0) / 10.0 * outline__unselectedMult
    let baseColor = outline__chosenColor
    let color = min(float4(uint4(baseColor)) * mult, float4(255.0, 255.0, 255.0, 255.0))
    outline__color = E3DCOLOR(uint4(color.x, color.y, color.z, color.w))

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
