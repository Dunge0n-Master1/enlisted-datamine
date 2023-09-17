from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { curHeroGrenadeEid } = require("%ui/hud/state/hero_weapons.nut")
let { grenades, grenadesEids } = require("%ui/hud/state/inventory_grenades_es.nut")
let {blurBack, notSelectedItemColor, HUD_ITEMS_COLOR, iconSize, itemAppearing} = require("style.nut")
let { grenadeIcon } = require("grenadeIcon.nut")

let getGrenadeIcon = memoize(@(gtype) grenadeIcon(gtype, iconSize[1]))

let curGrenadeSize = [hdpxi(27), hdpxi(27)]
let getCurGrenadeIcon = memoize(@(gtype) grenadeIcon(gtype, curGrenadeSize[1]))

let small_count = @(count, color) {
  rendObj = ROBJ_TEXT
  key = count
  text = count > 1 ? count.tostring() : null
  color = color
  vplace = ALIGN_BOTTOM
  pos = [0, hdpx(2)]
  animations = itemAppearing
}.__update(fontSub)


let currentGrenadeType = Computed(@() grenadesEids.value?[curHeroGrenadeEid.value])
let playerGrenadesBelt = Computed(function(){
  let allGrenades=grenades.value
  let curGrenadeType=currentGrenadeType.value
  let res = []
  let grenadesCopy = clone allGrenades
  local curGrenade = []
  if (curGrenadeType in grenadesCopy) {
    curGrenade = [[curGrenadeType, delete grenadesCopy[curGrenadeType]]]
  }
  foreach (grenadeType, grenadeCount in grenadesCopy){
    res.append([grenadeType, grenadeCount])
  }
  res.extend(curGrenade)
  return res
})

let function mkGrenadeImage(grenadeType, color, isCurrent=false, pos=null){
  return {
    rendObj = ROBJ_IMAGE
    image = isCurrent ? getCurGrenadeIcon(grenadeType) : getGrenadeIcon(grenadeType)
    hplace = ALIGN_CENTER
    size = isCurrent ? curGrenadeSize : iconSize
    color = color
    pos = pos
  }
}
let shadowColor = Color(0,0,0,90)
let selectedShadowColor = Color(0,0,0,120)
let function mkGrenadeWidget(grenadeType, count, key, isCurrent=false){
  let color = isCurrent ? HUD_ITEMS_COLOR : notSelectedItemColor
  return {
    flow = FLOW_HORIZONTAL
    gap = hdpx(1)
    key = key
    animations = itemAppearing
    children = [
      {
        children = [
          mkGrenadeImage(grenadeType, isCurrent ? selectedShadowColor : shadowColor, isCurrent, [hdpx(1), hdpx(1)])
          mkGrenadeImage(grenadeType, color, isCurrent)
        ]
        size = SIZE_TO_CONTENT
      }
      small_count(count, color)
    ]
  }
}
let function grenadesBlock() {
  let children = playerGrenadesBelt.value.map(@(g,i,list) mkGrenadeWidget(g[0],g[1], "_".concat(g[0],g[1],i), i==list.len()-1))

  return {
    size = SIZE_TO_CONTENT
    watch = [playerGrenadesBelt]
    children = [
      blurBack
      {
        flow = FLOW_HORIZONTAL
        size = SIZE_TO_CONTENT
        gap = fsh(0.4)
        children = children
        valign =ALIGN_BOTTOM
      }
    ]
    animations = itemAppearing
  }
}


let belt = {
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  gap = hdpx(10)
  valign = ALIGN_BOTTOM
  size = SIZE_TO_CONTENT //todo - min-height should be SIZE_TO_CONTENT, height - flex
  children = grenadesBlock
}

return belt

