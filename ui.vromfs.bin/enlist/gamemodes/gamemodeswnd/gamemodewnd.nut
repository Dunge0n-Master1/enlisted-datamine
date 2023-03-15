from "%enlSqGlob/ui_library.nut" import *

let { fontXLarge, fontSmall, fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { colPart, colFull, bigPadding, defTxtColor, titleTxtColor, midPadding, commonBorderRadius,
  selectedBgColor, smallPadding, transpPanelBgColor, commonWndPadding, navHeight
} = require("%enlSqGlob/ui/designConst.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { doesLocTextExist } = require("dagor.localize")
let faComp = require("%ui/components/faComp.nut")
let { blinkUnseen, unblinkUnseen, unseenPanel } = require("%ui/components/unseenComponents.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let isNewbie = require("%enlist/unlocks/isNewbie.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let { currentGameMode, setGameMode, mainModes, tutorialModes } = require("%enlist/gameModes/gameModeState.nut")
let { seenGamemodes, markSeenGamemode, markOpenedGamemodes
} = require("%enlist/gameModes/seenGameModes.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let crossplayIcon = require("%enlist/components/crossplayIcon.nut")
let { crossnetworkPlay, needShowCrossnetworkPlayIcon, CrossplayState
} = require("%enlSqGlob/crossnetwork_state.nut")
let msgbox = require("%ui/components/msgbox.nut")
let { scrollToCampaignLvl } = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { curSection, setCurSection } = require("%enlist/mainMenu/sectionsState.nut")
let { showVersionRestrictionMsgBox } = require("%enlist/restrictionWarnings.nut")
let { curBattleTutorial, curUnfinishedBattleTutorial, markCompleted
} = require("%enlist/tutorial/battleTutorial.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { hasCustomRooms, openCustomGameMode, openEventsGameMode, activeEvents
} = require("%enlist/gameModes/eventModesState.nut")
let { actualizeRoomCfg } = require("%enlist/gameModes/createEventRoomCfg.nut")
let { makeHorizScroll } = require("%ui/components/scrollbar.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { isLoggedIn } = require("%enlSqGlob/login_state.nut")
let { isInSquad, isLeavingWillDisbandSquad, leaveSquad, leaveSquadSilent
} = require("%enlist/squad/squadManager.nut")
let { mkColoredGradientY } = require("%enlSqGlob/ui/gradients.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { serverClusterBtn } = require("%enlist/gameModes/gameModesWnd/serverClusterUi.nut")
let { doubleSideHighlightLine, doubleSideBg } = require("%enlSqGlob/ui/defComponents.nut")


let fbImageByCampaign = {
  berlin = "ui/loading_berlin_26.avif"
  moscow = "ui/volokolamsk_village_01.avif"
  normandy = "ui/launcher_normandy_bg_2.avif"
}


let isTutorialsWndOpened = Watched(false)
let hasCrossplayDesc = Watched(true)
let isOpened = mkWatched(persist, "isOpened", false)
let defaultFbImage = Computed(@() fbImageByCampaign?[curCampaign.value]
  ?? "ui/volokolamsk_city_01.avif")
let defCustomGameImage = "ui/game_mode_moscow_solo.avif"

let titleTxtStyle = { color = titleTxtColor }.__update(fontXLarge)
let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let activeTxtStyle = { color = titleTxtColor }.__update(fontMedium)
let descTxtStyle = { color = titleTxtColor }.__update(fontSmall)


let gap = hdpx(32)
let cardSize = [colFull(4), colPart(7.516)]
let nameBlockSize = [colFull(4), colPart(1.322)]
let unseenPanelPos = [0, -colPart(0.709) - colPart(0.387)]
let cardDescritionHeight = cardSize[1] - nameBlockSize[1]

let nameBlockBgImg = mkColoredGradientY(0xFF444555, 0xFF181F34)
let activeNameBlockBgImg = mkColoredGradientY(0xFF5979B4, 0xFF2B2D44)


let defTutorialParams = Computed(@() {
  image = "ui/game_mode_tutorial_2.avif"
  id = "tutorials"
  title = loc("tutorials")
  description = loc("tutorials/desc")
  isAvailable = !isInSquad.value
  needShowCrossplayIcon = false
  isVersionCompatible = true
})


let close = function(){
  if (isTutorialsWndOpened.value)
    isTutorialsWndOpened(false)
  else
    isOpened(false)
}


let backBtn = Bordered(loc("gamemenu/btnBack"), close, { hotkeys = [[$"^{JB.B} | Esc"]] })
let topBlock = {
  size = [flex(), navHeight]
  valign = ALIGN_CENTER
  children = backBtn
}


let customGameMode = Computed(function() {
  if (!curBattleTutorial.value || !hasCustomRooms.value || isNewbie.value)
    return null

  let armyId = curArmy.value
  return {
    id = "customMatches"
    image = armiesPresentation?[armyId].customGameImage ?? defCustomGameImage
    title = loc("custom_matches")
    description = loc("custom_matches/desc")
    isAvailable = true
    needShowCrossplayIcon = true
    isVersionCompatible = true
    onClick = function() {
      openCustomGameMode()
      close()
    }
  }
})


let mkEventGameMode = @(event) {
  id = "events"
  image = event?.extraParams.imageGameMode ?? defCustomGameImage
  title = doesLocTextExist(event?.locId) ? loc(event.locId) : loc("events")
  description = loc(event?.descGameModeLocId ?? "events/descTitle")
  isAvailable = true
  needShowCrossplayIcon = true
  isVersionCompatible = true
  onClick = function() {
    openEventsGameMode()
    close()
  }
}


let mkImage = @(image, fbImage, isAvailable, sf) {
  size = flex()
  clipChildren = true
  children = {
    size = flex()
    rendObj = ROBJ_IMAGE
    keepAspect = KEEP_ASPECT_FILL
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    image = Picture(image)
    fallbackImage = Picture(fbImage)
  }.__update(isAvailable
    ? {
        transform = { scale = sf & S_HOVER ? [1.05, 1.05] : [1, 1] }
        transitions = [ { prop = AnimProp.scale, duration = 0.4, easing = OutQuintic } ]
      }
    : { picSaturate = 0.3, tint = Color(0, 0, 0, 128) })
}


let mkLevelLock = @(level){
  size = [flex(), colPart(0.333)]
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  pos = [0, -nameBlockSize[1] - smallPadding]
  children = level <= 0 ? null : [
    faComp("lock", {
      vplace = ALIGN_BOTTOM
      fontSize = activeTxtStyle.fontSize
      color = activeTxtStyle.color
    })
    {
      rendObj = ROBJ_TEXT
      text = loc("levelInfo", { level })
    }.__update(activeTxtStyle)
  ]
}


let descriptionBlock = @(text, sf) @() {
  watch = crossnetworkPlay
  size = [flex(), cardDescritionHeight]
  rendObj = ROBJ_SOLID
  color = transpPanelBgColor
  padding = [colPart(0.4), smallPadding]
  valign = ALIGN_BOTTOM
  transform = sf == 0 ? { translate = [0, cardSize[1]] } : { translate = [0, 0] }
  transitions = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutCubic}]
  children = {
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    halign = ALIGN_CENTER
    behavior = Behaviors.TextArea
    text
  }.__update(descTxtStyle)
}


let nameBlock = @(name, sf, isSelected = false) {
  rendObj = ROBJ_IMAGE
  size = [flex(), nameBlockSize[1]]
  image = isSelected || sf != 0 ? activeNameBlockBgImg : nameBlockBgImg
  valign = ALIGN_CENTER
  gap = midPadding
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = [flex(), SIZE_TO_CONTENT]
      text = name
      halign = ALIGN_CENTER
    }.__update(defTxtStyle)
  ]
}


let function mkCustomGameButton(modeCfg, hasSeen, animations) {
  let { image, title, id, onClick, description } = modeCfg
  return watchElemState(@(sf) {
    size = cardSize
    xmbNode = XmbNode()
    animations
    behavior = Behaviors.Button
    onClick
    function onHover(on) {
      if (!hasSeen)
        hoverHoldAction("unseenGamemode", id, @(id) markSeenGamemode(id))(on)
    }
    children = [
      mkImage(image, defCustomGameImage, true, sf)
      {
        flow = FLOW_VERTICAL
        size = flex()
        clipChildren = true
        children = [
          descriptionBlock(description, sf)
          nameBlock(utf8ToUpper(title), sf)
        ]
      }
      hasSeen ? null
        : unseenPanel(loc("unseen/gamemode"), { pos = unseenPanelPos})
    ]
  })
}

let function mkAnimations(idx, len) {
  let delay = idx * min(0.15, 0.9 / len)
  return [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, delay,
      play = true, easing = InOutCubic }
    { prop = AnimProp.translate, from = [sw(20), -fsh(5)], to = [0,0], duration = 0.4, delay,
      play = true, easing = InOutCubic }
    { prop = AnimProp.scale, from = [1.3, 1.3], to = [1,1], duration = 0.3, delay,
      play = true, easing = InOutCubic }
  ]
}

let mkTutorialsButton = @(unseenSign) watchElemState(function(sf) {
  let tutorialParams = defTutorialParams.value
  let { image, isAvailable, title, description } = tutorialParams
  return {
    watch = [isInSquad, defaultFbImage, defTutorialParams]
    size = cardSize
    xmbNode = XmbNode()
    animations = mkAnimations(0, 1)
    behavior = Behaviors.Button
    onClick = @() isTutorialsWndOpened(true)
    children = [
      mkImage(image, defaultFbImage.value, isAvailable, sf)
      {
        flow = FLOW_VERTICAL
        size = flex()
        clipChildren = true
        children = [
          descriptionBlock(description, sf)
          nameBlock(utf8ToUpper(title), sf)
        ]
      }
      {
        hplace = ALIGN_RIGHT
        children = unseenSign
      }
    ]
  }
})



let title = {
  size = [colFull(8), colPart(1.023)]
  hplace = ALIGN_CENTER
  margin = [colPart(1.61), 0 ,0,0 ]
  children = [
    doubleSideBg({
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc("change_mode"))
    }.__update(titleTxtStyle))
    doubleSideHighlightLine
    doubleSideHighlightLine({ vplace = ALIGN_BOTTOM })
  ]
}


