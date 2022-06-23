module awards_common shared
require ecs
require game.es.events
require EnlistedNet
require ecs.common
require enlisted.game.es.offender_cache_common

def send_award_to_player(player_eid : EntityId; award : string)
  server_send_schemeless_event(player_eid, typeinfo(undecorated_typename type<CmdAddAward>), player_eid) <| $(var init : Object#)
    set(init, "award", award)


def send_award_to_team(dst_team : int; award : string)
  query() <| $ [es] (eid : EntityId; team : int)
    if dst_team == team
      send_award_to_player(eid, award)

def push_soldier_stat(var awards : Array#; player : EntityId; guid : string; stat : string; amount : float = 1.0)
  push_to_array(awards) <| $(var obj : Object#)
    obj |> set("stat", stat)
    obj |> set("playerEid", player)
    obj |> set("guid", guid)
    obj |> set("amount", amount)

def push_soldier_stat(var awards : Array#; soldier : CachedSoldier; stat : string; amount : float = 1.0)
  push_soldier_stat(awards, soldier.player, soldier.guid, stat, amount)
