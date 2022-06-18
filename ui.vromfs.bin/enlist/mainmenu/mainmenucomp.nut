from "%enlSqGlob/ui_library.nut" import *

let mainMenuComp = {value = null}
let getMainMenuComp = @() mainMenuComp.value
let mainMenuVersion = Watched(0)

let function setMainMenuComp(comp) {
  mainMenuComp.value <- comp
  mainMenuVersion(mainMenuVersion.value+1)
}
return {
  getMainMenuComp, setMainMenuComp, mainMenuVersion
}