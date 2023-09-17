from "%enlSqGlob/ui_library.nut" import *

let { fontSub, fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { titleTxtColor, smallPadding, bigPadding, defTxtColor, defBdColor
} = require("%enlSqGlob/ui/designConst.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { makeGradientVertScroll, styling } = require("%ui/components/scrollbar.nut")
let sClassesConfig = require("%enlist/soldiers/model/config/sClassesConfig.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { newSquadBlock, starterPerkBlock, primePerkBlock
} = require("%enlist/soldiers/mkSquadPromo.nut")
let { mkViewItemDetails } = require("%enlist/soldiers/components/itemDetailsComp.nut")
let { mkShopItem } = require("%enlist/soldiers/model/items_list_lib.nut")

let detailsDescStyle = freeze({ color = defTxtColor }.__update(fontSub))
let headerTitleStyle = freeze({ color = titleTxtColor }.__update(fontBody))
let scrollStyle = styling.__merge({ Bar = styling.Bar(false) })

let mkText = @(text, style = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = [flex(), SIZE_TO_CONTENT]
  color = titleTxtColor
  text
}.__update(fontSub, style)


let function mkSquadDescBlock(squad, armyId) {
  let { newClass, newPerk = null, isPrimeSquad = false } = squad
  let descTxt = loc($"squadPromo/{newClass}/shortDesc")
  let primeDesc = loc($"soldierClass/{newClass}/desc")
  let defStats = loc($"squadPromo/{newClass}/longDesc")

  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    vplace = ALIGN_CENTER
    gap = bigPadding
    children = [
      newSquadBlock(armyId, newClass)
      starterPerkBlock(armyId, newPerk)
      isPrimeSquad ? primePerkBlock(primeDesc) : mkText(descTxt)
      mkText(defStats)
    ]
  }
}

let mkLockedClassAmount = @(sClass, amount) {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  padding = [0, smallPadding]
  children = [
    kindIcon(sClass, hdpxi(24), null, defTxtColor)
    {
      size = [SIZE_TO_CONTENT, hdpxi(24)]
      rendObj = ROBJ_TEXT
      text = amount
    }
  ]
}

let squadClassesUi = @(squadId, armyId) function() {
  let data = squadsCfgById.value?[armyId][squadId].startSoldiers ?? []
  return {
    watch = [sClassesConfig, squadsCfgById]
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = {
      rendObj = ROBJ_SOLID
      size = [hdpx(1), flex()]
      color = defBdColor
    }
    children = data.reduce(function(res, soldier) {
      let sKind = sClassesConfig.value?[soldier.sClass].kind
      if (sKind != null)
        res[sKind] <- (res?[sKind] ?? 0) + 1
      return res
    }, {})
    .reduce(@(res, count, sKind) res.append(mkLockedClassAmount(sKind, count)), [])
  }
}

let function mkSquadDetails(data) {
  let { squad, armyId } = data
  let { nameLocId, announceLocId, image, id } = squad
  return {
    size = flex()
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      {
        size = [flex(), hdpx(222)]
        rendObj = ROBJ_IMAGE
        image = Picture(image)
        keepAspect = KEEP_ASPECT_FIT
      }
      makeGradientVertScroll({
        size = [flex(), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = [
          squadClassesUi(id, armyId)
          mkText(loc(nameLocId), headerTitleStyle)
          mkSquadDescBlock(squad, armyId)
          mkText(loc(announceLocId), detailsDescStyle)
        ]
      }, {
        size = flex()
        gradientSize = hdpx(100)
        rootBase = { behavior = Behaviors.Pannable }
        styling = scrollStyle
      })
    ]
  }
}

let function mkItemDetails(data) {
  let { item, itemTemplate, armyId } = data
  let itemDetails = mkShopItem(itemTemplate, item, armyId)
  return mkViewItemDetails(itemDetails)
}

return {
  mkSquadDetails
  mkItemDetails
}