require ecs
require game.events_game
require enlisted.events_enlisted

[es(tag=playingReplay, REQUIRE=replay__overrideTargetSelect)]
def enlisted_next_replay_target_es(evt : NextReplayTarget;
                                   var camera__target : EntityId&;
                                   var camera__prevTarget : EntityId&)
  var humans : array<EntityId>
  query() <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (eid : EntityId)
    push(humans, eid)

  if length(humans) == 0
    return

  sort(humans) <| $(a, b : EntityId)
    var lhsName, rhsName : string
    var lshSuqadIdx, rshSuqadIdx : int
    query(a) <| $ [es] (squad_member__memberIdx : int; squad_member__playerEid : EntityId)
      lhsName = get_string(squad_member__playerEid, "name", "")
      lshSuqadIdx = squad_member__memberIdx

    query(b) <| $ [es] (squad_member__memberIdx : int; squad_member__playerEid : EntityId)
      rhsName = get_string(squad_member__playerEid, "name", "")
      rshSuqadIdx = squad_member__memberIdx

    return "{rhsName}{rshSuqadIdx}" < "{lhsName}{lshSuqadIdx}"

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
