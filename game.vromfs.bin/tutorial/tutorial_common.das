module tutorial_common shared
require ecs
require EnlistedNet
require app
require player
require ecs.common
require DagorMath
require math.base
require DagorSystem
require game.utils.team
require enlisted.tutorial.tutorial_events
require enlisted.events_enlisted

enum ZoneCheck : int
  IN_ZONE = 0
  OUT_ZONE = 1

let
  HINT_DEFAULT_TTL = 999999

let [[ignore_heap_usage]] TUTORIAL_IDENTITY_BOX = BBox3(float3(-0.1, -0.1, -0.1), float3(0.1, 0.1, 0.1))  // ignore heap usage because it is used c++ heap


def private check_tutorial_zone(isIntersect : bool; zoneCheck : int)
  if zoneCheck == int(ZoneCheck IN_ZONE)
    return isIntersect
  elif zoneCheck == int(ZoneCheck OUT_ZONE)
    return !isIntersect
  logerr("Unknown zoneCheck: {zoneCheck}. Possible: 0 - in zone, 1 - out from zone");
  return false


def check_tutorial_zone(humanTm : float3x4; humanBox : BBox3; transform : float3x4; zoneCheck : int)
  let isIntersect = check_bbox3_intersection(humanBox, humanTm, transform * TUTORIAL_IDENTITY_BOX, IDENT_TM)
  return check_tutorial_zone(isIntersect, zoneCheck)


def check_tutorial_zone(pos : float3; transform : float3x4; zoneCheck : int)
  let isIntersect = TUTORIAL_IDENTITY_BOX & (inverse(transform) * pos)
  return check_tutorial_zone(isIntersect, zoneCheck)

def query_active_tutorial_zone(humanTm : float3x4; humanBox : BBox3; var zoneEid : EntityId&; var zoneIdOut : das_string&)
  zoneEid = INVALID_ENTITY_ID
  zoneIdOut := ""
  ecs::find_query() <| $ [es(REQUIRE=tutorialZone)] (eid : EntityId;
                                                     tutorial_zone__active : bool;
                                                     transform : float3x4;
                                                     tutorial_zone__zoneCheck : int;
                                                     tutorial_zone__zoneId : string)
    if tutorial_zone__active && check_tutorial_zone(humanTm, humanBox, transform, tutorial_zone__zoneCheck)
      zoneEid = eid
      zoneIdOut := tutorial_zone__zoneId
      return true
    return false

def query_active_tutorial_zone(pos : float3; var zoneEid : EntityId&; var zoneIdOut : string&)
  zoneEid = INVALID_ENTITY_ID
  zoneIdOut = ""
  ecs::find_query() <| $ [es(REQUIRE=tutorialZone)] (eid : EntityId;
                                                     tutorial_zone__active : bool;
                                                     transform : float3x4;
                                                     tutorial_zone__zoneCheck : int;
                                                     tutorial_zone__zoneId : string)
    if tutorial_zone__active && check_tutorial_zone(pos, transform, tutorial_zone__zoneCheck)
      zoneEid = eid
      zoneIdOut = tutorial_zone__zoneId
      return true
    return false

def set_tutorial_zone_active(target : string; isActive : bool)
  query() <| $ [es(REQUIRE=tutorialZone)] (tutorial_zone__zoneId : string; var tutorial_zone__active : bool&)
    if target == tutorial_zone__zoneId
      tutorial_zone__active = isActive

def is_tutorial_zone_active(target : string)
  return find_query() <| $ [es(REQUIRE=tutorialZone)] (tutorial_zone__zoneId : string; tutorial_zone__active : bool)
    if target == tutorial_zone__zoneId && tutorial_zone__active
      return true
    return false

def set_target_active(target : string; isActive : bool)
  query() <| $ [es(REQUIRE=tutorialTarget)] (tutorial_target__targetId : string; var tutorial_target__active : bool&)
    if tutorial_target__targetId == target
      tutorial_target__active = isActive

def set_respawn_active(respawn_id : string; isActive : bool)
  query() <| $ [es] (tutorial__respawnId : string; var active : bool&)
    if tutorial__respawnId == respawn_id
      active = isActive

def set_active_capzone(isActive : bool)
  query() <| $ [es(REQUIRE=capzone)] (var active : bool&)
    active = isActive

def tutorial_hint(event : string; unique : string; text : string; hotkeys : Array; ttl : int = HINT_DEFAULT_TTL)
  let eid = get_local_player_eid()
  server_send_schemeless_event(eid, typeinfo(undecorated_typename type<CmdTutorialHint>), eid) <| $(var init : Object)
    set(init, "event", event)
    set(init, "unique", unique)
    set(init, "text", text)
    set(init, "hotkey", hotkeys)
    set(init, "ttl", ttl)

