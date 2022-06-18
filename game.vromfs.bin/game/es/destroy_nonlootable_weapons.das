require ecs
require HumanPhys

[es(tag=server, on_event=EventEntityDied, REQUIRE=destroyNonPrimaryWeaponOnDeath)]
def destroy_nonlootable_weapons(evt : Event; var human_weap__gunEids : EidList&; var human_weap__gunMods : Array&)
  for slotEnum in each_enum(HUWeaponSlots EWS_PRIMARY)
    let slot = int(slotEnum)
    if slotEnum == HUWeaponSlots EWS_PRIMARY || slot >= length(human_weap__gunEids)
      continue
    destroyEntity(human_weap__gunEids[slot])
    human_weap__gunEids[slot] = INVALID_ENTITY_ID
    var gunModEids = getRW_ecs_EidList(human_weap__gunMods[slot])
    for gunMod in *gunModEids
      // Destroy gun mods as well, otherwise they'll be hanging around
      // in the midair. Gun mods are attached to the gun and when the gun is destroyed
      // gun mods won't be able to move and they can't be interacted with.
      destroyEntity(gunMod)
    clear(*gunModEids)
