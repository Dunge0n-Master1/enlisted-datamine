from "%enlSqGlob/ui_library.nut" import *

let { body_txt, h2_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { modPath, receivedModInfos, requestModManifest, deleteMod, hasBeenUpdated
} = require("customMissionState.nut")
let {
  bigPadding, maxContentWidth, isWide, commonBtnHeight, titleTxtColor, defTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { localPadding, localGap, rowHeight } = require("%enlist/gameModes/eventModeStyle.nut")
let mkOptionRow = require("%enlist/gameModes/components/mkOptionRow.nut")
let { addModalWindow, removeModalWindow } = require("%ui/components/modalWindows.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")
let textInput = require("%ui/components/textInput.nut")
let { Bordered, FAButton } = require("%ui/components/textButton.nut")
let openUrl = require("%ui/components/openUrl.nut")
let faComp = require("%ui/components/faComp.nut")
let { mkLinearGradientImg } = require("%darg/helpers/mkGradientImg.nut")
let { noteTextArea } = require("%enlSqGlob/ui/defcomps.nut")
let modsDownloadInfo = require("modsDownloadInfo.ui.nut")
let { get_clipboard_text } = require("dagor.clipboard")
let { formatText } = require("%enlist/components/formatText.nut")

const WND_UID = "CUSTOM_MISSION_WND"
let sceneName = Watched("")
let sandboxUrl = "https://enlisted-sandbox.gaijin.net/"
let maxWndContentWidth = min(maxContentWidth, sw(100)) - localPadding * 2
let isInputFocused = Watched(false)

let modInfoWidth = hdpx(550)
let rowModWidth = hdpx(400)
let modListWidth = isWide
  ? (rowModWidth + localGap) * 3
  : (rowModWidth + localGap) * 2

let btnStyle = {
  margin = 0,
  size = [SIZE_TO_CONTENT, commonBtnHeight]
}

let closeButton = Bordered(loc("BackBtn"), function(){
  modPath("")
  removeModalWindow(WND_UID)
}, btnStyle.__merge({
  vplace = ALIGN_BOTTOM
  hotkeys = [["^J:B | Esc", { description = { skip = true }}]]
  pos = [0, commonBtnHeight * 0.5]
}))

let applyBtn = Bordered(loc("Apply"), @() removeModalWindow(WND_UID), btnStyle.__merge({
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  pos = [0, commonBtnHeight * 0.5]
}))


let modsWrapParams = {
  width = modListWidth
  hGap = localGap
  vGap = bigPadding
}

let inputOptions = {
  size = [flex(), commonBtnHeight - hdpx(7) * 2]
  textmargin = hdpx(7)
  colors = { backGroundColor = Color(0, 0, 0, 255) }
  placeholder = loc("pasteLink")
  valignText = ALIGN_CENTER
  hotkeys = [
    ["^J:Y", {action = @() sceneName(get_clipboard_text()), description = loc("pasteLink")}],
    ["^J:X", {action = @() sceneName(""), description = loc("clearInput")}]
  ]
  margin = 0
  onFocus = @() isInputFocused(true)
  onBlur = @() isInputFocused(false)
}.__update(body_txt)

let urlInput = @(){
  watch = sceneName
  size = [hdpx(400), commonBtnHeight]
  valign = ALIGN_CENTER
  children = [
    sceneName.value.len() > 0
      ? FAButton("close", @() sceneName(""), { margin = 0, pos = [ -hdpx(40), 0 ] })
      : null
    textInput(sceneName, inputOptions)
  ]
}

let urlInputBlock = @(){
  watch = [sceneName, isInputFocused]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_RIGHT
  gap = localGap
  children = [
    urlInput
    Bordered(loc("downloadMission"),
      function(){
        set_kb_focus(null)
        requestModManifest(sceneName.value)
        sceneName("")
      }, btnStyle.__merge({
        isEnabled = sceneName.value != ""
        hotkeys = isInputFocused.value ? [["^J:A | Enter", { skip = true }]] : null
      }))
  ]
}

let topBlock = @(){
  size = [flex(), hdpx(150)]
  watch = sceneName
  valign = ALIGN_CENTER
  children = [
    Bordered(loc("MissionsListOnWeb"), @() openUrl(sandboxUrl), btnStyle)
    urlInputBlock
  ]
}

let scrollOnlyUp = mkLinearGradientImg({
  points = [{offset = 0 color = [50, 35, 30]}, {offset = 100 color = [30, 35, 44]}]
  width = 16
  height = 128
  x1 = 0
  y1 = 0
  x2 = 0
  y2 = 128
})


let modsContent = makeVertScroll(@(){
  watch = [modPath, receivedModInfos]
  size = [modsWrapParams.width, SIZE_TO_CONTENT]
  children = wrap(receivedModInfos.value.values()
    .sort(@(a, b) a.title <=> b.title)
    .map(@(mod) mkOptionRow(mod.title,
      modPath.value == mod.id ? faComp("check") : null,
      {
        size = [rowModWidth, rowHeight]
        valign = ALIGN_CENTER
      },
      @() modPath(modPath.value != mod.id ? mod.id : ""),
      FAButton("close", @() deleteMod(mod.id), { margin = 0 }))
    ),
  modsWrapParams)
}, { size = [SIZE_TO_CONTENT, flex()] })

let function mkOptions(modInfo, option, needPrefix = false){
  local info = modInfo.room_params.rules[option].oneOf
  if (needPrefix)
    info = info.map(@(v) loc($"options/{v}"));
  return ", ".join(info)
}

let getLinkToMod = @(modInfo) $"{sandboxUrl}post/{modInfo.id}"

let modLinkButton = @(modInfo)
  formatText([{ t="url", url = getLinkToMod(modInfo), v = loc("mods/modOnSite")}])

let modInfoRows = @(modInfo) [
  { //TITLE
    text = modInfo.title
    color = titleTxtColor
    behavior = [Behaviors.Marquee, Behaviors.TextArea]
  }.__update(h2_txt)
  { //AUTHOR
    text = loc("options/authorsList", {
      count = modInfo.authors.len()
      authors = ", ".join(modInfo.authors)
    })
  }
  { //VERSION
    text = $"{loc("options/version")}: {modInfo.version}"
  }
  { //DIFFICULTY
    text = $"{loc("options/difficulty")}: {mkOptions(modInfo, "public/difficulty", true)}"
  }
  { //MAXPLAYERS
    text = $"{loc("options/maxPlayers")}: {mkOptions(modInfo, "public/maxPlayers")}"
  }
  {//BOT COUNT
    text = $"{loc("options/botCount")}: {mkOptions(modInfo, "public/botpop")}"
  }
  { //TEAM ARMIES
    text = $"{loc("options/teamArmies")}: {mkOptions(modInfo, "public/teamArmies", true)}"
  }
  { //DESCRIPTION
    text = (modInfo?.description ?? "") == ""
      ? ""
      : loc("mods/modDescription", { description = modInfo.description })
    behavior = Behaviors.TextArea
  }
]

let function currentModInfo(){
  let res = { watch = [modPath, receivedModInfos] }
  let curModInfo = receivedModInfos.value?[modPath.value]
  if (!curModInfo)
    return res
  return res.__update({
    size = [modInfoWidth, SIZE_TO_CONTENT]
    hplace = ALIGN_LEFT
    flow = FLOW_VERTICAL
    gap = localGap
    children = modInfoRows(curModInfo).map(@(v) noteTextArea({
      color = defTxtColor
    }).__update(sub_txt, v))
    .append(modLinkButton(curModInfo))
  })
}

let bottomBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  children = [
    applyBtn
    closeButton
  ]
}

let centerBlock = {
  size = flex()
  hplace = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = hdpx(20)
  children = [
    modsContent
    currentModInfo
  ]
}

let wndContent = {
  size = flex()
  maxWidth = maxWndContentWidth
  hplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    topBlock
    centerBlock
    bottomBlock
  ]
}

let function openCustomMissionWnd() {
  hasBeenUpdated(true)
  return addModalWindow({
    key = WND_UID
    rendObj = ROBJ_IMAGE
    image = scrollOnlyUp
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    size = [flex(), hdpx(900)]
    children =  [
      wndContent
      modsDownloadInfo
    ]
    onClick = @() null
  })
}

return openCustomMissionWnd