from "%enlSqGlob/ui_library.nut" import *
let { unitSize, bigPadding } = require("%enlSqGlob/ui/viewConst.nut")

// inventory slots
let fullWidth = unitSize * 10
let baseSlotHeight = unitSize * 2.2
let quadSlotSize = [unitSize * 2.4, unitSize * 1.6] // 108px x 72px
let thirdSlotSize = [hdpx(146), unitSize * 1.6]

let equipSlotRows = [
  [
    [
      {
        slotType = "primary"
        slotSize = [fullWidth, baseSlotHeight]
        slotImg = "empty_slot_weapon.svg"
        headerLocId = $"slot/empty_primary"
      }
    ],
    [
      {
        slotType = "secondary"
        slotSize = [fullWidth, baseSlotHeight]
        slotImg = "empty_slot_weapon.svg"
        headerLocId = $"slot/empty_secondary"
      }
    ],
    [
      {
        slotType = "side"
        slotSize = [fullWidth * 0.5, baseSlotHeight]
        slotImg = "item_pistol.svg"
        headerLocId = $"slot/empty_side"
      }
      {
        slotType = "melee"
        slotSize = [fullWidth * 0.5 - bigPadding, baseSlotHeight]
        slotImg = "melee.svg"
        headerLocId = $"slot/empty_melee"
      }
    ]
  ],
  [
    [
      {
        slotType = "radio"
        slotSize = quadSlotSize
        slotImg = "item_radio.svg"
      }
      {
        slotType = "parachute"
        slotSize = quadSlotSize
        slotImg = "item_parachute.svg"
      }
      {
        slotType = "medpack"
        slotSize = quadSlotSize
        slotImg = "item_backpack.svg"
      }
      {
        slotType = "backpack"
        slotSize = quadSlotSize
        slotImg = "item_backpack.svg"
      }
      {
        slotType = "mine"
        slotSize = quadSlotSize
        slotImg = "item_antitank_mine.svg"
        headerLocId = "inventoryAndEquipment"
      }
      {
        slotType = "flask_usable"
        slotSize = quadSlotSize
        slotImg = "flask_icon.svg"
      }
      {
        slotType = "binoculars_usable"
        slotSize = quadSlotSize
        slotImg = "binoculars_icon.svg"
      }
    ],
  ],
  [
    [
      {
        slotSize = thirdSlotSize
        slots = 3
        unitedSlots = [
          {
            slotType = "grenade"
            slotSize = thirdSlotSize
            slotImg = "item_grenade.svg"
          }
        ]
      }
    ],
    [
      {
        slotSize = quadSlotSize
        slots = 4
        unitedSlots = [
          {
            slotType = "inventory"
            slotSize = quadSlotSize
            slotImg = "item_backpack.svg"
          }
        ]
      }
    ]
  ]
]

let equipSlotTbl = {}

let addSlot = function(slotType) {
  assert(!(slotType in equipSlotTbl), $"Duplicate slot {slotType}")
  equipSlotTbl[slotType] <- true
}

foreach (group in equipSlotRows) {
  foreach (slotRow in group) {
    foreach (slotCfg in slotRow) {
      let { slotType = null, unitedSlots = [] } = slotCfg
      if (slotType != null) {
        addSlot(slotType)
      }
      foreach (slot in unitedSlots)
        addSlot(slot.slotType)
    }
  }
}

return {
  equipSlotRows
  equipSlotTbl
}