let showLockedMsgBox = @(level) msgbox.show({
  text = loc("obtainAtLevel", { level })
  buttons = [
    { text = loc("Ok"), isCancel = true}
    { text = loc("GoToCampaign"), action = function() {
      scrollToCampaignLvl(level)
      setCurSection("SQUADS")
    }}
  ]
})

local gameModeOnClickAction = @(_gameMode) null

gameModeOnClickAction = function(gameMode) {
  let { id, isAvailable, isLocked, isLocal, lockLevel, isVersionCompatible } = gameMode

  if (!isAvailable) {
    if (isInSquad.value && isLocal)
      msgbox.show({
        text = loc("squad/leaveSquadQst")
        buttons = [
          { text = loc("Yes"),
            isCurrent = true,
            action = @() isLeavingWillDisbandSquad.value
              ? leaveSquadSilent(@() gameModeOnClickAction(gameMode))
              : leaveSquad(@() gameModeOnClickAction(gameMode))
          }
          { text = loc("Cancel"), isCancel = true}
        ]
      })
    return
  }

  if (!isVersionCompatible) {
    showVersionRestrictionMsgBox()
    return
  }

  if (isLocked){
    showLockedMsgBox(lockLevel)
    return
  }
  if (curUnfinishedBattleTutorial.value)
    markCompleted()

  setGameMode(id)
  close()
}


