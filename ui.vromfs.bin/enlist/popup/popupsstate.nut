from "%enlSqGlob/ui_library.nut" import *

let POPUP_PARAMS = {
  id = ""
  text = ""
  styleName = ""
  showTime = 10.0
  onClick = null //function() - will be called on popup click
}

const MAX_POPUPS = 3
let popups = []
let popupsGen = Watched(0)
local counter = 0 //for popups without id

let function removePopup(id) {
 //id (str) or uid (int)
  let idx = popups.findindex(@(p) p.id == id || p.uid == id)
  if (idx == null)
    return
  popups.remove(idx)
  popupsGen(popupsGen.value+1)
}

let function addPopup(config) {
  let uid = counter++
  if (config?.id != null)
    removePopup(config.id)
  else
    config.id <- $"_{uid}"

  if (popups.len() >= MAX_POPUPS)
    popups.remove(0)

  let popup = POPUP_PARAMS.__merge(config)
  popup.uid <- uid

  popup.click <- function() {
    popup.onClick?()
    removePopup(popup.id)
  }

  popup.visibleIdx <- Watched(-1)
  popup.visibleIdx.subscribe(function(_newVal) {
    popup.visibleIdx.unsubscribe(callee())
    gui_scene.setInterval(popup.showTime,
      function() {
        gui_scene.clearTimer(callee())
        removePopup(uid) //if popup changed, it has own timer
      })
    })

  popups.append(popup)
  popupsGen(popupsGen.value+1)
}

console_register_command(@() addPopup({ text = $"Default popup\ndouble line {counter}" }),
  "popup.add")
console_register_command(@() addPopup({ text = $"Default error popup\nnext line {counter}", styleName = "error" }),
  "popup.error")

let getPopups = @() clone popups

return {
  getPopups
  addPopup
  removePopup
  popupsGen
}