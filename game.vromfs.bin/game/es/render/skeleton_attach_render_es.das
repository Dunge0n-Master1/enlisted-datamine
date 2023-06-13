require ecs
require DagorMath
require AnimV20
require DagorSystem
require DagorMath
require GeomNodeTree
require danetlibs.renderer.includes.render_events
require enlisted.events_enlisted

def get_node_no(node : uint16)
  return int(node) & int(0xFF)

def get_remapped_node_no(node : uint16)
  return (int(node) >> 8) & int(0xFF)

def copy_nodes_with_remap(var node_tree : GeomNodeTree&; att_node_tree : GeomNodeTree; skeleton_remap : UInt16List)
  for skelNode in skeleton_remap
    let nodeNo = get_node_no(skelNode)
    let remappedNodeNo = get_remapped_node_no(skelNode)
    geomtree_getNodeTm(node_tree, nodeNo) = geomtree_getNodeTm(att_node_tree, remappedNodeNo)
    geomtree_getNodeWtmRel(node_tree, nodeNo) = geomtree_getNodeWtmRel(att_node_tree, remappedNodeNo)

def recalc_branches(var node_tree : GeomNodeTree&; skeleton_recalc_branch : UInt8List)
  for nodeNo in skeleton_recalc_branch
    let intNodeNo = int(nodeNo)
    let parentNodeIdx = geomtree_getParentNodeIdx(node_tree, intNodeNo)
    let parentNodeWtm = float3x4(geomtree_getNodeWtmRel(node_tree, parentNodeIdx))
    let curNodeWtm = float3x4(geomtree_getNodeTm(node_tree, intNodeNo))
    geomtree_getNodeWtmRel(node_tree, intNodeNo) = mat44f(parentNodeWtm * curNodeWtm)
    geomtree_calcWtmForBranch(node_tree, intNodeNo)

def skeleton_attached_to(base_animchar : AnimcharBaseComponent&;
                         animchar__visible : bool;
                         base_attaches_list : EidList;
                         dt : float;
                         base_animchar_bbox : bbox3f;
                         var base_animchar_bsph_precalculated : vec4f&;
                         var base_animchar_attaches_bbox_precalculated : bbox3f?)
  if base_animchar_attaches_bbox_precalculated != null
    *base_animchar_attaches_bbox_precalculated = base_animchar_bbox

  for attachEid in base_attaches_list
    query(attachEid) <| $ [es(trust_access, REQUIRE=slot_attach__attachedTo)] (skeleton_attach__attached : bool;
                                                                               skeleton_attach__skeletonRemap : UInt16List;
                                                                               skeleton_attach__skeletonRecalcBranch : UInt8List;
                                                                               attaches_list : EidList const?;
                                                                               animchar_bbox : bbox3f;
                                                                               animchar_render : AnimcharRendComponent;
                                                                               var animchar : AnimcharBaseComponent&;
                                                                               var animchar__usePrecalculatedData : bool&;
                                                                               var animchar_bsph_precalculated : vec4f&;
                                                                               var animchar_node_wtm : AnimcharNodesMat44;
                                                                               var animchar_render__root_pos : vec4f&;
                                                                               var animchar_attaches_bbox_precalculated : bbox3f?;
                                                                               animchar_render__enabled : bool = true)
      if !animchar_render__enabled || !skeleton_attach__attached
        return
      animchar__usePrecalculatedData = true
      assume attNodeTree = *base_animchar.nodeTree
      assume nodeTree = *animchar.nodeTree;

      let wtmOfs = geomtree_getWtmOfs(attNodeTree)
      geomtree_setWtmOfs(nodeTree, wtmOfs)

      copy_nodes_with_remap(nodeTree, attNodeTree, skeleton_attach__skeletonRemap)
      recalc_branches(nodeTree, skeleton_attach__skeletonRecalcBranch)

      if animchar__visible
        animchar_forcePostRecalcWtm(animchar, dt)

      animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)
      animchar_bsph_precalculated = animchar_render_prepareSphere(animchar_render, animchar_node_wtm)

      if attaches_list != null
        skeleton_attached_to(animchar, animchar__visible, *attaches_list, dt, animchar_bbox, animchar_bsph_precalculated, animchar_attaches_bbox_precalculated)

      let attachDir = animchar_bsph_precalculated.xyz - base_animchar_bsph_precalculated.xyz
      let maxAttachDistance = length(attachDir) + animchar_bsph_precalculated.w
      if maxAttachDistance > base_animchar_bsph_precalculated.w
        base_animchar_bsph_precalculated.w = maxAttachDistance

      if base_animchar_attaches_bbox_precalculated != null
        bbox3f_add_box(*base_animchar_attaches_bbox_precalculated, animchar_bbox)


[es(tag=gameClient, after=slot_attach_init_tms_es, parallel_for=4, REQUIRE_NOT=attachedToParent)]
def skeleton_attach_es(info : ParallelUpdateFrameDelayed;
                       animchar : AnimcharBaseComponent&;
                       animchar__visible : bool;
                       animchar_bbox : bbox3f;
                       attaches_list : EidList;
                       var animchar_bsph_precalculated : vec4f&;
                       var animchar_attaches_bbox_precalculated : bbox3f?;
                       var animchar__usePrecalculatedData : bool&;
                       animchar_render : AnimcharRendComponent;
                       animchar_node_wtm : AnimcharNodesMat44;
                       animchar__updatable = true)
  if !animchar__updatable
    return
  animchar__usePrecalculatedData = true
  animchar_bsph_precalculated = animchar_render_prepareSphere(animchar_render, animchar_node_wtm)
  skeleton_attached_to(animchar, animchar__visible, attaches_list, info.dt, animchar_bbox, animchar_bsph_precalculated, animchar_attaches_bbox_precalculated);

[es(tag=gameClient, on_appear, REQUIRE=attachedToParent)]
def init_skeleton_attachment_wtm_ofs(evt : Event;
                                     skeleton_attach__skeletonRemap : UInt16List;
                                     skeleton_attach__skeletonRecalcBranch : UInt8List;
                                     slot_attach__attachedTo : EntityId;
                                     var animchar aka attachment_animchar : AnimcharBaseComponent&)
  query(slot_attach__attachedTo) <| $ [es] (animchar aka attached_to_animchar : AnimcharBaseComponent)
    assume attNodeTree = *attached_to_animchar.nodeTree
    assume nodeTree = *attachment_animchar.nodeTree;

    let wtmOfs = geomtree_getWtmOfs(attNodeTree)
    geomtree_setWtmOfs(nodeTree, wtmOfs)

    copy_nodes_with_remap(nodeTree, attNodeTree, skeleton_attach__skeletonRemap)
    recalc_branches(nodeTree, skeleton_attach__skeletonRecalcBranch)

    // TODO: remove bind existing checks if any major update came out since 03.05.23 (so everyone has the binds 100%)
    static_if typeinfo(builtin_function_exists @@ < (var arg0 : AnimV20::AnimcharBaseComponent implicit; arg1 : float const) : void > _::animchar_updateFastPhys)
      attachment_animchar |> animchar_resetFastPhysWtmOfs(wtmOfs)
      // simulate fastphys for some frames to let fastphys items settle
      let fastPhysSimTimeOnReset = 1.5
      attachment_animchar |> animchar_updateFastPhys(fastPhysSimTimeOnReset)
