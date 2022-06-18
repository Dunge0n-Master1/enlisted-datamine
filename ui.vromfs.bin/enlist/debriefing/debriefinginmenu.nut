from "%enlSqGlob/ui_library.nut" import *

let debriefingStateBase = require("debriefingStateInMenu.nut")
let { dbgShow, dbgData } = require("debriefingDbgState.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let navState = require("%enlist/navState.nut")

let function init(ctor, state = null) {
  let { show, data, clearData } = state ?? debriefingStateBase
  let dataToShow = Computed(@() dbgShow.value ? dbgData.value : data.value)

  let needShow = keepref(Computed(@()
    !isInBattleState.value && dataToShow.value != null && (dbgShow.value || show.value)))

  isInBattleState.subscribe(function(active) {
    if (!active)
      return
    clearData() //clear previous battle debriefing
    dbgShow(false)
  })

  let closeAction = @() dbgShow.value ? dbgShow(false) : show(false)
  let function debriefingWnd() {
    let children = (!(dataToShow.value?.isFinal ?? true))
        ? null
        : ctor(dataToShow.value, closeAction)
    return {
      key = "enlist_debriefing_root"
      watch = dataToShow
      onAttach = @() children == null ? closeAction() : null
      size = flex()
      children
    }
  }
  let function checkAndCloseDebr(){
    if (needShow.value && !dataToShow.value?.isFinal)
      closeAction()
  }
  needShow.subscribe(
    function(val) {
      if (val) {
        gui_scene.resetTimeout(1, checkAndCloseDebr)
        navState.addScene(debriefingWnd)
      }
      else {
        navState.removeScene(debriefingWnd)
        gui_scene.clearTimer(checkAndCloseDebr)
      }
    }
  )
  if (needShow.value)
    navState.addScene(debriefingWnd)
}
return init