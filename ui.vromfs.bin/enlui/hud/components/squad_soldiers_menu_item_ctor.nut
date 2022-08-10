from "%enlSqGlob/ui_library.nut" import *

let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let {
  mkGrenadeIcon, mkMineIcon, mkMemberHealsBlock, mkStatusIcon, mkAiActionIcon,
  mkMemberFlaskBlock
} = require("%ui/hud/components/squad_member.nut")
let { fabs } = require("math")
let { SUCCESS_TEXT_COLOR, DEFAULT_TEXT_COLOR, DEAD_TEXT_COLOR } = require("%ui/hud/style.nut")

let iconSize = hdpxi(40)
let sIconSize = hdpxi(15)

let function splitOnce(name) {
  local idx = name.indexof(" ")
  local found = null
  local minDist = name.len()
  let middle = minDist / 2
  while (idx != null) {
    let dist = fabs(middle - idx)
    if (dist < minDist) {
      found = idx
      minDist = dist
    }
    idx = name.indexof(" ", idx + 1)
  }
  return found == null
    ? name
    : $"{name.slice(0, found)}\n{name.slice(found + 1)}"
}

let mkName = @(member, color) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = (member?.callname ?? "") != ""
    ? splitOnce(member.callname)
    : splitOnce(member.name)
  color
  indent = hdpx(5)
  transform = {}
}

let equipmentStatusRow = @(member) {
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = hdpx(2)
  children = [
    mkMemberHealsBlock(member, sIconSize)
    mkMemberFlaskBlock(member, sIconSize)
    mkGrenadeIcon(member, sIconSize) ?? mkMineIcon(member, sIconSize)
  ]
}

let statusIcon = @(member, isHero) {
  size = [iconSize, iconSize]
  children = [
    mkStatusIcon(member, iconSize, isHero ? SUCCESS_TEXT_COLOR : DEFAULT_TEXT_COLOR)
    mkAiActionIcon(member, sIconSize)
  ]
}

return @(member, isHero, _radius) function(_curIdx, _idx) {
  let isAlive = member.isAlive
  let nameColor = !isAlive ? DEAD_TEXT_COLOR
                             : isHero ? SUCCESS_TEXT_COLOR
                             : DEFAULT_TEXT_COLOR
  let name = mkName(member, nameColor).__update(sub_txt)
  let icon = statusIcon(member, isHero)
  let equipment = isAlive ? equipmentStatusRow(member) : null

  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = SIZE_TO_CONTENT
    children = {
      valign = ALIGN_TOP
      flow = FLOW_HORIZONTAL
      children = [
        {
          size = [iconSize, SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          gap = hdpx(2)

          children = [
            icon
            equipment
          ]
        }
        name
      ]
    }
  }
}
