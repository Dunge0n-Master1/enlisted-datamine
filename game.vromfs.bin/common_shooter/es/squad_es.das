require ecs
require app
require math.base
require DngWalkerai
require pathfinder
require DagorDataBlock
require DagorRandom
require math
require common_shooter.es.squad_common
require game.es.vehicle.vehicle_events
require game.es.events
require game.es.battle_area_common
require zones
require DagorMath
require BehNodes
require game.utils.team
require game.es.squad_order_common


[es(tag=server, no_order)]
def squad_es(info : ecs::UpdateStageInfoAct;
             squad__numAliveMembers : int;
             squad__orderUseEntity : ecs::EntityId;
             var squad__leader : ecs::EntityId&;
             var squad__orderType : int&;
             squad__orderPosition : float3;
             var squad__regroupPos : float3&)
  if !doesEntityExist(squad__leader)
    squad__leader = ecs::INVALID_ENTITY_ID
  if squad__numAliveMembers <= 1 || squad__leader == ecs::INVALID_ENTITY_ID
    if squad__orderType != int(SquadOrder ESO_FOLLOW_ME)
      squad__orderType = int(SquadOrder ESO_FOLLOW_ME)

  if squad__orderType == int(SquadOrder ESO_FOLLOW_ME)
    query(squad__leader) <| $ [es] (transform : float3x4)
      var pos = transform[3]
      let projExtents = float3(1.5, FLT_MAX, 1.5)
      project_to_nearest_navmesh_point_no_obstacles(pos, projExtents)
      squad__regroupPos = pos
  elif squad__orderType == int(SquadOrder ESO_DEFEND_POINT)
    squad__regroupPos = squad__orderPosition
    query(squad__orderUseEntity) <| $ [es] (capzone__hasNearestNavmeshPos : bool; capzone__nearestNavmeshPos : float3)
      if capzone__hasNearestNavmeshPos
        squad__regroupPos = capzone__nearestNavmeshPos
  elif squad__orderType == int(SquadOrder ESO_USE_VEHICLE)
    query(squad__orderUseEntity) <| $ [es] (transform : float3x4)
      squad__regroupPos = transform[3]


def set_custom_spread_order_point(squad_eid : EntityId; apply_condition : bool; spread = float2(); force_spread : bool = false)
  query(squad_eid) <| $ [es] (squad__orderType : int;
                              var squad__spreadAroundOrderPoint : float3&;
                              var squad__checkMembersTimer : float&;
                              squad__initialSpreadAroundOrderPoint : float3;
                              squad__ownerPlayer : ecs::EntityId;
                              squad__formationSpreadClosest : float3;
                              squad__formationSpreadStandard : float3;
                              squad__formationSpreadWide : float3;
                              squad__defaultIncreasedSpreadAroundOrderPoint = float2(3.5f, 3.5f))
    var spreadDistance = length_sq(spread) > FLT_EPSILON ? spread : squad__defaultIncreasedSpreadAroundOrderPoint
    var formationSpread = int(SquadFormationSpread ESFN_CLOSEST)
    ecs::query(squad__ownerPlayer) <| $ [es] (squadFormationSpread : int)
      formationSpread = squadFormationSpread
    if squad__orderType == int(SquadOrder ESO_FOLLOW_ME) && apply_condition
      let minDistance = get_squad_formation_spread(formationSpread,
                                                   squad__spreadAroundOrderPoint,
                                                   squad__formationSpreadClosest,
                                                   squad__formationSpreadStandard,
                                                   squad__formationSpreadWide)
      if !force_spread
        spreadDistance.x = max(spreadDistance.x, minDistance.x)
        spreadDistance.y = max(spreadDistance.y, minDistance.y)
      squad__spreadAroundOrderPoint = float3(spreadDistance.x, spreadDistance.y, minDistance.z)
    else
      squad__spreadAroundOrderPoint = get_squad_formation_spread(formationSpread,
                                                   squad__initialSpreadAroundOrderPoint,
                                                   squad__formationSpreadClosest,
                                                   squad__formationSpreadStandard,
                                                   squad__formationSpreadWide)
    squad__checkMembersTimer = 0.0f

