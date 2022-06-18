from "daRg" import *
from "frp" import *

let eventbus = require("eventbus")

let { start_updater, UPDATER_EVENT_STAGE, UPDATER_EVENT_PROGRESS, UPDATER_EVENT_ERROR, UPDATER_EVENT_FINISH } = require("contentUpdater")

let spinnerSize = sh(8)

let spinnerPic = Picture("!gear.svg:{0}:{0}:K".subst(spinnerSize, spinnerSize))

let updaterStage = Watched(null)
let updaterProgress = Watched(null)
let updaterError = Watched(null)

let function progress() {
  let size = [sw(100)-sh(50)-sh(20), sh(2)]

  if (updaterProgress.value == null) {
    return {
      size = size
      watch = updaterProgress
    }
  }

  return {
    watch = updaterProgress
    size = size
    rendObj = ROBJ_SOLID
    color = Color(91, 103, 150,120)

    halign = ALIGN_LEFT

    children = {
      rendObj = ROBJ_SOLID
      size = [pw(updaterProgress.value), flex()]
      color = Color(200,200,200,100)
    }
  }
}


let spinner = {
  rendObj = ROBJ_IMAGE
  size = [spinnerSize, spinnerSize]
  image = spinnerPic
  color = Color(200,200,200)

  transform = {}

  animations = [
    { prop=AnimProp.rotate, from=0, to=360, duration=3, play=true, loop=true }
  ]
}


let function Root() {
  return {
    size = flex()
    rendObj = ROBJ_SOLID
    color = Color(0, 0, 0, 0)

    halign = ALIGN_CENTER
    valign = ALIGN_BOTTOM

    padding = sh(15)
    flow = FLOW_VERTICAL
    gap = sh(5)

    children = [
      spinner
      progress
    ]
  }
}


let updaterEvents = {
  [UPDATER_EVENT_STAGE]    = @(evt) updaterStage(evt?.stage),
  [UPDATER_EVENT_PROGRESS] = @(evt) updaterProgress(evt?.percent),
  [UPDATER_EVENT_FINISH]   = @(_evt) null,
  [UPDATER_EVENT_ERROR]    = @(evt) updaterError(evt?.error),
}


const ContentUpdaterEventId = "daNetGameUpdater.event"


eventbus.subscribe(ContentUpdaterEventId, function (evt) {
  let {eventType} = evt
  updaterEvents?[eventType](evt)
})


// Start the Content Updater
print("Start the updater")
start_updater(ContentUpdaterEventId)


return Root
