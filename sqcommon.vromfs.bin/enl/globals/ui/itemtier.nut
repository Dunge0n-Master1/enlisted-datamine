from "%enlSqGlob/ui_library.nut" import *

let { fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  smallPadding, soldierLvlColor, soldierLockedLvlColor
} = require("%enlSqGlob/ui/viewConst.nut")
let fa = require("%ui/components/fontawesome.map.nut")

let mkIconBar = @(count, color, fName, params = {}) count < 1 ? null : {
    rendObj = ROBJ_INSCRIPTION
    validateStaticText = false
    text = "".join(array(count, fa[fName]))
    font = fontawesome.font
    fontSize = hdpx(10)
    color
  }.__update(params)

let mkItemTier = @(item, itemLevelData = null, isFreemiumMode = false,
  thresholdColor = 0, mkBg = @(v) v
) function() {
  let tier = item?.tier ?? 0
  let { tierMax = tier, canUpgrade = false } = itemLevelData instanceof Watched
    ? itemLevelData.value
    : itemLevelData
  let showFreemiumStars = isFreemiumMode && (tierMax - tier > 1)
  let upgradesPending = showFreemiumStars ? tierMax - tier - 1
    : canUpgrade ? 1
    : 0
  let upgradesLeft = tierMax - tier - upgradesPending
  let color = showFreemiumStars ? thresholdColor : soldierLvlColor
  let res = { watch = itemLevelData }
  return tierMax < 1 ? res
    : mkBg({
        children = {
          hplace = ALIGN_RIGHT
          margin = smallPadding
          flow = FLOW_HORIZONTAL
          children = [
            mkIconBar(tier, color, "star")
            mkIconBar(upgradesPending, color, "star-o")
            mkIconBar(upgradesLeft, soldierLockedLvlColor, "star-o")
          ]
        }
      }.__update(res))
}

return {
  mkTierStars = @(tier, params = {}) mkIconBar(tier, soldierLvlColor, "star", params)
  mkItemTier
  mkIconBar
}