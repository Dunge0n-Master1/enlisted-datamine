from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { bigPadding, activeTxtColor, smallPadding, accentTitleTxtColor} = require("%enlSqGlob/ui/viewConst.nut")
let { noteTextArea, txt } = require("%enlSqGlob/ui/defcomps.nut")
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let faComp = require("%ui/components/faComp.nut")
let msgbox = require("%ui/components/msgbox.nut")

let localGap = hdpx(20)
let iconParams = @(itemType){
  itemType
  size = hdpx(27)
}

let function soldierIconWithType(soldierIcon, soldierName) {
  let { itemType, itemSubType = null } = iconParams(soldierIcon)
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = smallPadding
    minWidth = hdpx(150)
    children = [
      itemTypeIcon(itemType, itemSubType)
      txt(soldierName).__update(body_txt, { color = accentTitleTxtColor })
    ]
  }
}

let function weaponIconWithType(weapons){
  if (weapons.len() == 0)
    return null

  let children = weapons.map(function(weapon) {
    let { itemType, itemSubType = null } = iconParams(weapon.keys()[0])
    return {
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = [
        itemTypeIcon(itemType, itemSubType)
        txt(weapon.values()[0]).__update(body_txt)
      ]
    }
  })

  return {
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    gap = bigPadding
    minWidth = hdpx(200)
    children
  }
}

let function mkSoldierInfoRow(soldierIcon, soldierName, soldiersWeapons){
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = localGap
    children = [
      soldierIconWithType(soldierIcon, soldierName)
      faComp("arrow-right", {fontSize = hdpx(17)})
      weaponIconWithType(soldiersWeapons)
    ]
  }
}

let textAreaParams = {
  halign = ALIGN_CENTER
  color = activeTxtColor
}.__update(body_txt)

let windowDescription = {
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  gap = hdpx(50)
  halign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  children = [
    noteTextArea(loc("armory_tutorial/soldierWeapons")).__update(textAreaParams)
    mkSoldierInfoRow("boltaction_noscope",loc("soldierClass/rifle"),[
      { boltaction_noscope = loc("itemtype/boltaction_noscope") },
      { semiauto = loc("itemtype/semiauto") }
    ])
    mkSoldierInfoRow("submgun",loc("soldierClass/assault"),[{ submgun = loc("itemtype/submgun") }])
    noteTextArea(loc("armory_tutorial/unavailableSoldierWeapons")).__update(textAreaParams)
  ]
}

let armoryTutorial = {
  text = loc("armory_tutorial/armoryWnd")
  txtColor = accentTitleTxtColor
    children = {
      size = [fsh(90), SIZE_TO_CONTENT]
      margin = [localGap, 0, 0, 0]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      gap = localGap
      children = windowDescription
    }
}

let function openArmoryTutorial() {
  msgbox.showWithCloseButton(armoryTutorial)
}

return openArmoryTutorial