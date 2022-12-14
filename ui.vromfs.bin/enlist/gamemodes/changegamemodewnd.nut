from "%enlSqGlob/ui_library.nut" import *

let { h1_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { doesLocTextExist } = require("dagor.localize")
let faComp = require("%ui/components/faComp.nut")
let { normUnseenNoBlink, normUnseenBlink } = require("%ui/components/unseenComps.nut")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let armiesPresentation = require("%enlSqGlob/ui/armiesPresentation.nut")
let isNewbie = require("%enlist/unlocks/isNewbie.nut")
let { titleTxtColor, maxContentWidth } = require("%enlSqGlob/ui/viewConst.nut")
let { txt, autoscrollText } = require("%enlSqGlob/ui/defcomps.nut")

let { isGamepad } = require("%ui/control/active_controls.nut")
let { sceneWithCameraAdd, sceneWithCameraRemove } = require("%enlist/sceneWithCamera.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let { safeAreaBorders, safeAreaSize } = require("%enlist/options/safeAreaState.nut")
let { currentGameMode, setGameMode, mainModes, tutorialModes } = require("gameModeState.nut")
let {
  seenGamemodes, markSeenGamemode, markOpenedGamemodes
} = require("seenGameModes.nut")
let { curCampaign } = require("%enlist/meta/curCampaign.nut")
let crossplayIcon = require("%enlist/components/crossplayIcon.nut")
let { crossnetworkPlay, needShowCrossnetworkPlayIcon, CrossplayState
} = require("%enlSqGlob/crossnetwork_state.nut")
let msgbox = require("%ui/components/msgbox.nut")
let { scrollToCampaignLvl } = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { curSection, jumpToArmyProgress } = require("%enlist/mainMenu/sectionsState.nut")
let { Alert } = require("%ui/style/colors.nut")
let { showVersionRestrictionMsgBox } = require("%enlist/restrictionWarnings.nut")
let {
  curBattleTutorial, curUnfinishedBattleTutorial, markCompleted
} = require("%enlist/tutorial/battleTutorial.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { hasCustomRooms, openCustomGameMode, openEventsGameMode, activeEvents
} = require("eventModesState.nut")
let { actualizeRoomCfg } = require("%enlist/gameModes/createEventRoomCfg.nut")
let { makeHorizScroll } = require("%ui/components/scrollbar.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let { isLoggedIn } = require("%enlSqGlob/login_state.nut")
let { isInSquad, isLeavingWillDisbandSquad, leaveSquad, leaveSquadSilent
} = require("%enlist/squad/squadManager.nut")

let { hasValidBalance } = require("%enlist/currency/currencies.nut")

let isTutorialsWndOpened = Watched(false)

let hoverColor = Color(240, 200, 100, 190)
let padding = hdpx(6)
let gap = hdpx(32)
let cardSize = [hdpx(296), hdpx(466)]
let nameBlockSize = [hdpx(296), hdpx(84)]
let nameBlockColor = Color(27, 33, 38)
let selAnimOffset = hdpx(9)
let infoMaxWidth = hdpx(500)

let fbImageByCampaign = {
  berlin = "ui/loading_berlin_26.jpg"
  moscow = "ui/volokolamsk_village_01.jpg"
  normandy = "ui/launcher_normandy_bg_2.jpg"
}

let defTutorialParams = Computed(@() {
  image = "ui/game_mode_tutorial_2.jpg"
  id = "tutorials"
  title = loc("tutorials")
  description = loc("tutorials/desc")
  isAvailable = !isInSquad.value
  isLocal = true
  needShowCrossplayIcon = false
  isVersionCompatible = true
})

let hoveredGameMode = Watched(null)
let isOpened = mkWatched(persist, "isOpened", false)
let defaultFbImage = Computed(@() fbImageByCampaign?[curCampaign.value] ?? "ui/volokolamsk_city_01.jpg")

let defCustomGameImage = "ui/game_mode_moscow_solo.jpg"

let close = function(){
  if (isTutorialsWndOpened.value)
    isTutorialsWndOpened(false)
  isOpened(false)
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
    isAvailable = hasValidBalance.value
    isLocal = false
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
  isAvailable = hasValidBalance.value
  isLocal = false
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
  flow = FLOW_HORIZONTAL
  gap = hdpx(10)
  valign = ALIGN_CENTER
  children = [
    faComp("lock", {
      vplace = ALIGN_BOTTOM
      fontSize = hdpx(20)
      color = titleTxtColor
    })
    txt({ text = loc("levelInfo", { level })}.__update(body_txt))
  ]
}

let nameBlockParams = {
  rendObj = ROBJ_SOLID
  size = [flex(), nameBlockSize[1]]
  padding = hdpx(16)
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  color = nameBlockColor
  flow = FLOW_VERTICAL
}

let function nameBlock(name, width, icon, color, lockLevel = 0) {
  local nameComp = txt({ text = name, color }.__update(body_txt))
  local flow = null

  if (calc_str_box(nameComp)[0] > (width - 2 * padding - (icon?.size[0] ?? 0))) {
    flow = FLOW_HORIZONTAL
    nameComp = autoscrollText({
      text = name
      textParams = { color }.__update(body_txt)
      params = { halign = ALIGN_CENTER }
    })
  }

  return {
    rendObj = ROBJ_SOLID
    size = nameBlockSize
    valign = ALIGN_CENTER
    children = [
      {
        flow
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          nameComp,
          {
            padding = [0, 0, 0, padding]
            hplace = ALIGN_RIGHT
            children = icon
          }
        ]
      }
      lockLevel > 0 ? mkLevelLock(lockLevel) : null
    ]
  }.__update(nameBlockParams)
}

let modeFrameParams = {
  rendObj = ROBJ_BOX
  padding = padding
  borderWidth = hdpx(1)
  fillColor = Color(50,50,50)
  behavior = Behaviors.Button
  transform = {}
}

let function mkCustomGameButton(modeCfg, hasSeen, animations) {
  let { image, title, id, onClick, isAvailable } = modeCfg
  return watchElemState(@(sf) {
    size = cardSize
    xmbNode = XmbNode()
    borderColor = sf & S_HOVER ? hoverColor : Color(80,80,80,80)
    borderWidth = sf & S_HOVER ? hdpx(2) : 0
    function onHover(on) {
      hoveredGameMode(on ? modeCfg : null)
      if (!hasSeen)
        hoverHoldAction("unseenGamemode", id, @(id) markSeenGamemode(id))(on)
    }
    onClick
    children = [
      mkImage(image, defCustomGameImage, isAvailable, sf)
      {
        size = nameBlockSize
        padding
        valign = ALIGN_CENTER
        children = {
          rendObj = ROBJ_TEXTAREA
          size = [flex(), SIZE_TO_CONTENT]
          behavior = Behaviors.TextArea
          text = utf8ToUpper(title)
          color = titleTxtColor
        }.__update(body_txt)
      }.__update(nameBlockParams)
      hasSeen ? null
        : {
            hplace = ALIGN_RIGHT
            children = normUnseenNoBlink
          }
    ]
    animations = animations
  }.__update(modeFrameParams))
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
  let { image, isAvailable } = tutorialParams
  return {
    watch = [isInSquad, defaultFbImage, defTutorialParams]
    size = cardSize
    xmbNode = XmbNode()
    borderColor = sf & S_HOVER ? hoverColor : Color(80,80,80,80)
    borderWidth = sf & S_HOVER ? hdpx(2) : 0
    onHover = @(on) hoveredGameMode(on ? tutorialParams : null)
    onClick = @() isTutorialsWndOpened(true)
    children = [
      mkImage(image, defaultFbImage.value, isAvailable, sf)
      {
        size = nameBlockSize
        padding
        valign = ALIGN_CENTER
        children = {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = utf8ToUpper(tutorialParams.title)
          color = titleTxtColor
        }.__update(body_txt)
      }.__update(nameBlockParams)
      {
        hplace = ALIGN_RIGHT
        children = unseenSign
      }
    ]
    animations = mkAnimations(0, 1)
  }.__update(modeFrameParams)
})

let closeBtn = closeBtnBase({ onClick = close })

let title = {
  rendObj = ROBJ_TEXT
  text = loc("change_mode")
  hplace = ALIGN_CENTER
  color = titleTxtColor
}.__update(h1_txt)

let selAnimDelay = 0.9
let selAnimDuration = 0.8
let mkSelectedFrame = @(size) {
  size
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
  opacity = 0
  rendObj = ROBJ_FRAME
  borderWidth = hdpx(4)
  transform = {}
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0.5, easing = CosineFull,
      delay = selAnimDelay, duration = selAnimDuration, play = true, loop = true }
    { prop = AnimProp.scale, from = [1, 1], to = size.map(@(v) (v + selAnimOffset).tofloat() / v), easing = OutCubic,
      delay = selAnimDelay, duration = selAnimDuration, play = true, loop = true }
  ]
}


