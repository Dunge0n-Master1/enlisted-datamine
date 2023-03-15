from "%enlSqGlob/ui_library.nut" import *

let armyUnlocksUi = require("%enlist/soldiers/armyUnlocksUi.nut")
let JB = require("%ui/control/gui_buttons.nut")

let { utf8ToUpper } = require("%sqstd/string.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { fontXXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { isArmyProgressOpened } = require("%enlist/mainMenu/sectionsState.nut")
let { colFull, titleTxtColor, navHeight, sidePadding
} = require("%enlSqGlob/ui/designConst.nut")


let titleTxtStyle = { color = titleTxtColor }.__update(fontXXLarge)


let headerUi = {
  size = [flex(), navHeight]
  gap = colFull(1)
  valign = ALIGN_CENTER
  children = [
    Bordered(loc("BackBtn"), @() isArmyProgressOpened(false), {
      hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") }]]
    })
    {
      rendObj = ROBJ_TEXT
      hplace = ALIGN_CENTER
      text = utf8ToUpper(loc("menu/campaignRewards"))
    }.__update(titleTxtStyle)
  ]
}

let armyProgressScene = @() {
  watch = safeAreaBorders
  key = "armyProgressScene"
  size = flex()
  flow = FLOW_VERTICAL
  padding = [safeAreaBorders.value[0], sidePadding]
  children = [
    headerUi
    armyUnlocksUi
  ]
}


let function open() {
  sceneWithCameraAdd(armyProgressScene, "researches")
}

if (isArmyProgressOpened.value)
  open()

isArmyProgressOpened.subscribe(function(val) {
  if (val)
    open()
  else
    sceneWithCameraRemove(armyProgressScene)
})
