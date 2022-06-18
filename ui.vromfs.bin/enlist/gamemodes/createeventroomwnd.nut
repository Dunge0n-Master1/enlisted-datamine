from "%enlSqGlob/ui_library.nut" import *
from "createEventRoomState.nut" import *
let { sub_txt, body_txt, h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { logerr } = require("dagor.debug")
let { bigPadding, blurBgColor, defInsideBgColor, defTxtColor, accentColor,
  blurBgFillColor, smallPadding, activeTxtColor, commonBtnHeight,
  smallOffset
} = require("%enlSqGlob/ui/viewConst.nut")
let { chooseRandom } = require("%sqstd/rand.nut")
let { arrayByRows } = require("%sqstd/underscore.nut")
let {addModalWindow, removeModalWindow} = require("%darg/components/modalWindows.nut")
let closeBtn = require("%ui/components/closeBtn.nut")
let textInput = require("%ui/components/textInput.nut")
let spinnerList = require("%ui/components/spinnerList.nut")
let { mkWindowHeader, txtColor } = require("eventModesPkg.nut")
let textButton = require("%ui/components/textButton.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(80) })
let { localGap, localPadding, rowHeight } = require("eventModeStyle.nut")
let mkOptionRow = require("components/mkOptionRow.nut")
let mkWindowTab = require("%enlist/components/mkWindowTab.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let {sound_play} = require("sound")
let faComp = require("%ui/components/faComp.nut")
let { getImagesFromMissions } = require("%enlSqGlob/ui/missionsPresentation.nut")
let getMissionInfo = require("getMissionInfo.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { smallCampaignIcon } = require("roomsPkg.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { lobbyPresets, openSaveWindow, openChooseWindow
} = require("%enlist/mpRoom/saveChooseLobbySettings.nut")
let { updateModList, modPath, receivedModInfos, allowChooseCampaign
} = require("sandbox/customMissionState.nut")
let openCustomMissionWnd = require("sandbox/customMissionWnd.nut")
let { isXboxOne, isPS4, is_console } = require("%dngscripts/platform.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let { showModsInCustomRoomCreateWnd } = require("%enlist/featureFlags.nut")
let { isModsAvailable } = require("createEventRoomCfg.nut")

const WND_UID = "editEventGm"
let maxWndWidth = sw(95)
let wndHeight = hdpx(700)
let scrollWidth = hdpx(2)
let btnWidth = hdpx(400)
let infoRowsToShow = 3
let optionsWidth = hdpx(750)
let campaignsBlockWidth = hdpx(456)
let missionsCardWidth = hdpx(392)
let missionsBlockHeight = hdpx(550)
let missionsCardHeight = hdpx(234)
let campaignBlockWithPaddings = campaignsBlockWidth + localPadding * 3 + scrollWidth
let maxMissionsBlockWidth = maxWndWidth - campaignBlockWithPaddings
let maxMissionsCardsPerRaw = ((maxMissionsBlockWidth + localGap) / (missionsCardWidth + localGap)).tointeger()
let missionsBlockWidth = maxMissionsCardsPerRaw * (missionsCardWidth + localGap) - localGap
let wndWidth = campaignBlockWithPaddings + missionsBlockWidth

let prevGenPlatform = isXboxOne ? "xbox"
  : isPS4 ? "sony"
  : null

let curTabIdx = mkWatched(persist, "curTabIdx", 0)
let activeTabs = mkWatched(persist, "activeTabs", [])

enum TabsIds {
  EVENT_ID = "eventTab"
  CAMPAIGN_ID = "campaignTab"
  MISSION_ID = "missionsTab"
}

let function toggleCampaignsFilter(campaign){
  let idx = selectedCampaignsFilters.value.findindex(@(val) val == campaign)
  if(idx != null){
    selectedCampaignsFilters.mutate(@(val) val.remove(idx))
  }
  else
    selectedCampaignsFilters.mutate(@(val) val.append(campaign))
}

let IMAGE_RATIO = 16.0 / 9.0

let baseOptions = [
  optIsPrivate
  optMode
  optDifficulty
  optMaxPlayers
  optBotCount
  optTeamArmies
  optCluster
  optCrossplay
]

let function curTabById(id) {
  let idx = activeTabs.value.findindex(@(d) d.id == id)
  if (idx != null)
    curTabIdx(idx)
}

let infoBlockRows = [
  {
    option = optCampaigns
    onClick = @() allowChooseCampaign.value ? curTabById(TabsIds.CAMPAIGN_ID) : null
  },
  {
    option = optMissions
    onClick = @() curTabById(TabsIds.MISSION_ID)
  }
]

let close = @() isEditEventRoomOpened(false)

let locOn = loc($"option/on")
let locOff = loc($"option/off")
let defBoolToString = @(val) val ? locOn : locOff
let mkValueText = @(curValue, valToString) @() {
  watch = curValue
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = valToString?(curValue.value) ?? curValue.value
}.__update(body_txt)

let optionCtor = {
  [OPT_LIST] = @(opt, cfg, isDisabled = false) (cfg.values.len() <= 1 || isDisabled)
    ? mkValueText(opt.curValue, opt?.valToString)
    : spinnerList({
        curValue = opt.curValue, setValue = opt.setValue, allValues = cfg.values,
        valToString = opt?.valToString
      }),

  [OPT_CHECKBOX] = @(opt, cfg, isDisabled = false) (cfg.values.len() <= 1 || isDisabled)
    ? mkValueText(opt.curValue, opt?.valToString ?? defBoolToString)
    : spinnerList({
        curValue = opt.curValue, setValue = opt.setValue, allValues = cfg.values
        valToString = opt?.valToString ?? defBoolToString
      }),

  [OPT_EDITBOX] = @(opt, cfg, isDisabled = false) isDisabled
    ? mkValueText(opt.curValue, @(v) v)
    : textInput(opt?.savedValue ?? opt.curValue,
      { maxChars = cfg?.maxChars, placeholder = opt?.placeholder, setValue = opt.setValue,
        textmargin = [hdpx(6), hdpx(2)]})
}

let mkOption = @(option)  function () {
  let res = { watch = [option.cfg] }
  let cfg = option.cfg.value
  if (cfg == null)
    return res

  let { isEditAllowed = true } = option
  let { optType, locId = null } = cfg
  let hintText = loc($"{locId}/hint", "")

  return  {
    watch = [option.cfg, isInRoom]
    size = [ flex(), SIZE_TO_CONTENT]
    children = option.cfg == null ? null
      : mkOptionRow(locId, {
          size = [ optionsWidth/2.6, flex() ]
          valign = ALIGN_CENTER
          children = optionCtor?[optType](option, cfg, (isInRoom.value && !isEditAllowed))
        }, {
          onHover = hintText == "" ? null
            : @(on) setTooltip(on ? tooltipBox({
                rendObj = ROBJ_TEXT
                color = defTxtColor
                text = hintText
              }.__update(sub_txt)) : null)
        })
  }
}

let function mkMultiSelect(opt, cfg, ctor) {
  if (cfg == null)
    return []

  let { optType, values = [] } = cfg
  if (optType != OPT_MULTISELECT) {
    logerr($"Option {opt.id} support only multiselect mode in UI. (current option type: {optType})")
    return []
  }

  let {
    curValue, valToString = @(v) v, typeToString = @(v) v, toggleValue
  } = opt
  return values.map(@(value) ctor(
    valToString(value),
    typeToString(value),
    @(isChecked) toggleValue(value, isChecked),
    Computed(@() (curValue.value ?? []).contains(value)),
    value
  ))
}

let mkCampaignSelectRow = @(campaign) watchElemState(@(sf){
  rendObj = ROBJ_SOLID
  watch = selectedCampaignsFilters
  size = [campaignsBlockWidth, rowHeight]
  flow = FLOW_HORIZONTAL
  behavior = Behaviors.Button
  color = sf & S_HOVER ? defInsideBgColor : blurBgFillColor
  valign = ALIGN_CENTER
  function onClick(){
    toggleCampaignsFilter(campaign)
    sound_play(selectedCampaignsFilters.value.contains(campaign)
      ? "ui/enlist/flag_set"
      : "ui/enlist/flag_unset")
  }
  margin = [smallPadding, 0]
  padding = [0, bigPadding]
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      behavior = Behaviors.TextArea
      color = txtColor(sf)
      text = loc(gameProfile.value?.campaigns[campaign].title ?? campaign)
    }.__update(body_txt)
    selectedCampaignsFilters.value.contains(campaign) ? faComp("check") : null
  ]
})

let mkCampaignImg = @(campaign) {
  size = flex()
  rendObj = ROBJ_IMAGE
  keepAspect = KEEP_ASPECT_FILL
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  image = Picture($"ui/gameImage/{campaign}.jpg")
}

let cardTextBlock = @(label, typeTxt, sf, isSelected, params = {}){
  flow = FLOW_VERTICAL
  size = flex()
  halign = ALIGN_RIGHT
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      size = flex()
      behavior = Behaviors.TextArea
      color = txtColor(sf)
      text = label
    }.__update(h2_txt, params?.label ?? {})
    {
      size = [flex(), SIZE_TO_CONTENT]
      gap = smallPadding
      vplace = ALIGN_BOTTOM
      valign = ALIGN_CENTER
      children = [
        typeTxt == null ? null
          : {
              rendObj = ROBJ_TEXT
              color = txtColor(sf)
              text = typeTxt
            }.__update(body_txt)
        {
          size = [smallOffset, SIZE_TO_CONTENT]
          hplace = ALIGN_RIGHT
          children = isSelected.value ? faComp("check") : null
        }
      ]
    }.__update(params?.sign ?? {})
  ]
}.__update(params)

let mkCampaignSelectBlock = @(label, _typeTxt, setValue, isSelected, value)
  watchElemState(@(sf) {
    watch = isSelected
    rendObj = ROBJ_SOLID
    key = isSelected
    size = [missionsCardWidth, missionsCardWidth / IMAGE_RATIO]
    flow = FLOW_VERTICAL
    behavior = Behaviors.Button
    color = sf & S_HOVER ? defInsideBgColor : blurBgFillColor
    valign = ALIGN_CENTER
    function onClick(){
      setValue(!isSelected.value)
      sound_play(isSelected.value ? "ui/enlist/flag_set" : "ui/enlist/flag_unset")
    }
    children = [
      {
        size = flex()
        halign = ALIGN_RIGHT
        children = [
          mkCampaignImg(value)
          smallCampaignIcon(value, Color(25, 25, 25, 175))
        ]
      }
      cardTextBlock(label, null, sf, isSelected, {
        flow = FLOW_HORIZONTAL
        padding = bigPadding
        valign = ALIGN_CENTER
        size = [flex(), SIZE_TO_CONTENT]
        minHeight = hdpx(48)
        label = { size = [flex(), SIZE_TO_CONTENT] }
        sign = { size = [SIZE_TO_CONTENT, flex()] }
      })
    ]
  })

let allertSign = {
  rendObj = ROBJ_IMAGE
  size = [hdpx(30), hdpx(25)]
  image = Picture($"ui/uiskin/attention.png")
  margin = bigPadding
  behavior = Behaviors.Button
  hplace = ALIGN_RIGHT
  onHover = @(on) setTooltip(on ? tooltipBox({
    rendObj = ROBJ_TEXT
    color = defTxtColor
    text = loc("singleMissionAlert")
  }.__update(sub_txt)) : null)
}

optMissions.curValue.subscribe(function(v){
  if (prevGenPlatform) {
    let missionsWithAlert = []
    foreach (mission in v) {
      let { prevGenAlert = [] } = getMissionInfo(mission)
      if (prevGenAlert.contains(prevGenPlatform))
        missionsWithAlert.append(mission)
    }

    let count = missionsWithAlert.len()
    if (count > 0)
      msgbox.show({ text = count > 1
        // TODO show names of all problematic missions to tell the player how to fix it
        ? loc("manyMissionsAlert")
        : loc("singleMissionAlert")})
  }
})

let function mkMissionCard(label, typeTxt, setValue, isSelected, value){
  let { image, prevGenAlert = [] } = getMissionInfo(value)
  let hasPrevgen = prevGenAlert.contains(prevGenPlatform)
  return watchElemState(@(sf) {
    watch = isSelected
    rendObj = ROBJ_SOLID
    size = [missionsCardWidth, missionsCardHeight]
    behavior = Behaviors.Button
    flow = FLOW_VERTICAL
    color = sf & S_HOVER ? defInsideBgColor : blurBgFillColor
    function onClick(){
      setValue(!isSelected.value)
      sound_play(isSelected.value ? "ui/enlist/flag_set" : "ui/enlist/flag_unset")
    }
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = [flex(), missionsCardHeight/2]
        image = Picture(image)
        keepAspect = KEEP_ASPECT_FILL
        children = hasPrevgen ? allertSign : null
      }
      {
        size = flex()
        padding = bigPadding
        children = cardTextBlock(label, typeTxt, sf, isSelected)
      }
    ]
  })
}


