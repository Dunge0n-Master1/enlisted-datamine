require ecs
require HumanPhys
require common_shooter.events_common_shooter
require DngHuman

[es(tag=server, track=possessedByPlr, REQUIRE_NOT=deadEntity)]
def bot_weapon_reset_when_remove_possessed(evt : Event;
                                           possessedByPlr : EntityId;
                                           human_weap__gunEids : EidList;
                                           var human_net_phys : HumanActor)
  if !possessedByPlr
    let meleeSlotId = int(HUWeaponSlots EWS_MELEE)
    var newSlotId = meleeSlotId
    for slotId in [[int int(HUWeaponSlots EWS_PRIMARY); int(HUWeaponSlots EWS_SECONDARY);
                        int(HUWeaponSlots EWS_TERTIARY)]]
      if has(human_weap__gunEids[slotId], "gun") //ignore building tool and something else
        newSlotId = slotId
        break
    if newSlotId != meleeSlotId || human_weap__gunEids[meleeSlotId] != INVALID_ENTITY_ID
      human_net_phys.phys.producedCT |> set_chosen_weapon(HUWeaponSlots(newSlotId))
