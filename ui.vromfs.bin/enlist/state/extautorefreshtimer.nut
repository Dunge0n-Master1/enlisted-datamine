from "%enlSqGlob/ui_library.nut" import *

let {get_time_msec} = require("dagor.time")
let { windowActive, steamOverlayActive } = require("%enlist/state/windowState.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { appId } = require("%enlSqGlob/clientState.nut")
let { isBrowserClosed } = require("%ui/components/browserWidget.nut")
let { get_setting_by_blk_path } = require("settings")

let needOnBrowserCloseCb = get_setting_by_blk_path("updatePurchasesOnBrowserClose") ?? false

//call refresh function after alt+tab or steam overlay open
//function will be called only when logged in
let function mkExtAutoRefreshTimer(
  refresh, //function to call
  refreshDelaySec = 30 //minimum timeout after refresh to ignore window activate
) {
  local readyRefreshTime = 0
  local timeLeftToUpdate = 0
  local refreshPeriod = 10.0

  local startAutoRefreshTimer = null

  let function autoRefreshImpl() {
    if (userInfo.value?.userId == null || appId.value < 0)
      return

    readyRefreshTime = get_time_msec() + (1000 * refreshDelaySec).tointeger()
    refresh()

    timeLeftToUpdate = max(0, timeLeftToUpdate - 1)
    if (timeLeftToUpdate > 0)
      startAutoRefreshTimer()
  }

  local isAutorefreshTimerStarted = false
  startAutoRefreshTimer = function() {
    if (isAutorefreshTimerStarted)
      return
    isAutorefreshTimerStarted = true
    gui_scene.setTimeout(refreshPeriod, function() {
      isAutorefreshTimerStarted = false
      readyRefreshTime = 0
      if (windowActive.value && !steamOverlayActive.value)
        autoRefreshImpl()
    })
  }


  let function windowStateHandler(isActive) {
    if (isActive && (readyRefreshTime <= get_time_msec()))
      autoRefreshImpl()
  }

  isBrowserClosed.subscribe(function(v){
    if (v && needOnBrowserCloseCb)
      autoRefreshImpl()
  })

  windowActive.subscribe(windowStateHandler)
  steamOverlayActive.subscribe(@(overlayActive) windowStateHandler(!overlayActive))

  return {
    function refreshOnWindowActivate(repeatAmount = 1, refreshPeriodSec = 10.0) {
      readyRefreshTime = 0
      timeLeftToUpdate = repeatAmount
      refreshPeriod = refreshPeriodSec
    }
  }
}

return kwarg(mkExtAutoRefreshTimer)