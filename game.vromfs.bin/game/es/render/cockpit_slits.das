require ecs
require ecs.common
require math
require math.base
require math.easing
require AnimV20
require GeomNodeTree
require DagorMath
require DagorSystem
require game.es.node_attach_common
require DagorShaders

let
  cockpit_num_slitsVarId = get_shader_variable_id("cockpit_num_slits", true)
  cockpit_slit_xVarIds = [[ auto
    get_shader_variable_id("cockpit_slit_1_x", true);
    get_shader_variable_id("cockpit_slit_2_x", true);
    get_shader_variable_id("cockpit_slit_3_x", true);
    get_shader_variable_id("cockpit_slit_4_x", true);
    get_shader_variable_id("cockpit_slit_5_x", true);
    get_shader_variable_id("cockpit_slit_6_x", true);
    get_shader_variable_id("cockpit_slit_7_x", true);
    get_shader_variable_id("cockpit_slit_8_x", true)
  ]]
  cockpit_slit_yVarIds = [[ auto
    get_shader_variable_id("cockpit_slit_1_y", true);
    get_shader_variable_id("cockpit_slit_2_y", true);
    get_shader_variable_id("cockpit_slit_3_y", true);
    get_shader_variable_id("cockpit_slit_4_y", true);
    get_shader_variable_id("cockpit_slit_5_y", true);
    get_shader_variable_id("cockpit_slit_6_y", true);
    get_shader_variable_id("cockpit_slit_7_y", true);
    get_shader_variable_id("cockpit_slit_8_y", true)
  ]]
  cockpit_slit_zVarIds = [[ auto
    get_shader_variable_id("cockpit_slit_1_z", true);
    get_shader_variable_id("cockpit_slit_2_z", true);
    get_shader_variable_id("cockpit_slit_3_z", true);
    get_shader_variable_id("cockpit_slit_4_z", true);
    get_shader_variable_id("cockpit_slit_5_z", true);
    get_shader_variable_id("cockpit_slit_6_z", true);
    get_shader_variable_id("cockpit_slit_7_z", true);
    get_shader_variable_id("cockpit_slit_8_z", true)
  ]]

def set_cockpit_box_null(row_xVarId : int;
                         row_yVarId : int;
                         row_zVarId : int)
  // x offset is 2, so that tm*v will be outside of the [-1, 1] box for all v
  DagorShaders::set_color4(row_xVarId, Color4(float4(0, 0, 0, 2)))
  DagorShaders::set_color4(row_yVarId, Color4(float4(0, 0, 0, 0)))
  DagorShaders::set_color4(row_zVarId, Color4(float4(0, 0, 0, 0)))

def set_cockpit_box_tm(row_xVarId : int;
                       row_yVarId : int;
                       row_zVarId : int;
                       invtm : float3x4)
  DagorShaders::set_color4(row_xVarId, Color4(float4(invtm[0].x, invtm[1].x, invtm[2].x, invtm[3].x)))
  DagorShaders::set_color4(row_yVarId, Color4(float4(invtm[0].y, invtm[1].y, invtm[2].y, invtm[3].y)))
  DagorShaders::set_color4(row_zVarId, Color4(float4(invtm[0].z, invtm[1].z, invtm[2].z, invtm[3].z)))

[es(tag=(render, dev), on_event=EventComponentsDisappear, REQUIRE=daeditor__selected)]
def cockpit_slit_setter_unclicked(evt : Event;
                                  var node_attached__entity : ecs::EntityId&;
                                  cockpit_slit_setter__cockpitId : ecs::EntityId)
  node_attached__entity = cockpit_slit_setter__cockpitId // enable attachment

