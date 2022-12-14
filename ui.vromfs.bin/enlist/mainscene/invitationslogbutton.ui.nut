from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { unreadNum, hasUnread } = require("%enlist/mainScene/invitationsLogState.nut")
let mailboxWndOpen = require("%enlist/mainScene/invitationsLogBlock.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { sound_play } = require("sound")
let { fastAccessIconHeight, defTxtColor, hoverTxtColor, accentColor
} = require("%enlSqGlob/ui/designConst.nut")


let animsCounter = [{ prop = AnimProp.scale from = [3.0, 3.0] to = [1.0, 1.0] duration = 0.5
  trigger="new_mail" easing = OutCubic }]
const SOUND_NEW_MAIL = "ui/enlist/notification"
let accentTxtStyle = { color = accentColor }.__update(fontSmall)


let function readNumCounter(){
  let num = unreadNum.value
  return {
    watch = unreadNum
    rendObj = ROBJ_TEXT
    text = num < 1 ? "" : num
    pos =  [fastAccessIconHeight / 3, fastAccessIconHeight / 2]
    transform = {}
    animations = animsCounter
  }.__update(accentTxtStyle)
}

local prevUnread = unreadNum.value
unreadNum.subscribe(function(v) {
  if (v > prevUnread) {
    sound_play(SOUND_NEW_MAIL)
    anim_start("new_mail")
  } else
    anim_request_stop("new_mail")
  prevUnread = v
})

return @() {
  watch = hasUnread
  size = [fastAccessIconHeight, fastAccessIconHeight]
  halign = ALIGN_RIGHT
  children = [
    watchElemState(@(sf) {
      watch = hasUnread
      rendObj = ROBJ_IMAGE
      size = [fastAccessIconHeight, fastAccessIconHeight]
      image = Picture("ui/skin#fastAccessIcons/horn_icon.svg:{0}:{0}:K"
        .subst(fastAccessIconHeight))
      behavior = Behaviors.Button
      color = sf & S_HOVER ? hoverTxtColor : defTxtColor
      onClick = mailboxWndOpen
      onHover = @(on) setTooltip(on ? loc("tooltips/invites") : null)
      transform = {}
      animations = !hasUnread.value ? null
        : [{ prop = AnimProp.scale, from = [1.0, 1.0], to = [1.1, 1.1], duration = 1.3,
            loop = true, play = true, easing = CosineFull }]
    })
    readNumCounter
  ]
}
