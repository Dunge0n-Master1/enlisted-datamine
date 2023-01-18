from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let { perkChoiceWndParams, perksData, choosePerk, showActionError
} = require("%enlist/soldiers/model/soldierPerks.nut")
let { mkText, perkIcon, flexTextArea, getStatDescList, mkPerkCostChildren
} = require("%enlist/soldiers/components/perksPackage.nut")
let perksList = require("%enlist/meta/perks/perksList.nut")
let { perksStatsCfg } = require("%enlist/meta/perks/perksStats.nut")
let perksPoints = require("%enlist/meta/perks/perksPoints.nut")
let { sound_play } = require("sound")
let { defTxtColor, gap, bigPadding, activeBgColor, perkBigIconSize, defBgColor
} = require("%enlSqGlob/ui/viewConst.nut")
let textButton = require("%ui/components/textButton.nut")


let COST_ICON_PAIR_WIDTH = hdpx(50)
let BG_HOVER = Color(35, 35, 35, 255)
let BG_PREV_PERK = Color(55, 55, 55, 255)
let thumbIconSize = hdpxi(35)

let sPerks = Computed(@() perksData.value?[perkChoiceWndParams.value?.soldierGuid])

let needShow = Computed(@() sPerks.value != null
  && (perkChoiceWndParams.value?.choice.len() ?? 0) > 0)

let close = function() {
  perkChoiceWndParams(null)
}

let function applyButton(selectedPerk, hasPrevPerk, hovered){

  let function onChoose() {
    if (!needShow.value)
      return
    let { soldierGuid, tierIdx, slotIdx} = perkChoiceWndParams.value
    choosePerk(soldierGuid, tierIdx, slotIdx, selectedPerk,
      function(res) {
        if (!res?.isSuccess)
          showActionError(res?.errorText ?? "unknown error")
        else {
          defer(function() {
            anim_start($"tier{tierIdx}slot{slotIdx}")
            anim_start($"{soldierGuid}lvl_anim")
          })
        }
        close()
      })
    sound_play("ui/craft")
  }

  let btnActiveColor = 0xfa0982ca
  let btnStateFlag = Watched(0)

  let btnHotkeys = [[ $"^{JB.A} | Enter", {
    action = onChoose
    description = { skip = true }
    sound="click"
  }]]

  return @(){
    watch = [btnStateFlag, hovered]
    behavior = Behaviors.Button
    onElemState = @(sf) btnStateFlag(sf)
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    margin = [0,0,hdpx(20),0]
    children = textButton.PrimaryFlat(
      loc(hasPrevPerk ? "btn/keepPerk" : "btn/receivePerk"),
        onChoose,
      {
        style = {
          BgNormal = hovered.value ? btnActiveColor : activeBgColor
        }
        size = [SIZE_TO_CONTENT, hdpx(45)]
        margin = 0
        hotkeys = btnStateFlag.value & S_HOVER ? btnHotkeys : null
    })
  }
}

let function mkPerkCostFull(perk, override = {}) {
  let pPointsChildren = mkPerkCostChildren(perk)
  return {
    size = [SIZE_TO_CONTENT, hdpx(27)]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = gap
    children = pPointsChildren != null
    ? [
        mkText(loc("perkPointsTakeInfo")).__update({ color = defTxtColor })
        {
          size = [COST_ICON_PAIR_WIDTH, SIZE_TO_CONTENT]
          children = pPointsChildren
        }
     ]
    : null
  }.__update(override)
}

