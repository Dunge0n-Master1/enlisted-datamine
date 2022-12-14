from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let scrollbar = require("%ui/components/scrollbar.nut")
let { inbox, clearAll, markReadAll, hasUnread, isMailboxVisible, onNotifyRemove, onNotifyShow
} = require("%enlist/mainScene/invitationsLogState.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let { defTxtColor, hoverTxtColor, colPart, smallPadding, bigPadding,
  panelBgColor, titleTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { FAFlatButton, SmallBordered } = require("%ui/components/txtButton.nut")

const MAILBOX_MODAL_UID = "mailbox_modal_wnd"
let wndWidth = colPart(7.2)
let maxListHeight = colPart(5)
let defTxtStyle = { color = defTxtColor }.__update(fontSmall)
let titleTxtStyle = { color = titleTxtColor }.__update(fontSmall)


let mkRemoveBtn = @(notify) FAFlatButton("trash-o", @() onNotifyRemove(notify), {
  color = hoverTxtColor
  borderWidth = 0
  btnWidth = defTxtStyle.fontSize
  btnHeight = defTxtStyle.fontSize
})


let item = @(notify) {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    SmallBordered(notify.text, @() onNotifyShow(notify), { btnWidth = flex() })
    mkRemoveBtn(notify)
  ]
}

let mailsPlaceHolder = {
  size = [flex(), SIZE_TO_CONTENT]
  rendObj = ROBJ_SOLID
  padding = smallPadding
  color = panelBgColor
  children = {
    rendObj = ROBJ_TEXT
    text = loc("invitations/noNotifications")
  }.__update(titleTxtStyle)
}

let mkHeader = @(total) {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = { size = flex() }
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("invitations/notificationCount", { count = total })
    }.__update(defTxtStyle)
    FAFlatButton("times", @() modalPopupWnd.remove(MAILBOX_MODAL_UID))
  ]
}

let clearAllBtn = FAFlatButton("trash-o", clearAll, { hplace = ALIGN_RIGHT })

let function mailboxBlock() {
  let elems = inbox.value.map(item)
  if (elems.len() == 0)
    elems.append(mailsPlaceHolder)
  elems.reverse()

  return {
    watch = [hasUnread, inbox]
    size = [wndWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      mkHeader(inbox.value.len())
      scrollbar.makeVertScroll({
        size = [flex(), SIZE_TO_CONTENT]
        gap = smallPadding
        flow = FLOW_VERTICAL
        children = elems
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        maxHeight = maxListHeight
        needReservePlace = false
      })
      clearAllBtn
    ]
  }
}

inbox.subscribe(@(v) v.len() == 0 ? modalPopupWnd.remove(MAILBOX_MODAL_UID) : null)

return @(event) modalPopupWnd.add(event.targetRect,
  {
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
    fillColor = panelBgColor
    popupBg = { rendObj = ROBJ_WORLD_BLUR_PANEL }
    children = mailboxBlock
  })