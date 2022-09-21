require ecs
require math.base
require game.events_game
require enlisted.events_enlisted
require EnlistedCamera
require EnlistedHuman
require HumanPhys
require app
require game.es.player_common
require player

let HUMAN_PHYS_ZOOM_SPEED = 5.f // taked from humanPhys.h

[es(tag=playingReplay)]
def enlisted_next_replay_target_es(evt : NextReplayTarget; camera__target : EntityId)
  var heroEid = camera__target
  if has(camera__target, "vehicle")
    find_query() <| $ [es(REQUIRE=watchedByPlr)] (eid : EntityId)
      heroEid = eid
      return true

  var needPushHero = true
  var humans : array<EntityId>
  query() <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (eid : EntityId)
    push(humans, eid)
    if eid == heroEid
      needPushHero = false

  if length(humans) == 0
    return

  if needPushHero && !!heroEid
    push(humans, heroEid)

  sort(humans) <| $(a, b : EntityId)
    var lhsName, rhsName : string
    var lshSuqadIdx, rshSuqadIdx : int
    query(a) <| $ [es] (squad_member__memberIdx : int; squad_member__playerEid : EntityId)
      lhsName = get_string(squad_member__playerEid, "name", "")
      lshSuqadIdx = squad_member__memberIdx

    query(b) <| $ [es] (squad_member__memberIdx : int; squad_member__playerEid : EntityId)
      rhsName = get_string(squad_member__playerEid, "name", "")
      rshSuqadIdx = squad_member__memberIdx
    if rhsName == lhsName
      return rshSuqadIdx > lshSuqadIdx
    return rhsName < lhsName

  var j : int = max(find_index(humans, heroEid), 0)
  let len = length(humans)
  for _ in iter_range(humans)
    j = (j + evt.delta + len) % len
    if heroEid != humans[j]
      sendEvent(humans[j], [[ReplayPossessEntity]])
      break

[es(tag=playingReplay, on_appear, REQUIRE=watchedByPlr)]
def replay_on_possessed_entity_es(evt : Event;
                                  eid aka entity_eid : EntityId;
                                  squad_member__playerEid : EntityId;
                                  var bindedCamera : EntityId&;
                                  var watchedByPlr : EntityId&;
                                  var isTpsView aka entity_isTpsView : bool&)
  emit_hero_changed_event(entity_eid)
  find_query() <| $ [es(REQUIRE=replayCamera)] (eid : EntityId;
                                                camera__active : bool;
                                                isTpsView : bool;
                                                var camera__target : EntityId&)
    if !camera__active
      return false
    query(squad_member__playerEid) <| $ [es] (var specTarget : EntityId&)
      specTarget = entity_eid
      set_local_player_eid(squad_member__playerEid)
    watchedByPlr = entity_eid
    camera__target = entity_eid
    bindedCamera = eid
    entity_isTpsView = isTpsView
    return true

[es(tag=playingReplay, on_appear, on_event=EventHeroChanged, after=replay_on_possessed_entity_es, track=(human_attached_gun__attachedGunEid, isTpsView), REQUIRE=watchedByPlr)]
def replay_on_use_mounted_gun_es(evt : Event;
                                 eid aka entity_eid : EntityId;
                                 human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                                 isTpsView : bool)
  find_query() <| $ [es(REQUIRE=replayCamera)] (camera__active : bool;
                                                var camera__target : EntityId&)
    if !camera__active
      return false
    camera__target = !human_attached_gun__attachedGunEid || isTpsView ? entity_eid : human_attached_gun__attachedGunEid
    return true

[es(tag=playingReplay, REQUIRE_NOT=watchedByPlr)]
def replay_possess_entity_es(evt : ReplayPossessEntity; eid : EntityId)
  query() <| $ [es(REQUIRE=watchedByPlr)] (eid : EntityId)
    removeSubTemplate(eid, "replay_observed")

  addSubTemplate(eid, "replay_observed")

[es(tag=playingReplay, REQUIRE=player)]
def set_player_as_replay_target_es(evt : SetReplayTarget; possessed : EntityId)
  query(possessed) <| $ [es(REQUIRE_NOT=(watchedByPlr, deadEntity))] ()
    sendEvent(possessed, [[ReplayPossessEntity]])

[es(tag=playingReplay, REQUIRE=human, REQUIRE_NOT=(watchedByPlr, deadEntity))]
def set_human_as_replay_target_es(evt : SetReplayTarget; eid : EntityId)
  sendEvent(eid, [[ReplayPossessEntity]])

// Hack for fix broken fps view in replay mode
// Real fix: we need update phys for observed soldier in replay mode
// for do this thing we need set ROLE_REMOTELY_CONTROLLED_AUTHORITY, but for some reason it broken soldier at all
// See also: updateNetPhys
[es(tag=playingReplay, before=human_look_dir_camera_es, before=human_phys_es, REQUIRE=(watchedByPlr, isReplayObserved))]
def replay_simulate_net_phys_update_es(info : UpdateStageInfoAct;
                                       var human_net_phys : HumanActor&;
                                       isDowned : bool;
                                       human_net_phys__isClimbing : bool;
                                       // for scope weapons always setup zoom, bc HCT_ZOOM_VIEW isn't replicated
                                       human_weap__opticsAttached : bool;
                                       replay_gun__vertOffsetRestoreVisc : float = 0.4)
  assume phys = human_net_phys.phys
  assume currentState = phys.currentState
  assume appliedCT = phys.appliedCT

  let isAiming = (is_control_bit_set(appliedCT, HumanPhysControlType HCT_AIM) &&
                  human_phys_state_can_aim(currentState) &&
                  !isDowned && !human_net_phys__isClimbing &&
                  currentState.weapEquipState.curState != HUWeaponEquipState EES_DOWN)
  let isZooming = (isAiming &&
                   human_weap__opticsAttached &&
                   human_phys_state_can_zoom(currentState) &&
                   currentState.moveState != HUMoveState EMS_SPRINT)

  currentState.aimForZoomProgress = (isAiming ? max(currentState.aimPosition, currentState.aimForZoomProgress) : currentState.aimPosition)

  currentState.aimPosition = move_to(currentState.aimPosition, isAiming ? 1.f : 0.f, info.dt, human_net_phys.phys.aimSpeed * currentState.aimSpeedMult)
  currentState.zoomPosition = move_to(currentState.zoomPosition, (isZooming ? 1.f : 0.f) * currentState.aimForZoomProgress, info.dt,
    HUMAN_PHYS_ZOOM_SPEED * currentState.aimSpeedMult);

  let viscosity = replay_gun__vertOffsetRestoreVisc * currentState.aimingAfterFireMult
  currentState.gunAimOffset = approach(currentState.gunAimOffset, float2(), info.dt, viscosity)
