require ecs
require ecs.safe
require ecs.common
require app
require enlisted.events_enlisted
require enlisted.game.es.offender_cache_common
require game.events_game
require game.es.awards_common
require game.utils.team
require strings

def is_box_award_available_by_limit(uses_info : Object;
                                    max_uses_per_minute : int;
                                    requester_player : EntityId;
                                    cur_time : float)
  let uses = uses_info["{requester_player}"] ?as Object
  let time = uses?.time ?? 0.
  let count = uses?.count ?? 0
  return cur_time - time > 60. || count < max_uses_per_minute

def increase_box_use_count(var uses_info : Object&; requester_player : EntityId; cur_time : float)
  let key = "{requester_player}"
  let uses = uses_info[key] ?as Object
  let time = uses?.time ?? 0.
  let count = uses?.count ?? 0
  let shouldResetTime = cur_time - time > 60.
  uses_info |> push_to_object(key) <| $(var info : Object)
    info |> set("time", shouldResetTime ? cur_time : time)
    info |> set("count", shouldResetTime ? 1 : count + 1)

def on_box_refill(requester : EntityId;
                  box_owner_player : EntityId;
                  box_owner_soldier : EntityId;
                  stat : string;
                  var uses_info : Object&;
                  max_uses_per_minute : int)
  let requesterPlayer = get_Eid(requester, "squad_member__playerEid") ?? INVALID_ENTITY_ID
  if requesterPlayer == box_owner_player
    return
  let time = get_sync_time()
  if is_box_award_available_by_limit(uses_info, max_uses_per_minute, requesterPlayer, time)
    increase_box_use_count(uses_info, requesterPlayer, time)
    let guid = get_offender_from_cache(box_owner_soldier).guid
    send_award_stat(box_owner_player, guid, stat)

[es(tag=server, REQUIRE=ammunitionBox)]
def score_engineer_ammo_box_refill(evt : EventOnUsefulBoxSuccessfulUse;
                                   buildByPlayer : EntityId;
                                   buildByEngineerEid : EntityId)
  query(buildByPlayer) <| $ [es] (engineer_awards__ammoBoxAwardPerPlayerPerMinute : int; var engineer_awards__ammoBoxUses : Object&)
    let maxUsePerMin = engineer_awards__ammoBoxAwardPerPlayerPerMinute
    on_box_refill(evt.requester, buildByPlayer, buildByEngineerEid, "builtAmmoBoxRefills", engineer_awards__ammoBoxUses, maxUsePerMin)
    add_award(buildByPlayer, "engineer_ammo_box_usage")

[es(tag=server, REQUIRE=medBox)]
def score_med_box_refill(evt : EventOnUsefulBoxSuccessfulUse;
                         buildByPlayer : EntityId;
                         placeable_item__ownerEid : EntityId)
  query(buildByPlayer) <| $ [es] (awards__medBoxAwardPerPlayerPerMinute : int; var awards__medBoxUses : Object&)
    let maxUsePerMin = awards__medBoxAwardPerPlayerPerMinute
    on_box_refill(evt.requester, buildByPlayer, placeable_item__ownerEid, "builtMedBoxRefills", awards__medBoxUses, maxUsePerMin)

[es(tag=server)]
def score_engineer_barbwire_damage(evt : EventOnBarbwireDamageAward;
                                   buildByPlayer : EntityId;
                                   builder_info__guid : string)
  send_award_stat(buildByPlayer, builder_info__guid, "builtBarbwireActivations")

[es(tag=server)]
def score_engineer_capzone_fortification_award(evt : EventOnCapzoneFortificationAward;
                                               buildByPlayer : EntityId;
                                               builder_info__guid : string)
  send_award_stat(buildByPlayer, builder_info__guid, "builtCapzoneFortificationActivations")

[es(tag=server, on_appear, REQUIRE_NOT=builder_preview)]
def score_engineer_any_building_built(evt : Event;
                                      dependsOnBuildingEid : EntityId = INVALID_ENTITY_ID;
                                      buildByPlayer : EntityId;
                                      builder_info__guid : string)
  if dependsOnBuildingEid != INVALID_ENTITY_ID
    return
  assume playerEid = buildByPlayer
  assume guid = builder_info__guid
  query(playerEid) <| $ [es] (engineer_awards__buildingLimitPerMinute : int;
                              var engineer_awards__buildingTimerStartTime : float&;
                              var engineer_awards__buildingCountSinceTimerStart : int&)
    let time = get_sync_time()
    if time - engineer_awards__buildingTimerStartTime > 60.
      engineer_awards__buildingTimerStartTime = time
      engineer_awards__buildingCountSinceTimerStart = 0

    if engineer_awards__buildingCountSinceTimerStart < engineer_awards__buildingLimitPerMinute
      engineer_awards__buildingCountSinceTimerStart += 1
      send_award_stat(playerEid, guid, "builtStructures")

[es(tag=server)]
def engineer_building_destroyed_award(evt : EventEngineerBuildingBroken;
                                      builder_info__team : int const?;
                                      placeable_item__ownerTeam : int const?;
                                      building__destructionAwardStat : string)
  let offender = get_offender_from_cache(evt.offender)
  assume stat = building__destructionAwardStat
  let buildingTeam = builder_info__team ?? placeable_item__ownerTeam ?? TEAM_UNASSIGNED
  let offenderPlayerTeam = get_int(offender.player, "team") ?? TEAM_UNASSIGNED
  if !empty(stat) && is_valid_cache_soldier(offender) && buildingTeam != TEAM_UNASSIGNED && !is_teams_friendly(offenderPlayerTeam, buildingTeam)
    send_award_stat(offender.player, offender.guid, stat)

[es(tag=server, on_appear)]
def hosted_spawn_award(evt : Event;
                       squad__respawnBaseEid : EntityId;
                       squad__ownerPlayer : EntityId)
  assume spawnedPlayer = squad__ownerPlayer
  let rallyPointEid = get_Eid(squad__respawnBaseEid, "dependsOnBuildingEid") ?? INVALID_ENTITY_ID
  query(rallyPointEid) <| $ [es] (buildByPlayer : EntityId;
                                  builder_info__guid : string)
    if spawnedPlayer != buildByPlayer
      send_award_stat(buildByPlayer, builder_info__guid, "builtRallyPointUses")
      add_award(buildByPlayer, "engineer_rally_point_usage")

  let respawnOwnerEid = get_Eid(squad__respawnBaseEid, "respawnOwnerEid") ?? INVALID_ENTITY_ID
  query(respawnOwnerEid) <| $ [es] (squad_member__playerEid : EntityId; guid : string)
    assume spawnedOnPlayerEid = squad_member__playerEid
    if spawnedPlayer != spawnedOnPlayerEid
      send_award_stat(squad_member__playerEid, guid, "hostedOnSoldierSpawns")
