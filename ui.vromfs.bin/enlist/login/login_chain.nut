from "%enlSqGlob/ui_library.nut" import *

let {get_time_msec} = require("dagor.time")
let {send_error_log} = require("clientlog")
let statsd = require("statsd")
let {get_circuit} = require("app")
let { gameLanguage } = require("%enlSqGlob/clientState.nut")
let {yup_version, exe_version} = require("%dngscripts/appInfo.nut")
let {platformId} = require("%dngscripts/platform.nut")
let logLogin = require("%enlSqGlob/library_logs.nut").with_prefix("[LOGIN_CHAIN]")

let stagesOrder = persist("stagesOrder", @() [])
let currentStage = mkWatched(persist, "currentStage", null)
let processState = persist("processState", @() {})
let globalInterrupted = mkWatched(persist, "interrupted", false)
let afterLoginOnceActions = persist("afterLoginOnceActions", @() [])

let STEP_CB_ACTION_ID = "login_chain_step_cb"

currentStage.subscribe(@(stage) logLogin($"Login stage -> {stage}"))

let stagesConfig = {}
let isStagesInited = Watched(false)
let stages = {}
local onSuccess = null //@(processState)
local onInterrupt = null //@(processState)
local startLoginTs = -1
let loginTime = mkWatched(persist, "loginTime", 0)

let function makeStage(stageCfg) {
  let res = {
    id = ""
    action = @(_state, cb) cb()
    actionOnReload = null
  }.__update(stageCfg)

  if (res.actionOnReload == null)
    res.actionOnReload = res.action
  return res
}
let persistActions = persist("persistActions", @() {})
let function makeStageCb() {
  let curStage = currentStage.value
  return @(result) persistActions[STEP_CB_ACTION_ID](curStage, result)
}

let reportLoginEnd = @(reportKey)
  statsd.send_profile("login_time", get_time_msec() - startLoginTs, {status=reportKey})

let function startStage(stageName) {
  currentStage(stageName)
  stages[stageName].action(processState, makeStageCb())
}

let function curStageActionOnReload() {
  stages[currentStage.value].actionOnReload(processState, makeStageCb())
}

let function startLogin(params) {
  assert(currentStage.value == null)
  assert(stagesOrder.len() > 0)

  processState.clear()
  processState.params <- params
  processState.stageResult <- {}
  processState.userInfo <- "userInfo" in params ? clone params.userInfo : {}

  startLoginTs = get_time_msec()
  globalInterrupted(false)

  startStage(stagesOrder[0])
}

let function fireAfterLoginOnceActions() {
  let actions = clone afterLoginOnceActions
  afterLoginOnceActions.clear()
  foreach (action in actions)
    action()
}

let function onStageResult(result) {
  let stageName = currentStage.value
  processState.stageResult[stageName] <- result
  if (result?.status != null)
    processState.status <- result.status

  let errorId = result?.error
  if (errorId != null) {
    processState.stageResult.error <- errorId
    statsd.send_counter("login_fail", 1, {error = errorId,
                                          login_stage = stageName} )
    logLogin("login failed {0}: {1}".subst(stageName, errorId))
    send_error_log("login_failed", {
      attach_game_log = true
      collection = "login_failures"
      meta = {
        project="enl"
        hint = "error"
        version = yup_version.value
        exe_version = exe_version.value
        platform = platformId
        language = gameLanguage
        circuit = get_circuit()
      }
    })
  }

  let needErrorMsg = result?.needShowError ?? true
  processState.stageResult.needShowError <- needErrorMsg

  foreach (key in ["quitBtn"])
    if (key in result)
      processState.stageResult[key] <- result[key]

  if (errorId != null || result?.stop == true || globalInterrupted.value == true) {
    processState.interrupted <- true
    currentStage(null)
    reportLoginEnd("failure")
    afterLoginOnceActions.clear()
    onInterrupt?(processState)
    return
  }

  let idx = stagesOrder.indexof(stageName)
  if (idx == stagesOrder.len() - 1) {
    loginTime.update(get_time_msec())
    currentStage(null)
    reportLoginEnd("success")
    onSuccess?(processState)
    fireAfterLoginOnceActions()
    return
  }

  startStage(stagesOrder[idx + 1])
}

persistActions[STEP_CB_ACTION_ID] <- function(curStage, result) {
  if (curStage == currentStage.value)
    onStageResult(result)
  else
    logLogin($"Receive cb from stage {curStage} but current is {currentStage.value}. Ignored.")
}

let function makeStages(config) {
  assert(currentStage.value == null || stages.len() == 0)

  let prevStagesOrder = clone stagesOrder
  stagesOrder.clear()
  stages.clear()

  foreach (stage in config.stages) {
    assert(("id" in stage) && ("action" in stage), " login stage must have id and action")
    assert(!(stage.id in stages), " duplicate stage id")
    stages[stage.id] <- makeStage(stage)
    stagesOrder.append(stage.id)
  }
  isStagesInited(stages.len() > 0)

  onSuccess = config.onSuccess
  onInterrupt = config.onInterrupt

  if (currentStage.value == null)
    return

  if (!isEqual(prevStagesOrder, stagesOrder)) {
    //restart login process
    logLogin("Full restart")
    currentStage(null)
    startLogin(processState?.params ?? {})
  }
  else {
    //continue login process
    logLogin($"Reload stage {currentStage.value}")
    curStageActionOnReload()
  }
}

let function setStagesConfig(config) {
  stagesConfig.__update(config)
  makeStages(config)
}

return {
  loginTime = loginTime
  currentStage = currentStage
  startLogin = startLogin
  interrupt = @() globalInterrupted(true)
  setStagesConfig = setStagesConfig //should be called on scripts load to correct continue login after reload scripts.
  isStagesInited = isStagesInited
  doAfterLoginOnce = @(action) afterLoginOnceActions.append(action) //only persist or native actions will work correct in all cases
}
