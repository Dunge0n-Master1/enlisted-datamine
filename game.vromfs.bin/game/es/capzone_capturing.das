require ecs
require ecs.common
require game.utils.team
require game.events_game
require enlisted.events_enlisted
require game.es.stat_bq_common // TODO: move get_team_eid to different module!
require strings
require net
require DagorMath

let
  DECAPTURE = 2
  CAPTURE = 1
  UNKNOWN = 0

let MULTIPLE_TEAMS = -2 // a magic number to show that there is more than one team on zone.

def start_cap(eid : EntityId;
              team : int;
              var capzone__capTeam : int&;
              var capzone__capTeamEid : EntityId&;
              var capzone__captureStatus : int&)
  capzone__capTeam = team
  capzone__capTeamEid = get_team_eid(team)
  capzone__captureStatus = CAPTURE
  broadcastEvent([[EventZoneStartCapture eid=eid, team=team]])

def start_decap(eid : EntityId;
                capzone__decapOnNeutral : bool;
                var capzone__progress : float&;
                var capzone__capTeam : int&;
                var capzone__captureStatus : int&;
                var capzone__owningTeam : int&)
  let team = capzone__capTeam
  if team == TEAM_UNASSIGNED && !capzone__decapOnNeutral
    capzone__progress = 0.
    capzone__capTeam = TEAM_UNASSIGNED
    capzone__captureStatus = UNKNOWN
    capzone__owningTeam = TEAM_UNASSIGNED
  else
    capzone__captureStatus = DECAPTURE
    broadcastEvent([[EventZoneStartDecapture eid=eid, team=team]])

def on_team_dominate_zone(eid : EntityId;
                          team : int;
                          capzone__decapOnNeutral : bool;
                          var capzone__progress : float&;
                          var capzone__capTeam : int&;
                          var capzone__capTeamEid : EntityId&;
                          var capzone__owningTeam : int&;
                          var capzone__captureStatus : int&;
                          var capzone__curTeamCapturingZone : int&)
  if capzone__capTeam == team || capzone__capTeam == TEAM_UNASSIGNED
    if capzone__progress < 1.
      start_cap(eid, team, capzone__capTeam, capzone__capTeamEid, capzone__captureStatus)
      capzone__curTeamCapturingZone = team
  elif capzone__progress > 0.
    start_decap(eid, capzone__decapOnNeutral, capzone__progress, capzone__capTeam, capzone__captureStatus, capzone__owningTeam)
    capzone__curTeamCapturingZone = team
  else
    start_cap(eid, team, capzone__capTeam, capzone__capTeamEid, capzone__captureStatus)
    capzone__curTeamCapturingZone = team


def on_zone_tie_or_neutral(eid : EntityId;
                           num_teams_present : int;
                           capzone__autoCap : bool;
                           capzone__autoDecap : bool;
                           capzone__decapOnNeutral : bool;
                           var capzone__progress : float&;
                           var capzone__capTeam : int&;
                           var capzone__capTeamEid : EntityId&;
                           var capzone__owningTeam : int&;
                           var capzone__captureStatus : int&;
                           var capzone__curTeamCapturingZone : int&)
  capzone__curTeamCapturingZone = (num_teams_present > 1) ? MULTIPLE_TEAMS : TEAM_UNASSIGNED
  if capzone__progress >= 0.0 && capzone__progress < 1.0
    capzone__captureStatus = UNKNOWN
    if capzone__autoDecap || (capzone__owningTeam == TEAM_UNASSIGNED && capzone__autoCap)
      start_decap(eid, capzone__decapOnNeutral, capzone__progress, capzone__capTeam, capzone__captureStatus, capzone__owningTeam)
    elif capzone__autoCap
      start_cap(eid, capzone__owningTeam, capzone__capTeam, capzone__capTeamEid, capzone__captureStatus)

