require ecs
require game.es.events
require DngHuman
require DagorMath
require gameObject
require math.ang
require math.base
require enlisted.events_enlisted


def set_ladder_for_attach(eid : EntityId)
  var res = false
  query(eid) <| $ [es] (var human_ladder__ladderTm : float3x4&;
                        var human_ladder__numSteps : int&;
                        human_net_phys : HumanActor;
                        human_net_phys__isClimbing : bool;
                        human_net_phys__ladderTracePos : float3 = float3(0, 1, 0);
                        human_net_phys__ladderTraceDist : float = 1.0)
    assume state = human_net_phys.phys.currentState
    let canClimbLadders = (int(StateFlag ST_CRAWL | StateFlag ST_DOWNED) & int(state.states)) == 0
    if !canClimbLadders || state.isDetachedFromLadder || human_net_phys__isClimbing
      return
    var humanTransform : float3x4
    location_toTM(state.location, humanTransform)
    var dir = human_net_phys.phys.appliedCT.wishLookDir
    dir.y = max(dir.y, 0.0)
    let fromPos = humanTransform * human_net_phys__ladderTracePos
    let toPos = fromPos + dir * human_net_phys__ladderTraceDist

    res = find_ladder(fromPos, toPos, human_ladder__ladderTm, human_ladder__numSteps)
  return res


[es(after=(human_phys_es, before_net_phys_sync), on_event=UpdatePhysEvent, before=after_net_phys_sync,
    REQUIRE_NOT=deadEntity)]
def human_ladder_check_attach(evt : Event;
                              eid : EntityId;
                              var human_ladder__attached : bool&)
  if !human_ladder__attached
    human_ladder__attached = set_ladder_for_attach(eid)


[es(after=(human_phys_es, before_net_phys_sync, check_other_ladder), on_event=UpdatePhysEvent, before=after_net_phys_sync,
    REQUIRE_NOT=deadEntity)]
def human_ladder_check_detach(evt : Event;
                              var human_ladder__attached : bool&;
                              var human_net_phys : HumanActor;
                              human_ladder__curLadderTm : float3x4;
                              human_ladder__ladderTm : float3x4)
  if human_ladder__attached
    // on jump
    assume ct = human_net_phys.phys.appliedCT
    if ct |> is_control_bit_set(HumanPhysControlType HCT_JUMP)
      human_ladder__attached = false
      human_net_phys.phys.currentState |> human_phys_state_set_detachedFromLadder(true)
      return

    // on angle
    let ladderWidth = length(human_ladder__ladderTm[2])
    let toLadderDist = length(human_ladder__ladderTm[0]) + human_net_phys.phys.collRad
    let maxAngle = atan2(ladderWidth / 2.0f + 0.1f, toLadderDist)
    let lookDir = ct.wishLookDir
    let up = normalize(human_ladder__ladderTm[1])
    let toLadderDir = human_ladder__ladderTm[3] - float3(human_net_phys.phys.currentState.location.P)
    let curAngle = angle(toLadderDir - dot(toLadderDir, up) * up, lookDir - dot(lookDir, up) * up)
    if curAngle > maxAngle
      human_ladder__attached = false
      human_net_phys.phys.currentState |> human_phys_state_set_detachedFromLadder(true)
      return

    // on ladder down
    if distance_sq(human_ladder__curLadderTm[3], human_ladder__ladderTm[3]) < FLT_EPSILON
      let itm = inverse(human_ladder__ladderTm)
      let localPos = itm * float3(human_net_phys.phys.currentState.location.P)
      let walkDir = dot(human_net_phys.phys.currentState.velocity, human_ladder__curLadderTm[1])
      let down = walkDir < 0.0f
      if down && localPos.y < IDENT_BBOX.boxMin.y
        human_ladder__attached = false
        human_net_phys.phys.currentState |> human_phys_state_set_detachedFromLadder(true)
        return


[es(track=human_net_phys__isClimbing, before=human_pre_phys_ladder_update_es)]
def on_ladder_climb(evt : Event;
                    var human_ladder__attached : bool&;
                    human_net_phys__isClimbing : bool)
  if human_ladder__attached && human_net_phys__isClimbing
    human_ladder__attached = false


[es(after=human_phys_es, on_event=UpdatePhysEvent)]
def check_other_ladder(evt : Event;
                       var human_ladder__ladderTm : float3x4&;
                       human_ladder__curLadderTm : float3x4;
                       var human_ladder__numSteps : int&;
                       human_ladder__attached : bool;
                       human_net_phys : HumanActor)
  let toNextLadder = human_ladder__ladderTm[3] - human_ladder__curLadderTm[3]
  let walkDir = dot(human_net_phys.phys.currentState.velocity, human_ladder__curLadderTm[1])
  if ((length_sq(toNextLadder) > FLT_EPSILON && (abs(walkDir) < FLT_EPSILON ||
      walkDir * dot(toNextLadder, human_ladder__curLadderTm[1]) >= 0.0f))
      || !human_ladder__attached)
    return
  var humanTransform : float3x4
  location_toTM(human_net_phys.phys.currentState.location, humanTransform)
  let itm = inverse(human_ladder__curLadderTm)
  let ladderHeight = length(human_ladder__curLadderTm[1])
  assume standingHeight = human_net_phys.phys.standingHeight
  let localHeight = (itm * humanTransform[3]).y * ladderHeight
  let up = walkDir > 0.0f || (length_sq(toNextLadder) < FLT_EPSILON && abs(walkDir) < FLT_EPSILON)
  let down = walkDir < 0.0f
  if localHeight + standingHeight > ladderHeight / 2.0f && up
    let ladderUp = normalize(human_ladder__curLadderTm[1])
    let fromPos = human_ladder__curLadderTm * float3(0., IDENT_BBOX.boxMax.y, 0.) + 0.1f * ladderUp
    let toPos = fromPos + ladderUp * standingHeight
    find_ladder(fromPos, toPos, human_ladder__ladderTm, human_ladder__numSteps)
  elif localHeight < -ladderHeight / 2.0f && down // for better animation
    let ladderUp = normalize(human_ladder__curLadderTm[1])
    let fromPos = human_ladder__curLadderTm * float3(0., IDENT_BBOX.boxMin.y, 0.) - 0.1f * ladderUp
    let toPos = fromPos - ladderUp * standingHeight
    find_ladder(fromPos, toPos, human_ladder__ladderTm, human_ladder__numSteps)

// state ---------------------------------------------------------------

[es(track=(human_ladder__attached, human_net_phys__isClimbing))]
def human_attach_and_climb_track(evt : Event;
                                 eid : EntityId;
                                 human_ladder__attached : bool;
                                 human_net_phys__isClimbing : bool;
                                 var human_on_ladder__animation : EntityId&)
  if human_ladder__attached && !human_net_phys__isClimbing
    human_on_ladder__animation = createEntity("human_on_ladder_animation") <| $(var init)
      set(init, "game_effect__attachedTo", eid)
  elif ((human_net_phys__isClimbing || !human_ladder__attached) &&
        human_on_ladder__animation != INVALID_ENTITY_ID)
    destroyEntity(human_on_ladder__animation)
    human_on_ladder__animation = INVALID_ENTITY_ID
