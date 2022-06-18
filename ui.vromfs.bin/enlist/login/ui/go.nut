from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let background = require("%enlist/login/ui/background.nut")
let {local_storage} = require("app")
let auth = require("auth")
let {get_time_msec} = require("dagor.time")
let urlText = require("%enlist/components/urlText.nut")
let { save_settings, get_setting_by_blk_path, set_setting_by_blk_path } = require("settings")

let textInput = require("%ui/components/textInput.nut")
let checkBox = require("%ui/components/checkbox.nut")
let progressText = require("%enlist/components/progressText.nut")
let textButton = require("%ui/components/textButton.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let {safeAreaBorders} = require("%enlist/options/safeAreaState.nut")
let {exitGameMsgBox} = require("%enlist/mainMsgBoxes.nut")
let { getCurMsgbox, msgboxGeneration } = require("%enlist/components/msgbox.nut")
let regInfo = require("reginfo.nut")
let supportLink = require("%enlist/login/ui/supportLink.nut")
let system = require("dagor.system")

let {isLoggedIn} = require("%enlSqGlob/login_state.nut")
let {startLogin, currentStage} = require("%enlist/login/login_chain.nut")
let loginDarkStripe = require("%enlist/login/ui/loginDarkStripe.nut")
let { loginBlockOverride, infoBlock } = require("%enlist/login/ui/loginUiParams.nut")
let { enlsitedLogo } = require("%enlist/login/loginPkg.nut")


let forgotPasswordUrl = get_setting_by_blk_path("forgotPasswordUrl") ?? "https://login.gaijin.net/ru/sso/forgot"
let forgotPassword  = urlText(loc("forgotPassword"), forgotPasswordUrl, {
  opacity = 0.7
  hplace = ALIGN_CENTER
  padding = hdpx(7)
}.__update(sub_txt))

const autologinBlkPath = "autologin"
let doAutoLogin = mkWatched(persist, "doAutoLogin", get_setting_by_blk_path(autologinBlkPath) ?? false)

const DUPLICATE_ACTION_DELAY_MSEC = 100 //actions can be pushed by loading or by long frame. In such case we do not want double login assert
let AFTER_ERROR_PROCESSED_ID = "after_go_login_error_processed"

let arg_login = system.get_arg_value_by_name("auth_login")
let arg_password = system.get_arg_value_by_name("auth_password")
let storedLogin = arg_login ? arg_login : local_storage.hidden.get_value("login")
let storedPassword = arg_password ? arg_password : local_storage.hidden.get_value("password")
let need2Step = mkWatched(persist, "need2Step", false)
local lastLoginCalled = - DUPLICATE_ACTION_DELAY_MSEC
local focusedFieldIdxBeforeExitMsg = -1

isLoggedIn.subscribe(@(_) need2Step(false))

let formStateLogin = Watched(storedLogin ?? "")
let formStatePassword = Watched(storedPassword ?? "")
let formStateTwoStepCode = Watched(system.get_arg_value_by_name("two_step") ?? "")
let formStateSaveLogin = Watched(storedLogin != null)
let formStateSavePassword = Watched(storedPassword != null)
let formStateFocusedFieldIdx = Watched(null)
let formStateAutoLogin = Watched(get_setting_by_blk_path(autologinBlkPath) ?? false)
let areInputsEmpty = Computed(function() {
  return formStateLogin.value == "" || formStatePassword.value == ""
})

formStateAutoLogin.subscribe(function(v) {
  set_setting_by_blk_path(autologinBlkPath, v)
  save_settings()
})
let function availableFields() {
  return [
    formStateLogin,
    formStatePassword,
    (need2Step.value ? formStateTwoStepCode : null),
    formStateSaveLogin,
    (formStateSaveLogin.value ? formStateSavePassword : null),
    formStateAutoLogin
  ].filter(@(val) val)
}


let function tabFocusTraverse(delta) {
  let tabOrder = availableFields()
  let curIdx = formStateFocusedFieldIdx.value
  if (curIdx==null)
    set_kb_focus(tabOrder[0])
  else {
    let newIdx = (curIdx + tabOrder.len() + delta) % tabOrder.len()
    set_kb_focus(tabOrder[newIdx])
  }
}
let persistActions = persist("persistActions", @() {})

persistActions[AFTER_ERROR_PROCESSED_ID] <- function(processState) {
  let status = processState?.status
  if (status == auth.YU2_2STEP_AUTH) {
    need2Step(true)
    formStateTwoStepCode("")
    set_kb_focus(formStateTwoStepCode)
  }
  else if (status == auth.YU2_WRONG_LOGIN) {
    set_kb_focus(formStateLogin)
    anim_start(formStateLogin)
  }
}
formStateLogin.subscribe(@(_) need2Step(false))
let function doPasswordLogin() {
  if (currentStage.value!=null) {
    log($"Ignore start login due current loginStage is {currentStage.value}")
    return
  }
  let curTime = get_time_msec()
  if (curTime < lastLoginCalled + DUPLICATE_ACTION_DELAY_MSEC) {
    log("Ignore start login due duplicate action called")
    return
  }

  lastLoginCalled = curTime
  local isValid = true
  foreach (f in availableFields()) {
    if (typeof(f.value)=="string" && !f.value.len()) {
      anim_start(f)
      isValid = false
    }
  }
  if (isValid) {
    let twoStepCode = need2Step.value ? formStateTwoStepCode.value : null
    startLogin({
      login_id = formStateLogin.value,
      password = formStatePassword.value,
      saveLogin = formStateSaveLogin.value,
      savePassword = formStateSavePassword.value && formStateSaveLogin.value,
      two_step_code = twoStepCode
      needShowError = @(processState) processState?.status != auth.YU2_2STEP_AUTH
      afterErrorProcessed = @(processState) persistActions[AFTER_ERROR_PROCESSED_ID](processState)
    })
  }
}

let function onMessageBoxChange(_) {
  if (!getCurMsgbox() && focusedFieldIdxBeforeExitMsg!=-1) {
    let fields = availableFields()
    if (focusedFieldIdxBeforeExitMsg in fields)
      set_kb_focus(fields[focusedFieldIdxBeforeExitMsg])
    focusedFieldIdxBeforeExitMsg = -1
  }
}

let function showExitMsgBox(){
  focusedFieldIdxBeforeExitMsg = formStateFocusedFieldIdx.value
  set_kb_focus(null)
  exitGameMsgBox()
}

let function makeFormItemHandlers(field, debugKey=null, idx=null) {
  return {
    onFocus = @() formStateFocusedFieldIdx.update(idx)
    onBlur = @() formStateFocusedFieldIdx.update(null)
    onEscape = @() showExitMsgBox()
    onAttach = function(elem) {
      if (getCurMsgbox() != null)
        return
      let focusOn = need2Step.value ? formStateTwoStepCode
            : ((formStatePassword.value=="" && formStateLogin.value!="") ? formStatePassword : formStateLogin)
      if (field == focusOn)
        set_kb_focus(elem)
    }

    onReturn = function() { log("Start Login from text field", debugKey); doPasswordLogin() }
  }
}


let function formText(field, options={}, idx=null) {
  return textInput.Underlined(field, options.__merge(makeFormItemHandlers(field, options?.title, idx)))
}

let capslockText = {rendObj = ROBJ_TEXT text=loc("capsLock") color = Color(50,200,255)}
let capsDummy = {rendObj = ROBJ_TEXT text=null}
let function capsLock() {
  let children = (gui_scene.keyboardLocks.value & KBD_BIT_CAPS_LOCK) ? capslockText : capsDummy
  return {
    watch = gui_scene.keyboardLocks
    size = SIZE_TO_CONTENT
    hplace = ALIGN_CENTER
    children = children
  }
}

let keyboardLangColor = Color(100,100,100)
let function keyboardLang(){
  local text = gui_scene.keyboardLayout.value
  if (type(text)=="string")
    text = text.slice(0,5)
  else
    text = ""
  return {
    watch = gui_scene.keyboardLayout
    rendObj = ROBJ_TEXT text=text color=keyboardLangColor  hplace=ALIGN_RIGHT vplace=ALIGN_CENTER padding=[0,hdpx(5),0,0]
  }
}

let function formPwd(field, options={}, idx=null) {
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          textInput.Underlined(field, options.__merge(makeFormItemHandlers(field, options?.debugKey, idx)))
          keyboardLang
        ]
      }
      capsLock
    ]
  }
}
let formCheckbox = @(field, options={}, idx=null) checkBox(field,
      options.title, makeFormItemHandlers(field, options?.title, idx))

