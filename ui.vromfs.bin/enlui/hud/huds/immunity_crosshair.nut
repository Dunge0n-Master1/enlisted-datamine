let {mkCrosshair, mkCrosshairElement} = require("%ui/hud/huds/crosshair.nut")
let immunityMarks = require("immunity_marks.nut")

let crosshairImmunityMarks = mkCrosshair(@() [immunityMarks], [])

return mkCrosshairElement(crosshairImmunityMarks)