from "%enlSqGlob/ui_library.nut" import *

let {body_txt, sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {mkInputHintBlock} = require("%ui/hud/huds/tips/tipComponent.nut")
let { hasWeapon, curWeaponIsReloadable, curWeaponAmmo, curWeaponIsDualMag,
  curWeaponAdditionalAmmo, curWeaponTotalAmmo, curWeaponAltAmmo,
  curWeaponAltTotalAmmo, curWeaponIsModActive, curWeaponHasAltShot,
  curWeaponIconByHolders, curWeaponCurAmmoHolderIndex, curWeaponAmmoByHolders
} = require("%ui/hud/state/hero_weapons.nut")
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

let RIFLE_GRENADE_ICON = "!ui/uiskin/item_rifle_grenade.svg"

let ammoTypeImage = memoize(@(size, iconName) freeze({
  rendObj = ROBJ_IMAGE
  size = [size,size]
  image = Picture("{0}:{1}:{1}:K".subst(iconName, size.tointeger()))
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  margin = hdpx(5)
}))

let rifleGrenadeIcon = ammoTypeImage(ALT_ICON_SIZE, RIFLE_GRENADE_ICON)
let rifleGrenadeIconSecondary = ammoTypeImage(ALT_SECONDARY_ICON_SIZE, RIFLE_GRENADE_ICON)

let ammoCmp = @(curAmmo, additionalAmmo, totalAmmo, styles, icon = null) {
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
        icon
        curAmmo != null ? ammoText(curAmmo, styles.curAmmo) : null
        curAmmo != null && additionalAmmo != null ? add.__merge(styles.add) : null
        additionalAmmo != null ? ammoText(additionalAmmo, styles.additionalAmmo) : null
        curAmmo != null || additionalAmmo != null ? sep.__merge(styles.sep) : null
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
  return function() {
    if (!hasWeapon.value || !curWeaponIsReloadable.value)
      return {
        watch = [hasWeapon, curWeaponIsReloadable]
        size = [0, ammoCmpHgt]
      }

    let watch = [
      hasWeapon, curWeaponIsReloadable, curWeaponAmmo, curWeaponIsDualMag,
      curWeaponAdditionalAmmo, curWeaponTotalAmmo, curWeaponHasAltShot
    ]
    let curAmmo = curWeaponAmmo.value
    let additionalAmmo = curWeaponIsDualMag.value ? curWeaponAdditionalAmmo.value : null
    let totalAmmo = curWeaponTotalAmmo.value
    if (!curWeaponHasAltShot.value) {
      let iconByHolders = curWeaponIconByHolders.value
      let ammoByHolders = curWeaponAmmoByHolders.value
      let ammoByHoldersLen = ammoByHolders.len()
      let curAmmoHolderIndex = curWeaponCurAmmoHolderIndex.value
      let curTotalAmmo = ammoByHolders?[curAmmoHolderIndex] ?? totalAmmo
      let curAmmoIconName = iconByHolders?[curAmmoHolderIndex] ?? ""
      let curAmmoIcon = curAmmoIconName != "" ? ammoTypeImage(ALT_ICON_SIZE, curAmmoIconName) : null

      local children = [ ammoCmp(curAmmo, additionalAmmo, curTotalAmmo, mainStyles, curAmmoIcon) ]
      for (local i = 0; i < ammoByHoldersLen; i++) {
        if (i == curAmmoHolderIndex || ammoByHolders[i] <= 0)
          continue

        let ammoIconName = iconByHolders?[i] ?? ""
        let ammoIcon = ammoIconName != ""
                     ? ammoTypeImage(ALT_SECONDARY_ICON_SIZE, ammoIconName)
                     : null
        let ammoCounter = ammoCmp(null, null, ammoByHolders[i], secondaryStyles, ammoIcon)
        children.append(ammoCounter)
      }

      watch.append(curWeaponIconByHolders, curWeaponCurAmmoHolderIndex, curWeaponAmmoByHolders)

      return {
        watch
        valign = ALIGN_CENTER
        halign = ALIGN_RIGHT
        flow = FLOW_VERTICAL
        children
      }
    }

    watch.append(curWeaponAltAmmo, curWeaponAltTotalAmmo, curWeaponIsModActive)
    let altCurAmmo = curWeaponAltAmmo.value
    let altTotalAmmo = curWeaponAltTotalAmmo.value
    let isModActive = curWeaponIsModActive.value
    let mainAmmoIcon = isModActive ? rifleGrenadeIcon : null
    let altAmmoIcon = !isModActive ? rifleGrenadeIconSecondary : null
    return {
      watch
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        weapModToggleTip
        {
          flow = FLOW_VERTICAL
          halign = ALIGN_RIGHT
          children = [
            ammoCmp(curAmmo, additionalAmmo, totalAmmo, mainStyles, mainAmmoIcon)
            ammoCmp(altCurAmmo, additionalAmmo, altTotalAmmo, secondaryStyles, altAmmoIcon)
          ]
        }
      ]
    }
  }
}

return mkAmmoInfo