let loginBtn = @(){
  watch = areInputsEmpty
  size = [flex(), SIZE_TO_CONTENT]
  children = textButton.Flat(loc("Login"),
    function() { log("Start Login by login btn"); doPasswordLogin() },
    { size = [flex(), hdpx(70)], halign = ALIGN_CENTER, margin = 0
      hotkeys = [["^J:Y", { description = { skip = true }}]]
    }.__update(
      h2_txt,
      textButton.loginBtnStyle.__update({
        style = {
          BgNormal = areInputsEmpty.value ? Color(99, 97, 98) : Color(230, 130, 0)
        }
    }))
  )
}

let hotkeysRootChild = {hotkeys = [["^Tab", @() tabFocusTraverse(1)], ["^L.Shift Tab | R.Shift Tab", @() tabFocusTraverse(-1)],
  ["^Esc", @() showExitMsgBox()]]}

let function loginOptions() {
  let res = [
    {t = formText, w = formStateLogin, p = {placeholder=loc("login (e-mail)"), inputType="mail", title="login", showPlaceHolderOnFocus=true}.__update(body_txt)},
    {t = formPwd, w = formStatePassword, p = {placeholder=loc("password"), password="\u2022", title="password", showPlaceHolderOnFocus=true}.__update(body_txt)},
    need2Step.value ? {t=formText, w = formStateTwoStepCode, p = { placeholder=loc("2 step code"), title="twoStepCode", showPlaceHolderOnFocus=true}.__update(body_txt)} : null,
    {t = formCheckbox, w = formStateSaveLogin, p = {title=loc("Store login (e-mail)")}},
    formStateSaveLogin.value ? {t = formCheckbox, w = formStateSavePassword, p = {title=loc("Store password (this is unsecure!)")}} : null
  ].filter(@(v) v!=null).map(@(v, idx) v.t(v.w, v.p, idx))
  res.append(forgotPassword)
  res.insert(0, regInfo)
  return res
}

