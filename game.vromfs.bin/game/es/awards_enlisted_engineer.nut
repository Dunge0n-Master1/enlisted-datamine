import "%dngscripts/ecs.nut" as ecs
let squdPlayerQuery = ecs.SqQuery("squdPlayerQuery", {comps_ro=[["squad_member__playerEid"]]})
let { get_sync_time } = require("net")
let { EventOnUsefulBoxSuccessfulUse } = require("dasevents")

let function onBarbwireDamage(_evt, _player_eid, comp) {
  let playerEid = comp["buildByPlayer"]
  let guid = comp["builder_info__guid"]
  ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({
    list = [{ stat = "builtBarbwireActivations", guid, playerEid }]
  }))
}

let function isBoxAwardAvailableByLimit(uses_info, max_uses_per_minute, requester_player, cur_time) {
  let {time = 0, count = 0} = uses_info?[requester_player.tostring()] ?? {}
  return cur_time - time > 60 || count < max_uses_per_minute
}

let function increaseBoxUseCount(uses_info, requester_player, cur_time) {
  let {time=0, count=0} = uses_info?[requester_player.tostring()]
  uses_info[requester_player.tostring()] <- (cur_time - time > 60)
    ? {time = cur_time, count = 1}
    : {time, count = count + 1}
}

let function onBoxRefill(requester, box_owner_player, box_owner_eid, stat, uses_info, max_uses_per_minute) {
  let requesterPlayer = squdPlayerQuery(requester, @(_, comp) comp["squad_member__playerEid"]) ?? INVALID_ENTITY_ID
  if (requesterPlayer == box_owner_player)
    return
  let time = get_sync_time()
  if (isBoxAwardAvailableByLimit(uses_info, max_uses_per_minute, requesterPlayer, time)) {
    increaseBoxUseCount(uses_info, requesterPlayer, time)
    ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({
      list = [{ stat, eid=box_owner_eid, playerEid=box_owner_player }]
    }))
  }
}

let function onCapzoneFortificationAward(_, comp) {
  let playerEid = comp["buildByPlayer"]
  let guid = comp["builder_info__guid"]
  ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({
    list = [{ stat = "builtCapzoneFortificationActivations", guid, playerEid }]
  }))
}

let playerBuildingAwardCooldownQuery = ecs.SqQuery("playerBuildingAwardCooldownQuery", {
  comps_rw=[
    ["engineer_awards__buildingTimerStartTime", ecs.TYPE_FLOAT],
    ["engineer_awards__buildingCountSinceTimerStart", ecs.TYPE_INT]
  ],
  comps_ro=[["engineer_awards__buildingLimitPerMinute", ecs.TYPE_INT]]
})

let function onAnyBuildingBuilt(_, comp) {
  if (comp["dependsOnBuildingEid"] != INVALID_ENTITY_ID)
    return
  let playerEid = comp["buildByPlayer"]
  let guid = comp["builder_info__guid"]
  playerBuildingAwardCooldownQuery(playerEid, function(_, playerComp) {
    let time = get_sync_time()
    if (time - playerComp["engineer_awards__buildingTimerStartTime"] > 60) {
      playerComp["engineer_awards__buildingTimerStartTime"] = time
      playerComp["engineer_awards__buildingCountSinceTimerStart"] = 0
    }
    if (playerComp["engineer_awards__buildingCountSinceTimerStart"] < playerComp["engineer_awards__buildingLimitPerMinute"]) {
      playerComp["engineer_awards__buildingCountSinceTimerStart"]++
      ecs.g_entity_mgr.broadcastEvent(ecs.event.EventSquadMembersStats({
        list = [{ stat = "builtStructures", guid, playerEid }]
      }))
    }
  })
}

ecs.register_es("score_engineer_barbwire_damage",
  {[ecs.sqEvents.EventOnBarbwireDamageAward] = onBarbwireDamage },
  {
    comps_ro=[
      ["buildByPlayer", ecs.TYPE_EID],
      ["builder_info__guid", ecs.TYPE_STRING],
    ]
  }, {tags = "server"})

let playerAmmoBoxAwardCooldownQuery = ecs.SqQuery("playerAmmoBoxAwardCooldownQuery", {
  comps_rw=[["engineer_awards__ammoBoxUses", ecs.TYPE_OBJECT]],
  comps_ro=[["engineer_awards__ammoBoxAwardPerPlayerPerMinute", ecs.TYPE_INT]]
})

ecs.register_es("score_engineer_ammo_box_refill",
  {[EventOnUsefulBoxSuccessfulUse] = function(evt, _, comp) {
      playerAmmoBoxAwardCooldownQuery(comp.buildByPlayer, function(_, playerComp) {
        let maxUsePerMin = playerComp.engineer_awards__ammoBoxAwardPerPlayerPerMinute
        onBoxRefill(evt.requester, comp.buildByPlayer, comp.buildByEngineerEid, "builtAmmoBoxRefills", playerComp.engineer_awards__ammoBoxUses, maxUsePerMin)
      })
    }
  },
  {
    comps_ro=[
      ["buildByPlayer", ecs.TYPE_EID],
      ["buildByEngineerEid", ecs.TYPE_EID],
    ],
    comps_rq=["ammunitionBox"]
  }, {tags = "server"})

let playerMedBoxAwardCooldownQuery = ecs.SqQuery("playerMedBoxAwardCooldownQuery", {
  comps_rw=[["awards__medBoxUses", ecs.TYPE_OBJECT]],
  comps_ro=[["awards__medBoxAwardPerPlayerPerMinute", ecs.TYPE_INT]]
})

ecs.register_es("score_med_box_refill",
  {[EventOnUsefulBoxSuccessfulUse] = function(evt, _, comp) {
      playerMedBoxAwardCooldownQuery(comp.buildByPlayer, function(_, playerComp) {
        let maxUsePerMin = playerComp.awards__medBoxAwardPerPlayerPerMinute
        onBoxRefill(evt.requester, comp.buildByPlayer, comp.placeable_item__ownerEid, "builtMedBoxRefills", playerComp.awards__medBoxUses, maxUsePerMin)
      })
    }
  },
  {
    comps_ro=[
      ["buildByPlayer", ecs.TYPE_EID],
      ["placeable_item__ownerEid", ecs.TYPE_EID]
    ],
    comps_rq=["medBox"]
  }, {tags = "server"})

ecs.register_es("score_engineer_capzone_fortification_award",
  {[ecs.sqEvents.EventOnCapzoneFortificationAward] = onCapzoneFortificationAward },
  {
    comps_ro=[
      ["buildByPlayer", ecs.TYPE_EID],
      ["builder_info__guid", ecs.TYPE_STRING],
    ]
  }, {tags = "server"})

ecs.register_es("score_engineer_any_building_built",
  {[[ecs.EventEntityCreated, ecs.EventComponentsAppear]] = onAnyBuildingBuilt },
  {
    comps_no=["builder_preview"],
    comps_ro=[
      ["dependsOnBuildingEid", ecs.TYPE_EID, INVALID_ENTITY_ID],
      ["buildByPlayer", ecs.TYPE_EID],
      ["builder_info__guid", ecs.TYPE_STRING],
    ]
  }, {tags = "server"})
