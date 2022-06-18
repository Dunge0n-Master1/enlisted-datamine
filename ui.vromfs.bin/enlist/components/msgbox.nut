from "%enlSqGlob/ui_library.nut" import *

let {deep_clone} = require("%sqstd/underscore.nut")
let msgbox = deep_clone(require("%ui/components/msgbox.nut"))

if (msgbox.styling.BgOverlay?.sound!=null)
  msgbox.styling.BgOverlay.sound = null
return msgbox