let mkSelectBlock = @(options, content) function(){
  let children = arrayByRows(mkMultiSelect(options, options.cfg.value, content),
    maxMissionsCardsPerRaw)
      .map(@(row) {
        size = [missionsBlockWidth, SIZE_TO_CONTENT]
        gap = localGap
        flow = FLOW_HORIZONTAL
        children = row
      })
  return {
    size = [flex(), SIZE_TO_CONTENT]
    watch = options.cfg
    margin = [smallPadding, 0]
    children = makeVertScroll({
      flow = FLOW_VERTICAL
      gap = localGap
      size = [flex(), SIZE_TO_CONTENT]
      children
    },{
      size = [flex(), missionsBlockHeight]
      styling = thinStyle
    })
  }
}

let baseOptionsList = {
  size = [optionsWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = baseOptions.map(mkOption)
}

let roomInfoRow = @(block) function getRoomInfoRow(){
  let { option, onClick } = block
  let res = { watch = option.cfg }
  let chosenValues = []
  let currentValue = option.curValue.value
  if(option.cfg.value?.optType != OPT_MULTISELECT)
    return res

  let {values, locId} = option.cfg.value
  if (option.cfg.value.values.len() == 1)
    chosenValues.append(option.valToString(values[0]))
  else if (currentValue.len() == values.len() || currentValue.len() == 0)
    chosenValues.append(loc("options/any"))
  else {
    foreach (idx, val in currentValue) {
      if (idx >= infoRowsToShow)
        break
      chosenValues.append(option.valToString(val))
    }
    let count = currentValue.len() - infoRowsToShow
    if (count > 0)
      chosenValues.append(loc("options/andMore", { count }))
  }


  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    maxWidth = hdpx(500)
    margin = [smallPadding, 0]
    gap = localGap
    minHeight = rowHeight
    children = watchElemState(@(sf) {
      rendObj = ROBJ_SOLID
      color = sf & S_HOVER ? defInsideBgColor : blurBgFillColor
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      behavior = Behaviors.Button
      skipDirPadNav = true
      padding = [0, bigPadding]
      onClick
      children = [
        {
          rendObj = ROBJ_TEXT
          size = [SIZE_TO_CONTENT, rowHeight]
          text = loc(locId)
          valign = ALIGN_CENTER
          color = activeTxtColor
        }.__update(body_txt)
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          halign = ALIGN_RIGHT
          gap = localGap
          children = chosenValues.map(@(text) {
            rendObj = ROBJ_TEXT
            size = [flex(), rowHeight]
            clipChildren = true
            behavior = Behaviors.Marquee
            valign = ALIGN_CENTER
            halign = ALIGN_RIGHT
            color = defTxtColor
            text
          }.__update(body_txt))
        }
      ]
    })
  })
}

