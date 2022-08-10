require ecs
require DagorSystem
require AnimV20
require GeomNodeTree
require CollRes
require DagorMath
require enlisted.events_enlisted

[es(tag=ui, after=after_animchar_update_sync)]
def ui_geom_node_pos(info : ParallelUpdateFrameDelayed;
                     animchar__updatable : bool;
                     ui__geom_node_idx : int;
                     animchar : AnimcharBaseComponent;
                     var ui__node_pos : float3&)
  if animchar__updatable && ui__geom_node_idx >= 0
    ui__node_pos = geomtree_getNodeWpos(animchar.nodeTree, ui__geom_node_idx)

[es(tag=ui, on_appear, on_event=EventEntityRecreated, after=after_animchar_update_sync, track=ui__geom_node_name)]
def ui_geom_node_pos_name(evt : Event;
                          eid : EntityId;
                          animchar : AnimcharBaseComponent;
                          ui__geom_node_name : string;
                          var ui__geom_node_idx : int&;
                          var ui__node_pos : float3&)
  ui__geom_node_idx = geomtree_findNodeIndex(animchar.nodeTree, ui__geom_node_name)
  if ui__geom_node_idx >= 0
    ui__node_pos = geomtree_getNodeWpos(animchar.nodeTree, ui__geom_node_idx)
  else
    logerr("Node {ui__geom_node_name} not found in animchar for eid {eid} {getEntityTemplateName(eid)}")

[es(tag=(render, ui), REQUIRE=vehicle, no_order)]
def ui_bbox_node_pos_name(info : UpdateStageInfoAct;
                          transform : float3x4;
                          collres : CollisionResource;
                          var ui__node_pos : float3&)
  assume bbox = collres.vFullBBox
  ui__node_pos.x = (bbox.bmin.x + bbox.bmax.x) * 0.5
  ui__node_pos.y = bbox.bmax.y
  ui__node_pos.z = (bbox.bmin.z + bbox.bmax.z) * 0.5
  ui__node_pos = transform * ui__node_pos

[es(tag=ui, REQUIRE=ui__nodePosByCollresBbox, after=ui_geom_node_pos_name, on_appear, on_event=EventEntityRecreated)]
def ui_node_pos_collres_bbox(evt : Event;
                             collres : CollisionResource;
                             transform : float3x4;
                             var ui__node_pos : float3&)
  ui__node_pos = (transform * BBox3(collres.vFullBBox)).center

[es(tag=ui, REQUIRE=(ui__nodePosByCollresBbox, node_attached__updateWtm), no_order)]
def ui_node_pos_collres_bbox_update(evt : UpdateStageInfoAct;
                                    collres : CollisionResource;
                                    transform : float3x4;
                                    var ui__node_pos : float3&)
  ui__node_pos = (transform * BBox3(collres.vFullBBox)).center
