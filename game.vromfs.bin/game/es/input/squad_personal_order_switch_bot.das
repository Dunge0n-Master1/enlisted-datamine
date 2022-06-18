require ecs
require DagorInput
require game.es.input.input_events
require enlisted.game.es.squad_personal_order_common


def init(var personal_bot_order__inputSwitchBot : int&)
  personal_bot_order__inputSwitchBot = int(get_action_handle("Human.SwitchBotForOrders", TYPEGRP_DIGITAL))


def reset(var personal_bot_order__inputSwitchBot : int&)
  personal_bot_order__inputSwitchBot = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def squad_personal_bot_order_switch_bot_input_appear_es(evt : Event; var personal_bot_order__inputSwitchBot : int&)
  init(personal_bot_order__inputSwitchBot)

[es(tag=input, on_event=(EventEntityDestroyed))]
def squad_personal_bot_order_switch_bot_input_destroy_es(evt : Event; var personal_bot_order__inputSwitchBot : int&)
  reset(personal_bot_order__inputSwitchBot)

[es(tag=input, on_appear, after=squad_members_list_fill_es)]
def squad_personal_bot_order_switch_bot_init_es(evt : Event;
                                                eid : EntityId;
                                                squad_member__squad : EntityId;
                                                var personal_bot_order__currentBotEid : EntityId&)
  query(squad_member__squad) <| $ [es] (squad__allMembers : EidList)
    for memberEid in squad__allMembers
      if is_bot_valid_for_personal_order(eid, memberEid)
        personal_bot_order__currentBotEid = memberEid
        break

[es(tag=input, on_appear, REQUIRE=(heroSquad, deadEntity))]
def squad_personal_bot_order_switch_bot_on_bot_death(evt : Event; eid : EntityId; squad_member__squad : EntityId)
  let diedBotEid = eid
  query() <| $ [es] (eid : EntityId; var personal_bot_order__currentBotEid : EntityId&)
    if personal_bot_order__currentBotEid == diedBotEid
      personal_bot_order__currentBotEid = find_next_bot_for_personal_order(eid, squad_member__squad, personal_bot_order__currentBotEid)

[es(tag=input)]
def squad_personal_bot_order_switch_bot_input_es(evt : EventDaInputInit; var personal_bot_order__inputSwitchBot : int&)
  if evt.init
    init(personal_bot_order__inputSwitchBot)
  else
    reset(personal_bot_order__inputSwitchBot)

[es(tag=input)]
def squad_personal_bot_order_switch_bot_input(evt : EventDaInputActionTriggered;
                                              eid : EntityId;
                                              squad_member__squad : EntityId;
                                              input__enabled : bool;
                                              squad_member__isPersonalContextCommandMode : bool;
                                              personal_bot_order__inputSwitchBot : int;
                                              var personal_bot_order__currentBotEid : EntityId&)
  if !input__enabled || !squad_member__isPersonalContextCommandMode
    return

  if int(evt.action) == personal_bot_order__inputSwitchBot
    personal_bot_order__currentBotEid = find_next_bot_for_personal_order(eid, squad_member__squad, personal_bot_order__currentBotEid)