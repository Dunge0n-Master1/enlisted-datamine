from "%enlSqGlob/ui_library.nut" import *

let json = require("%sqstd/json.nut")
let debriefingState = require("debriefingStateInMenu.nut") //can be overrided by game
let { dbgShow, dbgData } = require("debriefingDbgState.nut")

local cfg = {
  state = debriefingState
  savePath = "debriefing.json"
  samplePath = ["../prog/enlist/debriefing/debriefing_sample.json"]
  loadPostProcess = function(_debriefingData) {} //for difference in json saving format, as integer keys in table
}

let saveDebriefing = @(path = null)
  json.save(path ?? cfg.savePath, cfg.state.data.value, {logger = log_for_user})

local function loadDebriefing(path = null) {
  path = path ?? cfg.savePath
  let data = json.load(path, { logger = log_for_user })
  if (data == null)
    return false

  cfg.loadPostProcess(data)
  data.isDebug <- true
  dbgData(data)
  dbgShow(true)
  return true
}

local function mkSessionPath(sessionId, path = null) {
  path = path ?? cfg.savePath
  let parts = path.split("/")
  local filename = parts.pop()
  let idx = filename.indexof(".")
  if (idx == null)
    return $"{path}_{sessionId}"
  path = "/".join(parts)
  filename = "{0}_{1}{2}".subst(filename.slice(0, idx), sessionId, filename.slice(idx))
  return path == "" ? filename : $"{path}/{filename}"
}
let saveDebriefingBySession = @()
  saveDebriefing(mkSessionPath(cfg.state.data.value?.sessionId ?? "0"))

let loadSample = @(idx) loadDebriefing(cfg.samplePath[idx])

console_register_command(@() loadSample(0), "ui.debriefing_sample")
console_register_command(@() saveDebriefing(), "ui.debriefing_save")
console_register_command(@() loadDebriefing(), "ui.debriefing_load")
console_register_command(@() saveDebriefingBySession(), "ui.debriefing_save_by_session")
console_register_command(@(sessionId) loadDebriefing(mkSessionPath(sessionId)), "ui.debriefing_load_by_session")
console_register_command(@() dbgData(clone dbgData.value), "ui.debriefing_dbg_trigger")

let function saveToLog(dData) {
  if (dData?.isDebug)
    return
  let { sessionId = "0" } = dData
  let jsonstr = json.to_string(dData, true)
  log($"Debriefing for session {sessionId } json:\n======\n{jsonstr}======")
}

let function saveToFile(dData, path) {
  if (dData?.isDebug)
    return
  let { sessionId = "0" } = dData
  let sessionPath = mkSessionPath(sessionId, path)
  saveDebriefing(sessionPath)
  log($"Debriefing for session {sessionId } saved as {sessionPath}")
}

return {
  init = function(params) {
    cfg = cfg.__merge(params.filter(@(_value, key) key in cfg))
    for(local i = 1; i < cfg.samplePath.len(); i++) {
      let idx = i
      console_register_command(@() loadSample(idx), $"ui.debriefing_sample{idx+1}")
    }
  }
  saveDebriefingToFile = saveToFile
  saveDebriefingToLog = saveToLog
}
