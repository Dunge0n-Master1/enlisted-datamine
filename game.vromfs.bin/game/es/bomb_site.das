require ecs
require app
require math.base
require DagorMath
require game.es.events
require enlisted.events_enlisted
require game.utils.team
require RendInst
require AnimV20
require GeomNodeTree

def start_planting(eid, requester_eid;
                   total_time : float;
                   var bomb_site__operator : EntityId&;
                   var bomb_site__plantProgressDeltaPerSec : float&)
  bomb_site__operator = requester_eid
  bomb_site__plantProgressDeltaPerSec = safeinv(total_time)
  sendEvent(eid, [[EventBombSitePlanting bombSiteOperator=bomb_site__operator]])


def start_reseting(requester_eid;
                   total_time : float;
                   var bomb_site__operator : EntityId&;
                   var bomb_site__plantProgressDeltaPerSec : float&)
  bomb_site__operator = requester_eid
  bomb_site__plantProgressDeltaPerSec = -safeinv(total_time)


def reset_bomb_site(var bomb_site__operator : EntityId&;
                    var bomb_site__plantProgress : float&;
                    var bomb_site__plantProgressPausedAt : float&;
                    var bomb_site__plantProgressDeltaPerSec : float&)
  bomb_site__operator = INVALID_ENTITY_ID
  bomb_site__plantProgress = 0.0
  bomb_site__plantProgressPausedAt = 0.0
  bomb_site__plantProgressDeltaPerSec = 0.0


def activate_bomb(eid;
                  bomb_site__timeToExplosion : float;
                  var bomb_site__planterEid : EntityId&;
                  var bomb_site__operator : EntityId&;
                  var bomb_site__isBombPlanted : bool&;
                  var bomb_site__plantProgressDeltaPerSec : float&;
                  var bomb_site__timeToExplosionLeft : float&)
  sendEvent(eid, [[EventBombSitePlanted bombSiteOperator=bomb_site__operator]])
  bomb_site__plantProgressDeltaPerSec = 0.0
  bomb_site__planterEid = bomb_site__operator
  bomb_site__operator = INVALID_ENTITY_ID
  bomb_site__isBombPlanted = true
  bomb_site__timeToExplosionLeft = bomb_site__timeToExplosion


def detonate_bomb(eid : EntityId; activator_template : string; transform : float3x4; offset : float3)
  sendEvent(eid, [[EventBombSiteExplosion]])
  createEntity(activator_template) <| $(var init : ComponentsInitializer)
    var tm = transform
    tm[3] += offset
    set(init, "transform", tm)


def reset_active_bomb(var bomb_site__isBombPlanted : bool&;
                      var bomb_site__defuseProgress : float&;
                      var bomb_site__defuseProgressPausedAt : float&;
                      var bomb_site__timeToExplosionLeft : float&;
                      var bomb_site__defuseProgressDeltaPerSec : float&)
  bomb_site__isBombPlanted = false
  bomb_site__defuseProgress = 0.0
  bomb_site__defuseProgressPausedAt = 0.0
  bomb_site__timeToExplosionLeft = -1.0
  bomb_site__defuseProgressDeltaPerSec = 0.0


def defuse_bomb(eid;
                bomb_site__resetPlantProgressOnDefuse : bool;
                bomb_site__timeToResetPlant : float;
                bomb_site__canResetProgressByInteraction : bool;
                var bomb_site__plantProgressDeltaPerSec : float&;
                var bomb_site__operator : EntityId&;
                var bomb_site__plantProgress : float&;
                var bomb_site__plantProgressPausedAt : float&;
                var bomb_site__isBombPlanted : bool&;
                var bomb_site__defuseProgress : float&;
                var bomb_site__defuseProgressPausedAt : float&;
                var bomb_site__defuseProgressDeltaPerSec : float&;
                var bomb_site__timeToExplosionLeft : float&;
                var bomb_site__planterEid : EntityId&)
  reset_active_bomb(bomb_site__isBombPlanted, bomb_site__defuseProgress, bomb_site__defuseProgressPausedAt,
                    bomb_site__timeToExplosionLeft, bomb_site__defuseProgressDeltaPerSec)
  sendEvent(eid, [[EventBombSiteDefused bombSiteOperator=bomb_site__operator]])
  if bomb_site__resetPlantProgressOnDefuse
    reset_bomb_site(bomb_site__operator, bomb_site__plantProgress, bomb_site__plantProgressPausedAt, bomb_site__plantProgressDeltaPerSec)
  elif bomb_site__canResetProgressByInteraction
    start_reseting(bomb_site__operator, bomb_site__timeToResetPlant, bomb_site__operator, bomb_site__plantProgressDeltaPerSec)
  bomb_site__planterEid = INVALID_ENTITY_ID


