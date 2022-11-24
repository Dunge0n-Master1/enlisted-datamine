from "%enlSqGlob/ui_library.nut" import *

let { sendNetEvent, RequestSquadChangeLeader } = require("dasevents")
let { localPlayerSquadMembers } = require("%ui/hud/state/squad_members.nut")
let mkPieItemCtor = require("%ui/hud/components/squad_soldiers_menu_item_ctor.nut")
let { controlledHeroEid } = require("%ui/hud/state/controlled_hero.nut")
let { playerEvents } = require("%ui/hud/state/eventlog.nut")
let { squadEid, heroSquadNumAliveMembers, canChangeSquadMember } = require("%ui/hud/state/hero_squad.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")

let radius = Watched(hdpx(365))
let elemSize = Computed(@() [(radius.value*0.35).tointeger(),(radius.value*0.35).tointeger()] )
let showSquadSoldiersMenu = mkWatched(persist, "showSquadSoldiersMenu", false)

let showMsg = @(text) playerEvents.pushEvent({ text = text, ttl = 5 })
let selectSoldier = @(eid) sendNetEvent(squadEid.value, RequestSquadChangeLeader({eid}))

let mkSoldierItem = @(member, isCurrent) {
  action = @() selectSoldier(member.eid)
  disabledAction = @() showMsg(loc("msg/squadMemberNotAvailable") )
  available = member.isAlive && member.canBeLeader
  text = member?.name ?? ""
  ctor = mkPieItemCtor(member, isCurrent, radius.value)
}

let squadSoldiersMenuItems = Computed(function() {
  local actualSquadSoldiers = localPlayerSquadMembers.value
  if (isGamepad.value)
    actualSquadSoldiers = actualSquadSoldiers.filter(@(member)
      member.isAlive && member.eid != controlledHeroEid.value)
  return actualSquadSoldiers.map(@(member) mkSoldierItem(member, member.eid == controlledHeroEid.value))
})

let isSquadSoldiersMenuAvailable = Computed(@() canChangeSquadMember.value && heroSquadNumAliveMembers.value > 0)

return {
  squadSoldiersMenuItems
  showSquadSoldiersMenu
  isSquadSoldiersMenuAvailable
  radius
  elemSize
}
