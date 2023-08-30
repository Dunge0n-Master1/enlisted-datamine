from "%enlSqGlob/ui_library.nut" import *

let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
let { get_country_code } = require("auth")
let {
  isLootBoxProhibited, setProhibitingLootbox, ProhibitionStatus
} = require("%enlist/meta/metaConfigUpdater.nut")
let { get_setting_by_blk_path } = require("settings")
let { showMessageWithContent } = require("%enlist/components/msgbox.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { bigPadding } = require("%enlSqGlob/ui/viewConst.nut")
let JB = require("%ui/control/gui_buttons.nut")

let skipCountryCheck = mkWatched(persist, "skipCountryCheck", false)

let prohibitionCountriesList = get_setting_by_blk_path("countriesProhibitingLootbox")

let isCountryProhibited = Computed(function() {
  if (!userInfo.value)
    return false
  return prohibitionCountriesList?[get_country_code()] ?? false
})

let function checkLootRestriction(cb, content, crateContent) {
  if (!isCountryProhibited.value || skipCountryCheck.value || !isLootBoxProhibited.value) {
    cb?()
    return
  }

  let { x = 0, y = 0 } = crateContent?.value.content.itemsAmount
  let { soldierRareMax = -1, soldierTierMin = -1, items = {} } = crateContent?.value.content
  let isLootBox = x != y || soldierRareMax != soldierTierMin || items.len() > 1
  if (!isLootBox){
    cb?()
    return
  }

  let function onDecline() {
    // user abandons country
    skipCountryCheck(true)
    setProhibitingLootbox(ProhibitionStatus.Allowed)
    cb?()
  }

  let function onAccept() {
    // user accepts country
    showMessageWithContent({
      content = {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        gap = hdpx(10)
        children = {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("countryRestriction/confirmation")
        }.__update(fontBody)
      }
      buttons = [
        { text = loc("buyAnyway"),
          action = function(){
            skipCountryCheck(true)
            setProhibitingLootbox(ProhibitionStatus.Prohibited)
            cb?()
          }
        }
        {
          text = loc("notFrom", { country = loc(get_country_code())}),
          action = onDecline,
          isCancel = true
        }
      ]
    })
  }

  let { itemView, description } = content

  showMessageWithContent({
    content = {
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = bigPadding
      children = [
        itemView
        description
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          size = [sw(50), SIZE_TO_CONTENT]
          maxWidth = hdpx(1000)
          text = loc("countryRestriction", { country = loc(get_country_code())})
        }.__update(fontBody)
      ]
    }
    buttons = [
      { text = loc("buyAnyway"), action = onAccept}
      { text = loc("notFrom", { country = loc(get_country_code())}), action = onDecline}
      { text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }}
    ]
  })
}


return checkLootRestriction