[es(tag=server)]
def on_bomb_site_use(evt : CmdUse;
                     eid : EntityId;
                     active : bool = true;
                     bomb_site__plantingTeam : int;
                     bomb_site__timeToPlant : float;
                     bomb_site__timeToResetPlant : float;
                     bomb_site__isBombPlanted : bool;
                     bomb_site__canResetProgressByInteraction : bool;
                     var bomb_site__operator : EntityId&;
                     var bomb_site__plantProgressDeltaPerSec : float&)
  if !active || !!bomb_site__operator || bomb_site__isBombPlanted
    return
  query(evt.requesterEid) <| $ [es] (team : int)
    let isPlanting = bomb_site__plantingTeam == team
    if isPlanting
      start_planting(eid, evt.requesterEid, bomb_site__timeToPlant, bomb_site__operator, bomb_site__plantProgressDeltaPerSec)
    elif bomb_site__canResetProgressByInteraction
      start_reseting(evt.requesterEid, bomb_site__timeToResetPlant, bomb_site__operator, bomb_site__plantProgressDeltaPerSec)

[es(tag=server)]
def on_planted_bomb_use(evt : CmdUse;
                        eid : EntityId;
                        active : bool = true;
                        bomb_site__plantingTeam : int;
                        bomb_site__timeToDefuse : float;
                        bomb_site__isBombPlanted : bool;
                        var bomb_site__operator : EntityId&;
                        var bomb_site__defuseProgressDeltaPerSec : float&)
  if !active || !!bomb_site__operator || !bomb_site__isBombPlanted
    return
  query(evt.requesterEid) <| $ [es] (team : int)
    let isDefuseTeam = bomb_site__plantingTeam != team
    if isDefuseTeam
      bomb_site__operator = evt.requesterEid
      bomb_site__defuseProgressDeltaPerSec = safeinv(bomb_site__timeToDefuse)
      sendEvent(eid, [[EventBombSiteDefusing bombSiteOperator=bomb_site__operator]])

[es(tag=server)]
def on_bomb_use_terminated(evt : CmdStopInteractBomb; var bomb_site__operator : EntityId&)
  if evt.operatorEid == bomb_site__operator
    bomb_site__operator = INVALID_ENTITY_ID

[es(tag=server, on_appear)]
def init_bomb_site_ri_max_use_dist(evt : Event;
                                   ri_extra : RiExtraComponent;
                                   var bomb_site__maxDist : float&)
  let riType = handle_to_ri_type(ri_extra.handle)
  let riCollres = get_ri_gen_extra_collres(int(riType))
  if riCollres == null
    return
  let padding = bomb_site__maxDist
  let diag = length(riCollres.vFullBBox.bmax.xz - riCollres.vFullBBox.bmin.xz)
  bomb_site__maxDist = diag * 0.5 + padding

[es(tag=server, no_order)]
def bomb_site_check_operator(info : UpdateStageInfoAct;
                             transform : float3x4;
                             bomb_site__maxDist : float;
                             var bomb_site__plantProgressDeltaPerSec : float&;
                             var bomb_site__defuseProgressDeltaPerSec : float&;
                             var bomb_site__operator : EntityId&)
  if !bomb_site__operator
    return
  let bombPos = transform[3]
  var isOperatorValid = false
  query(bomb_site__operator) <| $ [es] (isAlive : bool; isDowned : bool; transform : float3x4; human_use_object__nodeId : int; animchar : AnimcharBaseComponent)
    let isHeightValid = geomtree_getNodeWpos(*animchar.nodeTree, human_use_object__nodeId).y > bombPos.y
    isOperatorValid = isAlive && !isDowned && length_sq(transform[3] - bombPos) < square(bomb_site__maxDist) && isHeightValid
  if !isOperatorValid
    bomb_site__operator = INVALID_ENTITY_ID
    bomb_site__plantProgressDeltaPerSec = 0.0
    bomb_site__defuseProgressDeltaPerSec = 0.0

