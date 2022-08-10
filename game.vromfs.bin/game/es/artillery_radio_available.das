require ecs
require player

[es(tag=gameClient, REQUIRE=(heroSquad, isAlive, isDowned, human_weap__radioEid, human_net_phys__isSwimming, human_net_phys__isClimbing), track=(isAlive, isDowned, human_weap__radioEid, human_net_phys__isSwimming, human_net_phys__isClimbing), on_appear, on_disappear)]
def artillery_radio_available(evt : Event)
  query(get_local_player_eid()) <| $ [es] (var artillery__available : bool&)
    let available = find_query() <| $ [es(REQUIRE=heroSquad)] (human_weap__radioEid : EntityId;
                                                               isAlive : bool;
                                                               isDowned : bool;
                                                               human_net_phys__isSwimming : bool;
                                                               human_net_phys__isClimbing : bool)
      return isAlive && !isDowned && !!human_weap__radioEid && !human_net_phys__isSwimming && !human_net_phys__isClimbing
    artillery__available = available

def track_artillery_was_available_for_squad()
  query(get_local_player_eid()) <| $ [es] (possessed : EntityId;
                                           artillery__available : bool;
                                           var artillery__wasAvailableForSquad : EntityId&)
    let heroSquad = get_Eid(possessed, "squad_member__squad") ?? INVALID_ENTITY_ID
    if heroSquad == INVALID_ENTITY_ID
      artillery__wasAvailableForSquad = INVALID_ENTITY_ID
      return
    if artillery__wasAvailableForSquad != heroSquad
      artillery__wasAvailableForSquad = artillery__available ? heroSquad : INVALID_ENTITY_ID

[es(tag=gameClient, REQUIRE=(player, artillery__available), track=artillery__available, on_appear)]
def artillery_radio_was_available_for_squad_player(evt : Event; is_local : bool)
  if is_local
    track_artillery_was_available_for_squad()

[es(tag=gameClient, REQUIRE=(hero, squad_member__squad), track=squad_member__squad, on_appear)]
def artillery_radio_was_available_for_squad_changed_squad(evt : Event)
  track_artillery_was_available_for_squad()
