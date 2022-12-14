from "%enlSqGlob/ui_library.nut" import *

let { isUsermailWndOpend, hasUnseenLetters } = require("%enlist/usermail/usermailState.nut")
let { hasUsermail } = require("%enlist/featureFlags.nut")
let { mkBlinkNotifier } = require("%ui/components/unseenComponents.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { fastAccessIconHeight, defTxtColor, hoverTxtColor
} = require("%enlSqGlob/ui/designConst.nut")


return @() {
  watch = [hasUsermail, hasUnseenLetters]
  size = [fastAccessIconHeight, fastAccessIconHeight]
  children = !hasUsermail.value ? null
    : [
        watchElemState(@(sf) {
          rendObj = ROBJ_IMAGE
          size = [fastAccessIconHeight, fastAccessIconHeight]
          image = Picture("ui/skin#fastAccessIcons/message_icon.svg:{0}:{0}:K"
            .subst(fastAccessIconHeight))
          behavior = Behaviors.Button
          color = sf & S_HOVER ? hoverTxtColor : defTxtColor
          onClick = @() isUsermailWndOpend(true)
          onHover = @(on) setTooltip(on ? loc("mail/mailTab") : null)
        })
        !hasUnseenLetters.value ? null : mkBlinkNotifier.__update({
          pos = [fastAccessIconHeight / 2, -fastAccessIconHeight / 2]
        })
      ]
}