[es(tag=(render, dev), track=transform, REQUIRE=daeditor__selected)]
def cockpit_slit_setter_changed(evt : Event;
                                transform : float3x4;
                                var node_attached__localTm : float3x4&;
                                var node_attached__entity : ecs::EntityId&;
                                cockpit_slit_setter__cockpitId : ecs::EntityId;
                                node_attached__nodeId : int;
                                cockpit_slit_setter__index : int)
  node_attached__entity = INVALID_ENTITY_ID // disable attachment until editing is done
  query(cockpit_slit_setter__cockpitId) <| $ [es] (animchar : AnimcharBaseComponent)
    var nodeTm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, node_attached__nodeId, nodeTm)
    node_attached__localTm = inverse(nodeTm) * transform
    ecs::query(cockpit_slit_setter__cockpitId) <| $ [es] (var cockpit__slitBoxes : TMatrixList&)
      cockpit__slitBoxes[cockpit_slit_setter__index] = inverse(nodeTm) * transform

def cockpit_set_boxes(transform : float3x4;
                      animchar : AnimcharBaseComponent;
                      cockpit__slitNodes : IntList;
                      cockpit__slitNodeNames : StringList;
                      cockpit__slitBoxes : TMatrixList)
  let boxCount = length(cockpit__slitBoxes)
  DagorShaders::set_int(cockpit_num_slitsVarId, boxCount)
  for i in range(0, boxCount)
    let slitNodeId = (length(cockpit__slitNodes) > 0
      ? cockpit__slitNodes[i]
      : geomtree_findNodeIndex(*animchar.nodeTree, string(cockpit__slitNodeNames[i])))
    var nodeTm : float3x4
    geomtree_getNodeWtmScalar(*animchar.nodeTree, slitNodeId, nodeTm)
    let modelToNodeTm = inverse(nodeTm) * transform
    let invBoxTm = inverse(cockpit__slitBoxes[i]) * modelToNodeTm
    set_cockpit_box_tm(cockpit_slit_xVarIds[i], cockpit_slit_yVarIds[i], cockpit_slit_zVarIds[i], invBoxTm)
  for i in range(boxCount, length(cockpit_slit_xVarIds))
    set_cockpit_box_null(cockpit_slit_xVarIds[i], cockpit_slit_yVarIds[i], cockpit_slit_zVarIds[i])

[es(tag=render, track=cockpit__slitBoxes, track=cockpit__isAttached)]
def cockpit_boxes_changed(evt : Event;
                          transform : float3x4;
                          animchar : AnimcharBaseComponent;
                          cockpit__isAttached : bool;
                          cockpit__slitNodes : IntList;
                          cockpit__slitNodeNames : StringList;
                          cockpit__slitBoxes : TMatrixList)
  if !cockpit__isAttached
    return
  cockpit_set_boxes(transform, animchar, cockpit__slitNodes, cockpit__slitNodeNames, cockpit__slitBoxes)

[es(tag=(render, dev), on_disappear, REQUIRE=cockpit__slitBoxes)]
def vehicle_cockpit_destroyed(evt : Event)
  query() <| $ [es(REQUIRE=cockpit_slit_setter__index)] (eid : EntityId)
    destroyEntity(eid)

[es(tag=(render, dev), track=cockpit__isAttached)]
def cockpit_slits_attach_setters(evt : Event;
                                 eid : EntityId;
                                 animchar : AnimcharBaseComponent;
                                 cockpit__isAttached : bool;
                                 cockpit__slitBoxes : TMatrixList;
                                 cockpit__slitNodeNames : StringList)
  if !cockpit__isAttached
    query() <| $ [es(REQUIRE=cockpit_slit_setter__index)] (eid : EntityId)
      destroyEntity(eid)
    return

  for i in iter_range(cockpit__slitBoxes)
    let slitNodeId = geomtree_findNodeIndex(*animchar.nodeTree, string(cockpit__slitNodeNames[i]))
    if slitNodeId < 0
      continue

    let id = createEntity("cockpit_slit_setter") <| $(var init : ComponentsInitializer)
      set(init, "cockpit_slit_setter__index", i)
      set(init, "cockpit_slit_setter__cockpitId", eid)
    attach_to_node(id, eid, slitNodeId, cockpit__slitBoxes[i])