let modMissionTitle = is_console ? null : watchElemState(@(sf){
  rendObj = ROBJ_SOLID
  watch = [modPath, receivedModInfos]
  color = sf & S_HOVER ? defInsideBgColor : blurBgFillColor
  size = [flex(), SIZE_TO_CONTENT]
  maxWidth = hdpx(500)
  flow = FLOW_HORIZONTAL
  behavior = Behaviors.Button
  padding = [0, bigPadding]
  valign = ALIGN_CENTER
  margin = [smallPadding, 0]
  minHeight = rowHeight
  onClick = function() {
    updateModList()
    openCustomMissionWnd()
  }
  children = modPath.value == ""
    ? {
        rendObj = ROBJ_TEXT
        text = loc("mods/noActive")
      }.__update(body_txt)
    : [
        {
          rendObj = ROBJ_TEXT
          size = [flex(), SIZE_TO_CONTENT]
          color = activeTxtColor
          text = loc("Mods")
        }.__update(body_txt)
        {
          rendObj = ROBJ_TEXT
          size = [flex(3), SIZE_TO_CONTENT]
          clipChildren = true
          behavior = Behaviors.Marquee
          color = defTxtColor
          halign = ALIGN_RIGHT
          text = receivedModInfos.value?[modPath.value].title
        }.__update(body_txt)
      ]
})