let showLockedMsgBox = @(level)
  msgbox.show({
    text = loc("obtainAtLevel", { level })
    buttons = [
      { text = loc("Ok"), isCancel = true}
      { text = loc("GoToCampaign"), action = function() {
        scrollToCampaignLvl(level)
        jumpToArmyProgress()
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

let function mkGameModeButton(gameMode, idx, hasSeen) {
  let isSelectedW = Computed(@() gameMode == currentGameMode.value)
  let group = ElemGroup()
  let xmbNode = XmbNode()

  let {
    id, image, fbImage, isAvailable, isLocal, needShowCrossplayIcon, isLocked, lockLevel
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
        tutorialModes, mainModes, hasValidBalance]
      borderColor = sf & S_HOVER ? hoverColor : Color(80,80,80,80)
      borderWidth = (sf & S_HOVER) != 0 || isSelected ? hdpx(2) : 0

      function onAttach(){
        if (!isSelected)
          return
        if (isGamepad.value)
          move_mouse_cursor(id, false)
        gui_scene.setXmbFocus(xmbNode)
      }
      function onHover(on) {
        hoveredGameMode(on ? gameMode : null)
        if (!hasSeen)
          hoverHoldAction("unseenGamemode", gameMode.id,
            @(id) markSeenGamemode(id))(on)
      }
      onClick = @() gameModeOnClickAction(gameMode)

      xmbNode,
      group,

      children = [
        mkImage(image ?? defaultFbImage.value, fbImage ?? defaultFbImage.value,
          isAvailable && !isLocked && (isLocal || hasValidBalance.value), sf)
        nameBlock(
          gameMode.title,
          cardSize[0],
          needShowCrossnetworkPlayIcon
            && needShowCrossplayIcon
            && crossnetworkPlay.value != CrossplayState.OFF
              ? crossplayIcon({iconSize = hdpx(26), iconColor = titleTxtColor})
              : null,
          gameMode.isVersionCompatible ? titleTxtColor : Alert,
          isLocked ? lockLevel : 0
        )
        isSelected ? mkSelectedFrame(cardSize) : null
        hasSeen ? null
          : {
              hplace = ALIGN_RIGHT
              children = normUnseenNoBlink
            }
      ]

      key = id
      animations = animations
    }.__update(modeFrameParams)
  })
}

let tblScrollHandler = ScrollHandler()

let function gameModesList() {
  let seenGM = seenGamemodes.value?.seen
  let openedGM = seenGamemodes.value?.opened

  let hasUnseenTutorial = tutorialModes.value.findindex(@(m) m.id not in seenGM) != null
  let hasUnopenedTutorial = tutorialModes.value.findindex(@(m) m.id not in openedGM) != null
  let tutorialUnseen = !hasUnseenTutorial ? null
    : hasUnopenedTutorial ? normUnseenBlink
    : normUnseenNoBlink

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
        maxWidth = safeAreaSize.value[0]
        scrollHandler = tblScrollHandler
        rootBase = class {
          key = "gameModesUnlocksRoot"
          behavior = Behaviors.Pannable
          wheelStep = 0.82
        }
      })
      isTutorialsWndOpened.value ? Bordered(loc("BackBtn"), @() isTutorialsWndOpened(false), {
        vplace = ALIGN_BOTTOM
        hplace = ALIGN_LEFT
        hotkeys = [["^J:B", {description = "", action = @() isTutorialsWndOpened(false)}]]
      }) : null
    ]
  }
}

