from "%enlSqGlob/ui_library.nut" import *

let { fontHeading2 } = require("%enlSqGlob/ui/fontsStyle.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let {doesSceneExist, getTopScene, scenesListGeneration} = require("navState.nut")

let {getMainMenuComp, mainMenuVersion} = require("%enlist/mainMenu/mainMenuComp.nut")

let notLoggedInText = {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  text = loc("Error: not logged in")
}.__update(fontHeading2)

let mainMenu = @() {
  size = flex()
  children = getMainMenuComp()
  watch = mainMenuVersion
}

let function mainScreen() {
  let children = doesSceneExist()
    ? getTopScene()
    : userInfo.value==null
      ? notLoggedInText
      : mainMenu

  return {
    watch = [userInfo, scenesListGeneration]
    size = [sw(100), sh(100)]

    children
  }
}

return mainScreen
