from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  bigPadding, soldierLvlColor, activeTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let JB = require("%ui/control/gui_buttons.nut")
let textButton = require("%ui/components/textButton.nut")
let { withTooltip } = require("%ui/style/cursors.nut")
let { get_time_msec } = require("dagor.time")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { getObjectName, getItemDesc } = require("%enlSqGlob/ui/itemsInfo.nut")
let closeBtnBase = require("%ui/components/closeBtn.nut")
let {
  sceneWithCameraAdd, sceneWithCameraRemove
} = require("%enlist/sceneWithCamera.nut")
let { curSelectedItem } = require("%enlist/showState.nut")
let mkAnimatedItemsBlock = require("%enlist/soldiers/mkAnimatedItemsBlock.nut")
let { mkSoldierMedalIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { sound_play } = require("sound")
let { mkTierStars } = require("%enlSqGlob/ui/itemTier.nut")
let {
  needNewItemsWindow, newItemsToShow, markNewItemsSeen, justPurchasedItems
} = require("model/newItemsToShow.nut")
let { specialUnlock } = require("%enlist/unlocks/dailyRewardsState.nut")
let { activeUnlocks } = require("%enlSqGlob/userstats/unlocksState.nut")
let { makeVertScroll } = require("%ui/components/scrollbar.nut")


const SHOW_ITEM_DELAY = 1.0 //wait for fadeout
const ITEM_SELECT_DELAY = 0.01
const ANIM_TRIGGER = "reward_items_wnd_anim"
const ANIM_TEXT_TRIGGER = "reward_text_wnd_anim"
const ANIM_TITLE_TRIGGER = "reward_title_wnd_anim"

const STAR_DEF_DURATION = 0.2
const STAR_BLICK_DURATION = 0.4
const STAR_DEF_DELAY = 0.2
const STAR_DEF_DELAY_INCREASE = 0.1
const STAR_NEXT_DELAY = 0.3

let curItem = Watched(null)
curItem.subscribe(function(v) {
  if (v != null )
    gui_scene.setTimeout(ITEM_SELECT_DELAY, function() {
      curSelectedItem(v)
      anim_start(ANIM_TEXT_TRIGGER)
    })
  else
    curSelectedItem(null)
})

let wndCanBeClosed = Watched(true)

local animEndTime = -1

let function tryMarkSeen() {
  if (animEndTime > get_time_msec()) {
    anim_skip($"{ANIM_TRIGGER}_skip")
    anim_skip_delay(ANIM_TRIGGER)
    animEndTime = -1
    return
  }
  markNewItemsSeen()
}

let textAnimations = @(trigger = null) [
  { trigger = trigger, prop = AnimProp.opacity,
    from = 0, to = 1, duration = 0.8, play = true, easing = InOutCubic }
  { trigger = trigger, prop = AnimProp.scale,
    from = [1.5, 2], to = [1, 1], duration = 0.3, play = true, easing = InOutCubic }
]

let title = @(titleText) {
  rendObj = ROBJ_TEXTAREA
  size = [flex(), SIZE_TO_CONTENT]
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  margin = [bigPadding * 4, 0]
  transform = {}
  animations = textAnimations(ANIM_TITLE_TRIGGER)
  text = loc(titleText)
}.__update(h2_txt)

let curItemDescription = @(item) {
  size = [sw(50), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  margin = [0, 0, hdpx(25), 0]
  text = getItemDesc(item)
  transform = {}
  animations = textAnimations(ANIM_TEXT_TRIGGER)
}.__update(body_txt)

let function soldierMedal(soldier) {
  if (soldier?.itemtype != "soldier")
    return null

  let medal = mkSoldierMedalIcon(soldier, hdpx(24))
  return medal == null ? null
    : withTooltip(medal, @() loc("hero/medal"))
}

let curItemName = @(item) {
  flow = FLOW_HORIZONTAL

  gap = bigPadding
  valign = ALIGN_CENTER
  padding = [bigPadding, 0]
  transform = {}
  animations = textAnimations(ANIM_TEXT_TRIGGER)
  children = [
    {
      rendObj = ROBJ_TEXT
      size = SIZE_TO_CONTENT
      text =  getObjectName(item)
    }.__update(h2_txt)
    soldierMedal(item)
  ]
}

let underline = {
  rendObj = ROBJ_SOLID
  size = [pw(80), hdpx(1)]
  color = Color(100, 100, 100, 50)
}

let casualStarAnim = @(delay = 0, starCount = 1) [
  {
    prop = AnimProp.opacity, from = 0, to = 0,
    duration = delay, play = true, easing = InOutCubic
  }
  {
    prop = AnimProp.opacity, from = 0, to = 1,
    duration = STAR_DEF_DURATION, delay = delay,
    play = true, easing = InOutCubic,
    onFinish = @() sound_play("ui/order_fulfiled_star")
  }
  {
    prop = AnimProp.color, from = soldierLvlColor, to = activeTxtColor,
    duration = STAR_BLICK_DURATION, delay = STAR_NEXT_DELAY * starCount,
    play = true, easing = Blink
  }
]

let advancedStarAnim = @(delay = 0, starCount = 1, idx = 1) [
  {
    prop = AnimProp.opacity, from = 0, to = 0,
    duration = delay, play = true, easing = InOutCubic
  }
  {
    prop = AnimProp.opacity, from = 0, to = 1,
    duration = STAR_DEF_DURATION, delay = delay,
    play = true, easing = InOutCubic,
    onFinish = @() sound_play("ui/order_fulfiled_star")
  }
  {
    prop = AnimProp.color, from = soldierLvlColor, to = activeTxtColor,
    duration = STAR_DEF_DURATION, delay = STAR_DEF_DELAY_INCREASE * starCount + delay,
    play = true, easing = Blink,
    onFinish = @() sound_play( idx == 1 ? "ui/order_fulfiled_top" : "")
  }
  { prop = AnimProp.scale, from =[1.0, 1.0], to = [1.4, 1.4],
    duration = STAR_DEF_DURATION, delay = STAR_DEF_DELAY_INCREASE * starCount + delay,
    play = true,  easing = InOutCubic
  }
]

let function animatedStars(item){
  if (item?.itemtype != "soldier")
    return null
  local delay = 0.2
  let tier = item?.tier ?? 0
  let stars = array(tier, 1)
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    padding = [0,0,fsh(1),0]
    onAttach = tier >= 4
      ? function(){
          wndCanBeClosed(false)
          gui_scene.setTimeout(tier * (STAR_DEF_DURATION + STAR_DEF_DELAY),
          @() wndCanBeClosed(true))
        }
      : null
    children = stars.map(@(star, idx) function(){
      delay += STAR_DEF_DELAY_INCREASE
      return mkTierStars(star, {
        fontSize = hdpx(45),
        transform = {}
        animations = tier <= 3
          ? casualStarAnim(delay, tier)
          : advancedStarAnim(delay, tier, idx + 1)
        padding = bigPadding
      })
    })
  }
}

let function newIemsWndContent() {
  let itemsToShow = newItemsToShow.value
  if (itemsToShow == null)
    return null

  let { itemsGuids, soldiersGuids, allItems, header } = itemsToShow
  justPurchasedItems(clone itemsGuids)

  let itemsCount = itemsGuids.len()
  let soldiersCount = soldiersGuids.len()
  let subtitle = itemsCount > 1 ? "delivery/items"
    : itemsCount == 1 ? "delivery/item"
    : soldiersCount > 1 ? "delivery/soldiers"
    : "delivery/soldier"

  sound_play( itemsCount > 0 ? "ui/weaponry_delivery" : "ui/troops_reinforcement")

  let animBlock = mkAnimatedItemsBlock({ items = allItems }, {
    width = sw(80)
    addChildren = []
    hasAnim = true
    baseAnimDelay = SHOW_ITEM_DELAY
    animTrigger = ANIM_TRIGGER
    hasItemTypeTitle = false
    selectedKey = curItem
    onItemClick = @(item) curItem(item)
    onVisibleCb = function() {
      sound_play("ui/debriefing/new_equip")
    }
    isDisarmed = true
  })

  animEndTime = get_time_msec() + 1000 * animBlock.totalTime
  let curItemValue = curItem.value
  let specialUnlockHeader =
    activeUnlocks.value?[specialUnlock.value].meta.congratulationLangId ?? ""
  return {
    watch = [newItemsToShow, curItem, specialUnlock]
    size = [sw(80), fsh(86)]
    flow = FLOW_VERTICAL
    gap = bigPadding
    halign = ALIGN_CENTER

    children = [
      title(specialUnlockHeader == "" ? header : specialUnlockHeader)
      underline
      {
        size = flex()
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          curItemName(curItemValue)
          { size = flex() }
          curItemDescription(curItemValue)
        ]
      }
      animatedStars(curItemValue)
      underline
      title(subtitle)
      {
        margin = [hdpx(50), 0, 0, 0]
        size = [pw(100), SIZE_TO_CONTENT]
        children =  makeVertScroll(animBlock.component,
          {
            halign = ALIGN_CENTER
            size = [flex(), SIZE_TO_CONTENT]
            maxHeight = sh(25)
          }
        )
      }
    ]
  }
}

