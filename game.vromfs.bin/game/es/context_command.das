require ecs
require game.utils.team
require EnlistedWalkerai
require GridCollision
require RendInst
require Dacoll
require HumanPhys
require EnlistedWeapon
require DaWeaponProps
require danetlibs.native_dasevents.main.native_events
require enlisted.events_enlisted
require enlisted.game.es.context_command_common
require enlisted.game.es.bomb_site_common
require game.es.battle_area_common
require zones
require CollRes
require game.es.squad_order_common
require EnlistedNet
require matching

def get_alive_num_in_squad(squad_eid : EntityId) : int
  return get_int(squad_eid, "squad__numAliveMembers") ?? 0

[es(tag=gameClient, REQUIRE=human_context_command_input, no_order)]
def human_pre_context_command(act : ParallelUpdateFrameDelayed; squad_member__squad : ecs::EntityId; isInVehicle : bool;
                              human_context_command__nextUpdateTime : float;
                              var human_context_command__orderType : int&)
  if act.curTime >= human_context_command__nextUpdateTime
    if !isInVehicle && get_alive_num_in_squad(squad_member__squad) > 1
      human_context_command__orderType = int(ContextCommand ECC_NONE)
    else
      human_context_command__orderType = int(ContextCommand ECC_DISABLED)

[es(tag=gameClient, REQUIRE=human_context_command_input, after=human_context_command_defend_point)]
def human_post_context_command(act : ParallelUpdateFrameDelayed;
                               human_context_command__updateInterval : float;
                               var human_context_command__nextUpdateTime : float&)
  if act.curTime >= human_context_command__nextUpdateTime
    human_context_command__nextUpdateTime = act.curTime + human_context_command__updateInterval


[es(tag=gameClient, REQUIRE=human_context_command_input, after=human_pre_context_command)]
def human_revive_context_command(act : ParallelUpdateFrameDelayed; isDowned, isAlive : bool;
                                 human_context_command__nextUpdateTime : float;
                                 var human_context_command__orderType : int&)
  if act.curTime >= human_context_command__nextUpdateTime && human_context_command__orderType == int(ContextCommand ECC_NONE)
    if isAlive && isDowned
      human_context_command__orderType = int(ContextCommand ECC_REVIVE)


[es(tag=gameClient, REQUIRE=human_context_command_input, after=human_revive_context_command)]
def human_context_command_control_zone(act : ParallelUpdateFrameDelayed; human__lookAtZone : ecs::EntityId;
                                       human_context_command__nextUpdateTime : float;
                                       team : int;
                                       var human_context_command__orderType : int&;
                                       var human_context_command__orderUseEntity : ecs::EntityId&)
  if act.curTime >= human_context_command__nextUpdateTime && human_context_command__orderType == int(ContextCommand ECC_NONE)
    if human__lookAtZone != ecs::INVALID_ENTITY_ID && has(human__lookAtZone, "transform")
      let transform = get_TMatrix(human__lookAtZone, "transform")
      if transform != null && has_active_human_battle_area_at((*transform)[3], team)
        human_context_command__orderType = int(ContextCommand ECC_DEFEND_POINT)
        human_context_command__orderUseEntity = human__lookAtZone

def is_valid_contruction_command_target(eid : EntityId)
  return has(eid, "buildByPlayer") && (has(eid, "builder_preview") || has(eid, "building_destroy__timeToDestroy"))

[es(tag=gameClient, REQUIRE=human_context_command_input, after=human_context_command_control_zone)]
def human_context_command_construction(act : ParallelUpdateFrameDelayed;
                                       human_context_command__nextUpdateTime : float;
                                       human_use_object__selectedBuilding : EntityId;
                                       var human_context_command__orderType : int&;
                                       var human_context_command__orderUseEntity : ecs::EntityId&)
  if act.curTime >= human_context_command__nextUpdateTime && human_context_command__orderType == int(ContextCommand ECC_NONE)
    if is_valid_contruction_command_target(human_use_object__selectedBuilding)
      human_context_command__orderType = int(ContextCommand ECC_BUILD)
      human_context_command__orderUseEntity = human_use_object__selectedBuilding