def on_team_presence_changed(eid : EntityId;
                             active : bool;
                             capzone__presenceAdvantageToDominate : int;
                             capzone__advantageWeights : Object const?;
                             teamPresence : Object;
                             capzone__onlyTeamCanCapture : int;
                             capzone__allowDecap : bool;
                             capzone__canCaptureByPresenceDomination : bool;
                             capzone__locked : bool;
                             capzone__autoCap : bool;
                             capzone__autoDecap : bool;
                             capzone__decapOnNeutral : bool;
                             var capzone__progress : float&;
                             var capzone__capTeam : int&;
                             var capzone__capTeamEid : EntityId&;
                             var capzone__owningTeam : int&;
                             var capzone__captureStatus : int&;
                             var capzone__curTeamCapturingZone : int&;
                             var capzone__curTeamDominating : int&;
                             var capzone__capTeamAdvantage : int&;
                             var capzone__isMultipleTeamsPresent : bool&)
  if !active
    return

  let gap = capzone__presenceAdvantageToDominate
  var numTeamsPresent = 0
  var dominatingTeam = TEAM_UNASSIGNED
  var maxPresenceNum = 1 - gap
  var advantage = 0
  for it in teamPresence
    let tid = it.key
    let team = get_ecs_array(it.value)
    var teamPresenceNum = team != null ? length(*team) : 0
    let weight = capzone__advantageWeights != null ? get_int(*capzone__advantageWeights, tid) : null
    if weight != null
      teamPresenceNum *= (*weight)
    if teamPresenceNum > 0
      if teamPresenceNum >= maxPresenceNum + gap
        dominatingTeam = to_int(tid)
      elif teamPresenceNum > maxPresenceNum - gap
        dominatingTeam = MULTIPLE_TEAMS

      if teamPresenceNum > maxPresenceNum
        advantage = max(0, teamPresenceNum - (maxPresenceNum + gap - 1))
        maxPresenceNum = teamPresenceNum
      else
        advantage = clamp(maxPresenceNum - (teamPresenceNum + gap - 1), 0, advantage)

      numTeamsPresent++

  capzone__capTeamAdvantage = advantage
  capzone__isMultipleTeamsPresent = numTeamsPresent > 1

  let isNumberDomination = capzone__canCaptureByPresenceDomination
  let isTeamDominating = numTeamsPresent == 1 || (isNumberDomination && dominatingTeam >= 0)
  let isTeamCanCapture = (capzone__onlyTeamCanCapture == TEAM_UNASSIGNED || capzone__onlyTeamCanCapture == dominatingTeam || (capzone__allowDecap && capzone__progress == 1.0))

  capzone__curTeamDominating = (isTeamDominating && isTeamCanCapture) ? dominatingTeam : TEAM_UNASSIGNED

  if capzone__locked
    return

  if isTeamDominating && isTeamCanCapture
    on_team_dominate_zone(eid, dominatingTeam, capzone__decapOnNeutral, capzone__progress,
                          capzone__capTeam, capzone__capTeamEid, capzone__owningTeam, capzone__captureStatus, capzone__curTeamCapturingZone)
  else
    on_zone_tie_or_neutral(eid, numTeamsPresent, capzone__autoCap, capzone__autoDecap, capzone__decapOnNeutral, capzone__progress,
                           capzone__capTeam, capzone__capTeamEid, capzone__owningTeam, capzone__captureStatus, capzone__curTeamCapturingZone)


def capture_zone(zone_eid : EntityId;
                 capzone__deactivateAfterCap : bool;
                 capzone__checkAllZonesInGroup : bool;
                 capzone__capTeam : int;
                 capzone__deactivateAfterTimeout : float;
                 var active : bool&;
                 var capzone__progress : float&;
                 var capzone__captureStatus : int&;
                 var capzone__owningTeam : int&)
  capzone__progress = 1.0
  capzone__captureStatus = UNKNOWN

  if capzone__deactivateAfterCap && !capzone__checkAllZonesInGroup
    active = false // forcefully deactivate, so nobody will be able to push any events to it

  let reCap = capzone__owningTeam == capzone__capTeam
  capzone__owningTeam = capzone__capTeam
  if capzone__deactivateAfterTimeout > 0.
    if !reCap
      broadcast_net_event([[EventZoneIsAboutToBeCaptured zone=zone_eid, team=capzone__capTeam]])
  elif !reCap || capzone__checkAllZonesInGroup
    broadcast_net_event([[EventZoneCaptured zone=zone_eid, team=capzone__capTeam]])

  if !reCap
    sendEvent(zone_eid, [[EventAwardZoneCapturers]])