let newItemsWnd = @() {
  watch = [ safeAreaBorders, wndCanBeClosed]
  key = $"newItemsWindow"
  size = flex()
  padding = safeAreaBorders.value
  halign = ALIGN_CENTER
  behavior = Behaviors.MenuCameraControl
  flow = FLOW_VERTICAL
  children = [
    {
      margin = [bigPadding * 4, 0, 0, 0]
      hplace = ALIGN_RIGHT
      size = [flex(), fsh(2)]
      children = wndCanBeClosed.value ? closeBtnBase({onClick = tryMarkSeen}) : null
    }
    newIemsWndContent
    {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      children = wndCanBeClosed.value
        ? textButton(loc("Ok"), tryMarkSeen, {
            hotkeys = [["^{0} | Esc | Space | Enter".subst(JB.B), { description = loc("Close") }]]
          })
        : null
    }
  ]
}

let function close() {
  sceneWithCameraRemove(newItemsWnd)
  curItem(null)
}

let function open() {
  anim_start(ANIM_TITLE_TRIGGER)
  sceneWithCameraAdd(newItemsWnd, "new_items")
  curItem(newItemsToShow.value?.allItems[0])
}

if (needNewItemsWindow.value || specialUnlock.value != null)
  open()

needNewItemsWindow.subscribe(@(v) v ? open() : close())
