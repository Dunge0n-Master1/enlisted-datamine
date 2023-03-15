from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { rand } = require("math")
let { researchItemSize, defBgColor, airSelectedBgColor  } = require("%enlSqGlob/ui/viewConst.nut")
let {
  tableStructure, selectedTable, selectedResearch, research, researchStatuses,
  RESEARCHED, CAN_RESEARCH, GROUP_RESEARCHED
} = require("researchesState.nut")
let { seenResearches, markSeen } = require("unseenResearches.nut")
let hoverImage = require("%enlist/components/hoverImage.nut")
let { blinkUnseenIcon } = require("%ui/components/unseenSignal.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let { iconByGameTemplate } = require("%enlSqGlob/ui/itemsInfo.nut")
let researchIcons = require("%enlSqGlob/ui/researchIcons.nut")

const REPAY_TIME = 0.3
const MULTI_SIZE_MUL = 0.5
const MULTI_SELECTED_SIZE_MUL = 0.7

let function bgHighLight(id, sizeMul) {
  let highlightSize = hdpx(sizeMul * 220)
  let startRotation = rand() % 360
  return {
    size = [highlightSize, highlightSize]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    key = $"bgHighLight_{id}"
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture("ui/open_flash.avif")
        transform = { }
        transitions = hoverImage.transitions
        animations = [
          { prop = AnimProp.opacity, from = 0.8, to = 1, duration = 1,
            play = true, loop = true, easing = Blink },
          { prop = AnimProp.rotate, from = startRotation, to = startRotation + 360,
            duration = 47, play = true, loop = true }
        ]
      }
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = Picture("ui/open_flash.avif")
        transform = { }
        transitions = hoverImage.transitions
        animations = [
          { prop = AnimProp.opacity, from = 0.8, to = 1,
            duration = 1, play = true, loop = true, easing = Blink},
          { prop = AnimProp.rotate, from = startRotation-180, to = startRotation + 180,
            duration = 97, play = true, loop = true }
        ]
      }
    ]
  }
}

let crossImg = {
  size = flex()
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(4)
  color = Color(100, 100, 100, 255)
  commands = [
    [VECTOR_LINE, -5, -5, 105, 95],
    [VECTOR_LINE, -5, 95, 105, -5],
  ]
}

let selectedResearchTarget = @(research_id, bgColor, height) function (){
  let res = { watch = selectedResearch }
  if (selectedResearch.value?.research_id != research_id)
    return res

  let size = (height * 1.5).tointeger()
  let imgSize = size > 256 ? 256 : size
  return res.__update({
    size = [size, size]
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    pos = [0, hdpx(2)]
    rendObj = ROBJ_IMAGE
    image = Picture($"ui/skin#research_target_circle.svg:{imgSize}:{imgSize}:F")
    transform = { pivot = [0.5, 0.5]}
    animations = [
      {
        prop = AnimProp.scale, from = [0.1, 0.1], to = [1, 1], duration = 0.15,
        play = true, easing = OutQuad
      }
      {
        prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1, play = true,
        loop = true, easing = Blink
      }
    ]
    color = bgColor
  })
}

let RESEARCH_IMAGE_PARAMS = {
  imgName = ""
  color = Color(255, 255, 255, 255)
  size = researchItemSize
}

local function mkImageForResearch(params = {}) {
  params = RESEARCH_IMAGE_PARAMS.__merge(params)
  return {
    rendObj = ROBJ_IMAGE
    image = Picture("ui/skin#{2}.svg:{0}:{1}:K".subst(
      params.size[0].tointeger(), params.size[1].tointeger(), params.imgName))
  }.__update(params)
}

let unseen = blinkUnseenIcon()

let mkUnseen = @(isUnseen) @() {
  watch = isUnseen
  vplace = ALIGN_TOP
  hplace = ALIGN_RIGHT
  pos = [0, hdpx(10)]
  children = isUnseen.value ? unseen : null
}

let function mkCount(squad_size, squad_class_limit) {
  local count = (squad_size ?? {}).reduce(@(res, val) res + val, 0)
  if (count <= 0)
    count = (squad_class_limit ?? {}).reduce(@(res, classList) res + classList.reduce(@(sum, val) sum + val, 0), 0)
  if (count <= 1)
    return null
  return {
    rendObj = ROBJ_SOLID
    padding = hdpx(4)
    color = defBgColor
    children = txt({
      text = $"+{count}"
    }.__update(h2_txt))
  }
}

let mkImageByIcon = kwarg(function(
  width, height, sf, uid, image, isDisabled = false, iconOverride = null
) {
  let size = min(width, height)
  let resized = size * (iconOverride?.scale ?? 1.0)
  let pos = iconOverride?.pos ?? [0, 0]
  let imageName = image.endswith(".svg")
    ? $"!{image}:{(size * 1.2).tointeger()}:{(size * 1.2).tointeger()}:K"
    : $"{image}?Ac"
  return hoverImage.create({
    sf = sf
    uid = uid
    size = [size, size]
    image = null
    pivot = [0.5, 0.9]
    children = {
      size = [resized, resized]
      rendObj = ROBJ_IMAGE
      image = image != null ? Picture(imageName) : null
      tint = isDisabled ? Color(120, 120, 120, 255) : null
      pos = [(size - resized) * pos[0],  (size - resized) * pos[1]]
    }
  })
})

