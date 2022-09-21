from "%enlSqGlob/ui_library.nut" import *

let {heroCurrentGunSlot, heroModsByWeaponSlot, weaponSlotsStatic} = require("%ui/hud/state/hero_weapons.nut")
let {sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {SELECTION_BORDER_COLOR} = require("%ui/hud/style.nut")
let { blurBack } = require("style.nut")
let iconWidget = require("%ui/components/icon3d.nut")

let ammoColor = Color(100,100,100,50)
let curColor = Color(180,200,230,180)
let color = Color(168,168,168,150)
let curBorderColor = SELECTION_BORDER_COLOR
//let nextBorderColor = Color(200, 200, 200, 100)


let function itemAppearing(duration=0.2) {
  return {prop=AnimProp.opacity, from=0, to=1, duration=duration, play=true, easing=InOutCubic}
}
let wWidth = hdpx(280)
let aHgt = calc_str_box("A", sub_txt)[1]*2 //we want to be sure that weapon name and icon could be displayed without big overlapping
let wHeight = max(aHgt+hdpx(2), hdpx(40))

let weapIdPadding = freeze([0,0,hdpx(2),hdpx(2)])
let function weaponId(weaponName, isCurrent, params={width=flex() height=wHeight}) {
  let size = [params?.width ?? flex(), params?.height ?? wHeight]
  let {padding = weapIdPadding, margin = null} = params
  return {
    size
    padding
    margin
    clipChildren = true
    children = {
      behavior = Behaviors.Marquee
      size = flex()
      valign = ALIGN_BOTTOM
      children = @() {
        watch = isCurrent
        size = SIZE_TO_CONTENT
        halign = ALIGN_LEFT
        rendObj = ROBJ_TEXT
        text = loc(weaponName)
        fontFx = FFT_BLUR
        fontFxColor = Color(0,0,0,30)
        color = isCurrent.value ? curColor : color
      }.__update(sub_txt)
    }
  }
}
let wAmmoDef = {width=SIZE_TO_CONTENT height=SIZE_TO_CONTENT}
let weapAmmoAnimations = [ { prop=AnimProp.scale, from=[1.1,1.3], to=[1,1], duration=0.2, play=true, easing=OutCubic } ]

let function weaponAmmo(watchedWeapon, isCurrent, params=wAmmoDef, idx = null) {
  let size = [params?.width ?? SIZE_TO_CONTENT, params?.height ?? SIZE_TO_CONTENT]
  let totalAmmoW = Computed(@() watchedWeapon?.value.totalAmmo ?? 0)
  let curAmmoW = Computed(@() watchedWeapon?.value.curAmmo ?? 0)
  let addAmmoW =Computed(@() watchedWeapon?.value.additionalAmmo ?? 0)
  let {margin = hdpx(5), halign = ALIGN_RIGHT, hplace = ALIGN_RIGHT} = params
  return function(){
    let addAmmo = addAmmoW.value
    let curAmmo = curAmmoW.value + addAmmo
    let totalAmmo = max(0, totalAmmoW.value - addAmmo)
    let isReloadable = watchedWeapon.value?.isReloadable ?? weaponSlotsStatic?[idx].isReloadable

    let ammo_string = (totalAmmo + curAmmo <= 0 )
      ? ""
      : isReloadable
        ? $"{curAmmo}/{totalAmmo}"
        : curAmmo

    return {
      rendObj = ROBJ_TEXT
      watch = [totalAmmoW, curAmmoW, addAmmoW, isCurrent]
      text = ammo_string
      color = isCurrent.value ? curColor : ammoColor
      size
      clipChildren=true
      halign
      hplace
      transform  = {pivot =[0.5,0.5]}
      margin
      animations = weapAmmoAnimations
    }
  }
}


let silhouetteDefColor=[200,200,200,200]
let silhouetteEmptyColor=[0,0,0,120]
let silhouetteInactiveColor=[0,0,0,200]
let outlineDefColor=[0,0,0,0]
let outlineEmptyColor=[200,200,200,0]
let outlineInactiveColor=[200,200,200,0]

let weaponWidgetAnims = freeze([
  {prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true}
  itemAppearing()
])

let function iconCtor(itemInfo, isLoadable, isAmmoLoaded, width, height, mods=null) {
  return iconWidget(itemInfo, {
      width
      height
      hplace = ALIGN_CENTER
      shading = "silhouette"
      silhouette = isAmmoLoaded ? silhouetteDefColor : silhouetteEmptyColor
      outline = isLoadable ? outlineDefColor : outlineEmptyColor
      silhouetteInactive = silhouetteInactiveColor
      outlineInactive = outlineInactiveColor
    }, mods)
}
let iconCtorMemoized  = memoize(iconCtor)

let currentBorder = freeze({ size = flex(), rendObj = ROBJ_FRAME, borderWidth = hdpx(1), color = curBorderColor })

let function weaponWidget(weapon=null, idx=null, hint = null, width = wWidth, height = wHeight, weaponState = null, doMemoize=false) {
  let weaponWatched = Computed(@() (weapon ?? {}).__merge(weaponState?.value ?? {}))
  let name = Computed(@() weapon?.name ?? weaponSlotsStatic?[idx].name ?? weaponWatched?.value.name)
  let isCurrentW = Computed(@() heroCurrentGunSlot.value!=null && heroCurrentGunSlot.value == idx)
  let controlHint = hint
  let hintsPadding = wHeight + hdpx(2)
  let borderComp = @() {size = flex() children  = isCurrentW.value ? currentBorder : null, watch=isCurrentW}
  let weaponHudIcon = function() {
    let sInfo = weaponSlotsStatic?[idx]
    let isLoadable = sInfo?.isReloadable ?? weaponWatched?.value.isReloadable ?? ((weaponWatched?.value.maxAmmo ?? 0) > 0)
    let isAmmoLoaded = !isLoadable || ((weaponWatched?.value.curAmmo ?? 0) > 0)
    let ctor = doMemoize || (sInfo != null && !weaponWatched?.value.subsidiaryGunEid) ? iconCtorMemoized : iconCtor
    return {
      size = flex()
      watch= [heroModsByWeaponSlot,  name]
      children = ctor(weaponSlotsStatic?[idx] ?? weaponWatched.value, isLoadable, isAmmoLoaded, hdpx(128), height - hdpx(2) * 2, weaponWatched?.value.subsidiaryGunEid ? heroModsByWeaponSlot.value?[idx].iconAttachments : null)
    }
  }
  let ammo = weaponWatched != null ? weaponAmmo(weaponWatched, isCurrentW, {width = SIZE_TO_CONTENT height=wHeight/2 hplace=ALIGN_RIGHT vplace = ALIGN_CENTER}, idx) : null
  let weapId = @() weaponId(name.value, isCurrentW, { size=[flex(),height/2]}).__update({watch = name})

  return freeze({
    size = [width,height]
    animations = weaponWidgetAnims
    flow = FLOW_HORIZONTAL
    children = [
      {
        size = [width - hintsPadding, height]
        clipChildren = true
        children = [
          blurBack,
          borderComp,
          {
            size = [width-hintsPadding,height]
            clipChildren = true
            valign = ALIGN_CENTER
            children = {
              size = flex()
              padding=hdpx(2)
              children = [
                weaponHudIcon,
                {
                  flow = FLOW_HORIZONTAL
                  size = flex()
                  valign = ALIGN_CENTER
                  children = [ weapId, ammo ]
                }
              ]
            }
          }
        ]
      }
      {size = flex(0.01) minWidth=hdpx(1)}
      controlHint
    ]
  })
}

return {
  weaponWidget = kwarg(weaponWidget)
  weaponWidgetDefaultWidth = wWidth
}