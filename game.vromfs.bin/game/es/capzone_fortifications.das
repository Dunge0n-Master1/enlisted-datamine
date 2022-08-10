require ecs
require zones
require Grid
require GridCollision
require DagorMath
require game.utils.team
require Ballistics
require math.base
require math.linear
require enlisted.events_enlisted
require ecs.common
require app

def is_enemy_projectile_near(projectile_team : int;
                             projectile_start : float3;
                             projectile_end : float3;
                             fortification_team : int;
                             fortification_pos : float3;
                             check_distance : float)
  return (!is_teams_friendly(projectile_team, fortification_team)
          && distance_sq_to_seg(fortification_pos, projectile_start, projectile_end) <= square(check_distance))

def try_send_award(fortification_eid : EntityId; time : float)
  query(fortification_eid) <| $ [es(REQUIRE=activeCapzoneFortification)] (buildByPlayer : EntityId;
                                                                          capzone_fortification__awardCountLimit : int;
                                                                          var capzone_fortification__awardCount : int&)
    query(buildByPlayer) <| $ [es] (capzone_fortification__awardCooldown : float; var capzone_fortification__nextAwardAvailableAtTime : float&)
      if time >= capzone_fortification__nextAwardAvailableAtTime
        capzone_fortification__nextAwardAvailableAtTime = time + capzone_fortification__awardCooldown
        sendEvent(fortification_eid, [[EventOnCapzoneFortificationAward]])
        ++capzone_fortification__awardCount
        if capzone_fortification__awardCount >= capzone_fortification__awardCountLimit
          removeSubTemplate(fortification_eid, "active_capzone_fortification")


[es(tag=server, on_appear, REQUIRE=capzoneFortification, REQUIRE_NOT=activeCapzoneFortification)]
def capzone_fortification_activate(evt : Event;
                                   eid : EntityId;
                                   transform : float3x4;
                                   capzone_fortification__awardCount : int;
                                   capzone_fortification__awardCountLimit : int)
  if capzone_fortification__awardCount >= capzone_fortification__awardCountLimit
    return
  let buildingPos = transform[3]
  var capzoneEid = INVALID_ENTITY_ID
  find_query() <| $ [es(REQUIRE=capzone)] (eid : EntityId; active : bool)
    if active && is_point_in_capzone(buildingPos, eid, 1.3)
      capzoneEid = eid
      return true
    return false
  if !!capzoneEid
    addSubTemplate(eid, "active_capzone_fortification") <| $(var init)
      set(init, "capzone_fortification__capzoneEid", capzoneEid)

[es(tag=server, track=active, REQUIRE=capzone)]
def fortifications_track_active_capzones(evt : Event; eid : EntityId; active : bool)
  let capzoneEid = eid
  if active
    query() <| $ [es(REQUIRE=capzoneFortification, REQUIRE_NOT=activeCapzoneFortification)] (eid : EntityId;
                                                                                             transform : float3x4;
                                                                                             capzone_fortification__awardCount : int;
                                                                                             capzone_fortification__awardCountLimit : int)
      if capzone_fortification__awardCount < capzone_fortification__awardCountLimit && is_point_in_capzone(transform[3], capzoneEid, 1.3)
        addSubTemplate(eid, "active_capzone_fortification") <| $(var init)
          set(init, "capzone_fortification__capzoneEid", capzoneEid)
  else
    query() <| $ [es(REQUIRE=activeCapzoneFortification)] (eid : EntityId; capzone_fortification__capzoneEid : EntityId)
      if capzone_fortification__capzoneEid == capzoneEid
        removeSubTemplate(eid, "active_capzone_fortification")

