module hitpoints_common shared public

require ecs
require app
require game.utils.team
require strings

let private OFFENDER_TYPE_SIZE = 3

enum private OffenderType
  NEUTRAL = 0// Self-inflicted (fall damage, drowning, suicide) or Damage from non-soldier entity (like 'grey zone', or static location fire)
  FRIENDLY = 1// Any soldier of the same team
  ENEMY = 2// Any soldier of non-friendly team (may be TEAM_UNASSIGNED)

// Victim is not downed and damage is not critical (not down, not kill)
let private damage_table = [[bool[OFFENDER_TYPE_SIZE * OFFENDER_TYPE_SIZE]
//   NEU    FRIEND ENEMY <- NEW
/*N*/false; false; true;
/*F*/false; false; true;
/*E*/false; false; true
//^
//OLD
]]

// Victim is downed and any damage (may be killing blow)
let private downed_table = [[bool[OFFENDER_TYPE_SIZE * OFFENDER_TYPE_SIZE]
//   NEU    FRIEND ENEMY <- NEW
/*N*/true;  true;  true;
/*F*/false; false; true;
/*E*/false; false; false
//^
//OLD
]]

// Critical damage (downed or killed victim)
let private crit_table = [[bool[OFFENDER_TYPE_SIZE * OFFENDER_TYPE_SIZE]
//   NEU    FRIEND ENEMY <- NEW
/*N*/true;  true;  true;
/*F*/false; true;  true;
/*E*/false; true;  true
//^
//OLD
]]

def private get_offender_type(offender : EntityId;
                              offender_team : int;
                              is_offender_valid_soldier : bool;
                              victim : EntityId;
                              victim_team : int)
  if !offender || !is_offender_valid_soldier || offender == victim
    return int(OffenderType NEUTRAL)
  if is_teams_friendly(offender_team, victim_team)
    return int(OffenderType FRIENDLY)
  return int(OffenderType ENEMY)

def private should_accept_new_offender(old_offender_type : int; offender_type : int; is_victim_downed : bool; is_crit_damage : bool)
  let index = int(old_offender_type) * OFFENDER_TYPE_SIZE + int(offender_type)
  let acceptTable = (is_victim_downed ? downed_table
                      : is_crit_damage ? crit_table
                      : damage_table)
  return acceptTable[index]

def try_set_last_offender(offender : EntityId;
                          offender_team : int;
                          offender_possessed_by_player : EntityId;
                          offender_squad_player : EntityId;
                          damage_type : int;
                          gun_props_id : int;
                          shell_id : int;
                          coll_node_id : int;
                          is_crit_damage : bool;
                          victim : EntityId;
                          victim_team : int;
                          is_victim_downed : bool;
                          victim_possessed_by_player : EntityId;
                          hitpoints__clearOffenderTimer : float;
                          var hitpoints__lastOffenderTime : float&;
                          var hitpoints__lastOffender : EntityId&;
                          var death_desc__offenderTeam : int&;
                          var hitpoints__lastOffenderPlayer : EntityId&;
                          var death_desc__damageType : int&;
                          var death_desc__gunPropsId : int&;
                          var death_desc__shellId : int&;
                          var death_desc__collNodeId : int&;
                          var hitpoints__lastVictimPlayer : EntityId&;
                          var hitpoints__lastOffenderSquadPlayer : EntityId&)
  let atTime = get_sync_time()

  if hitpoints__lastOffender != offender
    let isSquadleaderStealFromSquad = hitpoints__lastOffenderSquadPlayer == offender_squad_player && !!offender_possessed_by_player
    let isLastOffenderValidSoldier = !!hitpoints__lastOffenderSquadPlayer
    let offenderValidSoldier = !!offender_squad_player
    let isLastOffenderTimeIsUp = hitpoints__lastOffenderTime < 0. || atTime - hitpoints__lastOffenderTime > hitpoints__clearOffenderTimer

    let oldOffenderType = ((isLastOffenderTimeIsUp || isSquadleaderStealFromSquad) ? int(OffenderType NEUTRAL)
      : get_offender_type(hitpoints__lastOffender, death_desc__offenderTeam, isLastOffenderValidSoldier, victim, victim_team))
    let offenderType = get_offender_type(offender, offender_team, offenderValidSoldier, victim, victim_team)

    if !should_accept_new_offender(oldOffenderType, offenderType, is_victim_downed, is_crit_damage)
      return false

  hitpoints__lastOffenderTime = atTime
  hitpoints__lastOffender = offender
  hitpoints__lastOffenderPlayer = offender_possessed_by_player
  hitpoints__lastOffenderSquadPlayer = offender_squad_player
  hitpoints__lastVictimPlayer = victim_possessed_by_player

  death_desc__offenderTeam = offender_team
  death_desc__damageType = damage_type
  death_desc__gunPropsId = gun_props_id
  death_desc__shellId = shell_id
  death_desc__collNodeId = coll_node_id
  return true

