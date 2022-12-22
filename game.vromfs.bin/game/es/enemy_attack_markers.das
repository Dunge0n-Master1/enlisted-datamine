require ecs
require game.utils.team
require player
require math

variant MaybeMiddlePoint
  pos : float3
  nothing : void?

def get_respawn_middle_point(team_check_cb : block<(team : int) : bool>)
  var middlePoint : float3
  var basesCount = 0
  query() <| $ [es] (active : bool; team : int; transform : float3x4; respawnbaseType : string)
    if active && invoke(team_check_cb, team) && respawnbaseType == "human"
      ++basesCount
      middlePoint += transform[3]
  if basesCount > 0
    middlePoint *= rcp(float(basesCount))
    return [[MaybeMiddlePoint pos=middlePoint]]
  return [[MaybeMiddlePoint nothing=null]]

def set_pos_dir_tm(pos : float3; dir : float2; var tm : float3x4&)
  if length_sq(dir) > 0.0
    let normDir = normalize(dir)
    tm[0] = float3(normDir.x, 0.0, normDir.y)
    tm[1] = float3(0, 1, 0)
    tm[2] = float3(-normDir.y, 0.0, normDir.x)
  else
    identity(tm)
  tm[3] = pos

def update_marker(var transform : float3x4&; offset : float)
  let localPlayerTeam = get_int(get_local_player_eid(), "team") ?? TEAM_UNASSIGNED
  let attackFromPos = get_respawn_middle_point <| $(base_team : int) { return !is_teams_friendly(base_team, localPlayerTeam); }
  if attackFromPos is nothing
    return
  let attackToPos = get_respawn_middle_point <| $(base_team : int) { return is_teams_friendly(base_team, localPlayerTeam); }
  let dir = attackToPos is pos ? (attackToPos as pos).xz - (attackFromPos as pos).xz : float2(1, 0)
  set_pos_dir_tm(attackFromPos as pos, dir, transform)
  transform[3] += transform[0] * offset

[es(tag=gameClient, on_appear, track=(active, team), REQUIRE=(respawnbaseType, team, active), REQUIRE_NOT=customRespawnBase)]
def ui_enemy_attack_marker(evt : Event; respawnbaseType : string)
  if respawnbaseType != "human"
    return
  query() <| $ [es(REQUIRE=enemy_attack_marker)] (enemy_attack_marker__offset : float; var transform : float3x4&)
    update_marker(transform, enemy_attack_marker__offset)

[es(tag=gameClient, on_appear, REQUIRE=enemy_attack_marker)]
def ui_enemy_attack_marker_init(evt : Event; enemy_attack_marker__offset : float; var transform : float3x4&)
  update_marker(transform, enemy_attack_marker__offset)

[es(tag=gameClient, on_appear, track=team, REQUIRE=(localPlayer, team))]
def ui_enemy_init_player_attack_marker(evt : Event)
  query() <| $ [es(REQUIRE=enemy_attack_marker)] (enemy_attack_marker__offset : float; var transform : float3x4&)
    update_marker(transform, enemy_attack_marker__offset)
