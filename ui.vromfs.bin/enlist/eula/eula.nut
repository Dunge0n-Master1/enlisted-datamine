from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let eulaLog = require("%enlSqGlob/library_logs.nut").with_prefix("[EULA]")
let colors = require("%ui/style/colors.nut")
let platform = require("%dngscripts/platform.nut")
let msgbox = require("%ui/components/msgbox.nut")
let {makeVertScroll, thinStyle} = require("%ui/components/scrollbar.nut")
let {safeAreaSize} = require("%enlist/options/safeAreaState.nut")
let {read_text_from_file, file_exists} = require("dagor.fs")
let json = require("%sqstd/json.nut")
let { gameLanguage } = require("%enlSqGlob/clientState.nut")
let JB = require("%ui/control/gui_buttons.nut")
let {hotkeysBarHeight} = require("%ui/hotkeysPanel.nut")

const NO_VERSION = -1

let json_load = @(file) json.load(file, { logger = eulaLog, load_text_file = read_text_from_file})

let function loadConfig(fileName) {
  let config = file_exists(fileName) ? json_load(fileName) : null
  local curLang = gameLanguage.tolower()
  if (!(curLang in config))
    curLang = "english"
  return {
    version = config?[curLang]?.version ?? NO_VERSION
    filePath = config?[curLang]?.file
  }
}

let eula = loadConfig("content/enlisted/eula/eula.json")
let nda = loadConfig("content/enlisted/nda/nda.json")

eulaLog("language:", gameLanguage)
eulaLog("eula config:", eula)
eulaLog("nda config:", nda)

local postProcessEulaText = @(text) text
if (platform.is_sony) {
  let ps4 = require("ps4")
  postProcessEulaText = function(text) {
    let regionKey = ps4.get_region() == ps4.SCE_REGION_SCEA ? "scea" : "scee"
    let regionText = loc($"sony/{regionKey}")
    return $"{text}{regionText}"
  }
}

let customStyleA = {hotkeys=[["^J:X | Enter | Space", {description={skip=true}}]]}
let customStyleB = {hotkeys=[["^Esc | {0}".subst(JB.B), {description={skip=true}}]]}

let function show(version, filePath, decisionCb) {
  if (version == NO_VERSION || filePath == null) {
    // accept if there is no EULA
    if (decisionCb)
      decisionCb(true)
    return
  }
  local eulaTxt = read_text_from_file(filePath)
  eulaTxt = postProcessEulaText("\x09".join(eulaTxt.split("\xE2\x80\x8B")))

  //!!FIX ME: better to count max height by msgBox self, and do not reserve place for buttons here
  let eulaSize = Computed(@() [safeAreaSize.value[0], safeAreaSize.value[1] - fsh(15) - hotkeysBarHeight.value])

  let eulaUiContent = @() {
    watch = [eulaSize]
    size = eulaSize.value
    children = makeVertScroll({
      size = [eulaSize.value[0], SIZE_TO_CONTENT]
      halign = ALIGN_LEFT
      children = {
        size = [eulaSize.value[0] - hdpx(20), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        color = colors.BtnTextNormal
        text = eulaTxt
      }.__update(sh(100) <= 720 ? h2_txt : body_txt)
    }, {
      size = SIZE_TO_CONTENT
      styling = thinStyle
      needReservePlace = false
      maxHeight = eulaSize.value[1]
      wheelStep = 30
    })
  }

  let eulaUi = {
    uid = "eula"
    content = eulaUiContent
  }

  if (decisionCb)
    eulaUi.buttons <- [
      {
        text = loc("eula/accept")
        isCurrent = true
        action = @() decisionCb(true)
        customStyle = customStyleA
      },
      {
        text = loc("eula/reject")
        isCancel = true
        action = @() decisionCb(false)
        customStyle = customStyleB
      }
    ]

  msgbox.showMessageWithContent(eulaUi)
}

let showEula = @(cb) show(eula.version, eula.filePath, cb)
let showNda = @(cb) show(nda.version, nda.filePath, cb)

console_register_command(@() showEula(@(a) log_for_user($"Result: {a}")), "eula.show")
console_register_command(@() showNda(@(a) log_for_user($"Result: {a}")), "nda.show")

return {
  showEula = showEula
  eulaVersion = eula.version
  showNda = showNda
  ndaVersion = nda.version
}