[es(tag=gameClient, REQUIRE=human_context_command_input, after=human_context_command_construction, after=human_weap_update_es, REQUIRE=watchedByPlr)]
def human_context_command_defend_point(act : ParallelUpdateFrameDelayed;
                                       human__aimTm : float3x4; team : int;
                                       human_weap__tracerayLen : float;
                                       human_weap__traceIntersectedEid : EntityId;
                                       human_context_command__nextUpdateTime : float;
                                       var human_context_command__orderType : int&;
                                       var human_context_command__orderPosition : float3&;
                                       var human_context_command__orderUseEntity : ecs::EntityId&;
                                       squad_member__squad : ecs::EntityId&;
                                       squad_member__playerEid : EntityId)
  if act.curTime >= human_context_command__nextUpdateTime &&  human_context_command__orderType == int(ContextCommand ECC_NONE)
    let traceDir = human__aimTm[0]
    let tracePos = human__aimTm[3]
    var len = human_weap__tracerayLen
    var height = 100.0

    ecs::query(squad_member__squad) <| $ [es] (squad__maxOrderDistance : float; squad__orderDistanceSub : float)
      len = min(len, squad__maxOrderDistance - squad__orderDistanceSub)

    var new_orderPosition = tracePos + traceDir * human_weap__tracerayLen
    if tracedown_normalized(new_orderPosition + float3(0.0, 0.1, 0.0), height, ETF_DEFAULT)
      new_orderPosition.y -= height

    if !has_active_human_battle_area_at(new_orderPosition, team)
      return

    human_context_command__orderType = int(ContextCommand ECC_DEFEND_POINT)
    human_context_command__orderUseEntity = ecs::INVALID_ENTITY_ID
    human_context_command__orderPosition = new_orderPosition

    ecs::query(human_weap__traceIntersectedEid) <| $ [es(REQUIRE=vehicle_seats__seats)] (isAlive : bool;
                                                                                         vehicle_seats__restrictToGroup : int64 = int64(INVALID_GROUP_ID);
                                                                                         vehicle_seats__restrictToTeam : int = TEAM_UNASSIGNED;
                                                                                         vehicle__isPlayerCanEnter : bool = true)
      if !isAlive || !vehicle__isPlayerCanEnter
        return
      let playerGroup = get_int64(squad_member__playerEid, "origGroupId") ?? int64(INVALID_GROUP_ID)
      if vehicle_seats__restrictToGroup != int64(INVALID_GROUP_ID) && playerGroup != vehicle_seats__restrictToGroup
        return
      if vehicle_seats__restrictToTeam == TEAM_UNASSIGNED || is_teams_friendly(vehicle_seats__restrictToTeam, team)
        human_context_command__orderType = int(ContextCommand ECC_DEFEND_POINT)
        human_context_command__orderUseEntity = human_weap__traceIntersectedEid
      else
        human_context_command__orderType = int(ContextCommand ECC_ATTACK_TARGET)
        human_context_command__orderUseEntity = human_weap__traceIntersectedEid

[es(tag=gameClient, REQUIRE=human_context_command_input, before=human_context_command_control_zone, after=human_pre_context_command, REQUIRE=watchedByPlr)]
def human_context_command_use_bomb(act : ParallelUpdateFrameDelayed;
                                   eid : EntityId;
                                   human__aimTm : float3x4;
                                   team : int;
                                   human_context_command__nextUpdateTime : float;
                                   squad_member__squad : EntityId;
                                   human_weap__tracerayLen : float;
                                   human_use_bomb_site__traceSafeOffset : float;
                                   var human_context_command__orderType : int&;
                                   var human_context_command__orderPosition : float3&;
                                   var human_context_command__orderUseEntity : EntityId&)
  if act.curTime >= human_context_command__nextUpdateTime && human_context_command__orderType == int(ContextCommand ECC_NONE)
    let heroEid = eid
    find_query() <| $ [es] (eid : EntityId;
                            active : bool = true;
                            transform : float3x4;
                            bomb_site__operator : EntityId;
                            bomb_site__plantingTeam : int;
                            bomb_site__isBombPlanted : bool;
                            bomb_site__canResetProgressByInteraction : bool;
                            ri_extra : RiExtraComponent)
      let canTeamInteract = (is_teams_friendly(team, bomb_site__plantingTeam)
        ? !bomb_site__isBombPlanted
        : (bomb_site__isBombPlanted || bomb_site__canResetProgressByInteraction))

      if active && canTeamInteract && (!bomb_site__operator || bomb_site__operator == heroEid)

        let riType = handle_to_ri_type(ri_extra.handle)
        let riCollres = get_ri_gen_extra_collres(int(riType))
        if riCollres == null
          return false

        let tracePos = human__aimTm[3]
        let traceDir = human__aimTm[0]

        var maxDist = human_weap__tracerayLen
        query(squad_member__squad) <| $ [es] (squad__maxOrderDistance : float; squad__orderDistanceSub : float)
          maxDist = min(maxDist, squad__maxOrderDistance - squad__orderDistanceSub)

        var norm : float3
        var matId : int

        if collres_traceray(*riCollres, transform, tracePos, traceDir, maxDist, norm, matId)
          var checkDist = max(0.f, maxDist - human_use_bomb_site__traceSafeOffset)
          if !traceray_normalized(tracePos, traceDir, checkDist, norm)
            let canPlant = can_plant_bomb(eid, heroEid)
            let canDefused = can_defuse_bomb(eid, heroEid)
            if canPlant || canDefused
              human_context_command__orderType = int(canPlant
                ? ContextCommand ECC_PLANT_BOMB
                : ContextCommand ECC_DEFUSE_BOMB
              )
              human_context_command__orderPosition = tracePos + traceDir * checkDist
              human_context_command__orderUseEntity = eid
              return true

      return false

