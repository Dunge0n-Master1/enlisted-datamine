require ecs
require ecs.safe
require EnlistedNet
require game.es.awards_common
require enlisted.events_enlisted
require strings

[es(tag=server, REQUIRE=player)]
def friendly_fire_forgive(evt : RequestForgiveFriendlyFire; var friendly_fire__forgivableStats : Object&)
  let key = "{evt.player}"
  let statsToForgive = friendly_fire__forgivableStats[key] ?as Array
  if statsToForgive != null
    using() <| $(var awardList : Array)
      for it in *statsToForgive
        let obj = it as Object
        let player = obj?.player ?? INVALID_ENTITY_ID
        let guid = obj?.guid ?? ""
        let stat = obj?.stat ?? ""
        let amount = obj?.amount ?? -1.
        if !!player && !empty(stat) && !empty(guid)
          awardList |> push_soldier_stat(player, guid, stat, amount)
      if length(awardList) > 0
        broadcast_schemeless_event(typeinfo(undecorated_typename type<EventSquadMembersStats>)) <| $(var init : Object)
          set(init, "list", awardList)
  friendly_fire__forgivableStats |> erase(key)
