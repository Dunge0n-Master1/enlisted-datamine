from "%enlSqGlob/ui_library.nut" import *


let { bigPadding, sidePadding, midPadding, footerContentHeight
} = require("%enlSqGlob/ui/designConst.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { localPlayerSquadMembers } = require("%ui/hud/state/squad_members.nut")
let { respRequested, spawnSquadId } = require("%ui/hud/state/respawnState.nut")
let respawnSelection = require("%ui/hud/state/respawnSelection.nut")
let { localPlayerEid } = require("%ui/hud/state/local_player.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { sendNetEvent, RequestNextRespawnEntity } = require("dasevents")
let { respawnTimer, forceSpawnButton, squadNameBlock, mkKeyboardHint, bgConfig,
  respAnims, commonBlockWidth, missionNameUI, titleTxtStyle, respawnHint
} = require("%ui/hud/menus/respawn/respawnPkg.nut")
let soldiersRespawnBlock = require("%ui/hud/menus/respawn/soldiersRespawnBlock.nut")
let cursors = require("%ui/style/cursors.nut")


let forceRespawn = @() respRequested(true)
let requestRespawnToEntity = @(eid)
  sendNetEvent(localPlayerEid.value, RequestNextRespawnEntity({memberEid=eid}))


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


let topBlock = {
  size = [flex(), SIZE_TO_CONTENT]
  animations = respAnims
  transform = {}
  children = [
    @(){
      watch = spawnSquadId
      size = [commonBlockWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = bigPadding
      children = [
        squadNameBlock(spawnSquadId.value, titleTxtStyle).__update(bgConfig)
        soldiersRespawnBlock
      ]
    }.__update(bgConfig)
    respawnHint(loc("respawn/soldierDied"))
    missionNameUI
  ]
}


let spawnInfoBlock = {
  size = [commonBlockWidth, SIZE_TO_CONTENT]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  halign = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  gap = midPadding
  hotkeys = [
    ["^Right | J:D.Right", @() changeRespawn(-1)],
    ["^Left | J:D.Left",  @() changeRespawn(1)],
    [$"^Enter| {JB.A}", @() forceRespawn()]
  ].extend(array(10).map(@(_, n)
    [$"^{n}", @() selectAndForceRespawn((10 + n - 1) % 10)]))
  children = [
    @() {
      watch = isGamepad
      children = isGamepad.value
        ? null
        : mkKeyboardHint("Space", loc("respawn/spawn_current_soldier"))
    }
    respawnTimer("respawn/soldierRespawnTimer")
    forceSpawnButton
  ]
}.__update(bgConfig)


return {
  size = flex()
  cursor = cursors.normal
  padding = [sidePadding, sidePadding, footerContentHeight, sidePadding]
  children = [
    topBlock
    spawnInfoBlock
  ]
}