[es(tag=gameClient, REQUIRE=human_context_command_input)]
def human_context_command_req(evt : RqContextCommand; eid, squad_member__squad : ecs::EntityId;
                              human_context_command__orderType : int;
                              human_context_command__orderPosition : float3;
                              human_context_command__orderUseEntity : ecs::EntityId)
  if human_context_command__orderType == int(ContextCommand ECC_CANCEL)
    send_net_event(squad_member__squad, [[RequestSquadOrder orderType=SquadOrder ESO_FOLLOW_ME, orderPosition=float3(), orderUseEntity=INVALID_ENTITY_ID]])
  elif human_context_command__orderType == int(ContextCommand ECC_DEFEND_POINT)
    var orderType = SquadOrder ESO_DEFEND_POINT
    var orderPosition = human_context_command__orderPosition
    let orderUseEntity = human_context_command__orderUseEntity
    if orderUseEntity != ecs::INVALID_ENTITY_ID
      let targetTM = get_TMatrix(orderUseEntity, "transform")
      if targetTM != null
        orderPosition = (*targetTM)[3]
      if has(orderUseEntity, "vehicle_seats__seats")
        orderType = SquadOrder ESO_USE_VEHICLE
    send_net_event(squad_member__squad, [[RequestSquadOrder orderType=orderType, orderPosition=orderPosition, orderUseEntity=orderUseEntity]])
  elif human_context_command__orderType == int(ContextCommand ECC_REVIVE)
    send_net_event(squad_member__squad, [[RequestSquadMateOrder orderType=SquadMateOrder ESMO_HEAL, orderPosition=float3(), orderUseEntity=INVALID_ENTITY_ID]])
  elif human_context_command__orderType == int(ContextCommand ECC_BRING_AMMO)
    send_net_event(squad_member__squad, [[RequestSquadMateOrder orderType=SquadMateOrder ESMO_BRING_AMMO, orderPosition=float3(), orderUseEntity=INVALID_ENTITY_ID]])
  elif human_context_command__orderType == int(ContextCommand ECC_BUILD)
    send_net_event(squad_member__squad, [[RequestSquadMateOrder orderType=SquadMateOrder ESMO_BUILD, orderPosition=float3(), orderUseEntity=human_context_command__orderUseEntity]])
  elif human_context_command__orderType == int(ContextCommand ECC_PLANT_BOMB)
    send_net_event(squad_member__squad, [[RequestSquadMateOrder
      orderType=SquadMateOrder ESMO_PLANT_BOMB,
      orderPosition=human_context_command__orderPosition,
      orderUseEntity=human_context_command__orderUseEntity
    ]])
  elif human_context_command__orderType == int(ContextCommand ECC_DEFUSE_BOMB)
    send_net_event(squad_member__squad, [[RequestSquadMateOrder
      orderType=SquadMateOrder ESMO_DEFUSE_BOMB,
      orderPosition=human_context_command__orderPosition,
      orderUseEntity=human_context_command__orderUseEntity
    ]])
  elif human_context_command__orderType == int(ContextCommand ECC_ATTACK_TARGET)
    let orderType = SquadMateOrder ESMO_ATTACK_TARGET
    var orderPosition = human_context_command__orderPosition
    let orderUseEntity = human_context_command__orderUseEntity
    if orderUseEntity != ecs::INVALID_ENTITY_ID
      let targetTM = get_TMatrix(orderUseEntity, "transform")
      if targetTM != null
        orderPosition = (*targetTM)[3]
    send_net_event(squad_member__squad, [[RequestSquadMateOrder orderType=orderType, orderPosition=orderPosition, orderUseEntity=orderUseEntity]])
  elif human_context_command__orderType == int(ContextCommand ECC_DISABLED) && get_alive_num_in_squad(squad_member__squad) <= 1
    sendEvent(eid, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/no_alive_squadmates"]])

[es(tag=gameClient, REQUIRE=human_context_command_input)]
def human_context_command_all_cancel_req(evt : RqCancelContextCommand; eid, squad_member__squad : ecs::EntityId)
  let squadEid = squad_member__squad
  var hasGlobalOrder = false
  ecs::query(squad_member__squad) <| $ [es] (squad__orderType : int)
    hasGlobalOrder = squad__orderType != int(SquadOrder ESO_FOLLOW_ME)
  var hasOrder = hasGlobalOrder
  if !hasOrder && evt.include_personal_orders
    ecs::find_query() <| $ [es] (squad_member__squad : ecs::EntityId; isAlive : bool; squad_member__orderType : int)
      hasOrder = squadEid == squad_member__squad && isAlive && squad_member__orderType != int(SquadOrder ESO_FOLLOW_ME)
      return hasOrder
  if hasGlobalOrder
    send_net_event(squad_member__squad, [[RequestSquadOrder orderType=SquadOrder ESO_FOLLOW_ME, orderPosition=float3(), orderUseEntity=INVALID_ENTITY_ID]])
  if evt.include_personal_orders
    send_net_event(squad_member__squad, [[RequestSquadMateOrder orderType=SquadMateOrder ESMO_NO_ORDER, orderPosition=float3(), orderUseEntity=INVALID_ENTITY_ID]])
  if hasOrder
    sendEvent(eid, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/all_orders_canceled"]])
