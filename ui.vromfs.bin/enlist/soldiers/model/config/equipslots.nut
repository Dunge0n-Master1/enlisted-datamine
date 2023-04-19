from "%enlSqGlob/ui_library.nut" import *

let { colFull, colPart, columnGap } = require("%enlSqGlob/ui/designConst.nut")


let slotOffset = columnGap
let miniOffset = (columnGap * 0.5).tointeger()

let headerHeight = columnGap + miniOffset
let baseSlotHeight = colPart(1.6)
let miniSlotSize = colPart(1)
let bigSlotSize = colFull(2)
let modSize = [colPart(1) + miniOffset, baseSlotHeight]
let baseItemSize = [colFull(4), baseSlotHeight]


let equipSlotRows = [
  [
    {
      slotType = "primary"
      slotSize = [colFull(5), baseSlotHeight]
      itemSize = baseItemSize
      slotImg = "empty_slot_weapon.svg"
      hasName = true
      hasTypeIcon = true
      headerLocId = $"slot/empty_primary"
    }
  ],
  [
    {
      slotType = "secondary"
      slotSize = [colFull(5), baseSlotHeight]
      itemSize = baseItemSize
      slotImg = "empty_slot_weapon.svg"
      hasName = true
      hasTypeIcon = true
      headerLocId = $"slot/empty_secondary"
    }
  ],
  [
    {
      slotType = "side"
      slotSize = [colFull(3), baseSlotHeight]
      slotImg = "item_pistol.svg"
      hasName = true
      headerLocId = $"slot/empty_side"
    }
    {
      slotType = "melee"
      slotSize = [colFull(2), baseSlotHeight]
      slotImg = "melee.svg"
      hasName = true
      headerLocId = $"slot/empty_melee"
    }
  ],
  [
    {
      slotType = "mine"
      slotSize = [miniSlotSize, miniSlotSize]
      slotImg = "item_antitank_mine.svg"
      headerLocId = "inventoryAndEquipment"
    }
    {
      slotType = "binoculars_usable"
      slotSize = [bigSlotSize, miniSlotSize]
      slotImg = "binoculars_icon.svg"
    }
    {
      slotType = "flask_usable"
      slotSize = [bigSlotSize, miniSlotSize]
      slotImg = "flask_icon.svg"
    }
  ],
  [
    {
      slotType = "backpack"
      slotSize = [bigSlotSize, bigSlotSize - miniOffset]
      slotImg = "item_backpack.svg"
    }
    {
      rowsAmount = 2
      slotSize = [miniSlotSize, miniSlotSize]
      unitedSlots = [
        {
          slotType = "grenade"
          slotSize = [miniSlotSize, miniSlotSize]
          slotImg = "item_grenade.svg"
        }
        {
          slotType = "inventory"
          slotSize = [miniSlotSize, miniSlotSize]
          slotImg = "item_backpack.svg"
        }
      ]
    }
  ]
]


let function getSlotParams(slotType) {
  foreach (row in equipSlotRows)
    foreach (slot in row) {
      if ((slot?.slotType ?? "") == slotType)
        return slot

      foreach (unitedSlot in slot?.unitedSlots ?? [])
        if ((unitedSlot?.slotType ?? "") == slotType)
          return unitedSlot
    }

  return null
}


return {
  equipSlotRows
  slotOffset
  miniOffset
  modSize
  baseItemSize
  headerHeight
  getSlotParams
}
