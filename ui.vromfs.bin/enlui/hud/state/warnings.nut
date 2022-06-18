import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {get_sync_time} = require("net")
let {CmdStartNarrator} = require("dasevents")

let warningsList = mkWatched(persist, "warningsList", [])

let WARNING_PRIORITIES = {
  HIGH = 0
  MEDIUM = 1
  LOW = 2
  ULTRALOW = 3
}

let possibleWarningsList = {}

assert(possibleWarningsList.len()==0, "should be added only where it used")

let function addWarnings(wList) {
  possibleWarningsList.__update(wList)
}

local updateWarinigsTime = @() null //fwd declaration
local function setWarningsList(list) {
  let curTime = get_sync_time()
  list = list.filter(@(v) v.showEndTime <= 0 || v.showEndTime > curTime)
    .sort(@(a, b) a.priority <=> b.priority || a.showEndTime <=> b.showEndTime || a.id <=> b.id)
  warningsList(list)

  let closestWarningTime = list
    .reduce(@(res, w) w.showEndTime > 0 && (res <= 0 || res > w.showEndTime) ? w.showEndTime : res, 0)
  if (closestWarningTime > 0)
    gui_scene.resetTimeout(closestWarningTime - curTime, updateWarinigsTime)
}
warningsList.whiteListMutatorClosure(setWarningsList)

updateWarinigsTime = @() setWarningsList(warningsList.value)


let function warningShow(warningId) {
  let wparams = possibleWarningsList?[warningId]
  if (wparams == null) {
    log($"Failed to add warning {warningId} it does not exist in possibleWarningsList")
    return
  }

  let list = warningsList.value
  let curWarning = list.findvalue(@(w) w.id == warningId)
  let newWarning = {
    id = warningId
    locId = wparams?.locId ?? warningId
    priority = wparams.priority
    showEndTime = "timeToShow" in wparams ? get_sync_time() + wparams.timeToShow : -1
    color = wparams?.color
  }
  if (curWarning)
    curWarning.__update(newWarning)
  else
    list.append(newWarning)
  setWarningsList(list)

  let snd = wparams?.getSound()
  if (snd != null)
    ecs.g_entity_mgr.broadcastEvent(CmdStartNarrator({phrase=snd, replace=false}))
}

let function warningHide(warningId) {
  let idx = warningsList.value.findindex( @(v) v.id == warningId )
  if (idx == null)
    return
  warningsList.value.remove(idx)
  setWarningsList(warningsList.value)
}

let warningUpdate = @(warningId, shouldShow)
  shouldShow ? warningShow(warningId) : warningHide(warningId)


console_register_command(function(idx=0) {
  let id = idx in possibleWarningsList ? idx
    : (possibleWarningsList.keys()?[idx] ?? possibleWarningsList.keys()?[0])
  let isVisible = warningsList.value.findindex(@(w) w.id == id) != null
  warningUpdate(id, !isVisible)
}, "ui.warning_debug")

return {
  warningsList
  warningShow
  warningHide
  addWarnings
  warningUpdate
  WARNING_PRIORITIES
}

