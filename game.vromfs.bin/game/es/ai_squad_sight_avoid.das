require ecs
require ecs.common
require game.es.events
require enlisted.game.es.enlisted_squad_common
require EnlistedWalkerai
require DagorConsole
require DagorDataBlock
require BehNodes
require pathfinder


[es(tag=server, on_appear)]
def squad_sight_avoid_create_es(evt : Event; eid : EntityId; squad__ownerPlayer : ecs::EntityId)
  var enable = !has(squad__ownerPlayer, "playerIsBot")
  ecs::query() <| $ [es] (squad_sight_avoid_debug__mode : int)
    if squad_sight_avoid_debug__mode == 1
      enable = true
    elif squad_sight_avoid_debug__mode == 2
      enable = false
  if enable
    addSubTemplate(eid, "squad_sight_avoid")

[es(tag=server, on_event=(EventComponentsDisappear, EventEntityDestroyed), REQUIRE=squad__ownerPlayer)]
def squad_sight_avoid_destroy_es(evt : Event; eid : EntityId)
  removeSubTemplate(eid, "squad_sight_avoid")

[es(tag=server, on_event=(EventComponentsDisappear, EventEntityDestroyed), REQUIRE=squad_sight_avoid)]
def squad_sight_avoid_destroyed_es(evt : Event; eid : EntityId)
  ecs::query() <| $ [es] (var beh_tree : BehaviourTree&; squad_member__squad : EntityId)
    if squad_member__squad == eid
      beh_tree.blackBoard |> set("sightAvoidEnabled", false)

[es(tag=server, no_order, REQUIRE=squad_sight_avoid)]
def squad_sight_avoid_update_es(info : ecs::UpdateStageInfoAct;
                                eid : EntityId;
                                squad_sight_avoid__forwardDist : float;
                                squad_sight_avoid__downDist : float;
                                squad_sight_avoid__sideDist : float;
                                squad_sight_avoid__weight : float2;
                                squad_sight_avoid__updateDelta : float;
                                var squad_sight_avoid__lastUpdateTime : float&;
                                squad__leader : ecs::EntityId)
  if (info.curTime < squad_sight_avoid__lastUpdateTime + squad_sight_avoid__updateDelta)
    return
  squad_sight_avoid__lastUpdateTime = info.curTime
  var found = false
  var leader_aimTm : float3x4
  ecs::query(squad__leader) <| $ [es] (var beh_tree : BehaviourTree&;
                                       human__aimTm : float3x4;
                                       isDowned : bool;
                                       isAlive : bool;
                                       isInVehicle : bool)
    if !isDowned && isAlive && !isInVehicle
      leader_aimTm = human__aimTm
      found = true
      beh_tree.blackBoard |> set("sightAvoidEnabled", false)
  collect_squad_ai(eid, squad__leader) <| $(var beh_tree : BehaviourTree&)
    beh_tree.blackBoard |> set("sightAvoidEnabled", found)
    if found
      var endPos = leader_aimTm[3] + leader_aimTm[0] * squad_sight_avoid__forwardDist
      endPos.y = leader_aimTm[3].y
      beh_tree.blackBoard |> set("sightAvoidPos", leader_aimTm[3])
      beh_tree.blackBoard |> set("sightAvoidForwardDir", endPos - leader_aimTm[3])
      beh_tree.blackBoard |> set("sightAvoidDownDist", squad_sight_avoid__downDist)
      beh_tree.blackBoard |> set("sightAvoidSideDist", squad_sight_avoid__sideDist)
      beh_tree.blackBoard |> set("sightAvoidWeight", squad_sight_avoid__weight)
    return false

[es(tag=server, on_appear, track=squad_member__squad, REQUIRE=squad_member__squad)]
def squad_sight_avoid_update_squad_es(evt : Event; var beh_tree : BehaviourTree&)
  beh_tree.blackBoard |> set("sightAvoidEnabled", false)
