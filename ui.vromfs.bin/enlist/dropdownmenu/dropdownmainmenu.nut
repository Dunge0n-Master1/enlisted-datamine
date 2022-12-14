from "%enlSqGlob/ui_library.nut" import *

let { isNewDesign, hasToggleDesign } = require("%enlSqGlob/designState.nut")
let mkDropMenuBtn = require("%enlist/dropdownmenu/mkDropDownMenuBlock.nut")
let {
  btnOptions, btnControls, btnExit, btnLogout, SEPARATOR, btnGSS, btnSupport, btnToggleDesign
} = require("%enlist/mainMenu/defMainMenuItems.nut")
let { openChangelog } = require("%enlist/openChangelog.nut")
let { isInQueue } = require("%enlist/state/queueState.nut")
let { customGamesOpen } = require("%enlist/mpRoom/customGamesWnd.nut")
let debugProfileWnd = require("%enlist/mainMenu/debugProfileWnd.nut")
let debugConfigsWnd = require("%enlist/mainMenu/debugConfigsWnd.nut")
let {hasClientPermission} = require("%enlSqGlob/client_user_rights.nut")
let { DBGLEVEL } = require("dagor.system")
let { get_circuit, app_set_offline_mode } = require("app")
let { is_sony, is_xbox, is_console } = require("%dngscripts/platform.nut")
let openUrl = require("%ui/components/openUrl.nut")
let qrWindow = require("%enlist/mainMenu/qrWindow.nut")
let { enlistedForumUrl, feedbackUrl } = require("%enlSqGlob/supportUrls.nut")
let { hasCampaignSelection }  = require("%enlist/campaigns/campaign_sel_state.nut")
let campaignSelectWnd = require("%enlist/campaigns/campaign_select_wnd.nut")
let { changelogDisabled } = require("%enlist/changeLogState.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { doesLocTextExist } = require("dagor.localize")
let gameLauncher = require("%enlist/gameLauncher.nut")
let { isReplayTabHidden } = require("%enlist/replay/replaySettings.nut")
let profileScene = require("%enlist/profile/profileScene.nut")

let noSandboxEditorInMenu = true
let function startSandBoxEditor() {
  app_set_offline_mode(true)
  gameLauncher.startGame({
      game = "enlisted", scene = "gamedata/scenes/sandbox_editor_start.blk", modId = "sandboxEditor"
  })
}

let btnChangeCampaign = {
  id = "ChangeCamppaign"
  name = loc("btn/changeCampaign")
  cb = @() campaignSelectWnd.open()
}

let btnCustomGames = {
  id  = "CustomGames"
  name = loc("Custom games")
  cb = customGamesOpen
}

let btnChangelog = changelogDisabled ? null : {
  id = "Changelog"
  name = loc("gamemenu/btnChangelog")
  cb = openChangelog
}

let gameStoryMsg = doesLocTextExist("gameStoryMsg") ? loc("gameStoryMsg") : ""
let btnShowGameStory = gameStoryMsg == "" ? null : {
  id = "GameStory"
  name = loc("gamemenu/btnGameStory")
  cb = @() showMsgbox({ text = gameStoryMsg })
}

let btnDebugProfile = {
  id = "DebugProfile"
  name = loc("Debug Profile")
  cb = debugProfileWnd
}

let btnDebugConfigs = {
  id = "DebugConfigs"
  name = loc("Debug Configs")
  cb = debugConfigsWnd
}

let btnForum = enlistedForumUrl == "" ? null : {
  id = "Forum"
  name = loc("forum")
  cb = !is_xbox ? @() openUrl(enlistedForumUrl)
    : @() qrWindow({url = enlistedForumUrl, header = loc("forum")})
}

let btnFeedback = feedbackUrl == "" ? null : {
  id = "Feedback"
  name = loc("feedback", "Feedback")
  cb = @() openUrl(feedbackUrl)
}

let btnSandboxEditor = {
  id = "SandboxEditor"
  name = loc("Sandbox Editor")
  cb = startSandBoxEditor
}

let btnReplays = {
  id = "replay"
  name = loc("replay/records")
  cb = @() profileScene("replay")
}

let needCustomGames = (DBGLEVEL > 0
  || ["moon","sun","ganymede","yueliang"].indexof(get_circuit()) != null)
    ? Computed(@() !isInQueue.value)
    : Watched(false)
let serverDataPermission = hasClientPermission("debug_server_data")
let canDebugProfile = Computed(@() DBGLEVEL > 0
  || serverDataPermission.value)

let function buttons(){
  let res = []
  if (needCustomGames.value) {
    res.append(btnCustomGames)
    if (!is_console && !noSandboxEditorInMenu)
      res.append(btnSandboxEditor)
  }
  res.append(btnShowGameStory)
  res.append(btnChangelog)
  if (!isReplayTabHidden.value)
    res.append(btnReplays)
  if (res.len() > 0)
    res.append(SEPARATOR)
  if (hasCampaignSelection.value)
    res.append(btnChangeCampaign)
  res.append(btnOptions, btnControls, btnSupport, btnForum, btnFeedback, btnGSS)
  if (hasToggleDesign.value)
    res.append(btnToggleDesign)
  if (is_xbox){
    res.append(btnLogout)
  } else if (!is_sony){
    res.append(btnExit)
  }
  if (canDebugProfile.value)
    res.append(SEPARATOR, btnDebugProfile, btnDebugConfigs)
  return res.filter(@(v) v!=null)
}
let watch = [needCustomGames, hasCampaignSelection, canDebugProfile, isReplayTabHidden, hasToggleDesign, isNewDesign]

return mkDropMenuBtn(buttons, watch)
