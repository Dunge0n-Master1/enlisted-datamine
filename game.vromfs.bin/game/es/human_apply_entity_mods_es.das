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


[es(tag=server, on_appear, track=item__ownerEid, REQUIRE=flamethrowerFuelTank)]
def apply_more_flamethrower_fuel_perk(evt : Event;
                                      item__ownerEid : EntityId;
                                      var ammo_holder__ammoCount : int&)
  query(item__ownerEid) <| $ [es] (entity_mods__flamethrowerFuelMult : float)
    ammo_holder__ammoCount = int(float(ammo_holder__ammoCount) * entity_mods__flamethrowerFuelMult)