let selectedLine = {
  size = [flex(), colPart(0.06)]
  rendObj = ROBJ_BOX
  borderWidth = 0
  borderRadius = commonBorderRadius
  fillColor = selectedBgColor
  vplace = ALIGN_BOTTOM
  pos = [0, midPadding]
}


let function mkGameModeButton(gameMode, idx, hasSeen) {
  let isSelectedW = Computed(@() gameMode == currentGameMode.value)
  let xmbNode = XmbNode()

  let {
    id, image, fbImage, isAvailable, needShowCrossplayIcon,
    isLocked, lockLevel, description
  } = gameMode

  return watchElemState(function(sf) {
    let isSelected = isSelectedW.value
    let modesCount = isTutorialsWndOpened.value
      ? tutorialModes.value.len()
      : mainModes.value.len()

    let animations = mkAnimations(idx, modesCount)
    return {
      size = cardSize
      watch = [isSelectedW, defaultFbImage, crossnetworkPlay, isTutorialsWndOpened,
        tutorialModes, mainModes]
      function onHover(on) {
        if (on)
          hasCrossplayDesc(needShowCrossnetworkPlayIcon
            && needShowCrossplayIcon
            && crossnetworkPlay.value != CrossplayState.OFF)
        else
          hasCrossplayDesc(false)
        if (!hasSeen)
          hoverHoldAction("unseenGamemode", id, @(id) markSeenGamemode(id))(on)
      }
      function onAttach(){
        if (!isSelected)
          return
        if (isGamepad.value)
          move_mouse_cursor(id, false)
        gui_scene.setXmbFocus(xmbNode)
      }
      behavior = Behaviors.Button
      onClick = @() gameModeOnClickAction(gameMode)
      xmbNode
      key = id
      animations = animations
      children = [
        mkImage(image ?? defaultFbImage.value, fbImage ?? defaultFbImage.value,
          isAvailable && !isLocked, sf)
        mkLevelLock(lockLevel)
        {
          size = flex()
          flow = FLOW_VERTICAL
          clipChildren = true
          children = [
            descriptionBlock(description, sf)
            nameBlock(gameMode.title, sf, isSelected)
          ]
        }
        hasSeen ? null
          : unseenPanel(loc("unseen/gamemode"), { pos = unseenPanelPos})
        isSelected ? selectedLine : null
      ]
    }
  })
}


