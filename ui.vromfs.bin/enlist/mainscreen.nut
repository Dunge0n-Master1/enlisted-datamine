from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let {doesSceneExist, getTopScene, scenesListGeneration} = require("navState.nut")

let {getMainMenuComp, mainMenuVersion} = require("%enlist/mainMenu/mainMenuComp.nut")

let notLoggedInText = {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  text = loc("Error: not logged in")
}.__update(h2_txt)

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
