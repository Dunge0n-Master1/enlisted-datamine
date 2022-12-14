require ecs
require app
require enlisted.events_enlisted
require game.es.capzones_common
require game.utils.team
require game.events_game

def on_deactivation(zone_eid : EntityId; team_id : int)
  query(zone_eid) <| $ [es] (groupName aka deactivated_groupName : string;
                             capzone__deactivateAfterCap : bool;
                             capzone__checkAllZonesInGroup : bool = false;
                             capzone__mustBeCapturedByTeam : int = TEAM_UNASSIGNED;
                             capzone__activateAfterCap : string = "";
                             capzone__activateAfterTeam1Cap : string = "";
                             capzone__activateAfterTeam2Cap : string = "";
                             capzone__activateChoice : Object const?)
    if !capzone__deactivateAfterCap
      return
    if (capzone__checkAllZonesInGroup
        && (team_id != capzone__mustBeCapturedByTeam || !all_capzones_in_group_captured_by_team(zone_eid, team_id, groupName)))
      return
    query() <| $ [es(REQUIRE_NOT=respbase)] (eid : EntityId;
                                             groupName aka target_groupName : string;
                                             deactivationDelay : float = -1.0)
      if target_groupName == deactivated_groupName
        if deactivationDelay > 0.
          sendEvent(eid, [[EventEntityAboutToDeactivate]])
        else
          sendEvent(eid, [[EventEntityActivate activate = false]])
    let hasChoice = capzone__activateChoice != null && !capzone__activateChoice.empty
    let hasNextGroup = (capzone__activateAfterCap != ""
      || capzone__activateAfterTeam1Cap != ""
      || capzone__activateAfterTeam2Cap != "")
    if hasNextGroup || hasChoice
      query() <| $ [es(REQUIRE=respbase, REQUIRE_NOT=customRespawnBase)] (eid : EntityId; groupName : string)
        if groupName == deactivated_groupName
          sendEvent(eid, [[EventEntityActivate activate = false]])

def deactivate_capzone(eid : EntityId; var capzone__deactivateTeam : int&; var capzone__deactivateAtTime : float&)
  if capzone__deactivateAtTime > 0.
    broadcastEvent([[EventZoneDeactivated zone=eid, team=capzone__deactivateTeam]])
    capzone__deactivateAtTime = -1.
    capzone__deactivateTeam = TEAM_UNASSIGNED
    removeSubTemplate(eid, "deactivating_capzone")

def deactivate_all_deactivating_zones()
  query() <| $ [es] (eid : EntityId; var capzone__deactivateTeam : int&; var capzone__deactivateAtTime : float&)
    deactivate_capzone(eid, capzone__deactivateTeam, capzone__deactivateAtTime)

[es(tag=server)]
def capzone_on_deactivate_captured(evt : EventZoneCaptured)
  on_deactivation(evt.zone, evt.team)

[es(tag=server)]
def capzone_on_deactivate_delayed(evt : EventZoneDeactivated)
  on_deactivation(evt.zone, evt.team)

[es(tag=server)]
def capzone_start_deactivation(evt : EventZoneIsAboutToBeCaptured)
  query(evt.zone) <| $ [es(REQUIRE_NOT=capzone__deactivateAtTime)] (eid : EntityId; capzone__deactivateAfterTimeout : float)
    addSubTemplate(eid, "deactivating_capzone") <| $(var init)
      set(init, "capzone__deactivateTeam", evt.team)
      set(init, "capzone__deactivateAtTime", get_sync_time() + capzone__deactivateAfterTimeout)

[es(tag=server, no_order)]
def capzone_deactivation_timer(info : UpdateStageInfoAct;
                               eid : EntityId;
                               var capzone__deactivateTeam : int&;
                               var capzone__deactivateAtTime : float&)
  if info.curTime > capzone__deactivateAtTime
    deactivate_capzone(eid, capzone__deactivateTeam, capzone__deactivateAtTime)

[es(tag=server)]
def capzone_destroy_respawn_base_on_deactivation(evt : EventZoneDeactivated)
  query(evt.zone) <| $ [es] (capzone__respawnBaseEid : EntityId)
    destroyEntity(capzone__respawnBaseEid)

[es(tag=server, REQUIRE=capzone__deactivateAfterTimeout)]
def capzone_first_enter(evt : EventCapZoneEnter;
                        capzone__onlyTeamCanCapture : int;
                        var capzone__respawnBaseEid : EntityId&)
  let team = get_int(evt.visitor, "team") ?? TEAM_UNASSIGNED
  if team != TEAM_UNASSIGNED && capzone__onlyTeamCanCapture == team
    if capzone__respawnBaseEid != INVALID_ENTITY_ID
      destroyEntity(capzone__respawnBaseEid)
      capzone__respawnBaseEid = INVALID_ENTITY_ID
    deactivate_all_deactivating_zones()

[es(tag=server, REQUIRE=temporaryRespawnbase, track=active)]
def capzone_deactivate_temporary_respbase(evt : Event; active : bool)
  if !active
    deactivate_all_deactivating_zones()
