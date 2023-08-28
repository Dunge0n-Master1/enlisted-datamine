require ecs
require DngNet
require ecs.common
require DagorInput
require AnimV20
require GeomNodeTree
require game.events_game
require game.es.input.input_events
require game.es.input.input_common
require game.es.fortification_action_common
require enlisted.events_enlisted


def init(var human_input__supplyMenu : int&)
  human_input__supplyMenu = int(get_action_handle("Human.SupplyMenu", TYPEGRP_DIGITAL))


def reset(var human_input__supplyMenu : int&)
  human_input__supplyMenu = int(BAD_ACTION_HANDLE)


[es(tag=input)]
def paratroopers_supply_box_input_on_init(evt : EventDaInputInit; var human_input__supplyMenu : int&)
  if evt.init
    init(human_input__supplyMenu)
  else
    reset(human_input__supplyMenu)


[es(tag=input, on_appear)]
def paratroopers_supply_box_input_on_appear(evt : Event; var human_input__supplyMenu : int&)
  init(human_input__supplyMenu)


[es(tag=input, on_disappear)]
def paratroopers_supply_box_input_on_disappear(evt : Event; var human_input__supplyMenu : int&)
  reset(human_input__supplyMenu)


[es(tag=input, track=human_paratroopers_supply_box__selectedEid)]
def paratroopers_supply_box_close_menu_on_moving(evt : Event;
                                                 possessedByPlr : EntityId;
                                                 human_paratroopers_supply_box__selectedEid : EntityId)
  if !human_paratroopers_supply_box__selectedEid
    sendEvent(possessedByPlr, [[CmdCloseSupplyMenu needApplyPreset=false]])


[es(tag=gameClient, REQUIRE=watchedByPlr)]
def human_paratroopers_find_supply_box_on_update(info : ParallelUpdateFrameDelayed;
                                                 isInVehicle : bool;
                                                 bindedCamera : EntityId;
                                                 human_binocular__mode : bool;
                                                 animchar : AnimcharBaseComponent;
                                                 human_use_object__nodeId : int;
                                                 human_use_object__useDist : float;
                                                 human_attached_gun__attachedGunEid : EntityId;
                                                 var human_paratroopers_supply_box__selectedEid : EntityId&)
  human_paratroopers_supply_box__selectedEid = INVALID_ENTITY_ID

  if has(bindedCamera, "spectator") || human_binocular__mode || !!human_attached_gun__attachedGunEid || isInVehicle
    return

  query(bindedCamera) <| $ [es] (transform : float3x4)
    let traceDir = transform[2]
    let traceBegin = (human_use_object__nodeId > 0
      ? geomtree_getNodeWpos(*animchar.nodeTree, human_use_object__nodeId)
      : transform[3])
    let traceEnd = traceBegin + traceDir * human_use_object__useDist

    find_query() <| $ [es(REQUIRE=supply_box__isActive)] (eid : EntityId;
                                                          transform : float3x4;
                                                          buildingRadius : float;
                                                          buildingCenterOffset : float3;
                                                          object__useDist : float)
      human_paratroopers_supply_box__selectedEid = find_fortification_object_impl(eid, false, transform[3], buildingCenterOffset, buildingRadius, traceBegin, traceEnd, object__useDist)
      return !!human_paratroopers_supply_box__selectedEid


[es(tag=input)]
def paratroopers_supply_box_input_on_triggered(evt : EventDaInputActionTriggered;
                                               input__enabled : bool;
                                               possessedByPlr : EntityId;
                                               squad_member__squad : EntityId;
                                               human_paratroopers_supply_box__selectedEid : EntityId;
                                               human_input__supplyMenu : int)
  if !input__enabled || int(evt.action) != human_input__supplyMenu
    return

  query(human_paratroopers_supply_box__selectedEid) <| $ [es] (supply_box__squad : EntityId; supply_box__isActive : bool)
    if squad_member__squad != supply_box__squad
      broadcastEvent([[CmdShowHint event="paratroopers_supply_box_wrong_squad",
                                   text ="msg/paratroopers_supply_box_wrong_squad",
                                   ttl=4.0,
                                   unique="paratroopers_supply_box_wrong_squad"]])
    elif !supply_box__isActive
      broadcastEvent([[CmdShowHint event="paratroopers_supply_box_already_used",
                                   text ="msg/paratroopers_supply_box_already_used",
                                   ttl=4.0,
                                   unique="paratroopers_supply_box_already_used"]])
    else
      sendEvent(possessedByPlr, [[CmdOpenSupplyMenu boxEid=human_paratroopers_supply_box__selectedEid]])


[es(tag=input)]
def paratroopers_supply_box_input_on_terminated(evt : EventDaInputActionTerminated;
                                                input__enabled : bool;
                                                possessedByPlr : EntityId;
                                                human_input__supplyMenu : int)
  if input__enabled && is_gamepad_input() && int(evt.action) == human_input__supplyMenu
    sendEvent(possessedByPlr, [[CmdCloseSupplyMenu needApplyPreset=true]])
