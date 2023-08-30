from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let spinner = require("%ui/components/spinner.nut")
let { WindowTransparent } = require("%ui/style/colors.nut")
let { noteTextArea } = require("%enlSqGlob/ui/defcomps.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let { defInsideBgColor, commonBtnHeight, titleTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let {
  replayDownload, REPLAY_DOWNLOAD_NONE,
  REPLAY_DOWNLOAD_PROGRESS, REPLAY_DOWNLOAD_FAILED
} = require("%enlist/replay/replayDownloadState.nut")
let { addModalWindow, removeModalWindow } = require("%ui/components/modalWindows.nut")
let { replayPlay } = require("%enlist/replay/replaySettings.nut")
let datacache = require("datacache")

let WND_UID = "replayDownloadUi"
let waitingSpinner = spinner()

let btnStyle = {
  margin = 0
  size = [SIZE_TO_CONTENT, commonBtnHeight]
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
}

let defaultSize = [hdpx(432), hdpx(324)]
let replayWndClose = @() removeModalWindow(WND_UID)
let defTxtStyle = { color = titleTxtColor }.__update(fontBody)

let closeButton = Bordered(loc("replay/Close"), replayWndClose, btnStyle)

let playButton = Bordered(loc("replay/Play"), @() replayPlay(replayDownload.value.filename), btnStyle)

let abortButton = Bordered(loc("replay/Abort"), @() datacache.abort_requests(replayDownload.value.downloadRequestId), btnStyle)

let title = noteTextArea({
  size = [flex(), SIZE_TO_CONTENT]
  text = loc("replay/Downloading")
  halign = ALIGN_CENTER
}).__update(defTxtStyle)

let content = @(message) {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  margin = [hdpx(30), 0]
  vplace = ALIGN_CENTER
  text = message
}.__update(defTxtStyle)

let infoContainer = @() {
  watch = replayDownload
  size = defaultSize
  gap = hdpx(20)
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  padding = hdpx(20)
  fillColor = WindowTransparent
  borderRadius = hdpx(2)
  rendObj = ROBJ_WORLD_BLUR_PANEL
  transform = {}
  animations = [
    { prop=AnimProp.translate,  from=[0, sh(5)], to=[0,0], duration=0.5, play=true, easing=OutBack }
    { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true, easing=OutCubic }
    { prop=AnimProp.translate, from=[0,0], to=[0, sh(30)], duration=0.7, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1.0, to=0.0, duration=0.6, playFadeOut=true, easing=OutCubic }
  ]
  children = replayDownload.value.state == REPLAY_DOWNLOAD_PROGRESS
    ? [
        title
        {
          size = flex()
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          flow = FLOW_VERTICAL
          children = [
            waitingSpinner
            replayDownload.value.contentLen >= 0
              ? content(loc("replay/fileSizeMb", { size = replayDownload.value.contentLen >> 20 }))
              : null
          ]
        }
        replayDownload.value.downloadRequestId != ""
          ? abortButton
          : null
      ]
    : [
        title
        content(loc(replayDownload.value.stateText))
        {
          size = flex()
          flow = FLOW_HORIZONTAL
          halign = ALIGN_CENTER
          gap = hdpx(5)
          children = [
              replayDownload.value.state != REPLAY_DOWNLOAD_FAILED
                ? playButton
                : null
              closeButton
          ]
        }
      ]
}

let open = @() addModalWindow({
  key = WND_UID
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = defInsideBgColor
  size = flex()
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  stopMouse = true
  children = infoContainer
  onClick = @() null
})

if (replayDownload.value.state != REPLAY_DOWNLOAD_NONE)
  open()

replayDownload.subscribe(@(v) v.state != REPLAY_DOWNLOAD_NONE ? open() : replayWndClose())
