from "%enlSqGlob/ui_library.nut" import *

let {sound_play} = require("%dngscripts/sound_system.nut")
let auth  = require("auth")
let msgbox = require("%enlist/components/msgbox.nut")
let urlText = require("%enlist/components/urlText.nut")
let {userInfoUpdate} = require("%enlSqGlob/userInfoState.nut")
let {getLoginActions} = require("loginActions.nut")
let {exit_game} = require("app")
let {readPermissions, readPenalties} = require("%enlSqGlob/permission_utils.nut")
let { remap_nick } = require("%enlSqGlob/remap_nick.nut")
let { isKZVersion } = require("chineseKongZhongVersion.nut")

let function onSuccess(state) {
  let authResult = state.stageResult.auth_result
  userInfoUpdate({
    userId = authResult.userId
    userIdStr = authResult.userId.tostring()
    name = authResult.name
    nameorig = (authResult?.nameorig ?? "") != "" ? authResult.nameorig : remap_nick(authResult.name)
    token = authResult.token
    tags = authResult?.tags ?? []
    permissions = readPermissions(state.stageResult?.char?.clientPermJwt, authResult.userId)
    penalties = readPenalties(state.stageResult?.char.penaltiesJwt, authResult.userId)
    penaltiesJwt = state.stageResult?.char.penaltiesJwt
    dedicatedPermJwt = state.stageResult?.char?.dedicatedPermJwt
    chardToken = state.stageResult?.char?.chard_token
    externalid = state.stageResult?.char?.externalid ?? []
  }.__update(state.userInfo))
  getLoginActions()?.onAuthComplete?.filter(@(v) type(v)=="function")?.map(@(action) action())
}

let function getErrorText(state) {
  if (!(state.params?.needShowError(state) ?? true))
    return null
  if (!state.stageResult?.needShowError)
    return null
  if ((state?.status ?? auth.YU2_OK) != auth.YU2_OK)
    return "{0} {1}".subst(loc("loginFailed/authError"), loc("responseStatus/{0}".subst(state.stageResult.error), state.stageResult.error))
  if ((state.stageResult?.char?.success ?? true) != true)
    return loc($"error/{state.stageResult.char.error}")
  let { errorStr = null } = state.stageResult
  if (errorStr != null)
    return errorStr
  let errorId = state.stageResult?.error
  if (errorId != null)
    return loc(errorId)
  return null
}

let function showStageErrorMsgBox(errText, state, mkChildren = @(defChild) defChild) {
  let afterErrorProcessed = state.params?.afterErrorProcessed
  if (errText == null) {
    afterErrorProcessed?(state)
    return
  }

  local urlObj = null
  let linkUrl = loc($"{state.stageResult.error}/link/url", "")
  let linkText = loc($"{state.stageResult.error}/link/text", "")
  if (linkUrl != "" && linkText != "") {
    urlObj = urlText(linkText, linkUrl)
  }

  sound_play("ui/enlist/login_fail")
  let msgboxParams = {
    text = errText,
    onClose = @() afterErrorProcessed?(state),
    children = mkChildren(urlObj)
  }

  let closeGameBtn = {
    text = loc("gamemenu/btnQuit")
    action = exit_game
    isCurrent = true
  }
  if (isKZVersion)
    msgboxParams.buttons <- [closeGameBtn]
  else if (state.stageResult?.quitBtn ?? false) {
    msgboxParams.buttons <- [
      {
        text = loc("mainmenu/btnClose")
      },
      closeGameBtn
    ]
  }

  msgbox.show(msgboxParams)
}

let onInterrupt = @(state) showStageErrorMsgBox(getErrorText(state), state)

return {
  onSuccess
  onInterrupt
  showStageErrorMsgBox
}
