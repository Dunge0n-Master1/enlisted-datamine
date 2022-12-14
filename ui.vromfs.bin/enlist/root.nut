#default:no-func-decl-sugar
#default:no-class-decl-sugar
#default:no-root-fallback
#default:explicit-this
#default:forbid-root-table

from "%enlSqGlob/ui_library.nut" import *
import "%dngscripts/ecs.nut" as ecs

ecs.clear_vm_entity_systems()

require("%enlist/getAppIdsList.nut").setAppIdsList([1131, 1132, 1168, 1178])
require("onScriptLoad.nut")

require("%sqstd/regScriptDebugger.nut")(debugTableData)



log($"loading enlist VM")

require("%ui/ui_config.nut")
require("voiceChat/voiceStateHandlers.nut")
require("%enlist/state/roomState.nut")
require("debriefing/debriefing_dbg.nut")

let friendlyErrorsBtn = require("friendly_logerr.ui.nut")
let { isNewDesign } = require("%enlSqGlob/designState.nut")
let { hotkeysButtonsBar } = isNewDesign.value
  ? require("%ui/hotkeysPanelBar.nut")
  : require("%ui/hotkeysPanel.nut")
let platform = require("%dngscripts/platform.nut")
let cursors = require("%ui/style/cursors.nut")
let {msgboxGeneration, getCurMsgbox} = require("components/msgbox.nut")
let {modalWindowsComponent} = require("%ui/components/modalWindows.nut")
let {isLoggedIn} = require("%enlSqGlob/login_state.nut")
let mainScreen = require("mainScreen.nut")
let {inspectorRoot} = require("%darg/helpers/inspector.nut")
let globInput = require("%ui/glob_input.nut")
let {DBGLEVEL} = require("dagor.system")
require("daRg.debug").requireFontSizeSlot(DBGLEVEL>0 && VAR_TRACE_ENABLED) //warning disable: -const-in-bool-expr
let {popupBlock} = require("%enlist/popup/popupBlock.nut")
let registerScriptProfiler = require("%sqstd/regScriptProfiler.nut")
let {underUiLayer, aboveUiLayer} = require("%enlist/uiLayers.nut")
let {safeAreaAmount,safeAreaVerPadding, safeAreaHorPadding} = require("%enlSqGlob/safeArea.nut")
let { fadeBlackUi } = require("fadeToBlack.nut")
let {getCurrentLoginUi, loginUiVersion} = require("login/currentLoginUi.nut")
let version_info = require("components/versionInfo.nut")
let {noServerStatus, saveDataStatus} = require("%enlist/mainMenu/info_icons.nut")
let speakingList = require("%ui/speaking_list.nut")


let {mkSettingsMenuUi, showSettingsMenu} = require("%ui/hud/menus/settings_menu.nut")
let emailLinkButton = require("mkLinkButton.nut")
let settingsMenuUi = mkSettingsMenuUi({
  onClose = @() showSettingsMenu(false)
  leftButtons = [ emailLinkButton ]
})
let {controlsMenuUi, showControlsMenu} = require("%ui/hud/menus/controls_setup.nut")
require("%enlist/options/onlineSaveDataHub.nut")

if (platform.is_xbox)
  require("%enlist/xbox/onLoadXbox.nut")
else if (platform.is_sony)
  require("%enlist/ps4/onLoadPs4.nut")


require("netUtils.nut")
require("autoexec.nut")
require("%enlSqGlob/charClient.nut")
require("%enlist/chat/chatState.nut").subscribeHandlers()
let {fpsBar, latencyBar} = require("%ui/fpsBar.nut")

let serviceInfo = !(platform.is_pc || DBGLEVEL > 0) ? null : {
  vplace = ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  gap = hdpx(2)
  children = [fpsBar, latencyBar]
}

registerScriptProfiler("enlist")

let underUi = @(){
  size = flex()
  watch = underUiLayer.generation
  children = underUiLayer.getComponents()
}

let aboveUi = @(){
  size = flex()
  watch = aboveUiLayer.generation
  children = aboveUiLayer.getComponents()
}

let msgboxesUI = @(){
  watch = msgboxGeneration
  children = getCurMsgbox()
}

let logerrsUi = @(){
  watch = safeAreaAmount
  halign = ALIGN_RIGHT
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER size = [sw(100)*safeAreaAmount.value, sh(100)*safeAreaAmount.value]
  children = friendlyErrorsBtn
}

let infoIcons = @(){
  margin = [max(safeAreaVerPadding.value/2.0,fsh(2)), max(safeAreaHorPadding.value/1.2,fsh(2))]
  watch = [safeAreaHorPadding, safeAreaVerPadding]
  children = [noServerStatus, saveDataStatus]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
}

let loginScreen = @(){
  watch = loginUiVersion
  children = getCurrentLoginUi()
  size = flex()
}

let function curScreen(){
  local children
  if (showSettingsMenu.value)
    children = settingsMenuUi
  else if (showControlsMenu.value)
    children = controlsMenuUi
  else if (isLoggedIn.value == false)
    children = loginScreen
  else
    children = mainScreen
  return {
    size = flex()
    onAttach = function(){
      log($"Enlist UI started")
    }
    watch = [isLoggedIn, showControlsMenu, showSettingsMenu]
    children = children
  }
}

return function Root() {
  return {
    cursor = cursors.normal
    watch = [ gui_scene.isActive ]
    children = !gui_scene.isActive.value ? null : [
      globInput, fadeBlackUi, underUi, curScreen, version_info, aboveUi, modalWindowsComponent,
      msgboxesUI, popupBlock, speakingList, logerrsUi, infoIcons, inspectorRoot, serviceInfo,
      hotkeysButtonsBar
    ]
  }
}

