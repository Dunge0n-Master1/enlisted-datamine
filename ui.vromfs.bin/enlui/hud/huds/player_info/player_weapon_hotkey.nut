from "%enlSqGlob/ui_library.nut" import *

let {sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let { textListFromAction, buildElems } = require("%ui/control/formatInputBinding.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkShortHudHintFromList } = require("%ui/components/controlHudHint.nut")
let { DEFAULT_TEXT_COLOR } = require("%ui/hud/style.nut")

let disabledColor = Color(128,128,128,128)

local function isHotkeysEmpty(textList){
  textList = textList ?? [""]
  if (textList.len()==1 && textList?[0] == "")
    return true
  return false
}

const eventTypeToText = false
let function makeControlTip(hotkey, active) {
  return function() {
    let textFunc = @(text) {
      rendObj = ROBJ_TEXT,
      color = active ? DEFAULT_TEXT_COLOR : disabledColor,
      padding = hdpx(4),
      text
    }.__update(sub_txt)
    local textList = textListFromAction(hotkey, isGamepad.value ? 1 : 0, eventTypeToText)
    if (isHotkeysEmpty(textList) && (["Human.Weapon1", "Human.Weapon2"].indexof(hotkey) != null)){
      textList = textListFromAction("Human.WeaponNextMain", isGamepad.value ? 1 : 0, eventTypeToText)
    }
    if (isHotkeysEmpty(textList) && ["Human.Weapon1", "Human.Weapon2", "Human.Weapon3", "Human.Weapon4"].indexof(hotkey) != null)
      textList = textListFromAction("Human.WeaponNext", isGamepad.value ? 1 : 0, eventTypeToText)
    if (isHotkeysEmpty(textList) && ["Human.Weapon1", "Human.Weapon2", "Human.Weapon3", "Human.Weapon4"].indexof(hotkey) != null)
      textList = textListFromAction("Human.WeaponPrev", isGamepad.value ? 1 : 0, eventTypeToText)
    let controlElems = buildElems(textList, {textFunc = textFunc, compact = true})
    return mkShortHudHintFromList(controlElems)
  }
}

let weaponHotkeysActive = {}
let weaponHotkeysInactive = {}
let weaponKeys = [
  "Human.Weapon1",
  "Human.Weapon2",
  "Human.Weapon3",
  "Human.Weapon4",
  "Human.Throw",
  "Human.SpecialItemSlot",
  "Inventory.UseMedkit",
  "Human.Melee",
  "Human.WeaponNextMain",
  "Human.GrenadeNext",
  "Human.FiringMode",
  "Inventory.UseFlask",
  "Human.UseBinocular"
]

foreach (key in weaponKeys) {
  weaponHotkeysActive[key] <- makeControlTip(key, true)
  weaponHotkeysInactive[key] <- makeControlTip(key, false)
}

let function getWeaponHotkeyWidget(key, active) {
  return (active ? weaponHotkeysActive : weaponHotkeysInactive)[key]
}

return getWeaponHotkeyWidget