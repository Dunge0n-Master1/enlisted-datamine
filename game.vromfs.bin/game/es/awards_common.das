module awards_common shared public

require ecs
require ecs.common
require enlisted.game.es.offender_cache_common
require enlisted.events_enlisted

def add_award(var awards : Array&; award_type : string)
  add_award(awards, award_type) <| $ [unused_argument(it)] (it) {}

def add_award(var awards : Array&; award_type : string; cb : block<(var it : Object#) : void>)
  push_to_array(awards) <| $(var obj : Object#)
    obj |> set("id", length(awards))
    obj |> set("type", award_type)
    invoke(cb, obj)

def add_award(player_eid : EntityId; award_type : string; cb : block<(var id : Object#) : void>)
  query(player_eid) <| $ [es] (var awards : Array&)
    add_award(awards, award_type, cb)

def add_award(player_eid : EntityId; award_type : string)
  add_award(player_eid, award_type) <| $ [unused_argument(it)] (it) {}

def push_soldier_stat(var awards : Array#; player : EntityId; guid : string; stat : string; amount : float = 1.0)
  push_to_array(awards) <| $(var obj : Object#)
    obj |> set("stat", stat)
    obj |> set("playerEid", player)
    obj |> set("guid", guid)
    obj |> set("amount", amount)

def push_soldier_stat(var awards : Array#; soldier : CachedSoldier; stat : string; amount : float = 1.0)
  push_soldier_stat(awards, soldier.player, soldier.guid, stat, amount)

def send_award_stat(player : EntityId; guid : string; stat : string; amount : float = 1.0)
  using <| $(var awardList : Array#)
    awardList |> push_soldier_stat(player, guid, stat, amount)
    broadcast_schemeless_event(typeinfo(undecorated_typename type<EventSquadMembersStats>)) <| $(var init : Object)
      set(init, "list", awardList)
