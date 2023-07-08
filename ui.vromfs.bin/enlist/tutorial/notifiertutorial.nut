from "%enlSqGlob/ui_library.nut" import *
let {
  PERK_ALERT_SIGN, REQ_MANAGE_SIGN, ITEM_ALERT_SIGN
} = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { needSoldiersManageBySquad } = require("%enlist/soldiers/model/reserve.nut")
let { notChoosenPerkArmies } = require("%enlist/soldiers/model/soldierPerks.nut")
let { unseenArmiesWeaponry } = require("%enlist/soldiers/model/unseenWeaponry.nut")
let { unseenArmiesVehicle } = require("%enlist/vehicles/unseenVehicles.nut")
let { settings } = require("%enlist/options/onlineSettings.nut")
let { sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { soldierWndWidth } = require("%enlSqGlob/ui/viewConst.nut")
let blinkingIcon = require("%enlSqGlob/ui/blinkingIcon.nut")

const SEEN_ID = "seen/notifierTutorials"
let seenData = Computed(@() settings.value?[SEEN_ID] ?? {})

let function markNotifierSeen(notifierId) {
  settings.mutate(function(set) {
    let saved = (clone set?[SEEN_ID] ?? {}).rawset(notifierId, true) //warning disable: -unwanted-modification
    set[SEEN_ID] <- saved
  })
}

let function resetSeen() {
  if (SEEN_ID not in settings.value)
    return

  settings.mutate(@(v) delete v[SEEN_ID])
}

enum Notifiers {
  PERK
  SOLDIER
  ITEM
}

let notifierConfig = {
  [Notifiers.PERK] = {
    icon = PERK_ALERT_SIGN
    order = 1
    locId = "hint/perkNotifier"
  },
  [Notifiers.SOLDIER] = {
    icon = REQ_MANAGE_SIGN
    order = 2
    locId = "hint/manageSoldiersNotifier"
  },
  [Notifiers.ITEM] = {
    icon = ITEM_ALERT_SIGN
    order = 3
    locId = "hint/newWeaponNotifier"
  }
}

let order = @(notifierId) notifierConfig?[notifierId].order ?? -1

let needShowAlert = Computed(function() {
  let activeNotifiers = []
  if ((notChoosenPerkArmies.value?[curArmy.value] ?? 0) > 0)
    activeNotifiers.append(Notifiers.PERK)
  if (needSoldiersManageBySquad.value.len() > 0)
    activeNotifiers.append(Notifiers.SOLDIER)
  if ((unseenArmiesWeaponry.value?[curArmy.value] ?? 0) > 0
    || (unseenArmiesVehicle.value?[curArmy.value].len() ?? 0) > 0)
    activeNotifiers.append(Notifiers.ITEM)

  let seen = seenData.value
  activeNotifiers.sort(@(a, b) a in seen <=> b in seen || order(a) <=> order(b))
  return activeNotifiers?[0]
})

let animatedParams = {
  transform = {}
  animations = [
    {
      prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1.5,
      play = true, loop = true, easing = Blink
    }
    {
      prop = AnimProp.opacity, from = 1, to = 1, delay = 6,
      play = true, loop = true, easing = Blink
    }
  ]
}

let notifierHint = function() {
  if (needShowAlert.value == null)
    return null
  let notifierId = needShowAlert.value
  let params = notifierId not in seenData.value ? animatedParams : {}
  let { icon, locId } = notifierConfig[notifierId]
  return {
    watch = [needShowAlert, seenData]
    minWidth = soldierWndWidth
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    children = [
      blinkingIcon(icon).__update({ animations = null })
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(locId)
      }.__update(sub_txt)
    ]
  }.__update(params)
}

console_register_command(resetSeen, "meta.resetSeenNotifiers")

return {
  Notifiers
  markNotifierSeen
  notifierHint
}
