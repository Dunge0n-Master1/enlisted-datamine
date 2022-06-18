from "%enlSqGlob/ui_library.nut" import *

let {body_txt, sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {curWeaponName, curWeaponFiringMode, showWeaponBlock} = require("weapons_state.nut")
let {blurBack, DEFAULT_TEXT_COLOR} = require("style.nut")

let mkAmmoInfo = require("player_ammo.ui.nut")
let heightFireMode = calc_str_box("auto", sub_txt)[1]
let heightTxt = calc_str_box("auto", body_txt)[1]


let weaponNameCmp = @() {
  size = SIZE_TO_CONTENT
  watch = curWeaponName
  children = curWeaponName.value != "" ?
    [
      blurBack,
      {
        padding=[0,hdpx(2),0,hdpx(2)]
        rendObj = ROBJ_TEXT
        text = loc(curWeaponName.value)
        color = DEFAULT_TEXT_COLOR
        minHeight=heightTxt
      }.__update(body_txt)
   ] : null
}

let firingModeTxtCmp = @(mode) {
  padding=[0,hdpx(2),0,hdpx(2)]
  rendObj = ROBJ_TEXT
  minHeight=heightFireMode
  text = loc("firing_mode/{0}".subst(mode))
  color = DEFAULT_TEXT_COLOR
}.__update(sub_txt)

let firingModeCmpStub = freeze({
  size = [0, calc_comp_size(firingModeTxtCmp("A"))[1]]
})

let firingModeCmp = @(){
  size = SIZE_TO_CONTENT
  watch = curWeaponFiringMode
  children = (curWeaponFiringMode.value != "") ? [
    blurBack
    firingModeTxtCmp(curWeaponFiringMode.value)
  ] : firingModeCmpStub
}

let function weaponBlock() {
  return {
    halign = ALIGN_RIGHT
    valign = ALIGN_BOTTOM
    watch = showWeaponBlock
    children = showWeaponBlock.value ? {
      size = SIZE_TO_CONTENT
      halign = ALIGN_RIGHT
      valign = ALIGN_BOTTOM
      children = {
        flow = FLOW_VERTICAL
        halign = ALIGN_RIGHT
        valign = ALIGN_BOTTOM
        size = SIZE_TO_CONTENT
        children = [
          mkAmmoInfo()
          weaponNameCmp
          firingModeCmp
        ]
      }
    }: null
  }
}

return {
  firingModeCmp
  weaponNameCmp
  weaponBlock
}