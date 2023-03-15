from "%enlSqGlob/ui_library.nut" import *

let {
  h0_txt, h2_txt, sub_txt, body_txt, tiny_txt
} = require("%enlSqGlob/ui/fonts_style.nut")
let {
  smallPadding, bigPadding, titleTxtColor, activeTxtColor, defBgColor, defTxtColor,
  accentTitleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { blinkUnseenIcon } = require("%ui/components/unseenSignal.nut")
let { timeLeft } = require("bpState.nut")
let { mkSeasonTime, mkRewardIcon, mkRewardImages, rewardWidthToHeight, defCardSize
} = require("rewardsPkg.nut")
let faComp = require("%ui/components/faComp.nut")
let {
  mkHeaderFlag, casualFlagStyle, primeFlagStyle
}= require("%enlSqGlob/ui/mkHeaderFlag.nut")
let { Purchase } = require("%ui/components/textButton.nut")
let { isBooster } = require("%enlist/soldiers/model/boosters.nut")
let {
  mkXpBooster, mkBoosterInfo, mkBoosterLimits
} = require("%enlist/components/mkXpBooster.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { hasEliteBattlePass } = require("eliteBattlePass.nut")
let { getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")

const DAY_SEC = 86400
const BP_LEFT_DAYS_ALERT = 3

let sizeBlocks        = fsh(40)
let hugePadding       = bigPadding * 4
let sizeIcon          = hdpx(35)
let sizeCard          = [hdpx(180), hdpx(230)]
let imageHeight       = hdpx(210)
let imageSize         = [rewardWidthToHeight * imageHeight, imageHeight]
let btnSize           = [hdpx(270), hdpx(55)]
let cardSelectAnim    = [ { prop = AnimProp.translate, duration = 0.15, easing = InOutCubic } ]
let cardStateCommon   = { translate = [0, 0] }
let cardStateSelected = { translate = [0, -hugePadding] }
let gapCards          = hdpx(32)
let lockBPLarge       = [hdpxi(90), hdpxi(90)]
let bgFree            = [hdpxi(180), hdpxi(30)]
let logoBP            = [hdpxi(40), hdpxi(40)]
let lockBPSmall       = [hdpxi(40), hdpxi(40)]
let unseenIcon = blinkUnseenIcon(1.3, accentTitleTxtColor).__update({ pos = [-hdpx(36), -bigPadding] })

let timeTracker = @() {
  watch = timeLeft
  gap = bigPadding
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("bp/timeLeft")
      color = defTxtColor
    }
    timeLeft.value > 0 ? mkSeasonTime(timeLeft.value) : null
  ]
}

let curItemName = @(locId) locId == null ? null : {
  rendObj = ROBJ_TEXT
  padding = [bigPadding, 0]
  text = loc(locId)
  color = titleTxtColor
}.__update(h2_txt)

let textAreaStyle = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
}.__update(sub_txt)

let curItemDescription = @(locId) locId == null ? null : {
  size = [hdpx(500), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  margin = [bigPadding, 0]
  color = titleTxtColor
  text = loc(locId)
}.__update(textAreaStyle)

let function lockScreenBlock() {
  let res = { watch = hasEliteBattlePass }
  if (hasEliteBattlePass.value)
    return res

  return res.__update({
    pos = [0, sh(49)]
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("bp/required")
        color = titleTxtColor
      }.__update(h2_txt)
      {
        rendObj = ROBJ_IMAGE
        pos = [-sh(0.5), -sh(22)]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        behavior = Behaviors.Button
        size = lockBPLarge
        onHover = @(on) setTooltip(on ? loc("bp/required/tip") : null)
        image = Picture($"!ui/uiskin/battlepass/lock_bp.svg:{lockBPLarge[0]}:{lockBPLarge[1]}:K")
      }
    ]
  })
}

