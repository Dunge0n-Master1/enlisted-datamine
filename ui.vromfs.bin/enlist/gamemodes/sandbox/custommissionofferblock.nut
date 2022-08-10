from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let mkDotPaginator = require("%enlist/components/mkDotPaginator.nut")
let { accentTitleTxtColor, activeTxtColor, defBgColor, smallPadding
} = require("%enlSqGlob/ui/viewConst.nut")
let { isEventModesOpened } = require("%enlist/gameModes/eventModesState.nut")
let { featuredMods, offersModMsgbox } = require("customMissionOfferState.nut")

const SWITCH_SEC = 8.0

let curWidgetIdx = Watched(0)

let mkOfferImage = @(img) {
  key = $"offer_{img}"
  rendObj = ROBJ_IMAGE
  size = flex()
  image = Picture(img)
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_RIGHT
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.6, play = true }
    { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.6, playFadeOut = true }
  ]
}

let mkInfo = @(addChild) {
  rendObj = ROBJ_SOLID
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = smallPadding
  vplace = ALIGN_BOTTOM
  color = defBgColor
  children = addChild
}


let featuredModsList = Computed(function() {
  let list = []
  if (isEventModesOpened.value) {
    featuredMods.value.each(function(mod) {
      let addChild = @(sf) [
        {
          size = [flex(), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
          text = mod.title
          color = sf & S_HOVER ? accentTitleTxtColor : activeTxtColor
        }
        {
          rendObj = ROBJ_TEXT
          text = loc("mods/author", { author = mod.authorsNick })
          color = sf & S_HOVER ? accentTitleTxtColor : activeTxtColor
        }
      ]
      list.append({
        backImage = mod.imageToShow
        mkContent = @(sf) {
          size = flex()
          halign = ALIGN_CENTER
          valign = ALIGN_BOTTOM
          children = mkInfo(addChild(sf))
        }
        onClick = @() offersModMsgbox(mod)
      })
    })
  }
  return list
})

featuredModsList.subscribe(function(wlist) {
  let wCount = wlist.len()
  if (wCount == 0)
    return curWidgetIdx(-1)

  curWidgetIdx(clamp(curWidgetIdx.value, 0, wCount - 1))
})

let paginatorTimer = Watched(SWITCH_SEC)

let header = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = accentTitleTxtColor
  hplace = ALIGN_CENTER
}.__update(body_txt)

let offersPaginator = mkDotPaginator({
  id = "offers"
  pageWatch = curWidgetIdx
  dotSize = hdpx(9)
  switchTime = paginatorTimer
})

let function customMissionOfferBlock() {
  let res = { watch = [curWidgetIdx, isEventModesOpened, featuredModsList] }
  let widgets = featuredModsList.value
  if (widgets.len() == 0)
    return res

  return res.__update({
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      header(loc("mods/modOfWeek"))
      {
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          mkOfferImage(widgets?[curWidgetIdx.value].backImage)
          {
            size = [flex(), SIZE_TO_CONTENT]
            flow = FLOW_VERTICAL
            children = [
              watchElemState(@(sf) {
                size = [flex(), hdpx(125)]
                behavior = Behaviors.Button
                onClick = widgets?[curWidgetIdx.value].onClick
                onHover = @(on) paginatorTimer(on ? 0 : SWITCH_SEC)
                children = widgets?[curWidgetIdx.value].mkContent(sf)
              })
              {
                rendObj = ROBJ_SOLID
                size = [flex(), SIZE_TO_CONTENT]
                padding = smallPadding
                halign = ALIGN_CENTER
                color = defBgColor
                children = offersPaginator(widgets.len())
              }
            ]
          }
        ]
      }
    ]
  })
}

return customMissionOfferBlock
