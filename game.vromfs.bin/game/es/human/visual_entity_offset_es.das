require ecs
require AnimV20
require GeomNodeTree
require DagorSystem
require DagorMath
require game.utils.hero
require EnlistedHuman
require Dacoll
require RendInst

[es(tag=gameClient, on_appear)]
def visual_entity_offset_init(evt : Event;
                              eid : EntityId;
                              animchar : AnimcharBaseComponent;
                              animchar__res : string;
                              visual_entity_offset__nodeName : string;
                              var visual_entity_offset__visNodeId : int&;
                              var visual_entity_offset__posNodeId : int&)
  visual_entity_offset__visNodeId = geomtree_findNodeIndex(*animchar.nodeTree, visual_entity_offset__nodeName)
  if visual_entity_offset__visNodeId < 0
    logerr("visual_entity_offset.nodeName '{visual_entity_offset__nodeName}' not found (eid: {eid} template: {getEntityTemplateName(eid)})")
    return

  let posNodeName = "Bip01"
  visual_entity_offset__posNodeId = geomtree_findNodeIndex(*animchar.nodeTree, posNodeName)
  if visual_entity_offset__posNodeId < 0
    logerr("'{posNodeName}'' node not found in '{animchar__res}'!")

[es(tag=gameClient)]
def visual_offset_updater_es(info : UpdateStageInfoAct; transform : float3x4; camera__active : bool; isHeroCockpitCam : bool = false)
  if !camera__active || isHeroCockpitCam
    return

  let curTime = info.curTime
  let pos = transform[3]

  ecs::query() <| $ [es(REQUIRE_NOT=disableUpdate)] (eid : EntityId;
                                                     var animchar : AnimcharBaseComponent&;
                                                     var animchar_node_wtm : AnimcharNodesMat44&;
                                                     var animchar_render__root_pos : vec4f&;
                                                     visual_entity_offset__visNodeId : int;
                                                     visual_entity_offset__posNodeId : int;
                                                     human_net_phys : HumanActor;
                                                     animchar__updatable : bool;
                                                     transform : float3x4;
                                                     isTpsView : bool;
                                                     visual_entity_offset__additionalLen : float = 0.05f;
                                                     visual_entity_offset__maxOffsetLen : float = 0.5f;
                                                     visual_entity_offset__maxApplyRadius : float = 30.0f;
                                                     visual_entity_offset__backoffMult : float = 0.5f;
                                                     visual_entity_offset__lmeshOffset : float = 0.25f)
    if !animchar__updatable
      return

    if length_sq(transform[3] - pos) >= pow(visual_entity_offset__maxApplyRadius, 2.0f) || human_net_phys.phys.currentState.isAttachedToLadder
      return

    if visual_entity_offset__visNodeId < 0 || visual_entity_offset__posNodeId < 0
      return

    let eyePos = geomtree_getNodeWpos(*animchar.nodeTree, visual_entity_offset__visNodeId)
    var geomtree_rootTm : float3x4
    geomtree_getNodeTmScalar(*animchar.nodeTree, 0, geomtree_rootTm)
    let itm = inverse(geomtree_rootTm)
    let localEyePos = itm * eyePos
    let localFromPos = itm * geomtree_getNodeWpos(*animchar.nodeTree, visual_entity_offset__posNodeId)
    let fromPos = geomtree_rootTm * float3(localFromPos.x, localEyePos.y, localFromPos.z)
    let dirToEye = eyePos - fromPos
    let lenSq = length_sq(dirToEye)
    if lenSq < 1e-12f
      return
    var len = sqrt(lenSq)
    let dir = dirToEye / len
    len += visual_entity_offset__additionalLen
    let initialLen = len
    let interpK = get_phys_interpk_clamped(human_net_phys.phys, curTime)
    let backoff = lerp(human_net_phys.phys.previousState.gunBackoffAmount, human_net_phys.phys.currentState.gunBackoffAmount, interpK)
    var backup = 0.0f
    if !isTpsView && has(eid, "hero")
      let eyeXZ = float2(eyePos.x, eyePos.z)
      let lOffset = eyePos.y - traceht_lmesh(eyeXZ)
      if lOffset < visual_entity_offset__lmeshOffset
        backup = visual_entity_offset__lmeshOffset - lOffset

    var out_pmid : int
    var out_norm : float3
    var out_desc = RendInstDesc()
    if traceray_normalized(fromPos, dir, len, out_pmid, out_norm, ETF_ALL, out_desc, -1, human_net_phys.phys.traceHandle) || backoff > 0.0f || backup > 0.0f
      let deltaLen = max(-visual_entity_offset__maxOffsetLen, len - initialLen) // negative sign as we have negative delta len (len is less than initialLen)
      let offset = rotate(itm, (dir * deltaLen) - transform[0] * (backoff * visual_entity_offset__backoffMult)) + float3(0.0f, backup, 0.0f)
      assert(length_sq(offset) < 1e10f)
      geomtree_getNodeTm(*animchar.nodeTree, visual_entity_offset__posNodeId).col3 += float4(offset.x, offset.y, offset.z, 0.0f)
      geomtree_invalidateWtm(*animchar.nodeTree)
      animchar_recalc_wtm(animchar)
      animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)
