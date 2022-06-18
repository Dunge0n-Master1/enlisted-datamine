require ecs

[es(track=gun__owner, on_appear, REQUIRE=grenade_thrower)]
def apply_longer_grenade_throw_perk_es(evt : Event;
                                       gun__owner : EntityId;
                                       var gun__projectileVelocityMult : float&)
  query(gun__owner) <| $ [es] (entity_mods__grenadeThrowDistMult : float)
    // throw distance = v^2 * sin(angle to horizon) / g
    // if we want to increase throw distance by 'a' using higher by 'k' speed
    // we get k = sqrt(a)
    gun__projectileVelocityMult = sqrt(entity_mods__grenadeThrowDistMult)