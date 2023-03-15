require DagorSystem
options no_aot
require ecs.common
require ecs
require GeomNodeTree
require AnimV20
require EcsUtils
require DagorDataBlock
require DagorConsole
require enlisted.game.es.blk_utils_common
require math.base

[es(tag=(dev, render), after=human_fpv_cam_pos, before=shooter_cam_update_tm_es, REQUIRE=daeditor__selected)]
def debug_setup_for_seats(info : UpdateStageInfoAct;
                          camera__target : EntityId;
                          transform : float3x4)
  var vehicleEid = INVALID_ENTITY_ID
  query(camera__target) <| $ [es] (human_anim__vehicleSelected : EntityId)
    vehicleEid = human_anim__vehicleSelected

  if vehicleEid == INVALID_ENTITY_ID
    return

  var moveOffset = float3()
  query(camera__target) <| $ [es] (animchar : AnimcharBaseComponent;
                                   human_cam__camNodeId : int;
                                   human_cam__offsetMult : float;
                                   var camera__look_at : DPoint3&)
    if human_cam__camNodeId < 0
      return
    let wposRel = geomtree_getNodeWposRel(*animchar.nodeTree, human_cam__camNodeId)
    let wofs = geomtree_getWtmOfs(*animchar.nodeTree)
    let lookAtOriginal = lerp(DPoint3(wposRel) + DPoint3(wofs), camera__look_at, human_cam__offsetMult)

    camera__look_at = DPoint3(transform[3])
    moveOffset = float3(camera__look_at - lookAtOriginal)

  var tankTransform : float3x4 = IDENT_TM
  query(vehicleEid) <| $ [es] (transform : float3x4)
    tankTransform = transform
    moveOffset = rotate(tankTransform, moveOffset)

  query(vehicleEid) <| $ [es] ([[shared_comp]] vehicle_seats__seats : Array;
                               vehicle_seats__seatEids : EidList)
    var ownerSeatEid = INVALID_ENTITY_ID
    for seatEid in vehicle_seats__seatEids
      let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
      if ownerEid == camera__target
        ownerSeatEid = seatEid
        break

    query(ownerSeatEid) <| $ [es] (seat__id : int;
                                   var seats_attach_nodes__attachTm : float3x4&;
                                   var seats_attach_nodes__initialTm : float3x4&)
      seats_attach_nodes__attachTm[3] += moveOffset
      seats_attach_nodes__initialTm[3] += moveOffset

      var seat = get_ecs_object(vehicle_seats__seats, seat__id)
      if seat == null
        return

      set(*seat, "attachTm", seats_attach_nodes__initialTm)

[console_cmd(name="vehicle.calc_seats_block")]
def calc_seats_block()
  find_query() <| $ [es(REQUIRE=(daeditor__selected, vehicle_seats__seats))] (eid : EntityId)
    using() <| $(var blk : DataBlock)
      components_to_blk(eid, blk, "vehicle_seats__", true)
      datablock_get_block(blk, "seats:shared:array") <| $(templatesArrayBlk)
        let templateName = getEntityTemplateName(eid)
        save_block_to_origin_template(templateName, "vehicle_seats__seats:shared:array", templatesArrayBlk)
    return true