let bigSlot = @(perkId, isAnimating, hasPrevPerk, hovered, isRecommended) function() {
  let perk = perksList.value?[perkId]
  let statDescList = getStatDescList(perksStatsCfg.value, perk)
  let pPointType = perk?.cost.keys()[0]
  let pPointCfg = perksPoints.pPointsBaseParams?[pPointType]
  let { color = null } = pPointCfg

  return {
    watch = [isAnimating, perksList, perksStatsCfg]
    size = perkBigIconSize
    padding = bigPadding
    children = [
      {
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          mkPerkCostFull(perk, {hplace = ALIGN_RIGHT})
          {
            size = [flex(), SIZE_TO_CONTENT]
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            children = [
              !isRecommended ? null : {
                rendObj = ROBJ_IMAGE
                size = [thumbIconSize, thumbIconSize]
                margin = [0, 0, 0, hdpx(10)]
                hplace = ALIGN_LEFT
                image = Picture($"!ui/uiskin/thumb.svg:{thumbIconSize}:{thumbIconSize}:K")
              }
              perkIcon(perk, hdpx(120), color)
            ]
          }
          flexTextArea({ text = "\n\n".join(statDescList),
            color = defTxtColor,
            fontSize = hdpx(19),
            halign = ALIGN_LEFT
            margin = [0, bigPadding]
          })
        ]
      }
      isAnimating.value ? null : applyButton(perkId, hasPrevPerk, hovered)
    ]
  }
}

let function mkAppearAnimation(idx, total, onFinishCb) {
  let animDelay = idx * 0.4
  let xOffset = total.tofloat() / 2 - 0.5 - idx
  let angle = -80 + idx * 20
  return [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = animDelay + 0.05,
      play = true, easing = InOutCubic, trigger = "perks_roll_anim" }
    { prop = AnimProp.scale, from = [1.6,1.6], to = [1.6,1.6], duration = animDelay,
      play = true, easing = InOutCubic, trigger = "perks_roll_anim" }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.6, delay = animDelay,
      play = true, easing = InOutCubic, trigger = "perks_roll_anim",
      onFinish = @() sound_play("ui/debriefing/new_equip") }
    { prop = AnimProp.scale, from = [1.6,1.6], to = [1,1], duration = 0.8, delay = animDelay,
      play = true, easing = InOutCubic, trigger = "perks_roll_anim" }
    { prop = AnimProp.rotate, from = angle, to = 0, duration = 0.8,
      delay = animDelay, play = true, easing = InOutCubic, trigger = "perks_roll_anim" }
    { prop = AnimProp.translate, from = [-(xOffset * sh(20)), -sh(20)], to = [0,0], duration = 0.8,
      delay = animDelay, play = true, easing = InOutCubic, trigger = "perks_roll_anim",
      onFinish = idx == total - 1 ? onFinishCb : null }
  ]
}

let function mkPerkChoiceSlot(perkId, idx, total, hasRoll,
                                isRollAnimation, prevPerk, costValue, isRecommended = false) {
  if (perkId)
    sound_play("ui/debriefing/squad_progression_appear")

  let hasPrevPerk = perkId == prevPerk
  let stateFlag = Watched(0)
  let hovered = Computed(@() stateFlag.value & S_HOVER)
  return @(){
    watch = stateFlag
    padding = hdpx(1)
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlag(sf)
    skipDirPadNav = true
    children = [
      {
        key = $"{perkId}"
        rendObj = ROBJ_BOX
        borderWidth = hdpx(1)
        size = perkBigIconSize
        flow = FLOW_VERTICAL
        borderColor = Color(70, 70, 70)
        fillColor = hasPrevPerk ? BG_PREV_PERK
          : stateFlag.value & S_HOVER ? BG_HOVER
          : defBgColor
        children = bigSlot(perkId, isRollAnimation, hasPrevPerk, hovered, isRecommended)
        transform = { pivot = [0.5, 0.5] }
        animations = hasRoll
          ? mkAppearAnimation(idx, total, idx == total - 1 ? @() isRollAnimation(false) : null)
          : null
        costValue = costValue
      }
    ]
    sound = {
      hover = "ui/enlist/button_highlight"
      click = "ui/enlist/button_click"
    }
  }
}

return {mkPerkChoiceSlot = kwarg(mkPerkChoiceSlot)}