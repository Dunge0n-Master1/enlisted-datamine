module awards_common shared
require ecs
require game.es.events
require EnlistedNet


def send_award_to_player(player_eid : EntityId; award : string)
  server_send_schemeless_event(player_eid, typeinfo(undecorated_typename type<CmdAddAward>), player_eid) <| $(var init : Object#)
    set(init, "award", award)


def send_award_to_team(dst_team : int; award : string)
  query() <| $ [es] (eid : EntityId; team : int)
    if dst_team == team
      send_award_to_player(eid, award)
