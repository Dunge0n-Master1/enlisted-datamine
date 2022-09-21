require ecs
require ecs.common
require soundEvent
require soundSystem
require DagorMath
require math.base
require sound_utils.modules.sound_player_common
require sound_utils.modules.sound_utils_events
require game.events_game
require game.utils.team
require game.es.stat_bq_common
require common_shooter.events_common_shooter
require DagorSystem


let CONDITION_WIN = 0.
let CONDITION_LOSE = 1.
let CONDITION_UNDEFINED = -1.
let CONDITION_RESULT_PART_VALUE = 3.


def make_player_enemy_team_scores() : float2
  var playerEnemyScores = float2(0., 0.)
  let playerTeam = get_local_player_team()
  query() <| $ [es] (team__id : int; team__score, team__scoreCap : float)
    if team__id == playerTeam
      playerEnemyScores.x = safediv(team__score, team__scoreCap)
    else
      playerEnemyScores.y = safediv(team__score, team__scoreCap)
  return saturate(playerEnemyScores)


def make_part(progress : float; battle_music__progressToPart : float3) : float
  if progress >= battle_music__progressToPart.z
    return 2.
  if progress >= battle_music__progressToPart.y
    return 1.
  if progress >= battle_music__progressToPart.x
    return 0.
  return -1.


[es(tag=sound, before=battle_music_update, REQUIRE=battleMusicScoresCondition)]
def battle_music_scores_condition_update(info : UpdateStageInfoAct;
                                         var battle_music__condition : float&)
  let playerEnemyScores = make_player_enemy_team_scores()
  battle_music__condition = playerEnemyScores.x >= playerEnemyScores.y ? CONDITION_WIN : CONDITION_LOSE


[es(tag=sound, after=battle_music_update)]
def battle_music_scores_progress_update(info : UpdateStageInfoAct;
                                        battle_music__scoresToProgress : float4;
                                        var battle_music__progress : float&)
  let playerEnemyScores = make_player_enemy_team_scores()
  let progress = cvt(min(playerEnemyScores.x, playerEnemyScores.y),
                         battle_music__scoresToProgress.x, battle_music__scoresToProgress.y,
                         battle_music__scoresToProgress.z, battle_music__scoresToProgress.w)
  battle_music__progress = max(progress, battle_music__progress)


[es(tag=sound, after=battle_music_update)]
def battle_music_capture_progress_update(info : UpdateStageInfoAct;
                                         battle_music__capProgressToProgress : float4;
                                         var battle_music__progress : float&)
  var progress = 0.
  var uncaptured = 0
  var captured = 0
  var total = 0
  var capTeam = TEAM_UNASSIGNED
  query() <| $ [es(REQUIRE_NOT=capzone__plantingTeam)] (active, capzone__alwaysShow, capzone__alwaysHide : bool; capzone__progress : float; capzone__owningTeam : int)
    if (active || capzone__alwaysShow) && !capzone__alwaysHide
      if capzone__owningTeam == TEAM_UNASSIGNED
        progress = capzone__progress
        ++uncaptured
      elif capTeam == TEAM_UNASSIGNED || is_teams_friendly(capTeam, capzone__owningTeam)
        capTeam = capzone__owningTeam
        ++captured
      ++total
  if uncaptured == 1 && captured + uncaptured == total
    progress = cvt(progress,
                   battle_music__capProgressToProgress.x, battle_music__capProgressToProgress.y,
                   battle_music__capProgressToProgress.z, battle_music__capProgressToProgress.w)
    battle_music__progress = max(progress, battle_music__progress)
  elif uncaptured == 0 && captured == total && total > 0
    battle_music__progress = 1.
  //logerr("captured={captured} uncaptured={uncaptured}  total={total}")


[es(tag=sound, no_order)]
def battle_music_update(info : UpdateStageInfoAct;
                        var battle_music__progress : float&;
                        battle_music__condition : float;
                        battle_music__roundResult : float;
                        battle_music__progressToPart : float3;
                        var battle_music__intensity : float&;
                        battle_music__intensityBleed : float;
                        battle_music__path : string;
                        var battle_music__event : SoundEvent&)

  let part = battle_music__roundResult != CONDITION_UNDEFINED ? CONDITION_RESULT_PART_VALUE : make_part(battle_music__progress, battle_music__progressToPart)
  let shouldPlay = battle_music__event.enabled || part >= 0.
  //logerr("progress={battle_music__progress}  part={part} condition={battle_music__roundResult != CONDITION_UNDEFINED ? battle_music__roundResult : battle_music__condition}")
  battle_music__progress = 0.

  if battle_music__event.enabled != shouldPlay
    battle_music__event.enabled = shouldPlay
    abandon(battle_music__event.handle)
    if shouldPlay
      battle_music__event |> play(battle_music__path, get_listener_pos())
      battle_music__event.abandonOnReset = true

  if battle_music__event.enabled
    set_pos(battle_music__event.handle, get_listener_pos())
    set_var(battle_music__event.handle, "intensity", battle_music__intensity)
    set_var(battle_music__event.handle, "part", max(part, 0.))
    let condition = battle_music__roundResult != CONDITION_UNDEFINED ? battle_music__roundResult : battle_music__condition
    set_var(battle_music__event.handle, "condition", condition)

  battle_music__intensity = max(0., battle_music__intensity - info.dt * battle_music__intensityBleed)


[es(tag=sound)]
def battle_music_on_round_result(evt : EventTeamRoundResult;
                                 var battle_music__roundResult : float&;
                                 battle_music__event : SoundEvent)
  if evt.team == get_local_player_team()
    battle_music__roundResult = evt.isWon ? CONDITION_WIN : CONDITION_LOSE
    set_var(battle_music__event.handle, "part", CONDITION_RESULT_PART_VALUE)

[es(tag=sound)]
def battle_music_on_shot(evt : EventOnWeaponSound;
                         var battle_music__intensity : float&;
                         battle_music__maxShotRange : float;
                         battle_music__addIntensityOnShotSingle : float;
                         battle_music__addIntensityOnShotLoop : float)
  var t = length_sq(get_listener_pos() - evt.pos)
  if t < square(battle_music__maxShotRange)
    t = 1. - safediv(sqrt(t), battle_music__maxShotRange)
    battle_music__intensity = t * min(battle_music__intensity + (evt.isLoop ? battle_music__addIntensityOnShotLoop : battle_music__addIntensityOnShotSingle), 100.)


[es(tag=sound)]
def battle_music_on_hit(evt : EventOnEntityHit;
                        eid aka victim_eid : EntityId;
                        team aka victim_team : int)
  if victim_eid == evt.victim
    query(evt.offender) <| $ [es] (team aka offender_team : int)
      let ourTeam = get_local_player_team()
      if (ourTeam == victim_team || ourTeam == offender_team) && !is_teams_friendly(offender_team, victim_team)
        query() <| $ [es] (var battle_music__intensity : float&;
                           battle_music__addIntensityOnHit : float)
          battle_music__intensity += battle_music__addIntensityOnHit