[es(tag=server, after=bomb_site_check_operator, track=(active, bomb_site__operator, bomb_site__isBombPlanted, bomb_site__timeToExplosionLeft))]
def bomb_site_track_bomb_ticking(evt : Event;
                                 active : bool = true;
                                 bomb_site__stopTimerWhenDefusing : bool;
                                 bomb_site__operator : EntityId;
                                 bomb_site__isBombPlanted : bool;
                                 bomb_site__timeToExplosionLeft : float;
                                 var bomb_site__isBombTicking : bool&)
  bomb_site__isBombTicking = active && bomb_site__isBombPlanted && bomb_site__timeToExplosionLeft >= 0.f && (!bomb_site__stopTimerWhenDefusing || !bomb_site__operator)

[es(tag=server, after=bomb_site_track_bomb_ticking)]
def bomb_site_ticking(info : UpdateStageInfoAct;
                      eid : EntityId;
                      transform : float3x4;
                      bomb_site__isBombTicking : bool;
                      bomb_site__shellActivatorTemplate : string;
                      bomb_site__shellOffset : float3;
                      var bomb_site__timeToExplosionLeft : float&)
  if !bomb_site__isBombTicking
    return
  bomb_site__timeToExplosionLeft = bomb_site__timeToExplosionLeft - info.dt
  if bomb_site__timeToExplosionLeft < 0.f
    detonate_bomb(eid, bomb_site__shellActivatorTemplate, transform, bomb_site__shellOffset)

[es(tag=server, track=bomb_site__isBombTicking)]
def bomb_site_save_bomb_ticking_timings_for_clients(evt : Event;
                                                    bomb_site__isBombTicking : bool;
                                                    bomb_site__timeToExplosionLeft : float;
                                                    var bomb_site__explosionTimeEnd : float&;
                                                    var bomb_site__explosionTimerPausedAtTime : float&)
  if bomb_site__isBombTicking
    bomb_site__explosionTimerPausedAtTime = -1.0
    bomb_site__explosionTimeEnd = get_sync_time() + bomb_site__timeToExplosionLeft
  else
    bomb_site__explosionTimerPausedAtTime = bomb_site__timeToExplosionLeft
    bomb_site__explosionTimeEnd = -1.0

[es(tag=server, after=bomb_site_check_operator, track=(active, bomb_site__operator, bomb_site__isBombPlanted))]
def bomb_site_track_planting_progress_alloved(evt : Event;
                                              active : bool = true;
                                              bomb_site__operator : EntityId;
                                              bomb_site__isBombPlanted : bool;
                                              var bomb_site__isPlantingOrReseting : bool&)
  bomb_site__isPlantingOrReseting = active && !bomb_site__isBombPlanted && !!bomb_site__operator

[es(tag=server, after=bomb_site_track_planting_progress_alloved)]
def bomb_site_planting(info : UpdateStageInfoAct;
                       eid : EntityId;
                       bomb_site__timeToExplosion : float;
                       bomb_site__isPlantingOrReseting : bool;
                       var bomb_site__isBombPlanted : bool&;
                       var bomb_site__plantProgressDeltaPerSec : float&;
                       var bomb_site__planterEid : EntityId&;
                       var bomb_site__operator : EntityId&;
                       var bomb_site__plantProgress : float&;
                       var bomb_site__plantProgressPausedAt : float&;
                       var bomb_site__timeToExplosionLeft : float&)
  if !bomb_site__isPlantingOrReseting
    return
  let delta = bomb_site__plantProgressDeltaPerSec * info.dt
  bomb_site__plantProgress += delta
  if bomb_site__plantProgress >= 1.0
    activate_bomb(eid, bomb_site__timeToExplosion, bomb_site__planterEid, bomb_site__operator, bomb_site__isBombPlanted,
                  bomb_site__plantProgressDeltaPerSec, bomb_site__timeToExplosionLeft)
  elif bomb_site__plantProgress <= 0.0
    reset_bomb_site(bomb_site__operator, bomb_site__plantProgress, bomb_site__plantProgressPausedAt, bomb_site__plantProgressDeltaPerSec)
  bomb_site__plantProgress = clamp(bomb_site__plantProgress, 0.0, 1.0)

