from "%enlSqGlob/ui_library.nut" import *
let { showMsgbox } = require("%enlist/components/msgbox.nut")


let showRentedSquadLimitsBox = @() showMsgbox({
  text = loc("msg/rentedSquadLimits")
})

return {
  showRentedSquadLimitsBox
}