let mainSettingsInfo = {
  flow = FLOW_VERTICAL
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  borderWidth = 0
  children = infoBlockRows.map(roomInfoRow)
    .append(modMissionTitle)
}

let applyButton = @(locId) textButton(loc(locId), editEventRoom, {
  size = [btnWidth, commonBtnHeight]
  textParams = { rendObj=ROBJ_TEXT }.__update(body_txt)
  style = { BgNormal = accentColor }
  hotkeys = [["^J:X", { description = { skip = true }}]]
})

let mainSettingsWndContent = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  gap = localPadding
  children = [
    baseOptionsList
    mainSettingsInfo
  ]
}

let campaignsDescBlock = {
  rendObj = ROBJ_TEXTAREA
  size = flex()
  behavior = Behaviors.TextArea
  color = defTxtColor
  padding = localPadding
}

let campaignsChooseBlock = {
  size = [missionsBlockWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = mkSelectBlock(optCampaigns, mkCampaignSelectBlock)
}

let campsWndContent ={
  flow = FLOW_HORIZONTAL
  gap = localPadding
  size = flex()
  children = [
    campaignsDescBlock
    campaignsChooseBlock
  ]
}


let campaignsFiltersBlock = @() {
  watch = optCampaigns.cfg
  size = [campaignsBlockWidth, SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = optCampaigns.cfg.value?.values.map(@(campaign) mkCampaignSelectRow(campaign))
}

let missionsWndContent = @(){
  flow = FLOW_HORIZONTAL
  gap = localPadding
  size = flex()
  children = [
    campaignsFiltersBlock
    mkSelectBlock(optMissions, mkMissionCard)
  ]
}

let allValuesButton = @(option) function(){
  let res = { watch = [option.cfg, option.curValue] }
  let { values = [], optType = null } = option.cfg.value
  if (optType != OPT_MULTISELECT)
    return res
  local hasSelected = false
  local hasUnselected = false
  let curList = option.curValue.value
  if (curList != null)
    foreach(m in values)
      if (curList.contains(m))
        hasSelected = true
      else
        hasUnselected = true
  return res.__update({
    gap = localGap
    flow = FLOW_HORIZONTAL
    children = [
      hasUnselected ? textButton(loc("SelectAll"), @() option.setValue(values)) : null
      hasSelected ? textButton(loc("DeselectAll"), @() option.setValue([])) : null
    ]
  })
}

let lobbyPresetsButtons = @() {
  watch = [lobbyPresets, modPath]
  flow = FLOW_HORIZONTAL
  gap = localGap
  children = modPath.value != "" ? null : [
    textButton(loc("Save settings"), openSaveWindow),
    (lobbyPresets.value ?? {}).len() == 0 ? null
      : textButton(loc("Choose settings"), openChooseWindow)
  ]
}

let gameStartButtons = @() {
  watch = [isInRoom, showModsInCustomRoomCreateWnd, optMaxPlayers.curValue, modPath, isModsAvailable]
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = localGap
  children = [
    !showModsInCustomRoomCreateWnd.value || isInRoom.value || !isModsAvailable.value || is_console
      ? null
      : textButton(loc("Mods"), function() {
          updateModList()
          openCustomMissionWnd()
        })
    modPath.value != "" && optMaxPlayers.curValue.value <= 1
      ? applyButton("Start local")
      : applyButton(isInRoom.value ? "changeAttributesRoom" : "createRoom")
  ]
}

let function fillActiveTabs(...){
  let res = [{
    locId = "events/setting"
    id = TabsIds.EVENT_ID
    content = mainSettingsWndContent
    buttons = [
      lobbyPresetsButtons
      gameStartButtons
    ]
  }]
  if (optCampaigns.cfg.value != null) {
    if (allowChooseCampaign.value)
      res.append({
        locId = "options/campaigns"
        content = campsWndContent
        id = TabsIds.CAMPAIGN_ID
        buttons = [
          allValuesButton(optCampaigns)
          gameStartButtons
        ]
      })
    if (modPath.value == "")
      res.append({
        locId = "options/missions"
        id = TabsIds.MISSION_ID
        content = missionsWndContent
        buttons = [
          allValuesButton(optMissions)
          gameStartButtons
        ]
      })
  }
  activeTabs(res)
}

fillActiveTabs()

foreach (v in [optCampaigns.cfg, modPath, allowChooseCampaign])
  v.subscribe(fillActiveTabs)

activeTabs.subscribe(function(v){
  if (curTabIdx.value >= v.len())
    curTabIdx(0)
})

let function switchTab(delta){
  let newIdx = curTabIdx.value + delta
  if (newIdx >= 0 && newIdx < activeTabs.value.len())
    curTabIdx(newIdx)
}

let headerTabs = @(tabs) @(){
  watch = [curTabIdx, isGamepad, optCampaigns.cfg, optMissions.cfg]
  flow = FLOW_HORIZONTAL
  size = [flex(), SIZE_TO_CONTENT]
  gap = localPadding
  children = tabs
    .map(@(tab, idx) mkWindowTab(loc(tab.locId), @() curTabIdx(idx), idx == curTabIdx.value))
    .insert(0, isGamepad.value && curTabIdx.value != 0 && tabs.len() > 1
      ? mkHotkey("^J:LB", @() switchTab(-1))
      : null)
    .append(isGamepad.value && curTabIdx.value + 1 < tabs.len()
      ? mkHotkey("^J:RB", @() switchTab(1))
      : null)
}

let createRoomContent = @(){
  size = [flex(), wndHeight]
  padding = [localPadding, localPadding, localPadding + localGap, localPadding]
  children = [
    @(){
      watch = [curTabIdx, activeTabs]
      flow = FLOW_VERTICAL
      size = [flex(), SIZE_TO_CONTENT]
      gap = localGap
      children = [
        headerTabs(activeTabs.value)
        activeTabs.value?[curTabIdx.value].content
      ]
    }
  ]
}


let wndButtons= @() {
  watch = [isEditInProgress, curTabIdx, activeTabs]
  size = [flex(), 0]
  margin = [0, localPadding]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  children = isEditInProgress.value ? spinner : activeTabs.value?[curTabIdx.value].buttons
}


let createRoomWnd = @() {
  watch = isInRoom
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = [wndWidth, SIZE_TO_CONTENT]
  maxWidth = maxWndWidth
  color = blurBgColor
  flow = FLOW_VERTICAL
  children = [
    mkWindowHeader(
      isInRoom.value ? loc("changeAttributesRoom") : loc("createRoom"),
      chooseRandom(getImagesFromMissions()),
      closeBtn({ onClick = close })
        .__update({ margin = bigPadding })
    )
    createRoomContent
    wndButtons
  ]
}

let open = @() addModalWindow({
  key = WND_UID
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = defInsideBgColor
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = createRoomWnd
  onClick = @() null
})

if (isEditEventRoomOpened.value)
  open()
isEditEventRoomOpened.subscribe(@(v) v ? open() : removeModalWindow(WND_UID))
