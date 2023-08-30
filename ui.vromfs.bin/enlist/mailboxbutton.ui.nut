from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor } = require("%enlSqGlob/ui/designConst.nut")
let { isMailboxVisible, unreadNum, hasUnread
} = require("%enlist/mainScene/invitationsLogState.nut")
let {sound_play} = require("%dngscripts/sound_system.nut")
let { FAFlatButton } = require("%ui/components/txtButton.nut")
let mailboxWndOpen = require("mailboxBlock.nut")
let { isInBattleState } = require("%enlSqGlob/inBattleState.nut")
let { navBottomBarHeight } = require("%enlist/mainMenu/mainmenu.style.nut")

let animsCounter = [
  {prop = AnimProp.scale from =[3.0, 3.0] to = [1.0,1.0]  duration = 0.5 trigger="new_mail" easing = OutCubic}
]
let soundNewMail = "ui/enlist/notification"
let hintTxtStyle = { color = defTxtColor }.__update(fontSub)

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
  }.__update(fontSub)
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

let hoverHint = {
  rendObj = ROBJ_TEXT
  text = loc("tooltips/invites")
}.__update(hintTxtStyle)

return @() {
  watch = [hasUnread, isMailboxVisible]
  children = [
    FAFlatButton("flag", mailboxWndOpen, {
      hint = hoverHint
      selected = isMailboxVisible
      btnWidth = navBottomBarHeight
      btnHeight = navBottomBarHeight
      key = hasUnread.value
      animations = hasUnread.value
        ? [{prop = AnimProp.scale, from =[1.0, 1.0], to = [1.1, 1.1], duration = 1.3, loop = true, play = true, easing = CosineFull }]
        : null
    })
    readNumCounter
  ]
}
