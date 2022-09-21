from "%enlSqGlob/ui_library.nut" import *

let unseenSignal = require("%ui/components/unseenSignal.nut")

let smallUnseen = unseenSignal(0.8)
let smallUnseenNoBlink = smallUnseen.__merge({ key = "blink_off", animations = null })
let smallUnseenBlink = smallUnseen.__merge({ key = "blink_on" })

let normUnseen = unseenSignal(1.4)
let normUnseenNoBlink = normUnseen.__merge({ key = "blink_off", animations = null })
let normUnseenBlink = normUnseen.__merge({ key = "blink_on" })


const BLINK = "blink"
const NO_BLINK = "noBlink"

let unseenByType = {
  [true] = smallUnseenBlink,
  [BLINK] = smallUnseenBlink,
  [NO_BLINK] = smallUnseenNoBlink
}

return {
  BLINK
  NO_BLINK
  smallUnseenBlink
  smallUnseenNoBlink
  normUnseenBlink
  normUnseenNoBlink
  unseenByType
}