def decapture_zone(eid : EntityId;
                   capzone__autoDecap : bool;
                   var capzone__progress : float&;
                   var capzone__captureStatus : int&;
                   var capzone__capTeam : int&;
                   var capzone__owningTeam : int&)
  capzone__progress = 0.0
  capzone__capTeam = TEAM_UNASSIGNED
  capzone__captureStatus = UNKNOWN
  if !capzone__autoDecap
    broadcast_net_event([[EventZoneDecaptured zone=eid, team=capzone__owningTeam]])
  capzone__owningTeam = TEAM_UNASSIGNED

def get_advantage_speed_mult(can_capture_by_presence_domination : bool; advantage : int; divisor : float)
  if !can_capture_by_presence_domination || divisor <= 0.
    return 1.
  return float(advantage) / divisor

def get_min_cap_decap_speed_mult(divisor : float)
  return divisor > 0.0 ? 1.0 / divisor : 1.0

def get_cap_speed(capzone__canCaptureByPresenceDomination : bool;
                  capzone__capTeamAdvantage : int;
                  capzone__advantageDivisor : float;
                  capzone__maxCapDecapSpeedMult : float;
                  cap_time : float;
                  speed_mult : float = 1.0)
  let advantageMult = get_advantage_speed_mult(capzone__canCaptureByPresenceDomination, capzone__capTeamAdvantage, capzone__advantageDivisor)
  let minCapSpeedMult = get_min_cap_decap_speed_mult(capzone__advantageDivisor)
  let maxCapSpeedMult = capzone__maxCapDecapSpeedMult
  return safediv(1.0, cap_time) * clamp(speed_mult * advantageMult, minCapSpeedMult, maxCapSpeedMult)


[es(tag=server)]
def capzone_capturing_enter(evt : EventCapZoneEnter;
                            eid : EntityId;
                            active : bool;
                            capzone__presenceAdvantageToDominate : int = 1;
                            capzone__advantageWeights : Object const?;
                            capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED;
                            capzone__allowDecap : bool = false;
                            capzone__canCaptureByPresenceDomination : bool = false;
                            capzone__locked : bool = false;
                            capzone__autoCap : bool = true;
                            capzone__autoDecap : bool = true;
                            capzone__decapOnNeutral : bool = false;
                            var capzone__progress : float&;
                            var capzone__capTeam : int&;
                            var capzone__capTeamEid : EntityId&;
                            var capzone__owningTeam : int&;
                            var capzone__captureStatus : int&;
                            var capzone__curTeamCapturingZone : int&;
                            var capzone__curTeamDominating : int&;
                            var capzone__capTeamAdvantage : int&;
                            var capzone__isMultipleTeamsPresent : bool&;
                            var teamPresence : Object&)
  let team = get_int(evt.visitor, "team") ?? TEAM_UNASSIGNED
  if team == TEAM_UNASSIGNED
    return
  let teamId = "{team}"
  var presence = getRW_ecs_array(teamPresence, teamId)
  if presence == null
    teamPresence |> push_to_object(teamId) <| $(var arr : Array)
      push(arr, evt.visitor)
  else
    push(*presence, evt.visitor)
  on_team_presence_changed(eid, active, capzone__presenceAdvantageToDominate, capzone__advantageWeights,
                           teamPresence, capzone__onlyTeamCanCapture, capzone__allowDecap, capzone__canCaptureByPresenceDomination,
                           capzone__locked, capzone__autoCap, capzone__autoDecap, capzone__decapOnNeutral,
                           capzone__progress, capzone__capTeam, capzone__capTeamEid, capzone__owningTeam, capzone__captureStatus, capzone__curTeamCapturingZone, capzone__curTeamDominating,
                           capzone__capTeamAdvantage, capzone__isMultipleTeamsPresent)

