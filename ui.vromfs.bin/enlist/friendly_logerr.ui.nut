from "%enlSqGlob/ui_library.nut" import *

let { fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let colors = require("%ui/style/colors.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let scrollbar = require("%ui/components/scrollbar.nut")
let dagorDebug = require("dagor.debug")
let dagorSys = require("dagor.system")
let { platformId, is_pc } = require("%dngscripts/platform.nut")


let errors = mkWatched(persist, "errors", [])
let haveUnseenErrors = mkWatched(persist, "haveUnseenErrors", false)

let maxErrorsToShow = 8

let function addError(tag, logstring, timestamp, text){
  local curErrors = clone errors.value

  if (curErrors.len() >= maxErrorsToShow)
    curErrors = curErrors.slice(-(maxErrorsToShow-1))
  curErrors.append({timestamp = timestamp, logstring = logstring, tag=tag, text=text})
  errors.update(curErrors)
  haveUnseenErrors(true)
}

let function mkSimpleCb(locid) {
  return function(tag, logstring, timestamp){
    addError(tag, logstring, timestamp, "logerr/{0}{1}".subst(is_pc ? "" : $"{platformId}/", locid))
  }
}

dagorDebug.clear_logerr_interceptors()

let tagsForPopup = ["web-vromfs:", "[disk]", "[network]"]
tagsForPopup.map(@(tag) dagorDebug.register_logerr_interceptor([tag], mkSimpleCb(tag)))

if (dagorSys.DBGLEVEL <= 0) {
  let clientlog = require("clientlog")
  let function sendErrorInRelease(_tag, logstring, _timestamp) {
    clientlog.send_error_log(logstring, {
      attach_game_log = false,
      meta = {}
    })
  }
  dagorDebug.register_logerr_interceptor(["[frp:error]"], sendErrorInRelease)
}

local counter = 0
let function test_log_errors(){
  counter++
  errors(clone errors.value)
  dagorDebug.logerr($"web-vromfs: [network] {counter}")
}
console_register_command(@()gui_scene.setInterval(2.0, test_log_errors), "ui.test_logerrs")

let function textarea(text, logstring) {
  local onClick

  if (dagorSys.DBGLEVEL > 0) {
    onClick = function onClickImpl() {
      modalPopupWnd.add([sw(50),sh(0)], {
        size = [sw(100), sh(100)]
        uid = "LOGGER_ERROR_DETAILS"
        padding = 0
        popupOffset = 0
        margin = 0
        children = {
          size = flex()
          rendObj = ROBJ_TEXTAREA
          behavior = [Behaviors.TextArea]
          text = logstring
          color = Color(220,220,220,220)
          textColor = Color(220,220,220,220)
        }
        popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, color = Color(220,220,220,220) fillColor = Color(0,0,0,180)}
      })
    }
  }

  return watchElemState(@(sf) {
    rendObj = ROBJ_TEXTAREA
    behavior = [Behaviors.TextArea, Behaviors.Button]
    text = loc(text,loc("unknown error"))
    color = (sf & S_HOVER) ? Color(220,220,220) : Color(128,128,128)
    size = [flex(), SIZE_TO_CONTENT]
    onClick = onClick
    skipDirPadNav = true
  })
}


let header = @(text) {
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  padding = hdpx(10)
  color = colors.WindowHeader
  children = {rendObj = ROBJ_TEXT text = text color = Color(128,128,128) size = [flex(), SIZE_TO_CONTENT]}
}
/*
todo:
 - show if error happens not very long time ago as pale icon (store timestamp and analyze it while it is not long)
 - show in UI_VM (like alerts)
*/

let function errors_list(){
  return {
    watch = errors
    flow = FLOW_VERTICAL
    size = [flex(), SIZE_TO_CONTENT]
    padding = hdpx(20)
    children = errors.value.map(@(v) textarea(v.text, v.logstring))
    gap = hdpx(20)
  }
}
let function onClick(event){
  modalPopupWnd.add(event.targetRect,
  {
    size = [sw(45), sh(40)]
    uid = "MODAL_LOGERR"
    padding = 0
    popupFlow = FLOW_VERTICAL
    popupValign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    flow= FLOW_VERTICAL
    popupOffset = 0
    margin = 0
    onDetach = @() haveUnseenErrors(false)
    onAttach = @() haveUnseenErrors(false)
    children = [
      header(loc("logerrWnd_hdr", "Warnings"))
      {
        size = flex()
        clipChildren = true
        children = scrollbar.makeVertScroll(errors_list)
      }
    ]
    popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, color = Color(220,220,220,220) fillColor = Color(0,0,0,180)}
  })
}
let function mkBtn(){
  let stateFlags = Watched(0)
  let onElemState = @(sf) stateFlags.update(sf)
  return function(){
  let sf = stateFlags.value
    return{
      behavior = Behaviors.Button
      onClick = onClick
      watch = stateFlags
      rendObj = ROBJ_INSCRIPTION
      validateStaticText = false
      onElemState = onElemState
      text = fa["exclamation-triangle"]
      fontSize = hdpx(12)
      font = fontawesome.font
      color = (sf & S_HOVER) ? Color(255,255,255) : Color(245, 100, 30, 100)
    }
  }
}

let errBtn = mkBtn()
let function errorBtn(){
  return {
    watch = [haveUnseenErrors,errors]
    size = SIZE_TO_CONTENT
    children = haveUnseenErrors.value ? errBtn : null
    padding = hdpx(5)
  }
}

return errorBtn
