from "%enlSqGlob/ui_library.nut" import *

let { doesLocTextExist } = require("dagor.localize")
let hoverHoldAction = require("%darg/helpers/hoverHoldAction.nut")
let spinner = require("%ui/components/spinner.nut")
let openUrl = require("%ui/components/openUrl.nut")
let { currenciesList } = require("%enlist/currency/currencies.nut")
let { sub_txt, body_txt, h2_txt, fontawesome } = require("%enlSqGlob/ui/fonts_style.nut")
let fa = require("%ui/components/fontawesome.map.nut")
let { txt } = require("%enlSqGlob/ui/defcomps.nut")
let {addModalWindow, removeModalWindow} = require("%ui/components/modalWindows.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let {
  mkPortraitFrame, mkPortraitIcon, mkDisabledPortraitIcon,
  mkNickFrame, mkExpireTime, PORTRAIT_SIZE, NICKFRAME_SIZE, mkRatingBlock
} = require("decoratorPkg.nut")
let {
  portraitCfgAvailable, nickFramesCfgAvailable, buyDecorator,
  portraitsConfig, availPortraits, chosenPortrait, chooseDecorator,
  nickFramesConfig, availNickFrames, chosenNickFrame,
  decoratorInPurchase
} = require("decoratorState.nut")
let {
  bigPadding, titleTxtColor, blurBgColor, bigOffset, tinyOffset, smallPadding,
  defBgColor, bonusColor, smallOffset
} = require("%enlSqGlob/ui/viewConst.nut")
let { basePortrait } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let {
  mkFooterWithBackButton, borderColor, txtColor, PROFILE_WIDTH
} = require("profilePkg.nut")
let { makeVertScroll, thinStyle } = require("%ui/components/scrollbar.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { mkCurrency } = require("%enlist/currency/currenciesComp.nut")
let {
  seenDecorators, unopenedPortraits, unopenedNickFrames, markSeenDecorator, markDecoratorsOpened,
  hasUnseenPortraits, hasUnseenNickFrames
} = require("unseenProfileState.nut")
let { Bordered } = require("%ui/components/textButton.nut")
let { is_pc } = require("%dngscripts/platform.nut")
let { playerRank, hasRankUnseen } = require("%enlist/profile/rankState.nut")
let isChineseVersion = require("%enlSqGlob/isChineseVersion.nut")
let { smallUnseenNoBlink, smallUnseenBlink } = require("%ui/components/unseenComps.nut")


const PORTRAIT_WND_UID = "SelectPortraitWnd"
const NICKFRAME_WND_UID = "SelectNickFrameWnd"
const MAX_PORTRAIT_IN_ROW = 7
const MAX_NICKS_IN_ROW = 3
const NICKFRAME_COLUMNS = 7
const PORTRAIT_COLUMNS = 6

let CHANGE_NICK_URL = "https://store.gaijin.net/profile.php?view=change_nick"
let portraitListWidth = (PORTRAIT_SIZE + bigPadding) * PORTRAIT_COLUMNS
let nickFrameListWidth = (NICKFRAME_SIZE + bigPadding) * NICKFRAME_COLUMNS
let hoverNickFrame = Watched("")

let mkCloseButtonCb = @(wndUid) @() removeModalWindow(wndUid)
let mkIcon = @(text, color) txt({ text, color }).__merge(fontawesome)
let iconParam = {
  hplace = ALIGN_RIGHT
  margin = bigPadding
  fontFxColor = Color(0,0,0)
  fontFxFactor = min(64,hdpx(64))
  fontFx = FFT_GLOW
}

let function mkPortraitCost(portraitCfg, override = {}) {
  let { buyData = null } = portraitCfg
  let { currencyId = "", price = 0 } = buyData
  return currencyId == "" && price <= 0 ? null
    : function() {
        let currency = currenciesList.value.findvalue(@(c) c.id == currencyId)
        return {
          watch = currenciesList
          children = currency == null ? null
            : mkCurrency({
                currency
                price
              }).__update({
                margin = bigPadding
                hplace = ALIGN_CENTER
                vplace = ALIGN_BOTTOM
              })
        }.__update(override)
      }
}

let function onNickFrameClick(nickFrameCfg, isEnabled) {
  let { guid = "", buyData = null } = nickFrameCfg

  if (isEnabled) {
    removeModalWindow(NICKFRAME_WND_UID)
    if ((chosenNickFrame.value?.guid ?? "") != guid)
      chooseDecorator("nickFrame", guid)
    return
  }

  let { currencyId = "", price = 0 } = buyData
  if (currencyId != "" && price > 0) {
    purchaseMsgBox({
      price
      currencyId
      description = loc("buyNickFrameConfirm")
      productView = mkNickFrame(nickFrameCfg)
      purchase = @() buyDecorator(guid, price)
      alwaysShowCancel = true
      srcComponent = "buy_decorator"
    })
  }
}

let function mkTooltip(decorator) {
  let locId = $"decorator/{decorator.guid}/tip"
  let { currencyId = "", price = 0 } = decorator?.buyData
  return doesLocTextExist(locId) ? loc(locId)
    : currencyId != "" && price > 0 ? loc("decorator/canBeBoughtTip")
    : loc("decorator/eventRewardTip")
}

let function nickFrameListUi() {
  let userName = userInfo.value?.nameorig ?? ""
  let availList = availNickFrames.value
  let nickFrameList = [null].extend(nickFramesCfgAvailable.value)
  let chosenGuid = chosenNickFrame.value?.guid ?? ""
  let curPurchase = decoratorInPurchase.value
  let unseen = seenDecorators.value?.unseen ?? {}
  let chosen = nickFrameList.findvalue(@(v) v?.guid == chosenGuid)
  return {
    watch = [
      chosenNickFrame, nickFramesCfgAvailable, availNickFrames,
      userInfo, seenDecorators, decoratorInPurchase
    ]
    size = [nickFrameListWidth, flex()]
    flow = FLOW_VERTICAL
    gap = smallOffset
    margin = [0,0,bigOffset,0]
    onAttach = @() hoverNickFrame(chosen?.framedNickName(userName) ?? userName)
    children = [
      txt({
        text = loc("selectNickFrameTitle")
        padding = [0, 0, tinyOffset, 0]
      }).__update(h2_txt)
      @() {
        watch = hoverNickFrame
        children = txt({
          text = hoverNickFrame.value
          padding = [0, 0, tinyOffset, 0]
        }).__update(h2_txt)
      }
      makeVertScroll({
        size = [flex(), SIZE_TO_CONTENT]
        children = wrap(nickFrameList.map(function(nickFrameCfg) {
          let guid = nickFrameCfg?.guid ?? ""
          let receivedData = guid == ""
            ? null : availList.findvalue(@(n) n.guid == guid)

          let isSelected = guid == chosenGuid
          let isEnabled = guid == "" || receivedData != null
          let expireTime = receivedData?.expireTime ?? 0
          let isUnseen = guid in unseen
          return {
            size = [NICKFRAME_SIZE, NICKFRAME_SIZE]
            children = [
              watchElemState(function(sf) {
                let addIcon = !isEnabled ? fa["lock"]
                  : isSelected ? fa["check"]
                  : null
                let iconColor = isSelected ? bonusColor : borderColor(sf, isEnabled)
                return {
                  behavior = Behaviors.Button
                  onClick = @() onNickFrameClick(nickFrameCfg, isEnabled)
                  onHover = function(on) {
                    hoverNickFrame((on ? nickFrameCfg : chosen)?.framedNickName(userName) ?? userName)
                    if (!isEnabled)
                      setTooltip(on ? mkTooltip(nickFrameCfg) : null)
                    if (isUnseen)
                      hoverHoldAction("merkSeenDecorator", guid, @(v) markSeenDecorator(v))(on)
                  }
                  children = [
                    mkNickFrame(nickFrameCfg, borderColor(sf, isEnabled), borderColor(sf))
                    mkIcon(addIcon, iconColor).__update(iconParam)
                  ]
                }
              })
              !isEnabled ? mkPortraitCost(nickFrameCfg, {
                    margin = smallPadding
                    hplace = ALIGN_RIGHT
                    vplace = ALIGN_BOTTOM
                  })
                : expireTime > 0 ? mkExpireTime(expireTime)
                : null
              curPurchase != guid ? null
                : spinner().__update({ hplace = ALIGN_CENTER, vplace = ALIGN_CENTER })
              !isUnseen ? null : smallUnseenNoBlink
            ]
          }
        }), {
          width = nickFrameListWidth
          hGap = bigPadding
          vGap = bigPadding
        })}, {
          styling = thinStyle
        }
      )
    ]
  }
}

let modalWndStyle = {
  watch = safeAreaBorders
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = flex()
  padding = safeAreaBorders.value
  halign = ALIGN_CENTER
  color = blurBgColor
}

let function openFrameWnd(key, content) {
  addModalWindow({
    key
    size = flex()
    onClick = @() null
    children = @() {
      children = {
        size = [PROFILE_WIDTH, flex()]
        flow = FLOW_VERTICAL
        padding = [bigOffset, 0]
        children = [
          content
          mkFooterWithBackButton(mkCloseButtonCb(key))
        ]
      }
    }.__update(modalWndStyle)
  })
}


let function onPortraitClick(portraitCfg, isEnabled) {
  let { guid = "", buyData = null } = portraitCfg

  if (isEnabled) {
    removeModalWindow(PORTRAIT_WND_UID)
    if ((chosenPortrait.value?.guid ?? "") != guid)
      chooseDecorator("portrait", guid)
    return
  }

  let { currencyId = "", price = 0 } = buyData
  if (currencyId != "" && price > 0) {
    purchaseMsgBox({
      price
      currencyId
      description = loc("buyPortraitConfirm")
      productView = mkPortraitFrame([ mkPortraitIcon(portraitCfg) ])
      purchase = @() buyDecorator(guid, price)
      alwaysShowCancel = true
      srcComponent = "buy_decorator"
    })
  }
}

let timerStyle = {
  rendObj = ROBJ_SOLID
  color = defBgColor
}

let function portraitListUi() {
  let availList = availPortraits.value
  let portraitList = [basePortrait].extend(portraitCfgAvailable.value)
  let curPurchase = decoratorInPurchase.value
  let unseen = seenDecorators.value?.unseen ?? {}
  let chosenGuid = chosenPortrait.value?.guid ?? ""
  return {
    watch = [portraitCfgAvailable, availPortraits, decoratorInPurchase, seenDecorators, chosenPortrait]
    size = [portraitListWidth, flex()]
    flow = FLOW_VERTICAL
    gap = bigOffset
    margin = [0,0,bigOffset,0]
    children = [
      txt({
        text = loc("selectPortraitTitle")
        padding = [0, 0, tinyOffset, 0]
      }).__update(h2_txt)
      makeVertScroll({
        size = [flex(), SIZE_TO_CONTENT]
        children = wrap(portraitList.map(function(portraitCfg) {
          let { guid = "" } = portraitCfg
          let isSelected = guid == chosenGuid
          let receivedData = guid == ""
            ? null : availList.findvalue(@(p) p.guid == guid)

          let isEnabled = guid == "" || receivedData != null
          let expireTime = receivedData?.expireTime ?? 0
          let isUnseen = guid in unseen
          let onClick = @() onPortraitClick(portraitCfg, isEnabled)
          let onHover = function(on) {
            if (!isEnabled)
              setTooltip(on ? mkTooltip(portraitCfg) : null)
            if (isUnseen)
              hoverHoldAction("merkSeenDecorator", guid, @(v) markSeenDecorator(v))(on)
          }
          let children = [
            isEnabled
              ? mkPortraitIcon(portraitCfg)
              : mkDisabledPortraitIcon(portraitCfg),
            !isEnabled ? mkPortraitCost(portraitCfg, {
                  margin = smallPadding
                  hplace = ALIGN_RIGHT
                  vplace = ALIGN_BOTTOM
                })
              : expireTime > 0 ? mkExpireTime(expireTime, timerStyle)
              : null
          ]
          let iconCtor = function(sf) {
            let addIcon = !isEnabled ? fa["lock"]
              : isSelected ? fa["check"]
              : null
            let iconColor = isSelected ? bonusColor : borderColor(sf, isEnabled)
            return mkIcon(addIcon, iconColor).__update(iconParam)
          }

          return {
            children = [
              mkPortraitFrame(children, onClick, onHover, iconCtor)
              curPurchase != guid ? null
                : spinner().__update({ hplace = ALIGN_CENTER, vplace = ALIGN_CENTER })
              !isUnseen ? null : smallUnseenNoBlink
            ]
          }
        }), {
          width = portraitListWidth
          hGap = bigPadding
          vGap = bigPadding
        })}, {
          styling = thinStyle
        }
      )
    ]
  }
}

let mkChangeNickFrameBtn = @(hasUnseen, hasUnopened) watchElemState(@(sf) {
  rendObj = ROBJ_BOX
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  padding = [bigPadding, 0]
  valign = ALIGN_CENTER
  borderWidth = [0,0,hdpx(1),0]
  borderColor = borderColor(sf)
  behavior = Behaviors.Button
  function onClick() {
    markDecoratorsOpened(unopenedNickFrames.value)
    openFrameWnd(NICKFRAME_WND_UID, nickFrameListUi)
  }
  children = [
    txt({
      text = loc("profile/changeNameDecorator")
      color = txtColor(sf)
    }).__update(sub_txt)
    mkIcon(fa["pencil"], borderColor(sf))
    !hasUnseen ? null
      : {
          size = [0, flex()]
          children = hasUnopened ? smallUnseenBlink : smallUnseenNoBlink
        }
  ]
})

let decoratorBlock = {
  flow = FLOW_HORIZONTAL
  size = [flex(), SIZE_TO_CONTENT]
  gap = fsh(5)
  valign = ALIGN_CENTER
  children = [
    function() {
      let portraitCfg = (portraitsConfig.value ?? [])
        .findvalue(@(p) p.guid == chosenPortrait.value?.guid) ?? basePortrait
      let children = [ mkPortraitIcon(portraitCfg) ]
      let function onClick() {
        markDecoratorsOpened(unopenedPortraits.value)
        openFrameWnd(PORTRAIT_WND_UID, portraitListUi)
      }
      let addObject = @(sf) mkIcon(fa["pencil"], borderColor(sf)).__update(iconParam)
      let hasUnseen = hasUnseenPortraits.value
      let hasUnopened = unopenedPortraits.value.len() > 0
      return {
        watch = [chosenPortrait, portraitsConfig, hasUnseenPortraits, unopenedPortraits]
        children = [
          mkPortraitFrame(children,
            onClick,
            @(on) setTooltip(on ? loc("profile/changePortraitDecorator") : null),
            addObject
          )
          !hasUnseen ? null : hasUnopened ? smallUnseenBlink : smallUnseenNoBlink
        ]
      }
    }
    function() {
      let nickFrame = (nickFramesConfig.value ?? [])
        .findvalue(@(p) p.guid == chosenNickFrame.value?.guid)
      let userName = userInfo.value?.nameorig ?? ""
      let nickName = nickFrame?.framedNickName(userName) ?? userName
      let hasUnseen = hasUnseenNickFrames.value
      let hasUnopened = unopenedNickFrames.value.len() > 0
      return {
        watch = [
          chosenNickFrame, nickFramesConfig, userInfo, hasUnseenNickFrames,
          unopenedNickFrames
        ]
        flow = FLOW_VERTICAL
        gap = fsh(2)
        valign = ALIGN_CENTER
        children = [
          txt({
            text = nickName
            color = titleTxtColor
          }).__update(body_txt)
          mkChangeNickFrameBtn(hasUnseen, hasUnopened)
          !is_pc || isChineseVersion ? null
            : Bordered(loc("profile/changeNick"), @() openUrl(CHANGE_NICK_URL),
                {
                  margin = 0
                  hotkeys = [["^J:Y"]]
                }
              )
        ]
      }
    }
  ]
}
return {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  children = [
    decoratorBlock
    mkRatingBlock(playerRank, hasRankUnseen)
  ]
}