def tutorial_hint(event : string; unique : string; text : string; hotkey : string; ttl : int = HINT_DEFAULT_TTL)
  using() <| $(var arr : Array)
    arr |> push(hotkey)
    tutorial_hint(event, unique, text, arr, ttl)

def tutorial_hint(event : string; unique : string; text : string; ttl : int; cb : block<(var arr : Array) : void>)
  using() <| $(var arr : Array)
    invoke(cb, arr)
    tutorial_hint(event, unique, text, arr, ttl)

def tutorial_hint(event : string; unique : string; text : string; ttl : int = HINT_DEFAULT_TTL)
  using() <| $(var arr : Array)
    tutorial_hint(event, unique, text, arr, ttl)

def set_tutorial_stage(stage)
  query() <| $ [es] (var tutorial__stageFlag : int&)
    tutorial__stageFlag = int(stage)

def is_tutorial_stage(stage)
  var isStage = false
  query() <| $ [es] (tutorial__stageFlag : int)
    isStage = tutorial__stageFlag == int(stage)
  return isStage

def tutorial_stage_action(stage; cb : block<void>)
  query() <| $ [es] (tutorial__stageFlag : int)
    if tutorial__stageFlag == int(stage)
      invoke(cb)

def tutorial_stage_action(stage; cb : block<(var stage : int&)>)
  query() <| $ [es] (var tutorial__stageFlag : int&)
    if tutorial__stageFlag == int(stage)
      invoke(cb, tutorial__stageFlag)

def tutorial_squad_change()
  query() <| $ [es(REQUIRE=hero)] (eid : EntityId;
                                   bindedCamera : EntityId;
                                   team : int;
                                   human_weap__currentGunEid : EntityId;
                                   var squad_member__squad : EntityId&)
    query() <| $ [es] (eid : EntityId; ownedBySquad : EntityId)
      if ownedBySquad == squad_member__squad
        destroyEntity(eid)
    query(human_weap__currentGunEid) <| $ [es] (grenade_thrower__projectileEntity : EntityId)
      destroyEntity(grenade_thrower__projectileEntity)
    destroyEntity(human_weap__currentGunEid)
    squad_member__squad = INVALID_ENTITY_ID
    query() <| $ [es(REQUIRE=heroSquad, REQUIRE_NOT=hero)] (eid : EntityId)
      destroyEntity(eid)
    query() <| $ [es] (respawnCameraForTeam : int; var respawnCamera__showDelay : float&)
      if is_teams_friendly(team, respawnCameraForTeam) || respawnCameraForTeam == TEAM_UNASSIGNED
        respawnCamera__showDelay = 0.f
    query(bindedCamera) <| $ [es] (var camera_shaker__extraShakeAngles : float3&)
      camera_shaker__extraShakeAngles = float3(0.f, 0.f, 0.f)
    destroyEntity(eid)

  query(get_local_player_eid()) <| $ [es] (var respawner__respStartTime : float&;
                                           var respawner__spectatorEnabled : bool&;
                                           var respawner__respTime : float&;
                                           var respawner__canSpawnMinTime : float&;
                                           var respawner__missionStartDelay : float&;
                                           var respawner__enabled : bool&;
                                           var respawner__respRequested : bool&)
    respawner__respTime = 0.f
    respawner__missionStartDelay = 0.f
    respawner__canSpawnMinTime = 0.f
    respawner__respStartTime = -1.f
    respawner__respRequested = false
    respawner__spectatorEnabled = false
    respawner__enabled = true

def spawn_squad_immediate()
  query(get_local_player_eid()) <| $ [es] (eid : EntityId;
                                           team : int;
                                           var respawner__enabled : bool&;
                                           var respawner__respStartTime : float&;
                                           var respawner__respEndTime : float&;
                                           var respawner__canRespawnTime : float&;
                                           var respawner__canRespawnWaitNumber : int&;
                                           respawner__respRequestedSquadId : int;
                                           respawner__respRequestedMemberId : int = 0;
                                           respawner__respawnGroupId : int = -1)
    let squadId = respawner__respRequestedSquadId
    let memberId = respawner__respRequestedMemberId
    let respawnGroupId = respawner__respawnGroupId
    respawner__enabled = false
    respawner__respStartTime = -1.f
    respawner__respEndTime = -1.f
    respawner__canRespawnTime = -1.f
    respawner__canRespawnWaitNumber = -1
    sendEvent(eid, [[CmdSpawnSquad team=team, possessed=INVALID_ENTITY_ID, squadId=squadId, memberId=memberId, respawnGroupId=respawnGroupId]])
