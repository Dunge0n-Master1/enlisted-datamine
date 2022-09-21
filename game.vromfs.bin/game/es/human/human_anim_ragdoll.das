require ecs
require app
require math.base
require game.events_game
require strings
require EnlistedHumanAnim
require EnlistedHuman
require EnlistedActor
require EnlistedNet
require PhysVars
require PhysDecl
require HumanPhys
require HumanAnim
require DagorMath
require DagorSystem
require Dacoll
require GeomNodeTree
require AnimV20


def clipout_nodes(var tree : GeomNodeTree;
                  var tm : float3x4;
                  var wtm : float3x4;
                  node : int;
                  parent_wtm : float3x4;
                  prefix : string;
                  prefix_len : int;
                  trace_handles : TraceMeshFaces implicit)
  let childCount = tree |> geomnodetree_getChildCount(node)
  for i in range(childCount)
    var childNode = tree |> geomnodetree_getChildNode(node, uint(i))
    let nodeName = tree |> geomnodetree_getNodeName(*childNode)
    if !starts_with(nodeName, prefix, uint(prefix_len))
      continue
    var childTm : float3x4
    childNode |> geomtreenode_getTmScalar(childTm)
    var childWtm = wtm * childTm
    var norm : float3
    var matId : int

    using() <| $(var desc : RendInstDesc#)
      let toChild = childWtm[3] - wtm[3]
      let toChildLen = length(toChild)
      if toChildLen > 1e-6
        let toChildDir = toChild / toChildLen
        var t = toChildLen
        if traceray_normalized(wtm[3], toChildDir, t, matId, norm, ETF_DEFAULT, desc, -1, trace_handles)
          // Rerotate parent tm to fix it out of collision
          let axis = normalize(cross(norm, toChildDir))
          let localAxis = rotate(inverse(wtm), axis)
          let ang = acos(t / toChildLen)
          var rotTm : float3x4
          make_tm(localAxis, ang, rotTm)
          tm = tm * rotTm
          wtm = parent_wtm * tm
          childWtm = wtm * childTm
          tree |> geomnodetree_getNode(node) |> geomtreenode_setTm(tm)
          tree |> geomnodetree_getNode(node) |> geomtreenode_setWtm(wtm)
      let initialLen = 0.1
      for j in range(6)
        let dir = childWtm[j / 2] * ((j & 1) != 0 ? 1.0 : -1.0)
        var t = initialLen
        if traceray_normalized(childWtm[3], dir, t, matId, norm, ETF_DEFAULT, desc, -1, trace_handles)
          // Rerotate parent tm to fix it out of collision
          let axis = normalize(cross(norm, dir))
          let localAxis = rotate(inverse(wtm), axis)
          let ang = acos(t / initialLen)
          var rotTm : float3x4
          make_tm(localAxis, ang, rotTm)
          tm = tm * rotTm
          wtm = parent_wtm * tm
          childWtm = wtm * childTm
          tree |> geomnodetree_getNode(node) |> geomtreenode_setTm(tm)
          tree |> geomnodetree_getNode(node) |> geomtreenode_setWtm(wtm)
    childNode |> geomtreenode_setWtm(childWtm)
    clipout_nodes(tree, childTm, childWtm, tree |> geomnodetree_getNodeIdx(*childNode), wtm, prefix, prefix_len, trace_handles)

def start_ragdoll(var ragdoll : PhysRagdoll;
                  var animchar : AnimcharBaseComponent;
                  unitTm : float3x4;
                  pos : float3;
                  vel : float3;
                  eid : EntityId;
                  curTime : float;
                  human_anim__dynamicRagdollClipoutTimeout : float;
                  human_anim__dynamicRagdollClipoutOffset : float3)
  animchar |> animchar_resetPostController()

  // Go through wtm/tms setuping proper collision
  // There was a hand-made extrapolation of current position by velocity, position and dt before.
  // Yes, fixing the jump in position creates more visually pleasing animations.
  // But it shouldn't be done, as also anything, that may move the animchar in a physically incorrect position.
  // Meaning it may become pushed inside the wall or under the ground. Hence why we override the transform position to
  // the last server-authoritated position.
  animchar |> animchar_set_tm(pos, unitTm[0], unitTm[1])
  // Recalc tm so ragdoll will have proper coordinates and anything, like visual entity offset will not interfere
  animchar |> animchar_recalc_wtm()

  if (human_anim__dynamicRagdollClipoutTimeout > 0.0f)
    let toPos = pos + human_anim__dynamicRagdollClipoutOffset
    ragdoll |> ragdoll_setDynamicClipout(toPos, human_anim__dynamicRagdollClipoutTimeout)
  ragdoll |> ragdoll_startRagdoll(int(PhysLayer EPL_CHARACTER),
                                  int(PhysLayer EPL_ALL & (~(PhysLayer EPL_KINEMATIC | PhysLayer EPL_CHARACTER))))
  ragdoll |> ragdoll_setOverrideVel(vel)
  sendEventImmediate(eid, [[CmdApplyRagdollParameters cur_time=curTime]])
  animchar |> animchar_setPostController(ragdoll)

def stop_ragdoll(var ragdoll : PhysRagdoll;
                 var animchar : AnimcharBaseComponent)
  ragdoll |> ragdoll_endRagdoll()
  animchar |> animchar_resetPostController()


[es(tag=render, no_order)]
def human_anim_ragdoll_es(info : UpdateStageInfoAct)
  var ragdollStarts = -1
  query() <| $ [es(REQUIRE=deadEntity)] (animchar__updatable : bool;
                                         human_net_phys__velocity : float3;
                                         human_net_phys__locationPos : DPoint3;
                                         transform : float3x4;
                                         eid : EntityId;
                                         ragdoll__isAllowed : bool = true;
                                         ragdoll__maxEntitiesInUpdate : int = 2;
                                         human_anim__dynamicRagdollClipoutTimeout : float = 0.4;
                                         human_anim__dynamicRagdollClipoutOffset : float3 = float3(0., 0.5, 0.);
                                         var human_anim__ragdollEnabled : bool&;
                                         var ragdoll : PhysRagdoll;
                                         var animchar : AnimcharBaseComponent)
    if !animchar__updatable
      return

    let shouldDoRagdoll = ragdoll__isAllowed
    if shouldDoRagdoll != human_anim__ragdollEnabled
      if shouldDoRagdoll
        if ragdollStarts < 0 && ragdoll__maxEntitiesInUpdate > 0
          ragdollStarts = ragdoll__maxEntitiesInUpdate

        if ragdollStarts == 0
          return

        human_anim__ragdollEnabled = true
        let curTime = info.curTime
        // human_net_phys__locationPos stores the last correct snapshot's position of the human phys
        start_ragdoll(ragdoll, animchar, transform, float3(human_net_phys__locationPos),
                      human_net_phys__velocity, eid, curTime, human_anim__dynamicRagdollClipoutTimeout,
                      human_anim__dynamicRagdollClipoutOffset)
        ragdollStarts--
      else
        human_anim__ragdollEnabled = false
        stop_ragdoll(ragdoll, animchar)


[es(tag=render, REQUIRE=deadEntity, on_event=(EventComponentsDisappear))]
def stop_ragdoll_es(event : Event;
                    var animchar : AnimcharBaseComponent;
                    var human_anim__ragdollEnabled : bool&;
                    var ragdoll : PhysRagdoll)
  if human_anim__ragdollEnabled
    human_anim__ragdollEnabled = false
    stop_ragdoll(ragdoll, animchar)


[es(tag=render, on_appear, REQUIRE=deadEntity)]
def disable_far_ragdolls_on_death_es(evt : Event; transform : float3x4; var ragdoll__isAllowed : bool&)
  ragdoll__isAllowed &&= distance_sq(transform[3], get_hidden_pos()) > 1.0
