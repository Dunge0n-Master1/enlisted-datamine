from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  sceneWithCameraAdd, sceneWithCameraRemove
} = require("%enlist/sceneWithCamera.nut")
let {
  bigPadding, defInsideBgColor, defTxtColor, blurBgFillColor, activeTxtColor,
  maxContentWidth, airBgColor, opaqueBgColor, smallPadding, accentTitleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let {
  letters, requestLetters, takeLetterReward, isRequest, closeUsermailWindow, isUsermailWndOpend,
  selectedLetterIdx, hasUnseenLetters
} = require("%enlist/usermail/usermailState.nut")
let spinner = require("%ui/components/spinner.nut")({ height = hdpx(80)})
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let JB = require("%ui/control/gui_buttons.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let rewardsItemMapping = require("%enlist/items/itemsMapping.nut")
let { mkRewardImages, rewardWidthToHeight, mkRewardText, mkRewardTooltip, mkSeasonTime
} = require("%enlist/battlepass/rewardsPkg.nut")
let { withTooltip } = require("%ui/style/cursors.nut")
let faComp = require("%ui/components/faComp.nut")
let { mkMedalCard } = require("%enlist/profile/medalsPkg.nut")
let mkWindowTab = require("%enlist/components/mkWindowTab.nut")

let messageHeight = hdpx(160)
let imageHeight = hdpx(100)
let imageSize = [rewardWidthToHeight * imageHeight, imageHeight]
let mailPadding = hdpx(15)
let mailBigPadding = hdpx(40)
let MAIL_WND_WIDTH = fsh(100)

let listBgColor = @(sf, isSelected) isSelected ? opaqueBgColor
  : sf & S_HOVER ? defInsideBgColor
  : blurBgFillColor
let listTxtColor = @(sf, isSelected) isSelected ? activeTxtColor
  : sf & S_HOVER ? Color(200,200,200)
  : defTxtColor

let noMessagesTitle = {
  rendObj = ROBJ_TEXT
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  color = activeTxtColor
  text = loc("mail/no_messages")
}.__update(body_txt)


let completedRewardSign = {
  size = [hdpx(28), hdpx(28)]
  rendObj = ROBJ_BOX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  fillColor = Color(0,0,0)
  hplace = ALIGN_LEFT
  children = faComp("check", { fontSize = hdpx(15) })
}

let function timeLimitIcon(){
  let size = hdpxi(15)
  return{
    rendObj = ROBJ_IMAGE
    size = [size, size]
    color = Color(0,0,0)
    image = Picture($"!ui/uiskin/battlepass/Ellipse.svg:{size}:{size}:K")
    vplace = ALIGN_BOTTOM
    hplace = ALIGN_RIGHT
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    margin = smallPadding
    children = faComp("clock-o", {
      fontSize = size + hdpx(1)
      color = accentTitleTxtColor
    })
  }
}

let function mkReward(rewardNumb, hasReceived = true) {
  if (rewardNumb == null)
    return null
  let reward = rewardsItemMapping.value?[rewardNumb]
  local rewardToShow = mkRewardImages(reward, imageSize)
    ?? mkRewardText(reward, hdpx(60), {size = imageSize})
  if (reward?.stackImages != null){
    let r = reward
    rewardToShow = mkMedalCard(r.bgImage, r.stackImages, imageHeight)
  }
  return {
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      withTooltip(rewardToShow, @() mkRewardTooltip(reward))
      hasReceived ? completedRewardSign : null
      reward?.isTemporary ? timeLimitIcon : null
    ]
  }
}

let function messageRow(message, idx){
  let { text, guid, cTime, isReceived = false, endTime = 0, reward = null } = message
  return watchElemState(function(sf){
    if (cTime > serverTime.value)
      return null

    let timeToEnd = endTime - serverTime.value
    let isSelected = selectedLetterIdx.value == idx

    return{
      rendObj = ROBJ_SOLID
      watch = [selectedLetterIdx, serverTime]
      size = [flex(), isSelected ? SIZE_TO_CONTENT : messageHeight]
      minHeight = messageHeight
      behavior = Behaviors.Button
      flow = FLOW_HORIZONTAL
      padding = mailPadding
      onClick = @() selectedLetterIdx(idx)
      gap = mailBigPadding
      clipChildren = true
      color = listBgColor(sf, isSelected)
      children = [
        {
          flow = FLOW_VERTICAL
          gap = bigPadding
          children = [
            timeToEnd > 0 ? mkSeasonTime(timeToEnd) : { size = [flex(), hdpx(16)]}
            mkReward(reward, isReceived)
          ]
        }
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = [flex(), isSelected ? SIZE_TO_CONTENT : messageHeight - mailPadding * 2]
          ellipsis = true
          textOverflowY = TOVERFLOW_LINE
          text = loc(text)
          color = listTxtColor(sf, isSelected)
        }.__update(body_txt)
        reward == null || isReceived || timeToEnd <= 0 ? null
          : Bordered(loc("mainmenu/receive"), @() takeLetterReward(guid),
              {
                hplace = ALIGN_RIGHT
                vplace = ALIGN_BOTTOM
                margin = 0
              }
            )
      ]
    }
  })
}

let waitingSpinner = spinner.__update({
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
})

let backBtn = Bordered(loc("BackBtn"), closeUsermailWindow, {
  margin = 0
  hotkeys = [[$"^{JB.B} | Esc", { description = loc("BackBtn") } ]]
})

let lettersBlock = @(letters) letters.len() <= 0 ? noMessagesTitle
  : makeVertScroll(
    {
      size = [flex(), SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = {
        rendObj = ROBJ_SOLID
        size = [flex(), hdpx(2)]
        color = airBgColor
      }
      children = letters.map(@(val, idx) messageRow(val, idx))
    },
    {
      size = flex()
      styling = thinStyle
    }
)

let function centralBlock(){
  let children = []
  if (letters.value.len() > 0)
    children.append(lettersBlock(letters.value))
  else if (!isRequest)
    children.append(noMessagesTitle)
  if (isRequest)
    children.append(waitingSpinner)
  return {
    watch = [letters, isRequest]
    size = flex()
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = isRequest.value ? waitingSpinner : lettersBlock(letters.value)
  }
}

let mailTab = {
  id = "mailTab"
  locId = "mail/mailTab"
  content = centralBlock
}

let topBlock = mkWindowTab(loc(mailTab.locId), @() null, true)

let mailWindow = {
  size = [MAIL_WND_WIDTH, flex()]
  maxWidth = maxContentWidth
  hplace = ALIGN_CENTER
  padding = [fsh(5), 0]
  gap = hdpx(25)
  flow = FLOW_VERTICAL
  children = [
    topBlock
    centralBlock
    backBtn
  ]
}

let function openMailWindow(){
  requestLetters()
  hasUnseenLetters(false)
  sceneWithCameraAdd(mailWindow, "events")
}

if (isUsermailWndOpend.value)
  openMailWindow()

isUsermailWndOpend.subscribe(@(v) v ? openMailWindow() : sceneWithCameraRemove(mailWindow))
