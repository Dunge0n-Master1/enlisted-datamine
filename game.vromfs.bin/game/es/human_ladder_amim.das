require ecs
require game.es.events
require AnimV20
require GeomNodeTree
require EffectorData
require DngHumanAnim
require PhysVars
require math.base
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


[es(REQUIRE=human_on_ladder_animation, after=update_phys_es, before=animchar_es)]
def human_ladder_update_animation(info : ParallelUpdateFrameDelayed;
                                  game_effect__attachedTo : EntityId)
  assume attachedTo = game_effect__attachedTo
  query(attachedTo) <| $ [es(REQUIRE_NOT=deadEntity)] (human_anim : HumanAnimCtx;
                                                       var animchar_effectors__effectorsState : Object;
                                                       human_ladder__ladderTm : float3x4&;
                                                       human_ladder__numSteps : int;
                                                       var human_ladder__curLadderTm : float3x4&;
                                                       var human_ladder__curNumSteps : int&;
                                                       transform : float3x4&;
                                                       var phys_vars : PhysVars;
                                                       animchar : AnimcharBaseComponent&;
                                                       human_anim__ladder__leftHandNodeId : int;
                                                       human_anim__ladder__rightHandNodeId : int;
                                                       human_anim__ladder__handToLegsOffset : float3&;
                                                       human_anim__ladder__effectorOffset : float3&;
                                                       animchar__visible = true;
                                                       animchar__actWhenInvisible = false;
                                                       human_anim__ladder__handSidesOffset : float  = 0.35f)
    if !animchar__visible && !animchar__actWhenInvisible
      return
    var rightHandEffector = getNullableRW_EffectorData(animchar_effectors__effectorsState, "r.hand")
    var leftHandEffector = getNullableRW_EffectorData(animchar_effectors__effectorsState, "l.hand")

    let d_wofs = geomtree_calc_optimal_wofs(transform[3])

    if distance_sq(human_ladder__curLadderTm[3], human_ladder__ladderTm[3]) > FLT_EPSILON
      let checkedUp = normalize(human_ladder__ladderTm[1])
      let checkedDir = human_ladder__ladderTm[3] - transform[3]
      let dir = basis_aware_x0z(checkedDir, checkedUp)
      let pos = transform[3] + human_anim__ladder__handToLegsOffset + length(human_ladder__ladderTm[0]) * normalize(dir)
      if abs(inverse(human_ladder__ladderTm) * pos).y <= IDENT_BBOX.boxMax.y
        human_ladder__curLadderTm = human_ladder__ladderTm
        human_ladder__curNumSteps = human_ladder__numSteps

    var lhandTm, rhandTm : float3x4
    geomtree_getNodeWtmRelScalar(*animchar.nodeTree, human_anim__ladder__rightHandNodeId, rhandTm)
    geomtree_getNodeWtmRelScalar(*animchar.nodeTree, human_anim__ladder__leftHandNodeId, lhandTm)
    let ladderItm = inverse(human_ladder__curLadderTm)
    let ladderZScale = length(human_ladder__curLadderTm[2])
    let ladderZSign = sign(dot(human_ladder__curLadderTm[2], transform[2]))
    let ladderWidth = length(human_ladder__curLadderTm[0])
    let ladderUp = normalize(human_ladder__curLadderTm[1])
    let tempDir = human_ladder__curLadderTm[3] - transform[3]
    let toLadderDir = normalize(basis_aware_x0z(tempDir, ladderUp))
    let lhandZposInLadderTransform = ladderZSign * human_anim__ladder__handSidesOffset * safeinv(ladderZScale) * 0.5f
    let rhandZposInLadderTransform = -ladderZSign * human_anim__ladder__handSidesOffset * safeinv(ladderZScale) * 0.5f
    let topHandPos = transform[3] + human_anim__ladder__handToLegsOffset + ladderWidth / 2.f * toLadderDir
    let posInLadderTransform = ladderItm * topHandPos
    let vertPosInLadderTransform = posInLadderTransform.y + 0.5f// 0.5 basis
    var ladderProgress = vertPosInLadderTransform * float(human_ladder__curNumSteps - 1) * 0.5f // 1 cycle - 4 steps

    let step = safeinv(float(human_ladder__curNumSteps - 1))
    let rHandPos = float3(0.f, (floor(ladderProgress) * 2.f + 1.f) * step - 0.5f, rhandZposInLadderTransform)
    let lHandPos = float3(0.f, (floor(ladderProgress) * 2.f) * step - 0.5f, lhandZposInLadderTransform)

    ladderProgress -= floor(ladderProgress)
    setVar(phys_vars, human_anim.ladderProgressVarId, ladderProgress)

    var normLadderTm = human_ladder__curLadderTm
    if posInLadderTransform.x < 0.f
      normLadderTm[0] = -normLadderTm[0]
    orthonormalize(normLadderTm)
    let worldOffset = normLadderTm |> rotate(human_anim__ladder__effectorOffset)

    rightHandEffector.position = human_ladder__curLadderTm * rHandPos - d_wofs + worldOffset
    rightHandEffector.wtm = rhandTm
    rightHandEffector.wtm[3] = rightHandEffector.position
    rightHandEffector.weight = saturate(2.f * sin((ladderProgress - 0.5f) * TWOPI))

    leftHandEffector.position = human_ladder__curLadderTm * lHandPos - d_wofs + worldOffset
    leftHandEffector.wtm = lhandTm
    leftHandEffector.wtm[3] = leftHandEffector.position
    leftHandEffector.weight = saturate(2.f * sin(ladderProgress * TWOPI))


[es(on_disappear, REQUIRE=human_on_ladder_animation)]
def human_ladder_end_animation(evt : Event;
                               game_effect__attachedTo : EntityId)
  assume attachedTo = game_effect__attachedTo
  query(attachedTo) <| $ [es] (var animchar_effectors__effectorsState : Object)
    var rightHandEffector = getNullableRW_EffectorData(animchar_effectors__effectorsState, "r.hand")
    var leftHandEffector = getNullableRW_EffectorData(animchar_effectors__effectorsState, "l.hand")

    rightHandEffector.weight = 0.f
    leftHandEffector.weight = 0.f


[es(on_appear, REQUIRE=human_on_ladder_animation)]
def human_ladder_start_animation(evt : Event;
                                 game_effect__attachedTo : EntityId)
  assume attachedTo = game_effect__attachedTo
  query(attachedTo) <| $ [es(REQUIRE_NOT=deadEntity)] (human_ladder__ladderTm : float3x4&;
                                                       human_ladder__numSteps : int;
                                                       var human_ladder__curLadderTm : float3x4&;
                                                       var human_ladder__curNumSteps : int&)
    human_ladder__curLadderTm = human_ladder__ladderTm
    human_ladder__curNumSteps = human_ladder__numSteps
