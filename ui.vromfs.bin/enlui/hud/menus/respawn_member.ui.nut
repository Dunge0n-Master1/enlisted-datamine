from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { logerr } = require("dagor.debug")
let armyData = require("%ui/hud/state/armyData.nut")
let soldiersData = require("%ui/hud/state/soldiersData.nut")
let { localPlayerSquadMembers } = require("%ui/hud/state/squad_members.nut")
let { respRequested, needSpawnMenu } = require("%ui/hud/state/respawnState.nut")
let respawnSelection = require("%ui/hud/state/respawnSelection.nut")
let { squadBlock, headerBlock, panel, respawnTimer, forceSpawnButton
} = require("%ui/hud/respawn_parts.nut")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let mkSoldierCard = require("%enlSqGlob/ui/mkSoldierCard.nut")
let { mkAiActionIcon, mkGrenadeIcon, mkMineIcon, mkMemberHealsBlock,
  mkMemberFlaskBlock } = require("%ui/hud/components/squad_member.nut")
let { sendNetEvent, RequestNextRespawnEntity } = require("dasevents")
let { smallPadding, bigPadding } = require("%enlSqGlob/ui/viewConst.nut")
let { darkPanelBgColor, defTxtColor, darkTxtColor } = require("%enlSqGlob/ui/designConst.nut")


let forceRespawn = @() respRequested(true)

let sIconSize = hdpxi(15)

let requestRespawnToEntity = @(eid)
  sendNetEvent(localPlayerEid.value, RequestNextRespawnEntity({memberEid=eid}))

let spawnSquadLocId = Computed(function() {
  if (!needSpawnMenu.value)
    return null
  let guid = localPlayerSquadMembers.value?[0].guid
  let squadsList = armyData.value?.squads
  if (guid == null || (squadsList?.len() ?? 0) == 0)
    return null

  let squad = squadsList.findvalue(
    @(sq) sq.squad.findindex(@(soldier) soldier.guid == guid) != null)

  let { squadId = null } = squad
  return squadId != null ? $"squad/{squadId}" : "unknown"
})

let function currentSquadButtons(membersList, activeTeammateEid, infoByGuid, expToLevel) {
  let items = []
  foreach (memberIter in membersList) {
    let member = memberIter
    let soldierInfo = infoByGuid?[member.guid]
    let isCurrent = (member.eid == activeTeammateEid)
    if (!soldierInfo) {
      logerr($"Not found member info for respawn screen {member.guid}")
      continue
    }

    let group = ElemGroup()
    let function button(sf) {
      let color = sf & S_HOVER ? darkTxtColor : defTxtColor
      return {
        behavior = (member.isAlive && member.canBeLeader) ? Behaviors.Button : null
        group = group
        children = mkSoldierCard({
          soldierInfo
          expToLevel
          sf
          group
          isSelected = isCurrent
          isDead = !member.isAlive
          isFaded = !member.canBeLeader
          displayedKind = member?.displayedKind
          addChild = @(...) {
            hplace = ALIGN_BOTTOM
            vplace = ALIGN_BOTTOM
            flow = FLOW_HORIZONTAL
            gap = hdpx(2)
            padding = smallPadding
            children = [
              mkMemberHealsBlock(member, sIconSize, color)
              mkMemberFlaskBlock(member, sIconSize, color)
              mkGrenadeIcon(member, sIconSize, color) ?? mkMineIcon(member, sIconSize, color)
              mkAiActionIcon(member, sIconSize, color)
            ]
          }
        })

        onClick = function() {
          requestRespawnToEntity(member.eid)
          if (isCurrent)
            forceRespawn()
        }
        onDoubleClick = forceRespawn

        animations = [
          {
            prop=AnimProp.fillColor
            from=Color(200,200,200,160)
            duration=0.25
            easing=OutCubic
            trigger=$"squadmate:{member.eid}"
          }
        ]
      }
    }

    items.append(watchElemState(button))
  }
  return items
}

let memberSpawnList = @() {
  watch = [localPlayerSquadMembers, respawnSelection, soldiersData, armyData]
  size = SIZE_TO_CONTENT
  minHeight = fsh(40)
  halign = ALIGN_CENTER
  gap = fsh(1)
  flow = FLOW_VERTICAL
  children = localPlayerSquadMembers.value
    ? currentSquadButtons(localPlayerSquadMembers.value, respawnSelection.value, soldiersData.value, armyData.value?.expToLevel)
    : null
}

let function selectAndForceRespawn(index) {
  let entity = localPlayerSquadMembers.value?[index]
  if ((entity?.isAlive ?? false) && (entity?.canBeLeader ?? true)) {
    requestRespawnToEntity(entity.eid)
    forceRespawn()
  }
}

let function changeRespawn(delta) {
  let alive = []
  let curEid = respawnSelection.value
  local curIdx = 0

  if (localPlayerSquadMembers.value) {
    foreach (entity in localPlayerSquadMembers.value) {
      if (entity.isAlive && entity.canBeLeader) {
        alive.append(entity.eid)
        if (entity.eid == curEid) {
          curIdx = alive.len()-1
        }
      }
    }
  }

  if (alive.len()) {
    let idx = (curIdx + delta + alive.len()) % alive.len()
    let eid = alive[idx]
    requestRespawnToEntity(eid)
    anim_start($"squadmate:{eid}")
  }
}

let squadInfoBlock = @() {
  watch = spawnSquadLocId
  size = [flex(), SIZE_TO_CONTENT]
  children = squadBlock(loc(spawnSquadLocId.value ?? "unknown"))
}

let memberRespawn = @() panel({
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    headerBlock("\n".concat(loc("Controlled soldier died."), loc("Select another squadmate to control")))
    {
      flow = FLOW_VERTICAL
      gap = smallPadding
      padding = bigPadding
      rendObj = ROBJ_SOLID
      color = darkPanelBgColor
      children = [
        squadInfoBlock
        memberSpawnList
        forceSpawnButton({ size = [flex(), fsh(8)] })
        respawnTimer(loc("respawn/respawn_in_bot"), fontSub)
      ]
    }
  ]
}, {
  size = SIZE_TO_CONTENT
  rendObj = null
  hotkeys = [
    ["^Right | J:D.Right", @() changeRespawn(-1)],
    ["^Left | J:D.Left",  @() changeRespawn(1)],
    [$"^Enter| J:Y", @() forceRespawn()]
  ].extend(array(10).map(@(_, n)
    [$"^{n}", @() selectAndForceRespawn((10 + n - 1) % 10)]
  ))
})

return memberRespawn