let mkImageByTemplate = kwarg(function(
  width, height, sf, uid, templateId, isDisabled = false, templateOverride = null
) {
  local tmplParams = templateOverride ?? {}
  let size = min(width, height)
  let resized = size * (tmplParams?.scale ?? 1.0)
  tmplParams = tmplParams.__merge({
    width = size * 1.2
    height = size * 1.2
    shading = "silhouette"
    silhouette = isDisabled ? [30, 30, 30, 255] : [255, 255, 255, 255]
    outline = [0, 0, 0, 85]
  })
  let templateIcon = iconByGameTemplate(templateId, tmplParams)
  if (templateIcon == null)
    return null
  return hoverImage.create({
    sf = sf
    uid = uid
    size = [size, size]
    image = null
    pivot = [0.5, 0.9]
    children = templateIcon.__update({ size = [resized, resized] })
  })
})

let hoverCallBacks = {}
return function(armyId, researchDef, elemPosX, elemPosY) {
  let researchId = researchDef.research_id
  let isMulti = (researchDef?.multiresearchGroup ?? 0) > 0
  let status = Computed(@() researchStatuses.value?[researchId])
  let isUnseen = Computed(@() seenResearches.value?.unseen[armyId][researchId] ?? false)
  let isSelected = Computed(@() selectedResearch.value?.research_id == researchId)
  let isOtherInGroupSelected = isMulti
    ? Computed(@() selectedResearch.value?.multiresearchGroup == researchDef?.multiresearchGroup
        && !isSelected.value)
    : Watched(false)

  let bgColor = tableStructure.value.pages[selectedTable.value].bg_color
  let darkedBgColor = mul_color(bgColor, 0.6) | 0xff000000
  let darkedStrokeColor = mul_color(bgColor, 0.85) | 0xff000000
  let stateFlags = Watched(0)

  let { squad_size = null, squad_class_limit = null } = researchDef?.effect
  let countComp = mkCount(squad_size, squad_class_limit)

  return function() {
    let researchStatus = status.value
    let iconImage = researchIcons?[researchDef?.icon_id]
    let templateId = researchDef?.gametemplate ?? ""
    let isDisabled = researchStatus != RESEARCHED && researchStatus != CAN_RESEARCH
    let needCross = researchStatus == GROUP_RESEARCHED
      || (isOtherInGroupSelected.value && researchStatus != RESEARCHED)

    let sizeMul = !isMulti ? 1
      : isSelected.value || researchStatus == RESEARCHED ? MULTI_SELECTED_SIZE_MUL
      : MULTI_SIZE_MUL
    let width = (sizeMul * researchItemSize[0]).tointeger()
    let height = (sizeMul * researchItemSize[1]).tointeger()
    let size = [width, height]

    return {
      watch = [status, isOtherInGroupSelected, isSelected, stateFlags]
      size = [width, height]
      pos = [elemPosX - 0.5 * width, elemPosY - 0.5 * height]

      children = [
        researchStatus == CAN_RESEARCH ? bgHighLight(researchDef, sizeMul) : null
        selectedResearchTarget(researchId, airSelectedBgColor, height)
        {
          pos = [0, hdpx(10)]
          key = researchId
          children = [
            mkImageForResearch({
              size,
              imgName = "research_shield_bg",
              color = researchStatus != RESEARCHED ? darkedBgColor : bgColor
            })
            mkImageForResearch({
              size,
              imgName = "research_shield_stroke_up",
              color = researchStatus != RESEARCHED ? darkedStrokeColor : null
            })
            templateId == "" ? null : mkImageByTemplate({
              width = width
              height = height
              sf = stateFlags.value
              uid = researchId
              templateId = templateId
              isDisabled = isDisabled
              templateOverride = researchDef?.templateOverride
            })
            iconImage == null ? null : mkImageByIcon({
              width = width
              height = height
              sf = stateFlags.value
              uid = researchId
              image = iconImage
              isDisabled = isDisabled
              iconOverride = researchDef?.iconOverride
            })
            mkImageForResearch({
              size,
              imgName = "research_shield_stroke_bottom",
              color = researchStatus != RESEARCHED ? darkedStrokeColor : null
            })
            mkImageForResearch({
              size
              key = researchDef
              imgName = "research_shield_bg"
              behavior = Behaviors.Button
              xmbNode = XmbNode()
              sound = {
                hover = "ui/enlist/button_highlight"
                click = researchStatus == RESEARCHED ? null : "ui/enlist/button_click"
              }
              onDoubleClick = @() research(researchId)
              onClick = @() selectedResearch(researchDef)
              onHover = function(on) {
                if (!isUnseen.value)
                  return
                if (hoverCallBacks?[researchId]) {
                  gui_scene.clearTimer(hoverCallBacks[researchId])
                  delete hoverCallBacks[researchId]
                }
                if (on) {
                  hoverCallBacks[researchId] <- function() {
                    markSeen(armyId, [researchId])
                    delete hoverCallBacks[researchId]
                  }
                  gui_scene.setTimeout(REPAY_TIME, hoverCallBacks[researchId])
                }
              }
              onDetach = function() {
                if (isUnseen.value)
                  markSeen(armyId, [researchId])
              }
              opacity = 0
              onElemState = @(sf) stateFlags(sf)
            })
            needCross ? crossImg : null
            countComp
          ]
        }
        mkUnseen(isUnseen)
      ]
    }
  }
}


