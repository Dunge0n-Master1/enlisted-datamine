require ecs


[es(tag=server, on_appear, track=game_option__friendlyFire)]
def game_option_toggle_friendly_fire_es(evt : Event; game_option__friendlyFire : bool; game_option__friendlyFireTemplate : string = "gamemodeFriendlyFire")
  var friendlyFireEid = INVALID_ENTITY_ID
  query() <| $ [es(REQUIRE=gamemodeFriendlyFire)] (eid : EntityId) { friendlyFireEid = eid; }
  if !game_option__friendlyFire
    destroyEntity(friendlyFireEid)
    return
  elif !friendlyFireEid
    createEntity(game_option__friendlyFireTemplate)


[es(tag=server, on_appear, REQUIRE=gamemodeFriendlyFire)]
def game_option_disable_friendly_fire_es(evt : Event; eid : EntityId)
  query() <| $ [es] (game_option__friendlyFire : bool)
    if !game_option__friendlyFire
      destroyEntity(eid)

