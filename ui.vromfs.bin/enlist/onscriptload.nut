from "%enlSqGlob/ui_library.nut" import *

require("%enlSqGlob/register_sqevents.nut")
set_nested_observable_debug(VAR_TRACE_ENABLED)
require("%enlSqGlob/ui/styleUpdate.nut")
require("notifications.nut")
require("currency/currenciesList.nut")
require("sections.nut")
require("scene/scene_control.nut")
require("soldiers/selectItemScene.nut")
require("campaigns/selectCampaignArmyScene.nut")
require("meta/profileServer.nut")
require("meta/profileRefresh.nut")
require("meta/dumpStats.nut")
require("faceGen.nut")
require("battleData/sendSoldiersData.nut")
require("battleData/mkDefaultProfile.nut")
require("battleData/singleMissionRewardId.nut")
require("battleData/applyBattleExp.nut")
let { setMainMenuComp } = require("%enlist/mainMenu/mainMenuComp.nut")
let mainMenu = require("%enlist/mainMenu/mainMenu.nut")
setMainMenuComp(mainMenu)
require("notifications/mainMenuDescription.nut")
require("notifications/premiumExpiration.nut")
require("notifications/memberLockedCampaign.nut")
require("notifications/unlockRewardCampaignNotification.nut")
require("notifications/newSquadReceivedNotification.nut")
require("notifications/serviceNotificationMonitor.nut")
require("notifications/updateGameNotify.nut")
require("%enlSqGlob/configs/configs.nut")
require("%enlist/login/initLogin.nut")
require("login/initLoginStages.nut")
require("squad/myExtData.nut")
require("soldiers/choosePerkWnd.nut")
require("%enlist/currency/initPurchaseActions.nut")
require("soldiers/chooseSquadsScene.nut")
require("soldiers/chooseSoldiersScene.nut")
require("soldiers/notReadySquadsMsg.nut")
require("%ui/complaints/complain.nut")
require("%enlist/tutorial/ordersTutorial.nut")
require("%enlist/tutorial/squadTutorialsMsg.nut")
require("%enlist/guidelinesPopup.nut")
require("%enlist/shop/shopResultMsgbox.nut")
require("%enlist/tutorial/tutorialWnd.nut")
require("%enlist/tutorial/newSquadByArmyLevelTutorial.nut")
require("%enlSqGlob/ui/webHandlers/webHandlers.nut")
require("%enlSqGlob/ui/weGameHandlers/weGameHandlers.nut")
require("battlepass/debugBpRewardsView.nut")
require("unlocks/dailyRewardsUi.nut")
require("gameModes/eventModesWindow.nut")
require("gameModes/createEventRoomWnd.nut")
require("leaderboard/leaderboardWnd.nut")
require("%enlist/profile/profileScene.nut")
require("%enlist/profile/unseenProfileStuffs.nut")
require("%enlist/contacts/externalIdsManager.nut")
require("%enlist/soldiers/soldierCustomizationScene.nut")
require("%enlist/usermail/usermailScene.nut")
require("%enlist/vehicles/selectVehicleScene.nut")
require("%enlist/vehicles/customizeScene.nut")
require("%enlist/soldiers/model/console_cmd.nut")

let { setMenuOptions, menuTabsOrder } = require("%ui/hud/menus/settings_menu_state.nut")
let { violenceOptions } = require("%ui/hud/menus/options/violence_options.nut")
let planeContolOptions = require("%ui/hud/menus/options/plane_control_options.nut")
let { cameraShakeOptions } = require("%ui/hud/menus/options/camera_shake_options.nut")
let { hudOptions } = require("%ui/hud/menus/options/hud_options.nut")
let { optXboxGraphicsPreset, dbgConsolePreset }  = require("%ui/hud/menus/console_preset_options.nut")
let { renderOptions } = require("%ui/hud/menus/options/render_options.nut")
let { soundOptions } = require("%ui/hud/menus/options/sound_options.nut")
let { cameraFovOption } = require("%ui/hud/menus/options/camera_fov_option.nut")
let { voiceChatOptions } = require("%ui/hud/menus/options/voicechat_options.nut")
let { crossnetworkOptions } = require("%enlist/options/crossnetwork_options.nut")
let { optGraphicsQualityPreset }  = require("%ui/hud/menus/quality_preset_option.nut")
let { vehicleCameraFovOption } = require("%ui/hud/menus/vehicle_camera_fov_option.nut")
let { vehicleCameraFollowOption } = require("%ui/hud/menus/vehicle_camera_follow_option.nut")
let { leaderboardOptions } = require("%ui/hud/menus/options/leaderboard_options.nut")
let narratorOptions = require("%ui/hud/menus/options/narrator_options.nut")
let platform = require("%dngscripts/platform.nut")

let {get_time_msec} = require("dagor.time")


let options = []
if (platform.is_xbox_scarlett || dbgConsolePreset.value == "xbox_scarlett")
  options.append(optXboxGraphicsPreset)
// This is not used anymore, but I expect to make use of it again on PS5 when we add 120 FPS mode so keeping it for now
// else if (platform.is_ps5 || dbgConsolePreset.value == "ps5")
//   options.append(optPSGraphicsPreset)
else
  options.append(optGraphicsQualityPreset)

