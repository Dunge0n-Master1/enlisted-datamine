from "%enlSqGlob/ui_library.nut" import *

let { body_txt, giant_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { sound_play } = require("sound")
let { bigPadding, titleTxtColor, strokeStyle, accentTitleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let navState = require("%enlist/navState.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let { Bordered, PrimaryFlat } = require("%ui/components/textButton.nut")
let { primeDescBlock, mkDescBlock, mkBackWithImage, mkSquadBodyBig, mkPromoSquadIcon,
  mkUnlockInfo, mkPromoBackBtn, mkFullScreenBack
} = require("mkSquadPromo.nut")
let { btnSizeBig, receivedCommon, receivedFreemium
} = require("%enlist/soldiers/components/campaignPromoPkg.nut")
let mkBuyArmyLevel = require("mkBuyArmyLevel.nut")
let { squadsCfgById } = require("model/config/squadsConfig.nut")
let { openChooseSquadsWnd } = require("model/chooseSquadsState.nut")
let { curSection } = require("%enlist/mainMenu/sectionsState.nut")
let { curArmy, armySquadsById, curUnlockedSquads, selectArmy
} = require("model/state.nut")
let { curArmySquadsUnlocks, curUnlockedSquadId, curArmyNextUnlockLevel,
  scrollToCampaignLvl, curArmyLevel, curBuyLevelData
} = require("model/armyUnlocksState.nut")
let colorize = require("%ui/components/colorize.nut")
let { isTestDriveProfileInProgress, startSquadTestDrive
} = require("%enlist/battleData/testDrive.nut")
let spinner = require("%ui/components/spinner.nut")({ height = btnSizeBig[1] })
let { CAMPAIGN_NONE, isCampaignBought, disableArmyExp
} = require("%enlist/campaigns/campaignConfig.nut")

let viewData = Watched(null)
let isUnlockSquadSceneVisible = Watched(false)
let btnBlockHeight = hdpx(150)

let open = kwarg(
  function (armyId, unlockInfo, squadCfg, squad = null, isNewSquad = false) {
    viewData({ squad, armyId, unlockInfo, squadCfg, isNewSquad })
  })

let function close() {
  curUnlockedSquadId(null)
  viewData(null)
}

let function closeAndKeepLevel() {
  scrollToCampaignLvl(curArmyNextUnlockLevel.value)
  close()
}

let closeBtn = {
  padding = bigPadding
  hplace = ALIGN_RIGHT
  children = closeBtnBase({ onClick = closeAndKeepLevel })
}

let mkAnimationsList = @(delay, onEnter = null, onFinish = null) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = delay,
      play = true, easing = InOutCubic }
  { prop = AnimProp.opacity, delay = delay, from = 0, to = 1, duration = 0.9,
      play = true, easing = InOutCubic }
  { prop = AnimProp.scale, delay = delay, from = [3,3], to = [1,1], duration = 0.9,
      play = true, easing = InOutCubic }
  { prop = AnimProp.translate, delay = delay, from = [sh(30),-sh(10)], to = [0,0],
      duration = 0.9, play = true, easing = InOutCubic, onEnter = onEnter, onFinish = onFinish }
]

let newSquadReceivedText = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  vplace = ALIGN_CENTER
  color = titleTxtColor
  pos = [0,hdpx(150)]
  margin = [hdpx(80), 0, 0, hdpx(80)]
  text = "{0} \n {1}".subst(colorize(accentTitleTxtColor, loc("mainmenu/congratulations")), loc("squad/gotNewSquad"))
  transform = {}
  animations = mkAnimationsList(0, @() sound_play("ui/squad_unlock_text"),
    @() sound_play("ui/squad_unlock_text_2"))
}.__update(giant_txt, strokeStyle)

let function onManage() {
  if (viewData.value == null)
    return
  let { armyId, squadCfg } = viewData.value
  close()
  selectArmy(armyId)
  openChooseSquadsWnd(armyId, squadCfg.id, true)
}

let mkTestDriveButton = @(armyId, squadId) @() {
  watch = isTestDriveProfileInProgress
  size = btnSizeBig
  halign = ALIGN_CENTER
  children = isTestDriveProfileInProgress.value ? spinner
    : Bordered(loc("testDrive/squad"), @() startSquadTestDrive(armyId, squadId), {
        size = btnSizeBig
        margin = 0
        hotkeys = [[ "^J:X", { description = { skip = true }} ]]
      })
}