let function bpItemInfo(showingItem) {
  if (showingItem == null)
    return null

  let itemName = curItemName(showingItem?.name)
  let itemDescription = curItemDescription(showingItem?.description)
  let specialDescription = (showingItem?.isSpecial ?? false)
    ? curItemDescription(loc("bp/otherRewardsAvailable", {
      weapon = getItemName(showingItem.gametemplate)
    }))
    : null
  return {
    size = flex()
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      {
        flow = FLOW_VERTICAL
        hplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          itemName
          itemDescription
          specialDescription
        ]
      }
    ]
  }
}

let bpTitle = @(hasPremiumBp, tailWidth = null) mkHeaderFlag(
  {
    padding = [bigPadding * 2, bigPadding * 3]
    rendObj = ROBJ_TEXT
    text = hasPremiumBp ? loc("bp/eliteBP") : loc("bp/battlePass")
  }.__update(h0_txt),
  {
    tail = tailWidth
    transform = {}
    animations = [
      { prop = AnimProp.translate, from = [-sizeBlocks, 0], to = [0, 0], duration = 0.2,
        easing = InOutCubic, play = true }
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5,
        easing = InOutCubic, play = true }
    ]
  }.__update(hasPremiumBp ? primeFlagStyle : casualFlagStyle)
)

let function mkEndSeasonMessage() {
  let hasAlert = Computed(@() timeLeft.value <= BP_LEFT_DAYS_ALERT * DAY_SEC)
  return @() {
    watch = hasAlert
    size = [fsh(36), hdpx(180)]
    children = !hasAlert.value ? null
      : [
          {
            size = [flex(), SIZE_TO_CONTENT]
            text = loc("bp/endSeasonMsg")
            color = accentTitleTxtColor
          }.__update(textAreaStyle, tiny_txt)
          unseenIcon
        ]
  }
}

let bpHeader = @(showingItem, closeButton, needLockScreen = true) {
  size = [flex(), SIZE_TO_CONTENT]
  gap = hdpx(100)
  margin = [hugePadding,0,0,0]
  children = [
    {
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        timeTracker
        mkEndSeasonMessage()
      ]
    }
    bpItemInfo(showingItem)
    needLockScreen && (showingItem?.isPremium || showingItem?.isSpecial)
      ? lockScreenBlock
      : null
    closeButton
  ]
}

let cardIconReceivedHeader = faComp("check", {
  padding = smallPadding
  fontSize = hdpx(15)
  color = activeTxtColor
  hplace = ALIGN_CENTER
})

let mkCardTopText = @(text) {
  rendObj = ROBJ_IMAGE
  image = Picture($"!ui/uiskin/battlepass/bg_free.svg:{bgFree[0]}:{bgFree[1]}:K")
  size = bgFree
  children = {
    rendObj = ROBJ_TEXT
    padding = smallPadding
    text
    color = activeTxtColor
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
  }.__update(sub_txt)
}

let cardFreeHeader = mkCardTopText(loc("bp/freeReward"))


let function cardPremiumHeader() {
  local iconData = hasEliteBattlePass.value
    ? {
      size = logoBP
      image = Picture($"!ui/uiskin/battlepass/bp_logo.svg:{logoBP[0]}:{logoBP[1]}:K")
    } : {
      size = lockBPSmall
      image = Picture($"!ui/uiskin/battlepass/lock_bp.svg:{lockBPSmall[0]}:{lockBPSmall[1]}:K")
    }
  return {
    watch = hasEliteBattlePass
    hplace = ALIGN_CENTER
    pos = [0, -hdpx(30)]
    children = {
      rendObj = ROBJ_IMAGE
      behavior = Behaviors.Button
      onHover = @(on) setTooltip(!on ? null
        : hasEliteBattlePass.value ? loc("bp/reward")
        : loc("bp/required/tip")
      )
    }.__update(iconData)
  }
}

let cardCount = @(count, style = {}) {
  children = {
    rendObj = ROBJ_TEXT
    padding = [0, smallPadding]
    text = count > 99 ? count : loc("common/amountShort", { count = count })
    color = accentTitleTxtColor
  }.__update(body_txt)
}.__update(style)