let function createLoginForm() {
  return [
    @() {
      watch = [formStateSaveLogin, need2Step]
      flow = FLOW_VERTICAL
      size = flex()
      children = loginOptions()
    }
    @(){
      watch = currentStage
      vplace = ALIGN_BOTTOM
      halign = ALIGN_CENTER
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children = currentStage.value == null ? loginBtn : null
    }
    hotkeysRootChild
  ]
}

let coincidenceBlock = {
  rendObj = ROBJ_TEXTAREA
  size = [flex(), SIZE_TO_CONTENT]
  behavior = Behaviors.TextArea
  color = Color( 150, 150, 150)
  text = loc("coincidence")
}

let function loginRoot() {
  let children = (currentStage.value || isLoggedIn.value)
    ? [progressText(loc("loggingInProcess"))]
    : createLoginForm()
  return {
    watch = [currentStage, need2Step, formStateSaveLogin, isLoggedIn, loginBlockOverride]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    function onAttach() {
      msgboxGeneration.subscribe(onMessageBoxChange)
      if (doAutoLogin.value) {
        doAutoLogin(false)
        doPasswordLogin()
      }
    }
    function onDetach() {
       msgboxGeneration.unsubscribe(onMessageBoxChange)
    }
    children = children
  }.__update(loginBlockOverride.value)
}

let headerHeight = calc_comp_size({size=SIZE_TO_CONTENT children={margin = [fsh(1), 0] size=[0, fontH(100)] rendObj=ROBJ_TEXT}.__update(h2_txt)})[1]*0.75
let enterHandler = @(){
  hotkeys = [["^Enter", function() {
  if ((formStateLogin.value ?? "").len()>1 && (formStatePassword.value ?? "").len()>1)
    doPasswordLogin()
  }]]
}
return {
  size = flex()
  children = [
    background
    loginDarkStripe
    @() {
      watch = infoBlock
      flow = FLOW_VERTICAL
      hplace = ALIGN_RIGHT
      vplace = ALIGN_CENTER
      pos = [-sw(15), 0]
      children = [
        enlsitedLogo
        infoBlock.value
        enterHandler
        loginRoot
        supportLink
        coincidenceBlock
      ]
    }
    {
      size = [headerHeight, headerHeight]
      hplace = ALIGN_RIGHT
      margin = safeAreaBorders.value[1]
      children = fontIconButton("power-off", { onClick = showExitMsgBox })
    }
  ]
}

