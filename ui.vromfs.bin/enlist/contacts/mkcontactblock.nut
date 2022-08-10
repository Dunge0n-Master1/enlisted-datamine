from "%enlSqGlob/ui_library.nut" import *

let { enabledSquad, squadMembers, squadId } = require("%enlist/squad/squadState.nut")
let { mkArmyIcon } = require("%enlist/soldiers/components/armyPackage.nut")
let { curArmiesList } = require("%enlist/soldiers/model/state.nut")
let contactBlock = require("%enlist/contacts/contactBlock.nut")

let iconHgt = hdpxi(32)
let diceIcon = {
  rendObj = ROBJ_IMAGE
  image = Picture("!ui/skin#dice_solid.svg:{0}:{0}:K".subst((iconHgt*3/4).tointeger()))
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_CENTER
  pos = [hdpx(1), hdpx(2)]
}

let armyImage = @(armyId) mkArmyIcon(armyId, iconHgt)

let memberAvatarCtor = @(uid) function() {
  let watch = [enabledSquad, squadMembers, squadId]
  let res = { watch = watch }
  let squadLeader = enabledSquad.value && squadId.value == uid ? squadMembers.value?[uid] : null
  if (squadLeader == null)
    return res
  watch.append(squadLeader.state)
  let randomTeam = squadLeader.state.value?.isTeamRandom ?? false
  let curArmy = squadLeader.state.value?.curArmy
  return res.__update({
    padding = [hdpx(4),0,0,0],
    children = !randomTeam
      ? curArmy ? mkArmyIcon(curArmy, iconHgt*4/3) : null
      : curArmiesList.value.map(@(army, idx) {children = armyImage(army), pos = [iconHgt*3.0/4*(idx - 1/2.0), -iconHgt/5]})
        .reverse()
        .append(diceIcon)
  })
}

let extensions = {
  memberAvatarCtor
}

return function(p) {
  let { hasStatusBlock = true } = p
  return contactBlock(p.__merge(hasStatusBlock ? extensions : {}))
}
