options no_aot
require DagorSystem
require ecs.common
require ecs
require GeomNodeTree
require AnimV20
require EcsUtils
require DagorDataBlock
require DagorConsole
require vehicle
require game.es.vehicle.vehicle_seats_common
require math.base
require math.ang
require enlisted.game.es.blk_utils_common

[es(tag=(dev, render), after=after_animchar_update_sync, before=vehicle_attach_cockpit_es, REQUIRE=daeditor__selected)]
def debug_setup_for_cockpit(info : UpdateStageInfoAct;
                            transform : float3x4;
                            cockpit__attachNodeIndices : IntList const?;
                            cockpit__attachNodeIndex : int;
                            cockpit__currentSlit : int;
                            var cockpit__cockpitOffsetBySlit : Point3List?;
                            var cockpit__offset : float3&;
                            cockpit__vehicleEid : EntityId;
                            cockpit__seatNo : int;
                            cockpit__angles : float3 const?;
                            cockpit__scale = float3(1.0, 1.0, -1.0))

  var tankTransform : float3x4 = IDENT_TM
  ecs::query(cockpit__vehicleEid) <| $ [es] (transform : float3x4)
    tankTransform = transform

  ecs::query(cockpit__vehicleEid) <| $ [es] (animchar : AnimcharBaseComponent;
                                             vehicle_seats__seatEids : EidList;
                                             vehicleCameraType : int;
                                             isAlive, isExploded : bool)
    if !isAlive || isExploded
      return

    if (vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_COMMANDER) ||
        vehicleCameraType == int(VehicleCameraType VEHICLE_CAMERA_DEAD))
      return

    let heroSeatNo = vehicle_get_hero_seat_idx(vehicle_seats__seatEids)
    if heroSeatNo < 0 || heroSeatNo != cockpit__seatNo
      return

    var ix = cockpit__attachNodeIndex;
    if cockpit__attachNodeIndices != null
      ix = (*cockpit__attachNodeIndices)[cockpit__currentSlit]

    var offset = cockpit__offset
    if cockpit__cockpitOffsetBySlit != null
      offset += (*cockpit__cockpitOffsetBySlit)[cockpit__currentSlit]

    var transformOrig : float3x4;

    geomtree_getNodeWtmScalar(*animchar.nodeTree, ix, transformOrig)
    transformOrig[0] = transformOrig[0] * cockpit__scale.x
    transformOrig[1] = transformOrig[1] * cockpit__scale.y
    transformOrig[2] = transformOrig[2] * cockpit__scale.z

    transformOrig[3] = transformOrig * offset

    if cockpit__angles != null
      transformOrig = transformOrig * make_rot_cw_zyx(*cockpit__angles * DEG_TO_RAD)

    let moveOffset = rotate(tankTransform, transform[3] - transformOrig[3])

    if cockpit__cockpitOffsetBySlit != null
      (*cockpit__cockpitOffsetBySlit)[cockpit__currentSlit] += moveOffset
    else
      cockpit__offset += moveOffset

[console_cmd(name="vehicle.calc_cockpit_block")]
def calc_cockpit_block()
  find_query() <| $ [es(REQUIRE=(daeditor__selected))] (eid : EntityId;
                                                        cockpit__offset : float3;
                                                        cockpit__cockpitOffsetBySlit : Point3List const?)
    using() <| $(var blk : DataBlock)
      components_to_blk(eid, blk, "cockpit__", true)
      datablock_get_block(blk, "cockpitOffsetBySlit:list<p3>") <| $(templatesArrayBlk)
        let templateName = getEntityTemplateName(eid)
        if cockpit__cockpitOffsetBySlit != null
          save_block_to_origin_template(templateName, "cockpit__cockpitOffsetBySlit:list<p3>", templatesArrayBlk)
        else
          save_param_to_origin_template(templateName) <| $(var originBlk : DataBlock&) : void
            set(originBlk, "cockpit__offset", cockpit__offset)

    return true
