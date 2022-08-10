from "%enlSqGlob/ui_library.nut" import *

let equipGroups = [
  {
    name = "weapons"
    locId = "inventory/Weapons"
    slots = ["primary", "secondary", "mortar", "antitank", "flamethrower", "building_tool",
                "medbox", "side", "melee"]
    maxSlotInRow = 2
    maxSlotTypesInRow = 3
  }
  {
    name = "grenades"
    locId = "inventory/Grenades"
    slots = ["grenade", "mine"]
    maxSlotInRow = 4
    maxSlotTypesInRow = 4
  }
  {
    name = "equipment"
    locId = "inventory/Equipment"
    slots = ["radio", "gasbag", "backpack", "binoculars_usable", "flask_usable", "parachute",
                "medpack", "inventory"]
    maxSlotInRow = 4
    maxSlotTypesInRow = 3
  }
]

let slotTypeToEquipGroup = {}
foreach (idx, eg in equipGroups) {
  eg.idx <- idx
  foreach (slot in eg.slots) {
    assert(!(slot in slotTypeToEquipGroup), $"Duplicate slot {slot}")
    slotTypeToEquipGroup[slot] <- eg
  }
}

return {
  equipGroups = equipGroups
  slotTypeToEquipGroup = slotTypeToEquipGroup
}