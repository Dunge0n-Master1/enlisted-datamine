from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { unreadNum, hasUnread } = require("%enlist/mainScene/invitationsLogState.nut")
let mailboxWndOpen = require("%enlist/mainScene/invitationsLogBlock.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { sound_play } = require("%dngscripts/sound_system.nut")
let { fastAccessIconHeight, defTxtColor, hoverTxtColor, accentColor
} = require("%enlSqGlob/ui/designConst.nut")


const SOUND_NEW_MAIL = "ui/enlist/notification"
let accentTxtStyle = { color = accentColor }.__update(fontSmall)


local prevUnread = unreadNum.value
unreadNum.subscribe(function(v) {
  if (v > prevUnread)
    sound_play(SOUND_NEW_MAIL)
  prevUnread = v
})


let function readNumCounter(){
  let res = { watch = unreadNum }
  let num = unreadNum.value
  return num < 1 ? res : res.__update({
    watch = unreadNum
    rendObj = ROBJ_TEXT
    key = $"invitaions_number_{num}"
    text = num
    pos =  [fastAccessIconHeight / 3, fastAccessIconHeight / 2]
    transform = {}
    animations = [{ prop = AnimProp.scale from = [1.5, 1.5] to = [1.0, 1.0] duration = 1.0
      easing = OutCubic, loop = true, play = true }]
  }.__update(accentTxtStyle))
}


return @() {
  watch = hasUnread
  size = [fastAccessIconHeight, fastAccessIconHeight]
  halign = ALIGN_RIGHT
  children = [
    watchElemState(@(sf) {
      watch = hasUnread
      key = $"invitations_button_{hasUnread.value}"
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
        : [{ prop = AnimProp.color, from = defTxtColor, to = accentColor, duration = 1.5,
            loop = true, play = true, easing = CosineFull }]
    })
    readNumCounter
  ]
}
