from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {Alert,Inactive} = require("%ui/style/colors.nut")
let { isMailboxVisible, unreadNum, hasUnread
} = require("%enlist/mainScene/invitationsLogState.nut")
let {sound_play} = require("sound")
let squareIconButton = require("%enlist/components/squareIconButton.nut")
let mailboxWndOpen = require("mailboxBlock.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")

let animsCounter = [
  {prop = AnimProp.scale from =[3.0, 3.0] to = [1.0,1.0]  duration = 0.5 trigger="new_mail" easing = OutCubic}
]
let soundNewMail = "ui/enlist/notification"

let function readNumCounter(){
  let num = unreadNum.value
  return {
    watch = unreadNum
    rendObj = ROBJ_TEXT
    text = num < 1 ? "" : num
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    pos = [-hdpx(3), hdpx(4)]
    fontFx = FFT_GLOW
    transform = { pivot = [0.5,0.5] }
    fontFxColor = Color(0, 0, 0, 255)
    animations = animsCounter
  }.__update(sub_txt)
}

local prevUnread = unreadNum.value
unreadNum.subscribe(function(v) {
  if (!isInBattleState.value)
    if (v > prevUnread) {
        sound_play(soundNewMail)
        anim_start("new_mail")
    } else
      anim_request_stop("new_mail")
  prevUnread = v
})

return function() {
  return {
    watch = [hasUnread, isMailboxVisible]
    children = [
      squareIconButton({
        onClick = mailboxWndOpen
        tooltipText = loc("tooltips/invites")
        iconId = "flag"
        selected = isMailboxVisible
        key = hasUnread.value
        animations = hasUnread.value
          ? [{prop = AnimProp.scale, from =[1.0, 1.0], to = [1.1, 1.1], duration = 1.3, loop = true, play = true, easing = CosineFull }]
          : null
      }, {
        animations = hasUnread.value
          ? [{prop = AnimProp.color, from = Inactive, to = Alert, duration = 1.3, loop = true, play = true, easing = CosineFull }]
          : null
      })
      readNumCounter
    ]
  }
}
