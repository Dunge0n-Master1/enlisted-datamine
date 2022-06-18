require ecs
require zones
require DagorSystem
require enlisted.events_enlisted
require game.utils.team

[es(tag=server, on_appear)]
def init_bomb_for_capzone(evt : Event;
                          eid : EntityId;
                          transform : float3x4;
                          capzone__bombTemplate : string;
                          capzone__bombTransformLocalPos : float3x4;
                          capzone__plantingTeam : int;
                          capzone__timeToPlant : float = -1.0;
                          capzone__timeToResetPlant : float = -1.0;
                          capzone__timeToDefuse : float = -1.0;
                          capzone__timeToExplosion : float = -1.0;
                          var capzone__bombSiteEid : EntityId&)
  if capzone__bombTemplate == ""
    logerr("Bomb template is empty for capzone {eid}")
    return
  if capzone__plantingTeam == TEAM_UNASSIGNED
    logerr("Planting team is not set for capzone {eid}")
  let initCompsOnCreated <- @ <| (eid : EntityId) : void
    query(eid) <| $ [es] (bomb_site__capzoneEid : EntityId; var active aka bomb_active : bool&)
      query(bomb_site__capzoneEid) <| $ [es] (active : bool)
        bomb_active = active
  capzone__bombSiteEid = createEntity(capzone__bombTemplate, initCompsOnCreated) <| $(var init : ComponentsInitializer)
    var tm = capzone__bombTransformLocalPos
    tm[3] += transform[3]
    init |> set("bomb_site__capzoneEid", eid)
    init |> set("transform", tm)
    init |> set("bomb_site__plantingTeam", capzone__plantingTeam)
    if capzone__timeToPlant >= 0.0
      init |> set("bomb_site__timeToPlant", capzone__timeToPlant)
    if capzone__timeToResetPlant >= 0.0
      init |> set("bomb_site__timeToResetPlant", capzone__timeToResetPlant)
    if capzone__timeToDefuse >= 0.0
      init |> set("bomb_site__timeToDefuse", capzone__timeToDefuse)
    if capzone__timeToExplosion >= 0.0
      init |> set("bomb_site__timeToExplosion", capzone__timeToExplosion)
  if !capzone__bombSiteEid
    logerr("Cannot create bomb with template {capzone__bombTemplate} for capzone {eid}")

[es(tag=server, track=active)]
def capzone_control_bomb_site_active_status(evt : Event; capzone__bombSiteEid : EntityId; active : bool)
  let capzoneActive = active
  query(capzone__bombSiteEid) <| $ [es] (var active : bool&)
    active = capzoneActive

[es(tag=server,
     track=bomb_site__isBombPlanted,
     track=bomb_site__plantedTimeEnd,
     track=bomb_site__resetTimeEnd,
     track=bomb_site__defusedTimeEnd,
     track=bomb_site__plantProgressPausedAt,
     track=bomb_site__defuseProgressPausedAt)]
def bomb_site_set_capzone_progress(evt : Event;
                                   bomb_site__capzoneEid : EntityId;
                                   bomb_site__isBombPlanted : bool;
                                   bomb_site__timeToPlant : float;
                                   bomb_site__timeToResetPlant : float;
                                   bomb_site__timeToDefuse : float;
                                   bomb_site__plantedTimeEnd : float;
                                   bomb_site__resetTimeEnd : float;
                                   bomb_site__defusedTimeEnd : float;
                                   bomb_site__plantProgressPausedAt : float;
                                   bomb_site__defuseProgressPausedAt : float)
  query(bomb_site__capzoneEid) <| $ [es] (var capzone__isBombPlanted : bool&;
                                          var progress__totalTime : float&;
                                          var progress__endTime : float&;
                                          var progress__pausedAt : float&;
                                          var progress__isPositive : bool&)
    capzone__isBombPlanted = false
    progress__isPositive = true
    if bomb_site__isBombPlanted
      capzone__isBombPlanted = true
      progress__totalTime = bomb_site__timeToDefuse
      progress__endTime = bomb_site__defusedTimeEnd
      progress__pausedAt = bomb_site__defuseProgressPausedAt
      return
    progress__pausedAt = bomb_site__plantProgressPausedAt
    if bomb_site__plantedTimeEnd >= 0.0
      progress__totalTime = bomb_site__timeToPlant
      progress__endTime = bomb_site__plantedTimeEnd
    elif bomb_site__resetTimeEnd >= 0.0
      progress__isPositive = false
      progress__totalTime = bomb_site__timeToResetPlant
      progress__endTime = bomb_site__resetTimeEnd

[es(tag=server, before=bomb_site_destroy_on_detonation)]
def bomb_site_explosion_set_capzone_status(evt : EventBombSiteExplosion; bomb_site__plantingTeam : int; bomb_site__capzoneEid : EntityId)
  sendEvent(bomb_site__capzoneEid, [[EventForceCapture team=bomb_site__plantingTeam]])
  query(bomb_site__capzoneEid) <| $ [es] (var active : bool&)
    active = false

[es(tag=server, on_appear, track=(bomb_site__isBombPlanted, bomb_site__isPlantingOrReseting))]
def bomb_site_stop_fail_timer(evt : Event;
                              bomb_site__isBombPlanted : bool;
                              bomb_site__isPlantingOrReseting : bool;
                              bomb_site__plantProgressDeltaPerSec : float;
                              bomb_site__plantingTeam : int;
                              bomb_site__capzoneEid : EntityId)
  query(bomb_site__capzoneEid) <| $ [es] (var capzone__stopFailTimerForTeam : int&)
    let shouldStopTimer = bomb_site__isBombPlanted || (bomb_site__isPlantingOrReseting && bomb_site__plantProgressDeltaPerSec > 0.0)
    capzone__stopFailTimerForTeam = shouldStopTimer ? bomb_site__plantingTeam : TEAM_UNASSIGNED

[es(tag=server, on_event=(EventEntityDestroyed, EventComponentsDisappear))]
def bomb_site_release_timer_if_destroyed(evt : Event; bomb_site__capzoneEid : EntityId)
  query(bomb_site__capzoneEid) <| $ [es] (var capzone__stopFailTimerForTeam : int&)
    capzone__stopFailTimerForTeam = TEAM_UNASSIGNED
