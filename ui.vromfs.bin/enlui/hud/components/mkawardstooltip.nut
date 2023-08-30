from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")
let mkBattleHeroAwardIcon = require("%enlSqGlob/ui/battleHeroAwardIcon.nut")
let {dtext} = require("%ui/components/text.nut")

let mkAwardsTooltip = @(awards, iconSize) tooltipBox({
  flow = FLOW_VERTICAL
  children = awards.map(@(award) {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      mkBattleHeroAwardIcon(award?.icon ?? award, iconSize)
      dtext(loc(award?.text ?? $"debriefing/award_{award}"), {padding = [0, hdpx(10)]}.__update(fontBody))
    ]
  })
})

return mkAwardsTooltip