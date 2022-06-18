require ecs

[es(track=(isInVehicle, locked__pickupItemsLockedByAffect, human_binocular__mode, human_weap__radioMode, human_weap__mortarMode, isAlive, medic__canHealSelectedSoldier))]
def can_pickup_items_conditions(evt : Event;
                                var human__canPickupItems : bool&;
                                var human_inventory__selectedItem : EntityId&;
                                isInVehicle : bool = false;
                                locked__pickupItemsLockedByAffect : bool = false;
                                human_weap__radioMode : bool = false;
                                human_weap__mortarMode : bool = false;
                                human_binocular__mode : bool = false;
                                isAlive : bool = true;
                                medic__canHealSelectedSoldier : bool = false)
  human__canPickupItems = (!isInVehicle &&
                              !locked__pickupItemsLockedByAffect &&
                              !human_weap__radioMode &&
                              !human_weap__mortarMode &&
                              !human_binocular__mode &&
                              isAlive &&
                              !medic__canHealSelectedSoldier)
  human_inventory__selectedItem = ecs::INVALID_ENTITY_ID
