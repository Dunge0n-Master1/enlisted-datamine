require ecs
require DagorSystem
require AnimV20
require enlisted.events_enlisted

let
  upperHash = ecs_hash("upper")
  lowerHash = ecs_hash("lower")

[es(tag=gameClient, on_appear)]
def parachute_init_animation(evt : Event;
                             var animchar : AnimcharBaseComponent&;
                             parachute_anim__closedState : string;
                             parachute_anim__openedState : string;
                             parachute_anim__closingState : string;
                             parachute_anim__openingState : string;
                             var parachute_anim__closedStateId : int&;
                             var parachute_anim__openedStateId : int&;
                             var parachute_anim__closingStateId : int&;
                             var parachute_anim__openingStateId : int&)
  assume animGraph = animchar.animGraph
  if animGraph != null
    parachute_anim__closedStateId = anim_graph_getStateIdx(*animGraph, parachute_anim__closedState)
    parachute_anim__openedStateId = anim_graph_getStateIdx(*animGraph, parachute_anim__openedState)
    parachute_anim__closingStateId = anim_graph_getStateIdx(*animGraph, parachute_anim__closingState)
    parachute_anim__openingStateId = anim_graph_getStateIdx(*animGraph, parachute_anim__openingState)

  if parachute_anim__closedStateId < 0
    logerr("Couldn't find parachute closed state animation!")
  if parachute_anim__openedStateId < 0
    logerr("Couldn't find parachute opened state animation!")
  if parachute_anim__closingStateId < 0
    logerr("Couldn't find parachute closing state animation!")
  if parachute_anim__openingStateId < 0
    logerr("Couldn't find parachute opening state animation!")

  *animGraph |> anim_graph_enqueueState(*animchar.animState, parachute_anim__closedStateId)


[es(tag=gameClient, after=human_anim_es)]
def parachute_animation_continuous(info : UpdateStageInfoAct;
                                   var animchar : AnimcharBaseComponent&;
                                   var parachute_anim__lastDeployState : bool&;
                                   var parachute_anim__openedAtTime : float&;
                                   var parachute_anim__closedAtTime : float&;
                                   parachute_anim__openDuration : float;
                                   parachute_anim__closeDuration : float;
                                   parachute_anim__closedStateId : int;
                                   parachute_anim__openedStateId : int;
                                   parachute_anim__closingStateId : int;
                                   parachute_anim__openingStateId : int;
                                   parachuteDeployed : Tag const?)
  assume animGraph = animchar.animGraph
  if animGraph == null
    return

  let deployed = parachuteDeployed != null

  // Feels like tracked should be used for this, but tracked es's are triggered at the end of the frame
  // Because of this current es will always be executed once before any track es
  // And unless we set openedAtTime and closedAtTime before that, one frame of already opened parachute
  // would play and it looked horrible
  if parachute_anim__lastDeployState != deployed
    if deployed
      parachute_anim__openedAtTime = info.curTime
    else
      parachute_anim__closedAtTime = info.curTime
    parachute_anim__lastDeployState = deployed

  if deployed
    if info.curTime < parachute_anim__openedAtTime + parachute_anim__openDuration
      *animGraph |> anim_graph_enqueueState(*animchar.animState, parachute_anim__openingStateId)
    else
      *animGraph |> anim_graph_enqueueState(*animchar.animState, parachute_anim__openedStateId)
  else
    if info.curTime < parachute_anim__closedAtTime + parachute_anim__closeDuration
      *animGraph |> anim_graph_enqueueState(*animchar.animState, parachute_anim__closingStateId)
    else
      *animGraph |> anim_graph_enqueueState(*animchar.animState, parachute_anim__closedStateId)


def set_human_anim_state(eid : EntityId; state : int)
  send_change_anim_state_event(eid, "lower", lowerHash, state)
  send_change_anim_state_event(eid, "upper", upperHash, state)


[es(tag=gameClient, on_appear)]
def human_parachute_init_animation(evt : Event;
                                   animchar : AnimcharBaseComponent;
                                   human_parachute_anim__openedState : string;
                                   human_parachute_anim__closingState : string;
                                   human_parachute_anim__openingState : string;
                                   var human_parachute_anim__openedStateId : int&;
                                   var human_parachute_anim__closingStateId : int&;
                                   var human_parachute_anim__openingStateId : int&)
  assume animGraph = animchar.animGraph
  if animGraph != null
    human_parachute_anim__openedStateId = anim_graph_getStateIdx(*animGraph, human_parachute_anim__openedState)
    human_parachute_anim__closingStateId = anim_graph_getStateIdx(*animGraph, human_parachute_anim__closingState)
    human_parachute_anim__openingStateId = anim_graph_getStateIdx(*animGraph, human_parachute_anim__openingState)

  if human_parachute_anim__openedStateId < 0
    logerr("Couldn't find human parachute opened state animation!")
  if human_parachute_anim__closingStateId < 0
    logerr("Couldn't find human parachute closing state animation!")
  if human_parachute_anim__openingStateId < 0
    logerr("Couldn't find human parachute opening state animation!")


[es(tag=gameClient, after=human_anim_es)]
def human_parachute_animation_continuous(info : UpdateStageInfoAct;
                                         eid : EntityId;
                                         var human_parachute_anim__lastDeployState : bool&;
                                         var human_parachute_anim__openedAtTime : float&;
                                         var human_parachute_anim__closedAtTime : float&;
                                         human_parachute_anim__openingSoundTemplate : string;
                                         human_parachute_anim__closingSoundTemplate : string;
                                         human_parachute_anim__openDuration : float;
                                         human_parachute_anim__closeDuration : float;
                                         human_parachute_anim__openedStateId : int;
                                         human_parachute_anim__closingStateId : int;
                                         human_parachute_anim__openingStateId : int;
                                         parachuteDeployed : Tag const?)
  let deployed = parachuteDeployed != null

  if human_parachute_anim__lastDeployState != deployed
    if deployed
      human_parachute_anim__openedAtTime = info.curTime
      createEntity(human_parachute_anim__openingSoundTemplate) <| $(init)
        init |> set("game_effect__attachedTo", eid)
    else
      human_parachute_anim__closedAtTime = info.curTime
      createEntity(human_parachute_anim__closingSoundTemplate) <| $(init)
        init |> set("game_effect__attachedTo", eid)
    human_parachute_anim__lastDeployState = deployed

  if deployed
    if info.curTime < human_parachute_anim__openedAtTime + human_parachute_anim__openDuration
      set_human_anim_state(eid, human_parachute_anim__openingStateId)
    else
      set_human_anim_state(eid, human_parachute_anim__openedStateId)
  else
    if info.curTime < human_parachute_anim__closedAtTime + human_parachute_anim__closeDuration
      set_human_anim_state(eid, human_parachute_anim__closingStateId)


[es(tag=gameClient, after=human_weap_block_aim_es, REQUIRE=parachuteDeployed)]
def human_parachute_block_aiming(info : ParallelUpdateFrameDelayed;
                                 var human_weap__blockAiming : bool&)
  human_weap__blockAiming = true