[es(tag=server)]
def capzone_capturing_exit(evt : EventCapZoneLeave;
                           eid : EntityId;
                           active : bool;
                           capzone__presenceAdvantageToDominate : int = 1;
                           capzone__advantageWeights : Object const?;
                           capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED;
                           capzone__allowDecap : bool = false;
                           capzone__canCaptureByPresenceDomination : bool = false;
                           capzone__locked : bool = false;
                           capzone__autoCap : bool = true;
                           capzone__autoDecap : bool = true;
                           capzone__decapOnNeutral : bool = false;
                           var capzone__progress : float&;
                           var capzone__capTeam : int&;
                           var capzone__capTeamEid : EntityId&;
                           var capzone__owningTeam : int&;
                           var capzone__captureStatus : int&;
                           var capzone__curTeamCapturingZone : int&;
                           var capzone__curTeamDominating : int&;
                           var capzone__capTeamAdvantage : int&;
                           var capzone__isMultipleTeamsPresent : bool&;
                           var teamPresence : Object&)
  let team = get_int(evt.visitor, "team") ?? TEAM_UNASSIGNED
  if team == TEAM_UNASSIGNED
    return
  let teamId = "{team}"
  var presence = getRW_ecs_array(teamPresence, teamId)
  if presence != null
    let idx = (*presence) |> find_index(evt.visitor)
    if idx >= 0
      (*presence) |> erase(idx)
  else
    teamPresence |> push_to_object(teamId) <| $ [unused_argument(arr)] (var arr : Array) {}
  on_team_presence_changed(eid, active, capzone__presenceAdvantageToDominate, capzone__advantageWeights,
                           teamPresence, capzone__onlyTeamCanCapture, capzone__allowDecap, capzone__canCaptureByPresenceDomination,
                           capzone__locked, capzone__autoCap, capzone__autoDecap, capzone__decapOnNeutral,
                           capzone__progress, capzone__capTeam, capzone__capTeamEid, capzone__owningTeam, capzone__captureStatus, capzone__curTeamCapturingZone, capzone__curTeamDominating,
                           capzone__capTeamAdvantage, capzone__isMultipleTeamsPresent)

[es(tag=server)]
def capzone_unlocked_check_presence(evt : EventZoneUnlock;
                                    eid : EntityId;
                                    active : bool;
                                    capzone__presenceAdvantageToDominate : int = 1;
                                    capzone__advantageWeights : Object const?;
                                    teamPresence : Object;
                                    capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED;
                                    capzone__allowDecap : bool = false;
                                    capzone__canCaptureByPresenceDomination : bool = false;
                                    capzone__locked : bool = false;
                                    capzone__autoCap : bool = true;
                                    capzone__autoDecap : bool = true;
                                    capzone__decapOnNeutral : bool = false;
                                    var capzone__progress : float&;
                                    var capzone__capTeam : int&;
                                    var capzone__capTeamEid : EntityId&;
                                    var capzone__owningTeam : int&;
                                    var capzone__captureStatus : int&;
                                    var capzone__curTeamCapturingZone : int&;
                                    var capzone__curTeamDominating : int&;
                                    var capzone__capTeamAdvantage : int&;
                                    var capzone__isMultipleTeamsPresent : bool&)
  on_team_presence_changed(eid, active, capzone__presenceAdvantageToDominate, capzone__advantageWeights,
                           teamPresence, capzone__onlyTeamCanCapture, capzone__allowDecap, capzone__canCaptureByPresenceDomination,
                           capzone__locked, capzone__autoCap, capzone__autoDecap, capzone__decapOnNeutral,
                           capzone__progress, capzone__capTeam, capzone__capTeamEid, capzone__owningTeam, capzone__captureStatus, capzone__curTeamCapturingZone, capzone__curTeamDominating,
                           capzone__capTeamAdvantage, capzone__isMultipleTeamsPresent)

