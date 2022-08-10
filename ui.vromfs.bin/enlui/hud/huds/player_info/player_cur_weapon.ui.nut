from "%enlSqGlob/ui_library.nut" import *

let {sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let {curWeaponFiringMode} = require("%ui/hud/state/hero_weapons.nut")
let {blurBack, DEFAULT_TEXT_COLOR} = require("style.nut")

let heightFireMode = calc_str_box("auto", sub_txt)[1]


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

return {
  firingModeCmp
}