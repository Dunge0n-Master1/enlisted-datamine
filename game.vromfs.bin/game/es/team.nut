import "%dngscripts/ecs.nut" as ecs
let {EventTeamMemberLeave, EventTeamMemberJoined} = require("dasevents")

let onMemberCountChangedQuery = ecs.SqQuery("onMemberCountChangedQuery", {comps_ro = [
      ["team__balancedRespawnTime", ecs.TYPE_FLOAT], ["team__disbalancedRespawnIncrease", ecs.TYPE_FLOAT], ["team__id", ecs.TYPE_INT], ["team__memberCount", ecs.TYPE_FLOAT]]})
let captureSpeedMulQuery = ecs.SqQuery("captureSpeedMulQuery", {comps_rw = [["team__captureSpeedMult", ecs.TYPE_FLOAT]],
      comps_ro = [["team__disbalanceCapSpeedMult", ecs.TYPE_FLOAT], ["team__memberCount", ecs.TYPE_FLOAT], ["team__id", ecs.TYPE_INT]]})

let teamsMebmberCountQuery = ecs.SqQuery("teamsMebmberCountQuery", {comps_ro = [["team__memberCount", ecs.TYPE_FLOAT]]})
let function onMemberCountChanged() {
  local minTeamMembers = 1 << 30
  teamsMebmberCountQuery(
    function(_eid, comp) {
      minTeamMembers = min(minTeamMembers, comp["team__memberCount"])
    })

  if (minTeamMembers == 0)
    return
  onMemberCountChangedQuery(
      function(eid, comp) {
        let mult = minTeamMembers > 0 ? max(0.0, comp["team__memberCount"] / minTeamMembers - 1.0) : 0.0
        let overrideParams = ecs.obsolete_dbg_get_comp_val(eid, "team__overrideUnitParam").getAll()
        if ("respawner__respTime" in overrideParams && "respawner__respTimeout" in overrideParams) {
          let resTime = comp["team__balancedRespawnTime"] + comp["team__disbalancedRespawnIncrease"] * mult
          overrideParams["respawner__respTime"] = resTime
          overrideParams["respawner__respTimeout"] = resTime
          ecs.obsolete_dbg_set_comp_val(eid, "team__overrideUnitParam", overrideParams)
        }
      })
  captureSpeedMulQuery(
    function(_eid, comp){
      let mult = max(0.5, 1.0 + (1.0 - comp["team__memberCount"] / minTeamMembers) * comp["team__disbalanceCapSpeedMult"])
      comp["team__captureSpeedMult"] = mult
    })
}

let function onTeamMemberJoined(evt, _eid, comp) {
  let tid = evt.team
  if (tid != comp["team__id"])
    return
  let eidMember = evt.eid
  if (comp["team__memberEids"].indexof(eidMember, ecs.TYPE_EID) == null) {
    comp["team__memberEids"].append(eidMember, ecs.TYPE_EID)
    comp["team__memberCount"] = comp["team__countAdd"] + comp["team__memberEids"].len()
    onMemberCountChanged()
    if (comp["team__capacity"] >= 0 && comp["team__memberCount"] >= comp["team__capacity"])
      comp["team__locked"] = true
  }
}


let function onTeamMemberLeft(evt, _eid, comp) {
  let tid = evt.team
  if (tid != comp["team__id"])
    return
  let idx = comp["team__memberEids"].getAll().indexof(evt.eid)
  if (idx != null) {
    comp["team__memberEids"].remove(idx)
    comp["team__memberCount"] = comp["team__countAdd"] + comp["team__memberEids"].len()
    // after removing we should check if other team is disbalanced now so they have an advantage and rebalance them
    // by either adding them respawn time or by adding them capture time
    onMemberCountChanged()
  }
}


let comps = {
  comps_rw = [
    ["team__id", ecs.TYPE_INT],
    ["team__memberCount", ecs.TYPE_FLOAT],
    ["team__locked", ecs.TYPE_BOOL],
    ["team__memberEids", ecs.TYPE_EID_LIST],
  ]
  comps_ro = [
    ["team__countAdd", ecs.TYPE_FLOAT, 0.0],
    ["team__capacity", ecs.TYPE_INT, -1],
    ["team__should_lock", ecs.TYPE_BOOL, false],
  ]
}

ecs.register_es("team_es", {
  [EventTeamMemberJoined] = onTeamMemberJoined,
  [EventTeamMemberLeave] = onTeamMemberLeft,
}, comps, {tags = "server"})
