require ecs
require zones
require game.utils.team

def add_progress(var data : Object&; eid : EntityId; progress : float)
  let key = "{eid}"
  let prevContribution = data |> get_float(key) ?? 0.0
  let contribution = prevContribution + max(0.0, progress)
  data |> set(key, contribution)


[es(tag=server, track=(bomb_site__operator, bomb_site__isPlantingOrReseting))]
def track_plant_participants(evt : Event;
                             bomb_site__operator : EntityId;
                             bomb_site__isPlantingOrReseting : bool;
                             bomb_site__plantProgress : float;
                             bomb_site__plantProgressDeltaPerSec : float;
                             var bomb_site_participants__currentPlanterEid : EntityId&;
                             var bomb_site_participants__startProgress : float&;
                             var bomb_site_participants__data : Object&)
  let isPlanting = !!bomb_site__operator && bomb_site__isPlantingOrReseting && bomb_site__plantProgressDeltaPerSec > 0.0
  let wasPlanting = !!bomb_site_participants__currentPlanterEid
  let isOperatorChanged = bomb_site__operator != bomb_site_participants__currentPlanterEid
  if wasPlanting && (!isPlanting || isOperatorChanged)
    bomb_site_participants__data |> add_progress(bomb_site_participants__currentPlanterEid, bomb_site__plantProgress - bomb_site_participants__startProgress)
    bomb_site_participants__currentPlanterEid = INVALID_ENTITY_ID
  if isPlanting
    bomb_site_participants__currentPlanterEid = bomb_site__operator
    bomb_site_participants__startProgress = bomb_site__plantProgress

[es(tag=server, track=bomb_site__isBombPlanted)]
def bomb_site_reset_participants_on_defuse(evt : Event;
                                           bomb_site__isBombPlanted : bool;
                                           var bomb_site_participants__data : Object&)
  if !bomb_site__isBombPlanted
    clear(bomb_site_participants__data)
    return

[es(tag=server, track=bomb_site__isBombPlanted)]
def bomb_site_copy_participants_info_to_capzone(evt : Event;
                                                bomb_site__capzoneEid : EntityId;
                                                bomb_site__isBombPlanted : bool;
                                                bomb_site__planterEid : EntityId;
                                                bomb_site_participants__data : Object)
  if bomb_site__isBombPlanted
    query(bomb_site__capzoneEid) <| $ [es] (var capzone__bombSitePlanterEid : EntityId&; var capzone__bombSitePlantParticipants : Object&)
      capzone__bombSitePlanterEid = bomb_site__planterEid
      capzone__bombSitePlantParticipants := bomb_site_participants__data

[es(tag=server, track=bomb_site__isBombPlanted)]
def track_bomb_site_zone_presence_for_awards(evt : Event;
                                             bomb_site__isBombPlanted : bool;
                                             bomb_site__capzoneEid : EntityId)
  query(bomb_site__capzoneEid) <| $ [es] (capzone__plantingTeam : int; var capzone__bombSiteZonePresenceOnPlant : EidList&)
    clear(capzone__bombSiteZonePresenceOnPlant)
    if bomb_site__isBombPlanted
      query() <| $ [es(REQUIRE_NOT=deadEntity, REQUIRE=(squad_member, human))] (eid : EntityId; transform : float3x4; team : int)
        if is_teams_friendly(team, capzone__plantingTeam) && is_point_in_capzone(transform[3], bomb_site__capzoneEid, 1.0)
          capzone__bombSiteZonePresenceOnPlant |> push(eid)