[es(tag=server, no_order, REQUIRE=activeCapzoneFortification)]
def capzone_fortification_check_nearby_soldiers(info : UpdateStageInfoAct;
                                                transform : float3x4;
                                                team : int;
                                                buildByPlayer : EntityId;
                                                capzone_fortification__soldierSearchInterval : float;
                                                capzone_fortification__soldierSearchRadius : float;
                                                capzone_fortification__soldierSearchHeight : float;
                                                var capzone_fortification__isFriendlySoldierNearby : bool&;
                                                var capzone_fortification__nextSoldierSearchTime : float&)
  if info.curTime < capzone_fortification__nextSoldierSearchTime
    return
  capzone_fortification__nextSoldierSearchTime = info.curTime + capzone_fortification__soldierSearchInterval

  var box = BBox3()
  let r = capzone_fortification__soldierSearchRadius
  let h = capzone_fortification__soldierSearchHeight
  box |> bbox3_add(transform[3] - float3(r, h, r))
  box |> bbox3_add(transform[3] + float3(r, h, r))

  let buildingTeam = team
  var soldierFound = false

  find_entity_in_grid(ecs_hash("humans"), box, GridEntCheck BOUNDING) <| $(eid : EntityId)
    query(eid) <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (team : int; squad_member__playerEid : EntityId)
      soldierFound = is_teams_friendly(team, buildingTeam) && buildByPlayer != squad_member__playerEid
    return soldierFound
  capzone_fortification__isFriendlySoldierNearby = soldierFound

[es(tag=server, on_event=EventEntityDestroyed, REQUIRE=projectile_ballistics)]
def capzone_fortification_projectile_destroyed_nearby(evt : Event;
                                                      projectile_ballistics : ProjectileBallistics;
                                                      projectile__prevPos : float3;
                                                      ownerEid : EntityId)
  let projectileTeam = get_int(ownerEid, "team") ?? TEAM_UNASSIGNED
  let projectileStart = projectile__prevPos
  let projectileEnd = projectile_ballistics.state.pos
  query() <| $ [es(REQUIRE=activeCapzoneFortification)] (eid : EntityId;
                                                         transform : float3x4;
                                                         team : int;
                                                         capzone_fortification__isFriendlySoldierNearby : bool;
                                                         capzone_fortification__projectileCheckDistance : float)
    if (capzone_fortification__isFriendlySoldierNearby
        && is_enemy_projectile_near(projectileTeam, projectileStart, projectileEnd, team, transform[3], capzone_fortification__projectileCheckDistance))
      try_send_award(eid, get_sync_time())

[es(tag=server, no_order, REQUIRE=activeCapzoneFortification)]
def capzone_fortification_detect_projectile(info : UpdateStageInfoAct;
                                            eid : EntityId;
                                            buildByPlayer : EntityId;
                                            transform : float3x4;
                                            team : int;
                                            capzone_fortification__isFriendlySoldierNearby : bool;
                                            capzone_fortification__projectileCheckDistance : float;
                                            capzone_fortification__projectileCheckInterval : float;
                                            var capzone_fortification__nextProjectileCheckTime : float&)
  if (!capzone_fortification__isFriendlySoldierNearby || capzone_fortification__nextProjectileCheckTime > info.curTime)
    return

  var nextAwardAvailableAtTime = 0.0
  query(buildByPlayer) <| $ [es] (capzone_fortification__nextAwardAvailableAtTime : float)
    nextAwardAvailableAtTime = capzone_fortification__nextAwardAvailableAtTime

  if info.curTime < nextAwardAvailableAtTime
    capzone_fortification__nextProjectileCheckTime = nextAwardAvailableAtTime + capzone_fortification__projectileCheckInterval * eid_frnd(eid)
    return

  capzone_fortification__nextProjectileCheckTime = info.curTime + capzone_fortification__projectileCheckInterval

  find_query() <| $ [es] (projectile_ballistics : ProjectileBallistics; projectile__prevPos : float3; ownerEid : EntityId)
    let ownerTeam = get_int(ownerEid, "team") ?? TEAM_UNASSIGNED
    let startPos = projectile__prevPos
    let endPos = projectile_ballistics.state.pos + projectile_ballistics.state.vel * info.dt
    if is_enemy_projectile_near(ownerTeam, startPos, endPos, team, transform[3], capzone_fortification__projectileCheckDistance)
      try_send_award(eid, info.curTime)
      return true
    return false
