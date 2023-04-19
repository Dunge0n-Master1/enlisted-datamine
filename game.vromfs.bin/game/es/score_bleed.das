require ecs
require DagorMath
require game.events_game
require enlisted.events_enlisted
require DngNet

[es(tag=server, no_order)]
def score_bleed_update(info : UpdateStageInfoAct;
                       team__id : int;
                       team__scoreCap : float = 0.;
                       score_bleed__staticBleed : float = 0.;
                       score_bleed__domBleed : float = 0.;
                       score_bleed__domBleedOn : bool = false;
                       score_bleed__totalDomBleedMul : float = 1.;
                       score_bleed__totalDomBleedOn : bool = false;
                       team__zeroScoreFailTimer : float = -1.;
                       score_bleed__interval : float = 1.;
                       var score_bleed__nextUpdate : float&;
                       var team__score : float&)
  if team__score == 0. || info.curTime < score_bleed__nextUpdate
    return

  let overtime = min(info.curTime - score_bleed__nextUpdate, score_bleed__interval)
  let dt = score_bleed__interval + overtime

  score_bleed__nextUpdate = info.curTime + score_bleed__interval

  let staticBleed = score_bleed__staticBleed > 0. ? score_bleed__staticBleed : 0.
  let domBleedMult = score_bleed__totalDomBleedOn ? score_bleed__totalDomBleedMul : 1.
  let domBleed = score_bleed__domBleed > 0. && score_bleed__domBleedOn ? score_bleed__domBleed : 0.
  let bleed = staticBleed + domBleed * domBleedMult

  if bleed > 0.
    let prevScore = safediv(team__score, team__scoreCap)
    team__score = max(team__score - dt * bleed, 0.0)
    let newScore = safediv(team__score, team__scoreCap)

    if newScore <= 0.5 && prevScore > 0.5
      broadcast_net_event([[EventTeamLoseHalfScore teamId=team__id]])
    elif newScore <= 0.2 && prevScore > 0.2
      broadcast_net_event([[EventTeamLowScore teamId=team__id]])

    if team__score == 0. && team__zeroScoreFailTimer < 0.
      broadcastEvent([[EventTeamLost team=team__id]])

[es(tag=server, track=team__numZonesCaptured, REQUIRE=team__numZonesCaptured)]
def score_bleed_check_capzone_count(evt : Event)
  var maxZonesCap = 0
  query() <| $ [es] (team__numZonesCaptured : int)
    if team__numZonesCaptured > maxZonesCap
      maxZonesCap = team__numZonesCaptured

  query() <| $ [es] (team__numZonesCaptured : int;
                     score_bleed__domBleed : float;
                     score_bleed__totalDomZoneCount : int = -1;
                     var score_bleed__domBleedOn : bool&;
                     var score_bleed__totalDomBleedOn : bool&)
    score_bleed__domBleedOn = team__numZonesCaptured < maxZonesCap && score_bleed__domBleed > 0.
    score_bleed__totalDomBleedOn = score_bleed__totalDomZoneCount == maxZonesCap && score_bleed__domBleed > 0.


def on_zone_captured(team : int)
  find_query() <| $ [es] (team__id : int; var team__numZonesCaptured : int&)
    if team__id == team
      team__numZonesCaptured += 1
      return true
    return false

def on_zone_decaptured(team : int)
  find_query() <| $ [es] (team__id : int; var team__numZonesCaptured : int&)
    if team__id == team
      team__numZonesCaptured -= 1
      return true
    return false

[es(tag=server)]
def score_bleed_zone_captured(evt : EventZoneCaptured)
  on_zone_captured(evt.team)

[es(tag=server)]
def score_bleed_zone_captured_delayed(evt : EventZoneIsAboutToBeCaptured)
  on_zone_captured(evt.team)

[es(tag=server)]
def score_bleed_zone_decaptured(evt : EventZoneDecaptured)
  on_zone_decaptured(evt.team)
