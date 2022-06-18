require ecs

[es(tag=server, on_appear)]
def set_flamethrower_damage_in_mode_with_friendly_fire(evt : Event;
                                                       friendly_fire_gamemode__friendlyDamageMult : float;
                                                       flamethrower__streamDamagePerSecond : float;
                                                       flamethrower__cloudDamagePerSecond : float;
                                                       var flamethrower__friendlyStreamDamagePerSecond : float&;
                                                       var flamethrower__friendlyCloudDamagePerSecond : float&)
  query() <| $ [es(REQUIRE=gamemodeFriendlyFire)] ()
    let mult = friendly_fire_gamemode__friendlyDamageMult
    flamethrower__friendlyStreamDamagePerSecond = flamethrower__streamDamagePerSecond * mult
    flamethrower__friendlyCloudDamagePerSecond = flamethrower__cloudDamagePerSecond * mult