options.append(cameraFovOption, vehicleCameraFovOption, vehicleCameraFollowOption)
  .extend(
    renderOptions, soundOptions, voiceChatOptions, cameraShakeOptions, violenceOptions, planeContolOptions,
    crossnetworkOptions, leaderboardOptions, hudOptions, narratorOptions
  )

setMenuOptions(options)

menuTabsOrder([
  {id = "Graphics", text=loc("options/graphicsParameters")},
  {id = "Sound", text = loc("sound")},
  {id = "Game", text = loc("options/game")},
  {id = "VoiceChat", text = loc("controls/tab/VoiceChat")},
])

// FIXME it's just quick and dirty fix. autoSquad parameter should be moved otside of general
// squadState and passed to quickMatchQueue as project specific argument
require("%enlist/squad/squadState.nut").autoSquad(null)
require("backgroundContentUpdater.nut")

let quickMatchQueueInfoCmp = require("queueWaitingInfo.ui.nut")
let {aboveUiLayer} = require("%enlist/uiLayers.nut")
aboveUiLayer.add(quickMatchQueueInfoCmp, "quickMatchQueue")

let { matchRandomTeam } = require("%enlist/quickMatch.nut")
let { curArmy, selectArmy } = require("soldiers/model/state.nut")
let { isEventModesOpened, selCustomRoomsMode, isCustomRoomsMode } = require("gameModes/eventModesState.nut")
let { curCampaign, setCurCampaign } = require("%enlist/meta/curCampaign.nut")

let { throttle } = require("%sqstd/timers.nut")
let { changelogDisabled, haveUnseenVersions, requestPatchnotes,
  patchnotesReceived, maxVersionInt } = require("changeLogState.nut")
let {openChangelog} = require("openChangelog.nut")

let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let patchnote = persist("patchnote", @() { cachedUpdatedVersion = -1, timeShown = -1, requestMadeTime = -1 })
let { unlockProgress } = require("%enlSqGlob/userstats/unlocksState.nut")

const MIN_SEC_BETWEEN_REQUESTS = 10 //10 seconds
let checkVersionAndReqPatchnotes = throttle(function(...){
  if (!isInBattleState.value
      && maxVersionInt.value >= 0
      && maxVersionInt.value > patchnote.cachedUpdatedVersion
    ) {
    requestPatchnotes()
    patchnote.cachedUpdatedVersion = maxVersionInt.value
    patchnote.requestMadeTime = get_time_msec()
  }
}, MIN_SEC_BETWEEN_REQUESTS, {leading=true, trailing=false})
checkVersionAndReqPatchnotes()
gui_scene.setInterval(301, checkVersionAndReqPatchnotes) //check version each 10minutes in menu
isInBattleState.subscribe(checkVersionAndReqPatchnotes) //check versions after returning from Battle

let needShowPatchnote = keepref(Computed(@() patchnotesReceived.value
  && haveUnseenVersions.value
  && unlockProgress.value.len() > 0 //received any progress
  && (unlockProgress.value?["not_a_new_player_unlock"].isCompleted ?? false)
  && patchnote.timeShown != patchnote.requestMadeTime
))

if (!changelogDisabled)
  needShowPatchnote.subscribe(function(v) {
    if (!v)
      return
    openChangelog()
    patchnote.timeShown = patchnote.requestMadeTime
  })

let leaveQueueNotification = require("notifications/leaveQueueNotification.nut")
leaveQueueNotification({
  watch = curCampaign
  setValue = setCurCampaign
})
leaveQueueNotification({
  watch = curArmy
  setValue = selectArmy
  askLeave = @() !matchRandomTeam.value
})
leaveQueueNotification({
  watch = isEventModesOpened
})
leaveQueueNotification({
  watch = isCustomRoomsMode
  setValue = selCustomRoomsMode
})

let dCtorBase = require("%enlist/debriefing/debriefingCtor.nut")
let debriefingState = require("%enlist/debriefing/debriefingStateInMenu.nut")
require("%enlist/debriefing/debriefingInMenu.nut")(dCtorBase, debriefingState)

let fonts = require("%enlSqGlob/ui/fonts_style.nut")
require("%enlist/components/fontsDebugWnd.nut")(fonts)
let debriefingDbg = require("%enlist/debriefing/debriefing_dbg.nut")
debriefingDbg.init({
  state = debriefingState
  samplePath = ["../prog/enlisted/enlist/debriefing/samples/debriefing_sample.json",
                "../prog/enlisted/enlist/debriefing/samples/debriefing_sample2.json"]
  savePath = "debriefing_enlisted.json"
  loadPostProcess = function(debrData) {
    if (typeof debrData?.players != "table")
      return

    let players = {}
    foreach(id, player in debrData.players)
      players[id.tointeger()] <- player
    debrData.players = players
  }
})

let { removeAllMsgboxes } = require("%ui/components/msgbox.nut")
isInBattleState.subscribe(function(v) {
  if (v)
    removeAllMsgboxes()
})

if (platform.is_sony)
  require("%enlist/ps4/supportedPlatforms.nut")(["PS4", "PS5"])

console_register_command(@(trigger) anim_start(trigger), "anim.start")
console_register_command(@(trigger) anim_request_stop(trigger), "anim.stop")
console_register_command(@(trigger) anim_skip(trigger), "anim.skip")
console_register_command(@(trigger) anim_skip_delay(trigger), "anim.skipDelay")
