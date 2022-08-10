require ecs
require ecs.common
require ecs.safe
require enlisted.events_enlisted
require game.es.awards_common
require game.utils.team
require strings

let // TODO: make ecs components
  CAPSCORES_CAPTURE_FINAL = 1.0
  CAPSCORES_CAPTURE_PARTICIPATE = 0.5

def get_visitor_player_eid(visitor_eid : EntityId) //get squad.ownerPlayer of hero or bot by squad
  let squadEid = get_Eid(visitor_eid, "squad_member__squad") ?? INVALID_ENTITY_ID
  return get_Eid(squadEid, "squad__ownerPlayer") ?? INVALID_ENTITY_ID


[es(tag=server)]
def track_capzone_presence_for_awards(evt : EventCapZoneEnter;
                                      capzone__owningTeam : int;
                                      var capzone__capturersEids : EidList&;
                                      var capzone__soldiersCapture : Object&)
  let visitorEid = evt.visitor
  let playerEid = get_visitor_player_eid(visitorEid)
  if playerEid == INVALID_ENTITY_ID
    return
  let teamId = get_int(visitorEid, "team") ?? TEAM_UNASSIGNED
  if teamId == TEAM_UNASSIGNED || teamId == capzone__owningTeam
    return

  if capzone__capturersEids |> find_index(playerEid) < 0
    capzone__capturersEids |> push(playerEid)

  query(visitorEid) <| $ [es] (squad_member__squad : EntityId = INVALID_ENTITY_ID; guid : string = "")
    if !squad_member__squad || empty(guid)
      return
    for soldierComp in capzone__soldiersCapture
      let s = soldierComp.value |> get_ecs_object()
      if (s?.guid ?? "") == guid && (s?.squadEid ?? INVALID_ENTITY_ID) == squad_member__squad
        return

    capzone__soldiersCapture |> push_to_object("{visitorEid}") <| $(var init : Object#)
      init |> set("eid", visitorEid)
      init |> set("squadEid", squad_member__squad)
      init |> set("guid", guid)
      init |> set("teamId", teamId)


[es(tag=server)]
def award_on_capzone_captured(evt : EventAwardZoneCapturers;
                              capzone__owningTeam : int;
                              teamPresence : Object;
                              var capzone__capturersEids : EidList&;
                              var capzone__soldiersCapture : Object&)
  var awardPlayers : table<uint; bool>//eid = bool, true - was at capture end, or had bot at capture end
  using <| $(var awardSoldiers : Array#) //award only soldiers who were on point when capture finished
    for eid in capzone__capturersEids
      let teamId = get_int(eid, "team") ?? TEAM_UNASSIGNED
      if teamId == capzone__owningTeam
        awardPlayers[uint(eid)] = false
    for it in capzone__soldiersCapture
      var soldierInfo = it.value |> getRW_ecs_object()
      if soldierInfo == null
        continue
      let capturerTeam = soldierInfo?.teamId ?? TEAM_UNASSIGNED
      if capturerTeam != TEAM_UNASSIGNED && capturerTeam == capzone__owningTeam
        awardSoldiers |> push_to_array <| $(var obj : Object#)
          move(obj, *soldierInfo)
          obj |> set("stat", "captures")
          obj |> set("amount", CAPSCORES_CAPTURE_PARTICIPATE)
    var capscoreBySquad : table<uint; float>

    for it in teamPresence
      let team = get_ecs_array(it.value)
      if team == null
        continue
      for eidComp in *team
        let eid = eidComp ?? INVALID_ENTITY_ID
        let playerEid = get_visitor_player_eid(eid)
        if playerEid != INVALID_ENTITY_ID
          awardPlayers[uint(playerEid)] = true
        query(eid) <| $ [es] (squad_member__squad : EntityId = INVALID_ENTITY_ID; guid : string = "")
          if !squad_member__squad || empty(guid)
            return
          for awardDataComp in awardSoldiers
            var awardData = getRW_ecs_object(awardDataComp)
            if awardData == null
              continue
            if (awardData?.guid ?? "" == guid) && (awardData?.squadEid ?? INVALID_ENTITY_ID) == squad_member__squad
              set(*awardData, "amount", CAPSCORES_CAPTURE_FINAL)
              capscoreBySquad[uint(squad_member__squad)] = CAPSCORES_CAPTURE_FINAL

    var presenceAmountBySquad : table<uint; float>
    for awardDataComp in awardSoldiers
      let awardData = get_ecs_object(awardDataComp)
      if awardData == null
        continue
      let squadUid = uint(awardData?.squadEid ?? INVALID_ENTITY_ID)
      let awardDataAmount = awardData?.amount ?? 0.
      presenceAmountBySquad[squadUid] = (presenceAmountBySquad?[squadUid] ?? 0.) + awardDataAmount
    for soldierComp in awardSoldiers
      var awardInfo = soldierComp |> getRW_ecs_object()
      if awardInfo == null
        continue
      let squadUid = uint(awardInfo?.squadEid ?? INVALID_ENTITY_ID)
      let squadPresenceTotalAmount = presenceAmountBySquad |> find(squadUid) ?? 0.
      let squadCaptureScore = capscoreBySquad?[squadUid] ?? CAPSCORES_CAPTURE_PARTICIPATE
      if squadPresenceTotalAmount > 0.
        let amount = awardInfo?.amount ?? 0.
        set(*awardInfo, "amount", amount * (squadCaptureScore / squadPresenceTotalAmount))

    for playerUid, isFinal in keys(awardPlayers), values(awardPlayers)
      let playerEid = EntityId(playerUid)
      if isFinal
        sendEvent(playerEid, [[EventPlayerSquadFinishedCapturing]])
        add_award(playerEid, "capture") <| $(award)
          set(award, "scoreId", "captures")

    broadcast_schemeless_event(typeinfo(undecorated_typename type<EventSquadMembersStats>)) <| $(var init : Object)
      set(init, "list", awardSoldiers)
    capzone__capturersEids |> clear()
    capzone__soldiersCapture |> clear()