[es(track=(squad__orderType), tag=server, REQUIRE=(squad__orderType), on_appear)]
def squad_order_change_squad_spread(evt : Event; eid : EntityId)
  set_custom_spread_order_point(eid, false)

[es(track=(squadFormationSpread), tag=server, REQUIRE=(squadFormationSpread))]
def formation_change_squad_spread(evt : Event; eid : EntityId)
  let ownerPlayer = eid
  ecs::query() <| $ [es] (eid : EntityId; squad__ownerPlayer : ecs::EntityId)
    if (squad__ownerPlayer == ownerPlayer)
      set_custom_spread_order_point(eid, false)

[es(track=human_weap__mortarMode, tag=server)]
def mortar_increase_squad_spread(evt : Event; human_weap__mortarMode : bool; squad_member__squad : EntityId)
  set_custom_spread_order_point(squad_member__squad, human_weap__mortarMode)

[es(track=building_action__target, tag=server)]
def building_squad_orderType_spread(evt : Event; building_action__target : EntityId; squad_member__squad : EntityId)
  var spreadAroundBuildingTarget = float2()
  query(building_action__target) <| $ [es] (buildingRadius : float; buildingDistance : float)
    let radius = 0.5 * buildingDistance + buildingRadius
    spreadAroundBuildingTarget = float2(radius, radius)
  set_custom_spread_order_point(squad_member__squad, building_action__target != INVALID_ENTITY_ID, spreadAroundBuildingTarget)

[es(track=human_anim__vehicleSelected, tag=server)]
def vehicle_change_squad_spread(evt : Event;
                                squad_member__squad : EntityId;
                                human_anim__vehicleSelected : EntityId)
  var spreadAroundSelectedVehicle = float2()
  if human_anim__vehicleSelected != INVALID_ENTITY_ID
    query(human_anim__vehicleSelected) <| $ [es(REQUIRE=additiveSquadSpread)] (animchar_bbox : bbox3f; additiveSpreadAround = float2(3.5f, 3.5f))
      spreadAroundSelectedVehicle = additiveSpreadAround
      let radius = 0.5 * length(animchar_bbox.bmax.xz - animchar_bbox.bmin.xz)
      spreadAroundSelectedVehicle.x += radius
      spreadAroundSelectedVehicle.y += radius
  if length_sq(spreadAroundSelectedVehicle) > FLT_EPSILON
    set_custom_spread_order_point(squad_member__squad, true, spreadAroundSelectedVehicle)
  else
    set_custom_spread_order_point(squad_member__squad, human_anim__vehicleSelected != INVALID_ENTITY_ID, float2(1.2f, 1.2f), true)

[es(tag=server, on_appear)]
def squad_mate_init_beh_tree(evt : Event; transform : float3x4; beh_tree__enabled : bool;
                             var beh_tree : BehaviourTree&;
                             beh_tree__blackboard__wishPositionSet : bool = false)
  let wishPositionName = "wishPosition"
  var wishPositionParam = datablock_find_param(beh_tree.blackBoard, wishPositionName)
  if wishPositionParam == -1
    wishPositionParam = add(beh_tree.blackBoard, wishPositionName, transform[3])
  if beh_tree__enabled && !beh_tree__blackboard__wishPositionSet
    set(beh_tree.blackBoard, wishPositionParam, transform[3])

[es(tag=server, on_appear)]
def team_init_vehicle_squad_spawn_cost(evt : Event; var team__vehicleSquadSpawnCost : int&; team__squadSpawnCost : int)
  if team__vehicleSquadSpawnCost < 0
    team__vehicleSquadSpawnCost = team__squadSpawnCost