let mkCardCountCtor = @(size, fontStyle) @(count) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  margin = bigPadding
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  image = Picture($"!ui/uiskin/battlepass/Ellipse.svg:{size}:{size}:K")
  children = {
    rendObj = ROBJ_TEXT
    padding = [0, smallPadding]
    text = count > 99 ? count : loc("common/amountShort", { count = count })
    color = titleTxtColor
  }.__update(fontStyle)
}

let cardCountCircle = mkCardCountCtor(hdpxi(43), body_txt)
let cardCountCircleSmall = mkCardCountCtor(hdpxi(30), sub_txt)

let cardBottom = @(count, cardIcon){
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  margin = bigPadding
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  children = [
    {
      size = [flex(), sizeIcon]
      flow = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      valign = ALIGN_BOTTOM
      children = [
        cardCount(count)
        cardIcon
      ]
    }
  ]
}

let function mkCard(reward, count, templates, onClick, isSelected, isReceived, isPremium, addToContainer) {
  let template = templates?[reward?.itemTemplate]
  local cardChildren = []

  let verticalPos = -(0.09 * imageSize[0]).tointeger()
  if (isBooster(template)) {
    cardChildren = [
      {
        size = defCardSize
        pos = [0, verticalPos]
        hplace = ALIGN_CENTER
        children = mkXpBooster(template)
          .__update({ margin = 0 })
      }
      {
        size = flex()
        padding = bigPadding
        children = [
          mkBoosterInfo(template, body_txt.__merge({ color = activeTxtColor }))
          mkBoosterLimits(template, body_txt.__merge({ color = activeTxtColor }))
        ]
      }
      isReceived ? null : isPremium ? cardPremiumHeader : null
    ]
  }
  else {
    let cardIcon = mkRewardIcon(reward, sizeIcon, { vplace = ALIGN_CENTER })
    let cardImages = mkRewardImages(reward, imageSize, {
      pos = [0, verticalPos], hplace = ALIGN_CENTER
    })
    cardChildren = [
      cardImages
      cardBottom(count, cardIcon)
      isReceived ? null : isPremium ? cardPremiumHeader : null
    ]
  }

  let cardBlock = {
    size = sizeCard
    rendObj = ROBJ_SOLID
    color = defBgColor
    children = cardChildren
  }
  return @() {
    watch = isSelected
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    vplace = ALIGN_BOTTOM
    halign = ALIGN_CENTER
    gap = bigPadding * 2
    children = [
      {
        xmbNode = XmbNode()
        behavior = Behaviors.Button
        onClick
        flow = FLOW_VERTICAL
        gap = 0.1 * imageHeight //FIXME: icon offset
        children = [
          isReceived ? cardIconReceivedHeader : isPremium ? null : cardFreeHeader
          cardBlock
        ]
        transform = isSelected.value ? cardStateSelected : cardStateCommon
        transitions = cardSelectAnim
        animations = isSelected.value
          ? [
              { prop = AnimProp.translate, from = [0, 0], to = cardStateSelected.translate,
                duration = 0.6, easing = InOutCubic, play = true }
              { prop=AnimProp.scale from=[0,1], to=[1,1], duration=0.6, play=true, easing=InOutCubic}
            ]
          : null
        sound = {
          hover = "ui/enlist/button_highlight"
          click = "ui/enlist/button_click"
        }
      }
      addToContainer
    ]
  }
}

let btnBuyPremiumPass = @(txt, cb) Purchase(txt, cb,
  {
    size = btnSize
    margin = 0
    hotkeys = [["^J:Y", { description = { skip = true }}]]
  })

return {
  timeTracker
  bpTitle
  bpHeader
  mkCard
  sizeBlocks
  hugePadding
  sizeIcon
  sizeCard
  btnSize
  btnBuyPremiumPass
  cardCount
  cardCountCircle
  cardCountCircleSmall
  imageSize
  gapCards
}