let infoText = @(override) {
  maxWidth = infoMaxWidth
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = titleTxtColor
  halign = ALIGN_CENTER
}.__update(body_txt, override)

let getVersionDescInfo =  @(gm) gm.isVersionCompatible ? null
  : infoText({ text = loc("msg/gameMode/unsupportedVersion"), color = Alert, halign = ALIGN_CENTER })

let mkInfo = @(gm) @() {
  watch = [crossnetworkPlay, hasValidBalance]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  rendObj = ROBJ_WORLD_BLUR_PANEL
  padding = fsh(1)

  children = [
    infoText({ text = utf8ToUpper(gm.title), color = titleTxtColor })
    !(hasValidBalance.value || gm.isLocal) ? infoText({ text = loc("gameMode/negativeBalance") })
      : gm.isAvailable ? infoText({ text = gm.description })
      : infoText({ text = loc("gameMode/onlineDenied") })
    getVersionDescInfo(gm)
    gm.isAvailable
    && needShowCrossnetworkPlayIcon
    && gm.needShowCrossplayIcon
    && crossnetworkPlay.value != CrossplayState.OFF
      ? {
          halight = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          children = [
            crossplayIcon({iconSize = hdpx(26)})
            infoText({ text = loc("crossPlay/enabled/desc") })
          ]
        }
      : null
  ]

  key = gm.id
  transform = {}
  animations = [
    { prop = AnimProp.translate,  from = [0,fsh(7)], to = [0, 0],       duration = 0.4, play = true, easing = OutQuintic }
    { prop = AnimProp.opacity,    from = 0,         to = 1,            duration = 0.4, play = true, easing = OutQuintic }
    { prop = AnimProp.scale,      from = [1.2,1.2], to = [1,1],        duration = 0.3, play = true, easing = OutQuintic }
    { prop = AnimProp.translate,  from = [0,0],     to = [0, -fsh(5)],  duration = 0.5, playFadeOut = true, easing = OutQuintic }
    { prop = AnimProp.opacity,    from = 1.0,       to = 0.0,          duration = 0.5, playFadeOut = true, easing = OutQuintic }
    { prop = AnimProp.scale,      from = [1,1],     to = [0.6,0.6],    duration = 0.3, playFadeOut = true, easing = OutQuintic }
  ]
}

let modeInfo = @() {
  watch = hoveredGameMode
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  margin = [0,0, gap, 0]
  children = hoveredGameMode.value == null ? null : mkInfo(hoveredGameMode.value)
}

let changeGameModeWnd = @() {
  watch = safeAreaBorders
  size = flex()
  hplace = ALIGN_CENTER
  maxWidth = maxContentWidth
  margin = safeAreaBorders.value
  padding = safeAreaBorders.value[0] == 0 ? [hdpx(20),0,0,0] : 0

  behavior = Behaviors.Button
  onClick = close

  children = [
    title
    gameModesList
    modeInfo
    closeBtn
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