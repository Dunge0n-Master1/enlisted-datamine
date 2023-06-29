from "%enlSqGlob/ui_library.nut" import *
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { smallPadding, bigPadding, activeBgColor, defTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { smallCampaignIcon } = require("%enlist/gameModes/roomsPkg.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let { getPortrait } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let roomMemberStatuses = require("roomMemberStatuses.nut")
let { mkArmySimpleIcon } = require("%enlist/soldiers/components/armyPackage.nut")
let { memberName, mkStatusImg } = require("components/memberComps.nut")

let portraitSize = hdpxi(132)

let mkText = @(text, color = defTxtColor) {
  rendObj = ROBJ_TEXT, color, text
}.__update(sub_txt)

let mkTextWithIcon = @(icon, text) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      size = [hdpx(35), SIZE_TO_CONTENT]
      children = icon
    }
    mkText(text)
  ]
}

let function mkPortrait(portrait) {
  let { icon } = getPortrait(portrait)
  return {
    padding = smallPadding
    rendObj = ROBJ_BOX
    borderColor = activeBgColor
    borderWidth = hdpx(1)
    children = {
      size = [portraitSize, portraitSize]
      rendObj = ROBJ_IMAGE
      image = Picture("!{0}:{1}:{1}:K".subst(icon, portraitSize))
    }
  }
}

let mkStatusRow = @(statusCfg) mkTextWithIcon(
  mkStatusImg(statusCfg.icon, statusCfg?.iconColor)
  loc(statusCfg.locId))

let function mkPlayerTooltip(player) {
  let { public, nameText } = player
  let { army = null, campaign = null, status = null, portrait = "", nickFrame = "" } = public
  let statusCfg = roomMemberStatuses?[status]
  return tooltipBox({
     flow = FLOW_HORIZONTAL
     gap = bigPadding
     children = [
       mkPortrait(portrait)
       {
         flow = FLOW_VERTICAL
         gap = bigPadding
         children = [
           memberName(nameText, nickFrame)
           statusCfg == null ? null : mkStatusRow(statusCfg)
           campaign == null ? null : mkTextWithIcon(smallCampaignIcon(campaign), loc($"{campaign}/full"))
           army == null ? null : mkTextWithIcon(mkArmySimpleIcon(army, hdpx(20), { margin = 0 }), loc(army))
         ]
       }
     ]
  })
}

return mkPlayerTooltip