[es(tag=server)]
def capzone_activated_check_presence(evt : EventEntityActivate;
                                     eid : EntityId;
                                     active : bool;
                                     capzone__presenceAdvantageToDominate : int = 1;
                                     capzone__advantageWeights : Object const?;
                                     teamPresence : Object;
                                     capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED;
                                     capzone__allowDecap : bool = false;
                                     capzone__canCaptureByPresenceDomination : bool = false;
                                     capzone__locked : bool = false;
                                     capzone__autoCap : bool = true;
                                     capzone__autoDecap : bool = true;
                                     capzone__decapOnNeutral : bool = false;
                                     var capzone__progress : float&;
                                     var capzone__capTeam : int&;
                                     var capzone__capTeamEid : EntityId&;
                                     var capzone__owningTeam : int&;
                                     var capzone__captureStatus : int&;
                                     var capzone__curTeamCapturingZone : int&;
                                     var capzone__curTeamDominating : int&;
                                     var capzone__capTeamAdvantage : int&;
                                     var capzone__isMultipleTeamsPresent : bool&)
  if evt.activate
    on_team_presence_changed(eid, active, capzone__presenceAdvantageToDominate, capzone__advantageWeights,
                             teamPresence, capzone__onlyTeamCanCapture, capzone__allowDecap, capzone__canCaptureByPresenceDomination,
                             capzone__locked, capzone__autoCap, capzone__autoDecap, capzone__decapOnNeutral,
                             capzone__progress, capzone__capTeam, capzone__capTeamEid, capzone__owningTeam, capzone__captureStatus, capzone__curTeamCapturingZone, capzone__curTeamDominating,
                             capzone__capTeamAdvantage, capzone__isMultipleTeamsPresent)
  else
    capzone__captureStatus = UNKNOWN


def capzone_tick_capture(zone_eid : EntityId; dt : float)
  query(zone_eid) <| $ [es] (capzone__canCaptureByPresenceDomination : bool = false;
                             capzone__advantageDivisor : float = 4.;
                             capzone__maxCapDecapSpeedMult : float = 2.;
                             capzone__deactivateAfterCap : bool = false;
                             capzone__checkAllZonesInGroup : bool = false;
                             capzone__deactivateAfterTimeout : float = -1.;
                             capzone__capTime : float = 20.;
                             capzone__capTeamEid : EntityId;
                             capzone__capTeamAdvantage : int;
                             capzone_award__awardedProgressStep : int;
                             capzone__capTeam : int;
                             var active : bool&;
                             var capzone__progress : float&;
                             var capzone__owningTeam : int&;
                             var capzone__captureStatus : int&;
                             var capzone_award__progressCheckpoint : int&)
    let capSpeedMult = get_float(capzone__capTeamEid, "team__captureSpeedMult") ?? 1.0
    let capSpeed = get_cap_speed(capzone__canCaptureByPresenceDomination, capzone__capTeamAdvantage, capzone__advantageDivisor,
                                capzone__maxCapDecapSpeedMult, capzone__capTime, capSpeedMult)
    let progressDelta = capSpeed * dt

    let lastCheckpoint = capzone_award__progressCheckpoint
    if capzone__progress + progressDelta >= 1.0
      capture_zone(zone_eid, capzone__deactivateAfterCap, capzone__checkAllZonesInGroup, capzone__capTeam,
                  capzone__deactivateAfterTimeout, active, capzone__progress,
                  capzone__captureStatus, capzone__owningTeam)
      capzone_award__progressCheckpoint = 100
    else
      capzone__progress += progressDelta
      capzone_award__progressCheckpoint = (int(capzone__progress * 100.) / capzone_award__awardedProgressStep) * capzone_award__awardedProgressStep

    if capzone_award__progressCheckpoint > lastCheckpoint
      let awardProgress = float(capzone_award__progressCheckpoint - lastCheckpoint) * .01
      sendEvent(zone_eid, [[EventAwardZoneCapturersProgressTick amount=awardProgress, team=capzone__capTeam]])