def try_set_last_offender(victim : EntityId;
                          offender : EntityId;
                          offender_team : int;
                          offender_possessed_by_player : EntityId;
                          offender_squad_player : EntityId;
                          damage_type : int;
                          gun_props_id : int;
                          shell_id : int;
                          coll_node_id : int;
                          is_crit_damage : bool)
  query(victim) <| $ [es] (hitpoints__clearOffenderTimer : float;
                           team aka victim_team : int = TEAM_UNASSIGNED;
                           isDowned : bool = false;
                           possessedByPlr : EntityId = INVALID_ENTITY_ID;
                           var hitpoints__lastOffenderTime : float&;
                           var hitpoints__lastOffender : EntityId&;
                           var death_desc__offenderTeam : int&;
                           var hitpoints__lastOffenderPlayer : EntityId&;
                           var death_desc__damageType : int&;
                           var death_desc__gunPropsId : int&;
                           var death_desc__shellId : int&;
                           var death_desc__collNodeId : int&;
                           var hitpoints__lastVictimPlayer : EntityId&;
                           var hitpoints__lastOffenderSquadPlayer : EntityId&)
    try_set_last_offender(offender,
                          offender_team,
                          offender_possessed_by_player,
                          offender_squad_player,
                          damage_type,
                          gun_props_id,
                          shell_id,
                          coll_node_id,
                          is_crit_damage,
                          victim,
                          victim_team,
                          isDowned,
                          possessedByPlr,
                          hitpoints__clearOffenderTimer,
                          hitpoints__lastOffenderTime,
                          hitpoints__lastOffender,
                          death_desc__offenderTeam,
                          hitpoints__lastOffenderPlayer,
                          death_desc__damageType,
                          death_desc__gunPropsId,
                          death_desc__shellId,
                          death_desc__collNodeId,
                          hitpoints__lastVictimPlayer,
                          hitpoints__lastOffenderSquadPlayer)

def reset_last_offender(var hitpoints__lastOffenderTime : float&;
                        var hitpoints__lastOffender : EntityId&;
                        var death_desc__offenderTeam : int&;
                        var hitpoints__lastOffenderPlayer : EntityId&;
                        var death_desc__damageType : int&;
                        var death_desc__gunPropsId : int&;
                        var death_desc__shellId : int&;
                        var death_desc__collNodeId : int&;
                        var hitpoints__lastVictimPlayer : EntityId&;
                        var hitpoints__lastOffenderSquadPlayer : EntityId&)
  hitpoints__lastOffenderTime = -1.
  hitpoints__lastOffender = INVALID_ENTITY_ID
  hitpoints__lastOffenderPlayer = INVALID_ENTITY_ID
  hitpoints__lastOffenderSquadPlayer = INVALID_ENTITY_ID
  hitpoints__lastVictimPlayer = INVALID_ENTITY_ID

  death_desc__offenderTeam = TEAM_UNASSIGNED
  death_desc__damageType = -1
  death_desc__gunPropsId = -1
  death_desc__shellId = -1
  death_desc__collNodeId = -1
