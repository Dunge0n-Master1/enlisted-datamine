from "%enlSqGlob/ui_library.nut" import *

let { colFull, colPart, columnGap } = require("%enlSqGlob/ui/designConst.nut")


let slotOffset = columnGap
let miniOffset = (columnGap * 0.5).tointeger()

let headerHeight = columnGap + miniOffset
let baseSlotHeight = colPart(1.6)
let miniSlotSize = colPart(1)
let bigSlotSize = colFull(2)
let modSize = [colPart(1) + miniOffset, ((baseSlotHeight - miniOffset) * 0.5).tointeger()]
let baseItemSize = [colFull(4), baseSlotHeight]
let animXMove = colFull(4)


let equipSlotRows = [
  [
    {
      slotType = "primary"
      slotSize = [colFull(5), baseSlotHeight]
      itemSize = baseItemSize
      slotImg = "assault_rifle.svg"
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
      slotImg = "assault_rifle.svg"
      hasName = true
      hasTypeIcon = true
      headerLocId = $"slot/empty_secondary"
    }
  ],
  [
    {
      slotType = "side"
      slotSize = [colFull(3), baseSlotHeight]
      itemSize = [colFull(2), baseSlotHeight]
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
      minSlotsAmount = 6
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
          slotImg = "item_medkit.svg"
        }
      ]
    }
  ]
]


let mkSlotAnim = @(delay) {
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, delay, duration = 0.3, play = true }
    { prop = AnimProp.translate, from = [animXMove,0], to = [0,0], delay,
      duration = 0.3, play = true, easing = OutQuart }
    { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, playFadeOut = true }
  ]
}


return {
  equipSlotRows
  slotOffset
  miniOffset
  modSize
  baseItemSize
  headerHeight
  mkSlotAnim
}