def capzone_tick_decapture(zone_eid : EntityId; dt : float)
  query(zone_eid) <| $ [es] (capzone__presenceAdvantageToDominate : int = 1;
                             capzone__advantageWeights : Object const?;
                             teamPresence : Object;
                             capzone__onlyTeamCanCapture : int = TEAM_UNASSIGNED;
                             capzone__allowDecap : bool = false;
                             capzone__canCaptureByPresenceDomination : bool = false;
                             capzone__locked : bool = false;
                             capzone__autoCap : bool = true;
                             capzone__autoDecap : bool = true;
                             capzone__decapOnNeutral : bool = false;
                             capzone__advantageDivisor : float = 4.;
                             capzone__maxCapDecapSpeedMult : float = 2.;
                             capzone__decapTime : float = 30.;
                             capzone_award__awardedProgressStep : int;
                             active : bool;
                             var capzone__progress : float&;
                             var capzone__capTeam : int&;
                             var capzone__capTeamEid : EntityId&;
                             var capzone__owningTeam : int&;
                             var capzone__captureStatus : int&;
                             var capzone__curTeamCapturingZone : int&;
                             var capzone__curTeamDominating : int&;
                             var capzone__capTeamAdvantage : int&;
                             var capzone__isMultipleTeamsPresent : bool&;
                             var capzone_award__progressCheckpoint : int&)
    let team = capzone__capTeam
    if capzone__progress == 1.0 && capzone__autoDecap
      broadcast_net_event([[EventZoneDecaptured zone=zone_eid, team=team]])

    let decapSpeed = get_cap_speed(capzone__canCaptureByPresenceDomination, capzone__capTeamAdvantage, capzone__advantageDivisor,
                                  capzone__maxCapDecapSpeedMult, capzone__decapTime)
    let progressDelta = decapSpeed * dt

    if progressDelta >= capzone__progress
      decapture_zone(zone_eid, capzone__autoDecap, capzone__progress, capzone__captureStatus, capzone__capTeam, capzone__owningTeam)

      on_team_presence_changed(zone_eid, active, capzone__presenceAdvantageToDominate, capzone__advantageWeights,
                              teamPresence, capzone__onlyTeamCanCapture, capzone__allowDecap, capzone__canCaptureByPresenceDomination,
                              capzone__locked, capzone__autoCap, capzone__autoDecap, capzone__decapOnNeutral,
                              capzone__progress, capzone__capTeam, capzone__capTeamEid, capzone__owningTeam, capzone__captureStatus, capzone__curTeamCapturingZone, capzone__curTeamDominating,
                              capzone__capTeamAdvantage, capzone__isMultipleTeamsPresent)
      capzone_award__progressCheckpoint = 0
    else
      capzone__progress -= progressDelta
      let nextCheckpoint = ceili(capzone__progress * 100.0 / float(capzone_award__awardedProgressStep)) * capzone_award__awardedProgressStep
      // Do not lower checkpoint unless progress was dropped to previous checkpoint.
      // This way capturers won't get award for small recaps (less than step)
      capzone_award__progressCheckpoint = min(capzone_award__progressCheckpoint, nextCheckpoint)


[es(tag=server, no_order)]
def capzone_update_timer(info : UpdateStageInfoAct;
                         eid : EntityId;
                         capzone__timerPeriod : float = 0.33;
                         capzone__captureStatus : int;
                         var capzone__nextUpdateTime : float&)
  if info.curTime < capzone__nextUpdateTime
    return

  let overtime = min(info.curTime - capzone__nextUpdateTime, capzone__timerPeriod)
  let dt = capzone__timerPeriod + overtime

  capzone__nextUpdateTime = info.curTime + capzone__timerPeriod

  if capzone__captureStatus == CAPTURE
    capzone_tick_capture(eid, dt)
  elif capzone__captureStatus == DECAPTURE
    capzone_tick_decapture(eid, dt)


[es(tag=server)]
def force_cap_zone(evt : EventForceCapture;
                   eid : EntityId;
                   capzone__deactivateAfterCap : bool = false;
                   capzone__checkAllZonesInGroup : bool = false;
                   capzone__deactivateAfterTimeout : float = -1.;
                   var capzone_award__progressCheckpoint : int&;
                   var active : bool&;
                   var capzone__progress : float&;
                   var capzone__captureStatus : int&;
                   var capzone__owningTeam : int&;
                   var capzone__capTeam : int&)
  if evt.team != TEAM_UNASSIGNED
    capzone__capTeam = evt.team
    capture_zone(eid, capzone__deactivateAfterCap, capzone__checkAllZonesInGroup, capzone__capTeam,
                 capzone__deactivateAfterTimeout, active, capzone__progress,
                 capzone__captureStatus, capzone__owningTeam)
    capzone_award__progressCheckpoint = 100