let function mkNewSquadButtons(squadId) {
  let isFirstSquad = Computed(@() curArmySquadsUnlocks.value?[0].unlockId == squadId)
  return @() {
    watch = isFirstSquad
    size = [btnSizeBig[0], SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    minHeight = btnBlockHeight
    valign = ALIGN_BOTTOM
    halign = ALIGN_CENTER
    gap = bigPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        color = titleTxtColor
        text = loc("squad/openManageRequest")
      }.__update(body_txt, strokeStyle)
      PrimaryFlat(loc("squads/squadManage"), onManage, {
        key = "SquadManageBtnInSquadPromo" //for tutorial
        size = btnSizeBig
        margin = 0
        hotkeys = [[ "^J:X | Enter", { description = {skip = true}} ]]
      })
      isFirstSquad.value ? null
        : Bordered(loc("squads/later"), closeAndKeepLevel, {
            size = btnSizeBig
            margin = 0
            hotkeys = [[ "^J:B | Esc", { description = {skip = true}} ]]
          })
    ]
    transform = {}
    animations = mkAnimationsList(0.7,  null, @() sound_play("ui/squad_unlock_buttons"))
  }
}

let function unlockSquadWnd() {
  if (viewData.value == null)
    return null

  let { armyId, unlockInfo, squadCfg, isNewSquad } = viewData.value
  let { isShowcase = false, isNextToBuyExp = false, unlockCb = null, unlockText = null,
    hasTestDrive = false, campaignGroup = CAMPAIGN_NONE } = unlockInfo
  let isFreemium = campaignGroup != CAMPAIGN_NONE
  let squadId = squadCfg.id

  let hasReceived = curUnlockedSquads.value.findvalue(@(s) s.squadId == squadId) != null

  let descBlock = isNewSquad ? newSquadReceivedText
    : isShowcase
      ? primeDescBlock(squadCfg)
    : mkDescBlock(squadCfg.announceLocId)

  let children = []
  if (isNewSquad)
    children.append(mkNewSquadButtons(squadId))
  else if (!hasReceived) {
    if (isNextToBuyExp || hasTestDrive)
      children.append(mkTestDriveButton(armyId, squadCfg.id))
    if (isNextToBuyExp) {
      if (!disableArmyExp.value)
        children.insert(0, mkBuyArmyLevel(curArmyLevel.value,
          curBuyLevelData.value?.cost,
          curBuyLevelData.value?.costFull))
    } else if (unlockCb != null
        && (!isFreemium || (disableArmyExp.value && isCampaignBought.value)))
      children.append(PrimaryFlat(
        unlockText ?? loc("squads/receive"),
        unlockCb,
        {
          margin = 0
          stopHover = true
          size = btnSizeBig
          hotkeys = [[ "^J:X | Enter", { description = {skip = true}} ]]
        }))
    else if (unlockText != null)
      children.append(mkUnlockInfo(unlockText, { size = btnSizeBig }))
    children.append(mkPromoBackBtn(close))
  } else
    children.append(mkPromoBackBtn(close))

  let buttons = children.len() <= 1 ? children?[0] : {
    flow = FLOW_VERTICAL
    minHeight = btnBlockHeight
    gap = bigPadding
    vplace = ALIGN_BOTTOM
    valign = ALIGN_BOTTOM
    children
  }
  let isPrimeSquad = (squadCfg?.battleExpBonus ?? 0.0) > 0.0

  return {
    key = "unlockSquadScene" //for tutorial
    watch = [viewData, curArmyNextUnlockLevel, curArmyLevel, curBuyLevelData,
      armySquadsById, disableArmyExp, isCampaignBought]
    onAttach = @() isUnlockSquadSceneVisible(true)
    onDetach = @() isUnlockSquadSceneVisible(false)
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    size = flex()
    vplace = ALIGN_CENTER
    children = {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      size = flex()
      color = Color(150,150,150,255)
      children = mkFullScreenBack(
        mkBackWithImage(squadCfg?.image, !hasReceived, false),
        [
          mkSquadBodyBig(squadCfg.__merge({
            armyId, isPrimeSquad = isPrimeSquad || isShowcase, hasReceived, isFreemium
          }), descBlock, buttons)
          mkPromoSquadIcon(squadCfg?.icon, !hasReceived)
          !hasReceived ? null
            : isFreemium ? receivedFreemium(campaignGroup)
            : receivedCommon
          isNewSquad ? null : closeBtn
        ]
      )
    }
  }
}

if (viewData.value != null)
  navState.addScene(unlockSquadWnd)

curUnlockedSquadId.subscribe(
  function(squadId) {
    if (squadId == null)
      return

    let armyId = curArmy.value
    let squad = armySquadsById.value?[armyId][squadId]
    let squadCfg = squadsCfgById.value?[armyId][squadId]
    if (squad == null || squadCfg == null)
      return

    viewData({
      armyId, squad, squadCfg, unlockInfo = null, isNewSquad = true
    })
  }
)

viewData.subscribe(
  function(val) {
    if (val)
      navState.addScene(unlockSquadWnd)
    else
      navState.removeScene(unlockSquadWnd)
  }
)

curSection.subscribe(@(_) close() )

return {
  openUnlockSquadScene = open
  closeUnlockSquadScene = close
  isUnlockSquadSceneVisible
  unlockSquadViewData = Computed(@() viewData.value)
}
