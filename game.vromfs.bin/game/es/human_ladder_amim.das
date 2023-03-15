require ecs
require ecs.common
require game.es.events
require AnimV20
require GeomNodeTree
require EffectorData
require EnlistedHumanAnim
require EnlistedHuman
require PhysVars
require math
require math.base
require DagorSystem
require DagorMath
require DagorMathUtils
require enlisted.events_enlisted

[es(on_appear)]
def human_ladder_anim_init_es(evt : Event;
                              animchar : AnimcharBaseComponent;
                              var human_anim__ladder__leftHandNodeId : int&;
                              var human_anim__ladder__rightHandNodeId : int&;
                              human_anim__ladder__leftHandNodeName : string;
                              human_anim__ladder__rightHandNodeName : string)
  human_anim__ladder__leftHandNodeId = geomtree_findNodeIndex(*animchar.nodeTree, human_anim__ladder__leftHandNodeName)
  human_anim__ladder__rightHandNodeId = geomtree_findNodeIndex(*animchar.nodeTree, human_anim__ladder__rightHandNodeName)


def mult(matr : float3x4;
         vect : float3) : float3
  var result : float3
  result[0] = matr[0][0] * vect[0] + matr[1][0] * vect[1] + matr[2][0] * vect[2]
  result[1] = matr[0][1] * vect[0] + matr[1][1] * vect[1] + matr[2][1] * vect[2]
  result[2] = matr[0][2] * vect[0] + matr[1][2] * vect[1] + matr[2][2] * vect[2]
  return result

[es(after=human_post_phys_ladder_update_es, REQUIRE_NOT=deadEntity)]
def human_ladder_anim_es(info : ParallelUpdateFrameDelayed;
                         human_anim : HumanAnimCtx;
                         var animchar_effectors__effectorsState : Object;
                         human_ladder__ladderTm : float3x4&;
                         human_ladder__attached : bool;
                         human_ladder__numSteps : int;
                         human_net_phys__isClimbing : bool;
                         transform : float3x4&;
                         var phys_vars : PhysVars;
                         animchar : AnimcharBaseComponent&;
                         human_anim__ladder__leftHandNodeId : int;
                         human_anim__ladder__rightHandNodeId : int;
                         human_anim__ladder__handToLegsOffset : float3&;
                         human_anim__ladder__effectorOffset : float3&;
                         animchar__visible = true;
                         human_anim__ladder__handSidesOffset : float  = 0.35f)
  if !animchar__visible
    return
  var rightHandEffector = getNullableRW_EffectorData(animchar_effectors__effectorsState, "r.hand")
  var leftHandEffector = getNullableRW_EffectorData(animchar_effectors__effectorsState, "l.hand")
  if human_ladder__attached && !human_net_phys__isClimbing
    let d_wofs = geomtree_calc_optimal_wofs(transform[3])

    var lhandTm, rhandTm : float3x4
    geomtree_getNodeWtmRelScalar(*animchar.nodeTree, human_anim__ladder__rightHandNodeId, rhandTm)
    geomtree_getNodeWtmRelScalar(*animchar.nodeTree, human_anim__ladder__leftHandNodeId, lhandTm)
    let ladderItm = inverse(human_ladder__ladderTm)
    let ladderZScale = length(human_ladder__ladderTm[2])
    let ladderZSign = sign(dot(human_ladder__ladderTm[2], transform[2]))
    let lhandZposInLadderTransform = ladderZSign * human_anim__ladder__handSidesOffset * safeinv(ladderZScale) * 0.5f
    let rhandZposInLadderTransform = -ladderZSign * human_anim__ladder__handSidesOffset * safeinv(ladderZScale) * 0.5f
    let topHandPos = transform[3] + human_anim__ladder__handToLegsOffset
    let posInLadderTransform = ladderItm * topHandPos
    let vertPosInLadderTransform = posInLadderTransform.y + 0.5f// 0.5 basis
    var ladderProgress = vertPosInLadderTransform * float(human_ladder__numSteps - 1) * 0.5f // 1 cycle - 4 steps

    let step = safeinv(float(human_ladder__numSteps - 1))
    let rHandPos = float3(0.f, (floor(ladderProgress) * 2.f + 1.f) * step - 0.5f, rhandZposInLadderTransform)
    let lHandPos = float3(0.f, (floor(ladderProgress) * 2.f) * step - 0.5f, lhandZposInLadderTransform)

    ladderProgress -= floor(ladderProgress)
    setVar(phys_vars, human_anim.ladderProgressVarId, ladderProgress)

    var normLadderTm = human_ladder__ladderTm
    if posInLadderTransform.x < 0.f
      normLadderTm[0] = -normLadderTm[0]
    orthonormalize(normLadderTm)
    let worldOffset = mult(normLadderTm, human_anim__ladder__effectorOffset)

    rightHandEffector.position = human_ladder__ladderTm * rHandPos - d_wofs + worldOffset
    rightHandEffector.wtm = rhandTm
    rightHandEffector.wtm[3] = rightHandEffector.position
    rightHandEffector.weight = saturate(2.f * sin((ladderProgress - 0.5f) * TWOPI))

    leftHandEffector.position = human_ladder__ladderTm * lHandPos - d_wofs + worldOffset
    leftHandEffector.wtm = lhandTm
    leftHandEffector.wtm[3] = leftHandEffector.position
    leftHandEffector.weight = saturate(2.f * sin(ladderProgress * TWOPI))
  else
    rightHandEffector.weight = 0.f
    leftHandEffector.weight = 0.f