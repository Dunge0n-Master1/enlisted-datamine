require ecs
require ecs.common
require ecs.safe
require enlisted.events_enlisted
require game.es.awards_common
require game.utils.team
require strings
require DagorMath

def get_capturing_soldiers_by_player(teamPresence : Object; capturing_team : int)
  var soldiersByPlayers : table<uint; array<string>>
  for it in teamPresence
    let soldiersOnCapzone = it.value as Array
    if soldiersOnCapzone == null
      continue
    for eidComp in *soldiersOnCapzone
      let eid = eidComp ?? INVALID_ENTITY_ID
      query(eid) <| $ [es] (squad_member__playerEid : EntityId; guid : string; team : int)
        if !!squad_member__playerEid && !empty(guid) && team != TEAM_UNASSIGNED && capturing_team == team
          let key = uint(squad_member__playerEid)
          if !key_exists(soldiersByPlayers, key)
            soldiersByPlayers[key] <- [[array<string>]]
          soldiersByPlayers[key] |> push(guid)
  return <- soldiersByPlayers

def apply_award_to_participants(soldiers_by_players : table<uint; array<string>>; amount_per_player : float; stat : string)
  using <| $(var awards : Array#)
    for playerUint, soldierGuids in keys(soldiers_by_players), values(soldiers_by_players)
      let player = EntityId(playerUint)
      let soldierCount = length(soldierGuids)
      let amount = safediv(amount_per_player, float(soldierCount))
      for guid in soldierGuids
        awards |> push_soldier_stat(player, guid, stat, amount)
    broadcast_schemeless_event(typeinfo(undecorated_typename type<EventSquadMembersStats>)) <| $(var init : Object)
      set(init, "list", awards)

[es(tag=server)]
def award_on_capzone_capturing(evt : EventAwardZoneCapturersProgressTick;
                               teamPresence : Object;
                               capzone_award__progressAwardPortion : float;
                               capzone_award__stat : string = "captures")
  let amountPerPlayer = evt.amount * capzone_award__progressAwardPortion
  let soldiersByPlayers <- get_capturing_soldiers_by_player(teamPresence, evt.team)
  apply_award_to_participants(soldiersByPlayers, amountPerPlayer, capzone_award__stat)

[es(tag=server)]
def award_on_capzone_captured(evt : EventAwardZoneCapturers;
                              teamPresence : Object;
                              capzone__owningTeam : int;
                              capzone_award__progressAwardPortion : float;
                              capzone_award__stat : string = "captures")
  let amountPerPlayer = 1.0 - capzone_award__progressAwardPortion
  let soldiersByPlayers <- get_capturing_soldiers_by_player(teamPresence, capzone__owningTeam)
  apply_award_to_participants(soldiersByPlayers, amountPerPlayer, capzone_award__stat)

  for playerUint in keys(soldiersByPlayers)
    let player = EntityId(playerUint)
    sendEvent(player, [[EventPlayerSquadFinishedCapturing]])
    add_award(player, "capture")
