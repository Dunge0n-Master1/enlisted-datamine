require ecs
require math.base
require game.events_game
require enlisted.events_enlisted
require EnlistedCamera
require EnlistedHuman
require HumanPhys

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

def private set_replay_target(eid : EntityId)
  query(get_cur_cam_entity()) <| $ [es] (var camera__target : EntityId&; var camera__prevTarget : EntityId&)
    camera__prevTarget = camera__target
    camera__target = eid

[es(tag=playingReplay, REQUIRE=player)]
def set_player_as_replay_target_es(evt : SetReplayTarget; possessed : EntityId)
  if !has(possessed, "deadEntity")
    set_replay_target(possessed)

[es(tag=playingReplay, REQUIRE=human, REQUIRE_NOT=deadEntity)]
def set_human_as_replay_target_es(evt : SetReplayTarget; eid : EntityId)
  set_replay_target(eid)

// Hack for fix broken camera rotation in replay (fps mode only)
// Real fix: we need update phys for observed soldier in replay mode
// for do this thing we need set ROLE_REMOTELY_CONTROLLED_AUTHORITY, but for some reason it broken soldier at all
// See also: updateNetPhys
[es(tag=playingReplay, before=human_look_dir_camera_es, REQUIRE=(watchedByPlr, isReplayObserved))]
def replay_target_reset_camera_offset_es(info : UpdateStageInfoAct;
                                         var human_net_phys : HumanActor&;
                                         replay_gun__vertOffsetRestoreVisc : float = 0.4)
  assume currentState = human_net_phys.phys.currentState
  let viscosity = replay_gun__vertOffsetRestoreVisc * currentState.aimingAfterFireMult
  currentState.gunAimOffset = approach(currentState.gunAimOffset, float2(), info.dt, viscosity)
