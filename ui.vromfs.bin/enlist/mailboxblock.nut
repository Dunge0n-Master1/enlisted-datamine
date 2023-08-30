from "%enlSqGlob/ui_library.nut" import *

let { fontawesome } = require("%enlSqGlob/ui/fontsStyle.nut")
let colors = require("%ui/style/colors.nut")
let { bigGap, gap } = require("%enlSqGlob/ui/viewConst.nut")
let scrollbar = require("%ui/components/scrollbar.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let textButton = require("%ui/components/textButton.nut")
let { inbox, clearAll, markReadAll, hasUnread, isMailboxVisible, onNotifyRemove, onNotifyShow
} = require("%enlist/mainScene/invitationsLogState.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")

let MAILBOX_MODAL_UID = "mailbox_modal_wnd"
let wndWidth = hdpx(450)
let maxListHeight = hdpx(300)
let padding = gap

/*
  this layout looks ugly cause we have no valid autolayout for objects that should be in scrollbox and in the same time scrollbox can depend on it's content (min\maxHeight and min\maxWidth)
  TODO:
    introduce timestamp for notifications
    show timestamsp
    show new notifications different way from old one
    auto 'markread' new notifications if visible for long enough time
*/

let defTextCtor = @(text, _params, _handler, _group, _sf) text

let mkRemoveBtn = @(notify) {
  size = SIZE_TO_CONTENT
  children = fontIconButton("trash-o",
    { onClick = @() onNotifyRemove(notify),
      color = Color(200,200,200)
    })
}

let btnParams = textButton.smallStyle.__merge({ margin = 0, size = [flex(), hdpx(30)], halign = ALIGN_LEFT })
let defaultStyle = btnParams
let buttonStyles = {
  toBattle = textButton.onlinePurchaseStyle.__merge(btnParams)
  primary = textButton.primaryButtonStyle.__merge(btnParams)
}

let item = @(notify) {
  size = [flex(), SIZE_TO_CONTENT]
  flow  = FLOW_HORIZONTAL
  gap = hdpx(2)
  children = [
    textButton(notify.text, @() onNotifyShow(notify), (buttonStyles?[notify.styleId] ?? defaultStyle).__merge({textCtor = defTextCtor}))
    mkRemoveBtn(notify)
  ]
}

let mailsPlaceHolder = {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_SOLID
  padding = padding
  color = colors.ControlBg
  children = {
    rendObj = ROBJ_TEXT
    color = colors.TextHighlight
    text = loc("no notifications")
  }
}

let mkHeader = @(total) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER

  children = [
    {
      rendObj = ROBJ_TEXT
      text="{0} {1}".subst(loc("Notifications:"), total > 0 ? total : "")
      color =colors.Inactive
      margin = [0, 0, 0, gap]
    }
    {size=[flex(),0]}
    {
      vplace = ALIGN_CENTER
      children = fontIconButton("times",
        {
          function onClick() {
            modalPopupWnd.remove(MAILBOX_MODAL_UID)
          }
        })
    }
  ]
}

let clearAllBtn = textButton.FAButton("trash-o", clearAll, {hplace=ALIGN_RIGHT}.__update(fontawesome))

let function mailboxBlock() {
  let elems = inbox.value.map(item)
  if (elems.len() == 0)
    elems.append(mailsPlaceHolder)
  elems.reverse()

  return {
    size = [wndWidth, SIZE_TO_CONTENT]
    watch = [hasUnread, inbox]
    flow = FLOW_VERTICAL
    gap = bigGap

    children = [
      mkHeader(inbox.value.len())
      scrollbar.makeVertScroll({
        size = [flex(), SIZE_TO_CONTENT]
        gap = gap
        flow = FLOW_VERTICAL
        children = elems
      },
      {
        size = [flex(), SIZE_TO_CONTENT]
        maxHeight = maxListHeight
        needReservePlace = false
      })
      clearAllBtn
    ]
  }
}

inbox.subscribe(function(v) { if (v.len() == 0) modalPopupWnd.remove(MAILBOX_MODAL_UID) })

return @(event) modalPopupWnd.add(event.targetRect,
  {
    watch = inbox //!!FIX ME: This watch need only because of bug with incorrect recalc parent on child size change
    uid = MAILBOX_MODAL_UID
    onAttach = function() {
      markReadAll()
      isMailboxVisible(true)
    }
    onDetach = function() {
      markReadAll()
      isMailboxVisible(false)
    }

    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    fillColor = colors.WindowBlurredColor
    popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL, fillColor = colors.ModalBgTint }

    children = mailboxBlock
  })