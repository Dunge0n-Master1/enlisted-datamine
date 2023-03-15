from "%enlSqGlob/ui_library.nut" import *

let { isUsermailWndOpend, hasUnseenLetters } = require("%enlist/usermail/usermailState.nut")
let { hasUsermail } = require("%enlist/featureFlags.nut")
let squareIconButton = require("%enlist/components/squareIconButton.nut")
let { blinkUnseenIcon } = require("%ui/components/unseenSignal.nut")


let unseenIcon = blinkUnseenIcon(1).__update({ hplace = ALIGN_RIGHT })

return @() {
  watch = [hasUsermail, hasUnseenLetters]
  children = !hasUsermail.value ? null
    : [
        squareIconButton({
          onClick = @() isUsermailWndOpend(true)
          tooltipText = loc("mail/mailTab")
          iconId = "envelope"
        })
        hasUnseenLetters.value ? unseenIcon : null
      ]
}