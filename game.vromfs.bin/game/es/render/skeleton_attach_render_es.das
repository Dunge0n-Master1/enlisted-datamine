require ecs
require DagorMath
require AnimV20
require DagorSystem
require DagorMath
require GeomNodeTree
require danetlibs.renderer.includes.render_events


def get_node_no(node : uint16)
  return int(node) & int(0xFF)

def get_remapped_node_no(node : uint16)
  return (int(node) >> 8) & int(0xFF)

def skeleton_attached_to(base_animchar : AnimcharBaseComponent&;
                         animchar__visible : bool;
                         base_attaches_list : EidList;
                         dt : float;
                         base_animchar_bbox : bbox3f;
                         var base_animchar_bsph : vec4f&;
                         var base_animchar_attaches_bbox : bbox3f?)
  if base_animchar_attaches_bbox != null
    *base_animchar_attaches_bbox = base_animchar_bbox

  for attachEid in base_attaches_list
    query(attachEid) <| $ [es(trust_access, REQUIRE=slot_attach__attachedTo)] (skeleton_attach__attached : bool;
                                                                               skeleton_attach__skeletonRemap : UInt16List;
                                                                               skeleton_attach__skeletonRecalcBranch : UInt8List;
                                                                               attaches_list : EidList const?;
                                                                               animchar_bbox : bbox3f;
                                                                               var animchar : AnimcharBaseComponent&;
                                                                               var animchar_render : AnimcharRendComponent;
                                                                               var animchar_bsph : vec4f&;
                                                                               var animchar_node_wtm : AnimcharNodesMat44;
                                                                               var animchar_render__root_pos : vec4f&;
                                                                               var animchar_attaches_bbox : bbox3f?;
                                                                               animchar_render__enabled : bool = true)
      if !animchar_render__enabled || !skeleton_attach__attached
        return

      assume attNodeTree = *base_animchar.nodeTree
      assume nodeTree = *animchar.nodeTree;

      let wtmOfs = geomtree_getWtmOfs(attNodeTree)
      geomtree_setWtmOfs(nodeTree, wtmOfs)

      for skelNode in skeleton_attach__skeletonRemap
        let nodeNo = get_node_no(skelNode)
        let remappedNodeNo = get_remapped_node_no(skelNode)
        geomtree_getNodeTm(nodeTree, nodeNo) = geomtree_getNodeTm(attNodeTree, remappedNodeNo)
        geomtree_getNodeWtmRel(nodeTree, nodeNo) = geomtree_getNodeWtmRel(attNodeTree, remappedNodeNo)

      for nodeNo in skeleton_attach__skeletonRecalcBranch
        let intNodeNo = int(nodeNo)
        let parentNodeIdx = geomtree_getParentNodeIdx(nodeTree, intNodeNo)
        let parentNodeWtm = float3x4(geomtree_getNodeWtmRel(nodeTree, parentNodeIdx))
        let curNoteWtm = float3x4(geomtree_getNodeTm(nodeTree, intNodeNo))
        geomtree_getNodeWtmRel(nodeTree, intNodeNo) = mat44f(parentNodeWtm * curNoteWtm)
        geomtree_calcWtmForBranch(nodeTree, intNodeNo)

      if animchar__visible
        animchar_forcePostRecalcWtm(animchar, dt)

      animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)
      animchar_bsph = animchar_render_prepareSphere(animchar_render, animchar_node_wtm)

      if attaches_list != null
        skeleton_attached_to(animchar, animchar__visible, *attaches_list, dt, animchar_bbox, animchar_bsph, animchar_attaches_bbox)

      let attachDir = animchar_bsph.xyz - base_animchar_bsph.xyz
      let maxAttachDistance = length(attachDir) + animchar_bsph.w
      if maxAttachDistance > base_animchar_bsph.w
        base_animchar_bsph.w = maxAttachDistance

      if base_animchar_attaches_bbox != null
        bbox3f_add_box(*base_animchar_attaches_bbox, animchar_bbox)


[es(tag=gameClient, parallel_for=4, REQUIRE_NOT=attachedToParent)]
def skeleton_attach_es(info : UpdateStageInfoBeforeRender;
                       animchar : AnimcharBaseComponent&;
                       animchar__visible : bool;
                       animchar_bbox : bbox3f;
                       attaches_list : EidList;
                       var animchar_bsph : vec4f&;
                       var animchar_attaches_bbox : bbox3f?;
                       var animchar_render : AnimcharRendComponent;
                       var animchar_node_wtm : AnimcharNodesMat44;
                       animchar__updatable = true)
  if !animchar__updatable
    return

  animchar_bsph = animchar_render_prepareSphere(animchar_render, animchar_node_wtm)
  skeleton_attached_to(animchar, animchar__visible, attaches_list, info.dt, animchar_bbox, animchar_bsph, animchar_attaches_bbox);

