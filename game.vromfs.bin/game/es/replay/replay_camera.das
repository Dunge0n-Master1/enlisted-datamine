require ecs
require app
require game.es.events
require game.events_game
require DagorConsole
require DagorMath
require DagorSystem
require EnlistedHuman
require Dacoll
require math
require math.base
require game.utils.team
require player
require enlisted.events_enlisted

[es(tag=playingReplay, REQUIRE=replayCamera)]
def spectate_on_replay(evt : ChangeReplayTarget;
                       camera__target : EntityId)
  if evt.newReplayTarget != INVALID_ENTITY_ID && has(evt.newReplayTarget, "specTarget")
    set(evt.newReplayTarget, "specTarget", camera__target)

[es(tag=playingReplay, track=camera__target, REQUIRE=replayCamera)]
def replay_change_human(evt : Event;
                        eid : EntityId;
                        camera__target : EntityId)
  find_query() <| $ [es(REQUIRE=isReplayObserved)] (eid : EntityId)
    removeSubTemplate(eid, "replay_observed")
    return true

  query(camera__target) <| $ [es(REQUIRE_NOT=isReplayObserved)] (possessedByPlr : EntityId)
    let set_camera <- @ <| (target : EntityId)
      sendEvent(eid, [[CmdSetCameraTarget target=target]])

    addSubTemplate(camera__target, "replay_observed", set_camera) <| $(var init : ComponentsInitializer)
      set(init, "watchedByPlr", camera__target)
      set(init, "bindedCamera", eid)

    query() <| $ [es(REQUIRE=replayCamera)] (eid : EntityId)
      sendEvent(eid, [[ChangeReplayTarget newReplayTarget=possessedByPlr]])
    //in replay check is_local for print tip
    if possessedByPlr |> has("is_local")
      set_local_player_eid(possessedByPlr)

[es(tag=playingReplay, no_order, REQUIRE=replayCamera)]
def catch_human_view(evt : UpdateStageInfoAct;
                     eid : EntityId;
                     camera__target : EntityId;
                     camera__active : bool)
  if !camera__active
    return

  var isTargetFound = false
  if camera__target != INVALID_ENTITY_ID
    query(camera__target) <| $ [es] (isAlive : bool)
      isTargetFound = isAlive
  if isTargetFound
    return

  sendEvent(eid, [[NextReplayTarget delta=1]])

[es(tag=playingReplay, REQUIRE_NOT=replay__overrideTargetSelect)]
def select_next_replay_target(evt : NextReplayTarget;
                              var camera__target : EntityId&;
                              var camera__prevTarget : EntityId&)
  var humans : array<EntityId>
  query() <| $ [es] (possessedByPlr : EntityId;
                     eid : EntityId)
    if possessedByPlr != INVALID_ENTITY_ID
      push(humans, eid)
  if length(humans) == 0
    return

  sort(humans) <| $(a, b : EntityId)
    var lhsName, rhsName : string
    query(a) <| $ [es] (possessedByPlr : EntityId)
      query(possessedByPlr) <| $ [es] (name : string)
        lhsName = name
    query(b) <| $ [es] (possessedByPlr : EntityId)
      query(possessedByPlr) <| $ [es] (name : string)
        rhsName = name
    return lhsName < rhsName

  var i : int = 0
  if camera__target != INVALID_ENTITY_ID
    for playerNo in iter_range(humans)
      if camera__target == humans[playerNo]
        i = playerNo
        break

  var isTargetFound = false
  var j : int = i
  let len = length(humans)
  for _ in iter_range(humans)
    if isTargetFound
      break
    j = (j + evt.delta + len) % len
    query(humans[j]) <| $ [es] (isAlive : bool)
      if isAlive
        if camera__target != humans[j]
          camera__prevTarget = camera__target
          camera__target = humans[j]
        isTargetFound = true

  if !isTargetFound
    camera__prevTarget = camera__target
    camera__target = INVALID_ENTITY_ID
