from "%enlSqGlob/ui_library.nut" import *

let {
  colPart, haveLevelColor, gainLevelColor
} = require("%enlSqGlob/ui/designConst.nut")


let starShadowColor = 0x44000000

let MAKE_PARAMS = {
  starSize = colPart(0.33)
  starGap = 0
  blockGap = 0
  ownedCfg = {
    img = "star_level_filled"
    commonColor = haveLevelColor
    invertColor = haveLevelColor
    shadowColor = starShadowColor
  }
  gainCfg = {
    img = "star_level_filled"
    commonColor = gainLevelColor
    invertColor = gainLevelColor
    shadowColor = starShadowColor
  }
  emptyCfg = {
    img = "star_level_empty"
    commonColor = 0xFF999999
    invertColor = 0xCC000000
  }
}


let mkShadow = @(shadowSize, shadowColor){
  size = [shadowSize, shadowSize]
  rendObj = ROBJ_IMAGE
  image = Picture("ui/skin#star_level_filled_shadow.svg:{0}:{0}:K".subst(shadowSize))
  color = shadowColor
}


let function mkStar(isActive, starSize, cfg) {
  let { img, commonColor, invertColor, shadowColor = null } = cfg
  return {
    size = [starSize, starSize]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      shadowColor != null ? mkShadow(starSize * 2, shadowColor) : null
      {
        size = [starSize, starSize]
        rendObj = ROBJ_IMAGE
        image = Picture("ui/skin#{0}.svg:{1}:{1}:K".subst(img, starSize))
        color = isActive ? invertColor : commonColor
      }
    ]
  }
}


let function mkLevels(isActive, owned, gain = 0, empty = 0, params = MAKE_PARAMS) {
  params = MAKE_PARAMS.__merge(params)

  let { starSize, starGap, blockGap, ownedCfg, gainCfg, emptyCfg } = params
  let configs = [ownedCfg, gainCfg, emptyCfg]
  return {
    flow = FLOW_HORIZONTAL
    gap = blockGap
    children = [owned, gain, empty].map(@(count, idx) count == 0 ? null
      : {
          flow = FLOW_HORIZONTAL
          gap = starGap
          children = array(count).map(@(_) mkStar(isActive, starSize, configs[idx]))
        })
  }
}


return mkLevels
