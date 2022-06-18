import "%dngscripts/ecs.nut" as ecs
let { FIRST_GAME_TEAM } = require("team")
let { INVALID_GROUP_ID } = require("matching.errors")
let localPlayer = persist("localPlayer", @() { eid = INVALID_ENTITY_ID, groupId=INVALID_GROUP_ID })


let teammate_outline_comps = {
  comps_ro = [
    ["teammate_outline__color", ecs.TYPE_COLOR],
    ["team", ecs.TYPE_INT]
  ]
  comps_rw = [
    ["outline__enabled", ecs.TYPE_BOOL],
    ["outline__color", ecs.TYPE_COLOR]
  ]
}


let heroToPlayerMap = {}

let getGroupQuery = ecs.SqQuery("getGroupQuery", { comps_ro = [["groupId", ecs.TYPE_INT64]] })

let function update_outline(eid, comp) {
  if (comp.team >= FIRST_GAME_TEAM && (eid in heroToPlayerMap) && heroToPlayerMap[eid]!=localPlayer.eid) {
    let groupId = getGroupQuery.perform(heroToPlayerMap[eid], @(_eid,comp) comp.groupId)
    if (groupId == localPlayer.groupId) {
      comp["outline__enabled"] = true
      comp["outline__color"] = comp["teammate_outline__color"]
      return
    }
  }
  comp["outline__enabled"] = false
}

let updateTeammatesQuery = ecs.SqQuery("updateTeammatesQuery", teammate_outline_comps)
let function updateTeammates(){
  updateTeammatesQuery.perform(update_outline)
}

let function player_onInit(eid, comp) {
  if (comp["possessed"] != INVALID_ENTITY_ID)
    heroToPlayerMap[comp["possessed"]] <- eid

  if (comp.is_local) {
    localPlayer.eid = eid
    localPlayer.groupId = comp.groupId
    updateTeammates()
  }
}


let function player_trackComponents(eid, comp) {
  let isLocal = comp.is_local
  let heroEid = comp["possessed"]
  if (eid == localPlayer.eid && !isLocal) {
    localPlayer.eid = INVALID_ENTITY_ID
    localPlayer.groupId = INVALID_GROUP_ID
  }
  else if (isLocal) {
    localPlayer.eid = eid
    localPlayer.groupId = comp.groupId
  }
  if (heroEid in heroToPlayerMap)
    delete heroToPlayerMap[heroEid]
  if (heroEid != INVALID_ENTITY_ID)
    heroToPlayerMap[heroEid] <- eid
  updateTeammates()
}

let function player_onDestroy(eid, comp) {
  if (eid == localPlayer.eid) {
    localPlayer.eid = INVALID_ENTITY_ID
    localPlayer.groupId = INVALID_GROUP_ID
  }
  let heroEid = comp["possessed"]
  if (heroEid in heroToPlayerMap)
    delete heroToPlayerMap[heroEid]
  updateTeammates()
}


ecs.register_es("teammate_outline_players_es", {
    onInit = player_onInit
    onDestroy = player_onDestroy
    onChange = player_trackComponents
  },
  {
    comps_track = [
      ["groupId", ecs.TYPE_INT64],
      ["is_local", ecs.TYPE_BOOL],
      ["possessed", ecs.TYPE_EID],
    ],
    comps_rq = ["player"]
  }
)


ecs.register_es("teammate_outline_outline_es", {
  [["onInit","onChange"]] = @(eid,comp) update_outline(eid, comp)
}, teammate_outline_comps, {tags = "render", track="teammate_outline__color,team"})