let tblScrollHandler = ScrollHandler()


let function gameModesList() {
  let seenGM = seenGamemodes.value?.seen
  let openedGM = seenGamemodes.value?.opened

  let hasUnseenTutorial = tutorialModes.value.findindex(@(m) m.id not in seenGM) != null
  let hasUnopenedTutorial = tutorialModes.value.findindex(@(m) m.id not in openedGM) != null
  let tutorialUnseen = !hasUnseenTutorial ? null
    : hasUnopenedTutorial ? unblinkUnseen
    : blinkUnseen

  let tutorialsToShow = tutorialModes.value
    .map(@(mode, idx) mkGameModeButton(mode, idx, seenGM?[mode?.id] ?? false))

  let tutorialsToMarkOpened = tutorialModes.value.map(@(m) m.id)
  let modesToMarkOpened = mainModes.value.map(@(m) m.id)
  let modes = mainModes.value
    .map(@(mode, idx) mkGameModeButton(mode, idx + 1, seenGM?[mode?.id] ?? false))
    .insert(0, mkTutorialsButton(tutorialUnseen))

  if (activeEvents.value.len() > 0) {
    let events = mkEventGameMode(activeEvents.value[0])
    modes.append(mkCustomGameButton(events,
      seenGM?[events?.id] ?? false,
      mkAnimations(modes.len(), modes.len() + 1)))
    modesToMarkOpened.append(events?.id)
  }

  let custGameMode = customGameMode.value
  if (custGameMode != null) {
    modes.append(mkCustomGameButton(custGameMode,
      seenGM?[custGameMode?.id] ?? false,
      mkAnimations(modes.len(), modes.len() + 1)))
    modesToMarkOpened.append(custGameMode?.id)
  }

  let modesOnScreen = isTutorialsWndOpened.value ? tutorialsToShow : modes
  let toMarkOpened = isTutorialsWndOpened.value
    ? tutorialsToMarkOpened
    : modesToMarkOpened

  gui_scene.setTimeout(0.1, @()
    markOpenedGamemodes(toMarkOpened.filter(@(m) m not in seenGamemodes.value?.opened)))
  return {
    size = flex()
    watch = [seenGamemodes, customGameMode, mainModes, tutorialModes,
      isTutorialsWndOpened, activeEvents]
    xmbNode = XmbContainer({
      canFocus = @() false
      scrollSpeed = 10.0
      isViewport = true
    })
    halign = ALIGN_CENTER
    children = [
      makeHorizScroll({
        onDetach = @() isTutorialsWndOpened(false)
        flow = FLOW_HORIZONTAL
        gap
        vplace = ALIGN_CENTER
        children = modesOnScreen.map(@(children) { children })
      }, {
        size = [SIZE_TO_CONTENT, flex()]
        scrollHandler = tblScrollHandler
        rootBase = class {
          key = "gameModesUnlocksRoot"
          behavior = Behaviors.Pannable
          wheelStep = 0.82
        }
      })
      isTutorialsWndOpened.value ? backBtn : null
    ]
  }
}


let function crossplayDescBlock() {
  let res = { watch = hasCrossplayDesc }
  if (!hasCrossplayDesc.value)
    return res
  return res.__update({
    size = [colFull(4), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = bigPadding
    children = [
      crossplayIcon({ iconSize = colPart(0.5) })
      {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("crossPlay/enabled/desc")
      }.__update(defTxtStyle)
    ]
  })
}


let serverBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  minWidth = SIZE_TO_CONTENT
  halign = ALIGN_CENTER
  children = serverClusterBtn
}

let bottomBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  vplace = ALIGN_BOTTOM
  children = [
    crossplayDescBlock
    serverBlock
  ]
}


let changeGameModeWnd = {
  size = flex()
  hplace = ALIGN_CENTER
  padding = commonWndPadding
  behavior = Behaviors.Button
  onClick = @() null
  children = [
    topBlock
    title
    gameModesList
    bottomBlock
  ]
}

isLoggedIn.subscribe(function(v) {
  if (v)
    actualizeRoomCfg()
})

isOpened.subscribe(function(v) {
  if (v) {
    actualizeRoomCfg()
    sceneWithCameraAdd(changeGameModeWnd, "researches")
  }
  else
    sceneWithCameraRemove(changeGameModeWnd)
})
if (isOpened.value)
  sceneWithCameraAdd(changeGameModeWnd, "researches")

curSection.subscribe(@(_) close())

return @() isOpened(true)