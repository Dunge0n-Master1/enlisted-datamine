require ecs
require enlisted.game.es.player_group_common
require player

[es(tag=ui, on_appear, on_event=EventOnSeatOwnersChanged)]
def vehicle_marker_state_ui(evt : Event;
                            vehicle_seats__seatEids : EidList;
                            var vehicle_marker_ui__gropmateNames : StringList&;
                            var vehicle_marker_ui__gropmateNickFrames : StringList&;
                            var vehicle_marker_ui__isEmpty : bool&;
                            var vehicle_marker_ui__hasGroupmates : bool&;
                            var vehicle_marker_ui__hasSquadmates : bool&)
  vehicle_marker_ui__gropmateNames |> clear()
  vehicle_marker_ui__gropmateNickFrames |> clear()
  vehicle_marker_ui__isEmpty = true
  vehicle_marker_ui__hasGroupmates = false
  vehicle_marker_ui__hasSquadmates = false
  query(get_local_player_eid()) <| $ [es] (squad_members_ui__watchedSquadEid : EntityId; groupId aka local_groupId : int64)
    for sitterEid in vehicle_seats__seatEids
      query(sitterEid) <| $ [es] (seat__ownerEid : EntityId;
                                  seat__squadEid : EntityId;
                                  seat__playerEid : EntityId;
                                  seat__isOwnerAlive : bool;
                                  seat__isPlayer : bool)
        if !!seat__ownerEid && seat__isOwnerAlive
          var isGroupmate = false
          if local_groupId != INVALID_GROUP_ID_INT64 && !!seat__playerEid
            query(seat__playerEid) <| $ [es] (groupId aka sitter_groupId : int64;
                                              name : string;
                                              decorators__nickFrame : string)
              isGroupmate = local_groupId == sitter_groupId
              if seat__isPlayer && isGroupmate
                vehicle_marker_ui__gropmateNames |> push(name)
                vehicle_marker_ui__gropmateNickFrames |> push(decorators__nickFrame)
          let isSquadmate = !!seat__squadEid && seat__squadEid == squad_members_ui__watchedSquadEid
          vehicle_marker_ui__hasSquadmates ||= isSquadmate
          vehicle_marker_ui__hasGroupmates ||= !isSquadmate && isGroupmate
          vehicle_marker_ui__isEmpty &&= false