[es(tag=server, track=bomb_site__isPlantingOrReseting)]
def bomb_site_save_planting_timings_for_clients(evt : Event;
                                                bomb_site__isPlantingOrReseting : bool;
                                                bomb_site__plantProgress : float;
                                                bomb_site__timeToPlant : float;
                                                bomb_site__timeToResetPlant : float;
                                                bomb_site__plantProgressDeltaPerSec : float;
                                                var bomb_site__plantedTimeEnd : float&;
                                                var bomb_site__resetTimeEnd : float&;
                                                var bomb_site__plantProgressPausedAt : float&)
  if bomb_site__isPlantingOrReseting
    bomb_site__plantProgressPausedAt = -1.0
    let isPlanting = bomb_site__plantProgressDeltaPerSec > 0.0
    let time = get_sync_time()
    bomb_site__plantedTimeEnd = isPlanting ? (time + bomb_site__timeToPlant * (1.0 - bomb_site__plantProgress)) : -1.0
    bomb_site__resetTimeEnd = !isPlanting ? (time + bomb_site__timeToResetPlant * bomb_site__plantProgress) : -1.0
  else
    bomb_site__plantProgressPausedAt = bomb_site__plantProgress
    bomb_site__plantedTimeEnd = -1.0
    bomb_site__resetTimeEnd = -1.0

[es(tag=server, after=bomb_site_check_operator, track=(active, bomb_site__operator, bomb_site__isBombPlanted, bomb_site__defuseProgress))]
def bomb_site_track_defusing_progress_alloved(evt : Event;
                                              active : bool = true;
                                              bomb_site__defuseProgress : float;
                                              bomb_site__operator : EntityId;
                                              bomb_site__isBombPlanted : bool;
                                              var bomb_site__isDefusing : bool&)
  bomb_site__isDefusing = active && bomb_site__isBombPlanted && !!bomb_site__operator && bomb_site__defuseProgress < 1.0

[es(tag=server, after=bomb_site_track_defusing_progress_alloved)]
def bomb_site_defusing(info : UpdateStageInfoAct;
                       eid : EntityId;
                       bomb_site__isDefusing : bool;
                       bomb_site__resetPlantProgressOnDefuse : bool;
                       bomb_site__timeToResetPlant : float;
                       bomb_site__canResetProgressByInteraction : bool;
                       var bomb_site__defuseProgressDeltaPerSec : float&;
                       var bomb_site__timeToExplosionLeft : float&;
                       var bomb_site__isBombPlanted : bool&;
                       var bomb_site__operator : EntityId&;
                       var bomb_site__plantProgressDeltaPerSec : float&;
                       var bomb_site__plantProgress : float&;
                       var bomb_site__plantProgressPausedAt : float&;
                       var bomb_site__defuseProgress : float&;
                       var bomb_site__defuseProgressPausedAt : float&;
                       var bomb_site__planterEid : EntityId&)
  if !bomb_site__isDefusing
    return
  let delta = bomb_site__defuseProgressDeltaPerSec * info.dt
  bomb_site__defuseProgress += delta
  if bomb_site__defuseProgress >= 1.0
    defuse_bomb(eid, bomb_site__resetPlantProgressOnDefuse, bomb_site__timeToResetPlant, bomb_site__canResetProgressByInteraction, bomb_site__plantProgressDeltaPerSec,
                bomb_site__operator, bomb_site__plantProgress, bomb_site__plantProgressPausedAt, bomb_site__isBombPlanted,
                bomb_site__defuseProgress, bomb_site__defuseProgressPausedAt, bomb_site__defuseProgressDeltaPerSec,
                bomb_site__timeToExplosionLeft, bomb_site__planterEid)
  bomb_site__defuseProgress = clamp(bomb_site__defuseProgress, 0.0, 1.0)

[es(tag=server, track=bomb_site__isDefusing)]
def bomb_site_save_defuse_timings_for_clients(evt : Event;
                                              bomb_site__isDefusing : bool;
                                              bomb_site__defuseProgress : float;
                                              bomb_site__timeToDefuse : float;
                                              var bomb_site__defusedTimeEnd : float&;
                                              var bomb_site__defuseProgressPausedAt : float&)
  if bomb_site__isDefusing
    bomb_site__defuseProgressPausedAt = -1.0
    bomb_site__defusedTimeEnd = get_sync_time() + bomb_site__timeToDefuse * (1.0 - bomb_site__defuseProgress)
  else
    bomb_site__defuseProgressPausedAt = bomb_site__defuseProgress
    bomb_site__defusedTimeEnd = -1.0

[es(tag=server)]
def bomb_site_destroy_on_detonation(evt : EventBombSiteExplosion; eid : EntityId)
  destroyEntity(eid)