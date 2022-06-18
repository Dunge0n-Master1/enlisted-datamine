from "%enlSqGlob/ui_library.nut" import *

let {body_txt, sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {mkInputHintBlock} = require("%ui/hud/huds/tips/tipComponent.nut")
let {
  hasWeapon, curWeaponIsReloadable, curWeaponAmmo, curWeaponIsDualMag, curWeaponAdditionalAmmo, curWeaponTotalAmmo, curWeaponAltAmmo,
  curWeaponAltTotalAmmo, curWeaponIsModActive, curWeaponHasAltShot
} = require("weapons_state.nut")
let {blurBack, DEFAULT_TEXT_COLOR} = require("style.nut")

let heightTxt = calc_str_box("auto", body_txt)[1]
let ammoNumAnim = [
  { prop=AnimProp.scale, from=[1.25,1.4], to=[1,1], duration=0.25, play=true, easing=OutCubic }
]

let ALT_ICON_SIZE = hdpx(22)
let ALT_SECONDARY_ICON_SIZE = hdpx(19)

let weapModToggleHint = mkInputHintBlock("Human.WeapModToggle")
let function weapModToggleTip() {
  return {
    watch = [curWeaponHasAltShot]
    vplace = ALIGN_CENTER
    children = curWeaponHasAltShot.value ? [weapModToggleHint] : null
    padding = [0,heightTxt/2,0,0]
  }
}

let sep = {
  rendObj = ROBJ_TEXT
  text = "/"
}

let add = {
  rendObj = ROBJ_TEXT
  text = "+"
}

let ammoText = @(txt, styles) {
  rendObj = ROBJ_TEXT
  text = txt
  key = txt
  transform = {
    pivot = [0.5, 0.5]
  }
  animations = ammoNumAnim
}.__update(styles)

let rifleGrenadeImage = @(size){
  rendObj = ROBJ_IMAGE
  size = [size,size]
  image = Picture("!ui/uiskin/item_rifle_grenade.svg:{1}:{1}:K".subst(size.tointeger()))
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  margin = hdpx(5)
}

let ammoCmp = @(curAmmo, additionalAmmo, totalAmmo, styles, isAlt = false, isSecondary = false){
  size = SIZE_TO_CONTENT
  children = [
    styles.useBlur ? blurBack : null,
    {
      size  = [SIZE_TO_CONTENT, heightTxt]
      padding = [0,hdpx(2)]
      flow  = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      valign = ALIGN_CENTER
      gap = heightTxt/10
      children = [
        isAlt ? rifleGrenadeImage(isSecondary ? ALT_SECONDARY_ICON_SIZE : ALT_ICON_SIZE) : null
        ammoText(curAmmo, styles.curAmmo)
        additionalAmmo != null ? add.__merge(styles.add) : null
        additionalAmmo != null ? ammoText(additionalAmmo, styles.additionalAmmo) : null
        sep.__merge(styles.sep)
        ammoText(max(0, totalAmmo - (additionalAmmo ?? 0)), styles.totalAmmo)
      ]
    }
  ]
}


let defMainStyles = {
  curAmmo = {color = DEFAULT_TEXT_COLOR}.__update(body_txt)
  sep = {color = DEFAULT_TEXT_COLOR}.__update(sub_txt)
  totalAmmo = {color = DEFAULT_TEXT_COLOR}.__update(sub_txt)
  add = {color = DEFAULT_TEXT_COLOR}.__update(sub_txt)
  additionalAmmo = {color = DEFAULT_TEXT_COLOR}.__update(sub_txt)
  useBlur = true
}

let ammoCmpHgt = calc_comp_size(ammoCmp(1,2,3, defMainStyles))[1]

let defSecondaryStyles = {
  curAmmo = {color = DEFAULT_TEXT_COLOR}.__update(sub_txt)
  sep = {color = DEFAULT_TEXT_COLOR}.__update(sub_txt)
  totalAmmo = {color = DEFAULT_TEXT_COLOR}.__update(sub_txt)
  add = {color = DEFAULT_TEXT_COLOR}.__update(sub_txt)
  additionalAmmo = {color = DEFAULT_TEXT_COLOR}.__update(sub_txt)
  useBlur = true
}

let mkAmmoInfo = function(mainStyles = {}, secondaryStyles = {}) {
  mainStyles = defMainStyles.__merge(mainStyles)
  secondaryStyles = defSecondaryStyles.__merge(secondaryStyles)
  return function(){
    if (!hasWeapon.value || !curWeaponIsReloadable.value)
      return { watch = [hasWeapon, curWeaponIsReloadable] size = [0, ammoCmpHgt]}

    let res = {
      watch = [
        curWeaponHasAltShot, curWeaponAmmo, curWeaponTotalAmmo, curWeaponAltAmmo,
        curWeaponAltTotalAmmo, curWeaponIsModActive, hasWeapon, curWeaponIsReloadable
      ]
      flow = FLOW_HORIZONTAL
      size = SIZE_TO_CONTENT
      valign = ALIGN_CENTER
    }
    let curAmmo = curWeaponAmmo.value
    let additionalAmmo = curWeaponIsDualMag.value ? curWeaponAdditionalAmmo.value : null
    let totalAmmo = curWeaponTotalAmmo.value
    if (!curWeaponHasAltShot.value)
      return res.__update({
        children = {
          flow = FLOW_VERTICAL
          size = SIZE_TO_CONTENT
          halign = ALIGN_RIGHT
          children = ammoCmp(curAmmo, additionalAmmo, totalAmmo, mainStyles)
        }
      })

    let altCurAmmo = curWeaponAltAmmo.value
    let altTotalAmmo = curWeaponAltTotalAmmo.value
    let isModActive = curWeaponIsModActive.value
    return res.__update({
      children = [
        weapModToggleTip
        {
          flow = FLOW_VERTICAL
          size = SIZE_TO_CONTENT
          halign = ALIGN_RIGHT
          children = [
            ammoCmp(curAmmo, additionalAmmo, totalAmmo, mainStyles, isModActive)
            ammoCmp(altCurAmmo, additionalAmmo, altTotalAmmo, secondaryStyles, !isModActive, true)
          ]
        }
      ]
    })
  }
}

return mkAmmoInfo