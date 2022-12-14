require ecs
require EnlistedWalkerai
require enlisted.events_enlisted
require enlisted.game.es.squad_personal_order_common
require enlisted.game.es.context_command_common
require EnlistedNet
require danetlibs.native_dasevents.main.native_events
require game.es.squad_order_common

[es(tag=gameClient, REQUIRE=human_context_command_input)]
def human_personal_context_command_req(evt : RqPersonalContextCommand;
                                       eid : EntityId;
                                       squad_member__squad : EntityId;
                                       human_context_command__orderType : int;
                                       human_context_command__orderPosition : float3;
                                       human_context_command__orderUseEntity : ecs::EntityId;
                                       var personal_bot_order__currentBotEid : EntityId&)
  var isOrdered = false
  if human_context_command__orderType == int(ContextCommand ECC_DEFEND_POINT)
    var orderType = SquadMateOrder ESMO_DEFEND_POINT
    var orderPosition = human_context_command__orderPosition
    let orderUseEntity = human_context_command__orderUseEntity
    query(orderUseEntity) <| $ [es] (transform : float3x4)
      orderPosition = transform[3]
    if has(orderUseEntity, "vehicle")
      orderType = SquadMateOrder ESMO_USE_VEHICLE
    isOrdered = true
    send_net_event(personal_bot_order__currentBotEid, [[RequestPersonalSquadMateOrder orderType=int(orderType), orderPosition=orderPosition, orderUseEntity=orderUseEntity]])
  elif human_context_command__orderType == int(ContextCommand ECC_BUILD)
    isOrdered = true
    send_net_event(personal_bot_order__currentBotEid, [[RequestPersonalSquadMateOrder orderType=int(SquadMateOrder ESMO_BUILD), orderPosition=float3(), orderUseEntity=human_context_command__orderUseEntity]])
  elif human_context_command__orderType == int(ContextCommand ECC_ATTACK_TARGET)
    let orderType = SquadMateOrder ESMO_ATTACK_TARGET
    let orderUseEntity = human_context_command__orderUseEntity
    if orderUseEntity != INVALID_ENTITY_ID
      isOrdered = true
      send_net_event(personal_bot_order__currentBotEid, [[RequestPersonalSquadMateOrder orderType=int(orderType), orderPosition=float3(), orderUseEntity=orderUseEntity]])
  elif human_context_command__orderType == int(ContextCommand ECC_PLANT_BOMB)
    send_net_event(personal_bot_order__currentBotEid, [[RequestPersonalSquadMateOrder
      orderType=int(SquadMateOrder ESMO_PLANT_BOMB),
      orderPosition=human_context_command__orderPosition,
      orderUseEntity=human_context_command__orderUseEntity
    ]])
  elif human_context_command__orderType == int(ContextCommand ECC_DEFUSE_BOMB)
    send_net_event(personal_bot_order__currentBotEid, [[RequestPersonalSquadMateOrder
      orderType=int(SquadMateOrder ESMO_DEFUSE_BOMB),
      orderPosition=human_context_command__orderPosition,
      orderUseEntity=human_context_command__orderUseEntity
    ]])
  else
    sendEvent(eid, [[RqContextCommand]])

  if isOrdered
    personal_bot_order__currentBotEid = find_next_bot_for_personal_order(eid, squad_member__squad, personal_bot_order__currentBotEid)

[es(tag=gameClient, REQUIRE=human_context_command_input)]
def human_personal_context_command_cancel_req(evt : RqCancelPersonalContextCommand;
                                              eid : EntityId;
                                              personal_bot_order__currentBotEid : EntityId)
  query(personal_bot_order__currentBotEid) <| $ [es] (squad_member__isPersonalOrder : bool)
    if squad_member__isPersonalOrder
      send_net_event(personal_bot_order__currentBotEid, [[RequestPersonalSquadMateOrder orderType=int(SquadMateOrder ESMO_NO_ORDER), orderPosition=float3(), orderUseEntity=INVALID_ENTITY_ID]])
      sendEvent(eid, [[CmdHeroLogEvent event="squad_order_canceled", text="context_command/personal_order_canceled"]])