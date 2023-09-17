require ecs
require ecs.safe
require ecs.common
require game.es.input.input_events
require game.es.input.input_common
require game.es.cannon_resupply_common
require game.es.human_use_action_common
require game.es.events
require game.utils.hero
require DagorInput
require DagorSystem
require daslib/strings_boost


let INPUT_COLUMN = 1


struct ActionDesc
  handle : int
  index : int


def get_action_event_type(action : int)
  let binding = get_digital_action_binding(uint16(action), INPUT_COLUMN)
  return (binding != null
          ? int(digital_action_binding_get_eventType(*binding))
          : -1)


def retain_only_actions_on_same_event_type(var conflictedActionDescs : array<ActionDesc>)
  let conflictedActionDescsLen = length(conflictedActionDescs)
  if conflictedActionDescsLen < 2
    return

  let mainEventType = get_action_event_type(conflictedActionDescs[0].handle)
  for i in range(0, conflictedActionDescsLen)
    let revI = conflictedActionDescsLen - i - 1
    let curEventType = get_action_event_type(conflictedActionDescs[revI].handle)
    if curEventType != mainEventType
      erase(conflictedActionDescs, revI)


def init(eid : EntityId;
         input_priority__actionsOrder : StringList;
         var input_priority__actionsHandles : IntList&;
         var input_priority__actionsPriorities : IntList&;
         var input_priority__actionsAvailability : BoolList&;
         var input_priority__conflictedActionsTable : IntList&)
  var actionsToProcess : table<int; int>
  var allActions : array<int>

  clear(input_priority__actionsHandles)
  clear(input_priority__actionsPriorities)
  clear(input_priority__actionsAvailability)
  var actionIndex = 0
  for actionPriority, actionsNames in iter_range(input_priority__actionsOrder), input_priority__actionsOrder
    for splittedActionName in split(string(actionsNames), "&&")
      let actionName = strip(splittedActionName)
      let actionHandle = int(get_action_handle(string(actionName), uint16(0xFFFF)))
      if actionHandle == int(BAD_ACTION_HANDLE)
        logerr("invalid action name '{actionName}' in input_priority__actionsOrder")
        continue

      actionsToProcess[actionHandle] = actionIndex
      push(allActions, actionHandle)

      push(input_priority__actionsHandles, actionHandle)
      push(input_priority__actionsPriorities, actionPriority)
      push(input_priority__actionsAvailability, true)

      actionIndex++

  var conflictedActionsTable : array<array<int>>
  for actionHandle in allActions
    var conflictedActionDescs : array<ActionDesc>
    for actionHandleToProcess, actionIndexToProcess in keys(actionsToProcess), values(actionsToProcess)
      if actionHandle == actionHandleToProcess || check_bindings_conflicts_one(uint16(actionHandle), INPUT_COLUMN, uint16(actionHandleToProcess), INPUT_COLUMN)
        push(conflictedActionDescs, [[ActionDesc handle=actionHandleToProcess, index=actionIndexToProcess]])

    retain_only_actions_on_same_event_type(conflictedActionDescs)

    for conflictedActionDesc in conflictedActionDescs
      erase(actionsToProcess, conflictedActionDesc.handle)

    if !empty(conflictedActionDescs)
      sort(conflictedActionDescs) <| $(lhs, rhs : ActionDesc)
        let lhsPrior = input_priority__actionsPriorities[lhs.index]
        let rhsPrior = input_priority__actionsPriorities[rhs.index]
        return lhsPrior != rhsPrior ? lhsPrior < rhsPrior : lhs.index < rhs.index

      var confictedActionsIndices : array<int>
      for actionDesc in conflictedActionDescs
        push(confictedActionsIndices, actionDesc.index)
      emplace(conflictedActionsTable, confictedActionsIndices)

  clear(input_priority__conflictedActionsTable)
  push(input_priority__conflictedActionsTable, length(conflictedActionsTable))
  for actions in conflictedActionsTable
    push(input_priority__conflictedActionsTable, length(actions))
    for action in actions
      push(input_priority__conflictedActionsTable, action)

  sendEvent(eid, [[EventInputPriorityActionsAvailabilityChanged]])


def reset(eid : EntityId;
          var input_priority__actionsHandles : IntList&;
          var input_priority__actionsPriorities : IntList&;
          var input_priority__actionsAvailability : BoolList&;
          var input_priority__conflictedActionsTable : IntList&)
  for action in input_priority__actionsHandles
    set_action_enabled(uint16(action), true)

  clear(input_priority__actionsHandles)
  clear(input_priority__actionsPriorities)
  clear(input_priority__actionsAvailability)
  clear(input_priority__conflictedActionsTable)

  sendEvent(eid, [[EventInputPriorityActionsAvailabilityChanged]])


[es(tag=input, on_appear, track=glob_input__inputMode, on_event=EventControlsMenuToggle)]
def input_priority_on_appear(evt : Event;
                             eid : EntityId;
                             glob_input__inputMode : int;
                             input_priority__actionsOrder : StringList;
                             var input_priority__actionsHandles : IntList&;
                             var input_priority__actionsPriorities : IntList&;
                             var input_priority__actionsAvailability : BoolList&;
                             var input_priority__conflictedActionsTable : IntList&)
  if glob_input__inputMode == int(InputMode MODE_GAMEPAD)
    init(eid,
         input_priority__actionsOrder,
         input_priority__actionsHandles,
         input_priority__actionsPriorities,
         input_priority__actionsAvailability,
         input_priority__conflictedActionsTable)
  else
    reset(eid,
          input_priority__actionsHandles,
          input_priority__actionsPriorities,
          input_priority__actionsAvailability,
          input_priority__conflictedActionsTable)


[es(tag=input)]
def input_priority_on_init(evt : EventDaInputInit;
                           eid : EntityId;
                           input_priority__actionsOrder : StringList;
                           var input_priority__actionsHandles : IntList&;
                           var input_priority__actionsPriorities : IntList&;
                           var input_priority__actionsAvailability : BoolList&;
                           var input_priority__conflictedActionsTable : IntList&)
  if evt.init && is_gamepad_input()
    init(eid,
         input_priority__actionsOrder,
         input_priority__actionsHandles,
         input_priority__actionsPriorities,
         input_priority__actionsAvailability,
         input_priority__conflictedActionsTable)
  else
    reset(eid,
          input_priority__actionsHandles,
          input_priority__actionsPriorities,
          input_priority__actionsAvailability,
          input_priority__conflictedActionsTable)


[es(tag=input, on_event=EventInputPriorityActionsAvailabilityChanged, track=(input_priority__conflictedActionsTable))]
def input_priority_update_enabled_actions(evt : Event;
                                          input_priority__actionsHandles : IntList;
                                          input_priority__actionsPriorities : IntList;
                                          input_priority__actionsAvailability : BoolList;
                                          input_priority__conflictedActionsTable : IntList)
  if empty(input_priority__conflictedActionsTable)
    return

  global_cls_drv_update_cs_lock() <| $()
    let rows = input_priority__conflictedActionsTable[0]
    var i = 1
    for _row in range(0, rows)
      let cols = input_priority__conflictedActionsTable[i]
      i++

      var isEnabledActionPriority = -1
      var prevActionPriority = -1
      for col in range(0, cols)
        let actionIndex = input_priority__conflictedActionsTable[i]
        i++

        let nextActionIndex = col + 1 < cols ? input_priority__conflictedActionsTable[i] : -1
        let nextActionPriority = input_priority__actionsPriorities?[nextActionIndex] ?? -1

        let actionHandle = input_priority__actionsHandles[actionIndex]
        let actionPriority = input_priority__actionsPriorities[actionIndex]
        let isAvailable = input_priority__actionsAvailability[actionIndex]
        let isActionPairedWithPrevAction = prevActionPriority > -1 && actionPriority == prevActionPriority
        let isActionPairedWithNextAction = nextActionPriority > -1 && actionPriority == nextActionPriority
        let isEnabled = isAvailable && (isEnabledActionPriority < 0 || isActionPairedWithPrevAction && actionPriority == isEnabledActionPriority)
        set_action_enabled(uint16(actionHandle), isEnabled)
        set_action_mask_immediate(uint16(actionHandle), isEnabled && isActionPairedWithNextAction)
        if isAvailable
          isEnabledActionPriority = actionPriority

        prevActionPriority = actionPriority


[es(tag=input)]
def input_priority_update(info : UpdateStageUpdateInput;
                          eid : EntityId;
                          glob_input__inputMode : int;
                          input_priority__actionsHandles : IntList;
                          var input_priority__actionsAvailability : BoolList&)
  if glob_input__inputMode != int(InputMode MODE_GAMEPAD)
    return

  query() <| $ [es(REQUIRE=hero)] (human_input__use : int;
                                   human_input__exitVehicleAlone : int;
                                   human_input__reload : int;
                                   human_input__vehicleMaintenance : int;
                                   human_input__pushObject : int;
                                   human_input__melee : int;
                                   human_input__bipodToggle : int;
                                   human_input__buildingAction : int;
                                   human_inventory_input__pickup : int;
                                   human_inventory_input__forcedPickup : int;
                                   human_context_command__aCancelContextCommand : int;
                                   human_input__throwBack : int;
                                   mortar_input__switchShellType : int;
                                   human_input__fortificationMirrorPreview : int;
                                   human_input__repairBuilding : int;
                                   human_use_object__selectedObject : EntityId;
                                   human_use_object__selectedBuilding : EntityId;
                                   human_weap__currentGunEid : EntityId;
                                   human_vehicle__isHoldingGunPassenger : bool;
                                   useActionAvailable : int;
                                   push_object__canPush : bool;
                                   squad_member__squad : EntityId;
                                   maintenance__isExtinguishAvailable : bool;
                                   maintenance__isRepairAvailable : bool;
                                   isInVehicle : bool;
                                   bipod__placeable : bool;
                                   human_weap__throwMode : bool;
                                   grenade_rethrow__grenadeEid : EntityId;
                                   human_weap__mortarMode : bool;
                                   stockOfBuilderCapabilities : float)
    let isHumanUseEnabled = !!human_use_object__selectedObject && !human_vehicle__isHoldingGunPassenger
    let isHumanExitVehicleAloneEnabled = isHumanUseEnabled && isInVehicle
    let isHumanPushObjectEnabled = push_object__canPush
    let isInventoryPickup = useActionAvailable == int(HumanAction ACTION_PICK_UP) || useActionAvailable == int(HumanAction ACTION_SWITCH_WEAPONS)
    let isHumanBipodToggle = bipod__placeable
    let isHumanThrowBack = !!grenade_rethrow__grenadeEid || human_weap__throwMode
    let isMortarSwitchShellType = human_weap__mortarMode
    let isHumanMaintenanceEnabled = maintenance__isExtinguishAvailable || maintenance__isRepairAvailable

    var isHumanBuildingActionEnabled = false
    query(human_use_object__selectedBuilding) <| $ [es(REQUIRE=building__canDismantle, REQUIRE_NOT=undestroyableBuilding)] ()
      isHumanBuildingActionEnabled = true

    var isHumanReloadEnabled = false
    var isHumanMeleeEnabled = false
    var isHumanRepairBuilding = false
    query(human_weap__currentGunEid) <| $ [es] (gun__ammo : int = 0;
                                                gun__maxAmmo : int = 0;
                                                gun__totalAmmo : int = 0;
                                                disableMelee : Tag const?;
                                                buildingTool : Tag const?)
      isHumanReloadEnabled = gun__ammo < gun__maxAmmo && gun__totalAmmo > 0 || buildingTool != null
      isHumanMeleeEnabled = (disableMelee == null)

      if buildingTool != null
        query(human_use_object__selectedBuilding) <| $ [es] (fortification_repair__costPercent : float;
                                                             additiveBuildNeedRepair : bool = true;
                                                             buildingCost : float const?;
                                                             turret_control__gunEids : EidList const?)
          isHumanRepairBuilding = additiveBuildNeedRepair
          if turret_control__gunEids != null && buildingCost != null
            let shellInfo = get_turrets_shell_info(*turret_control__gunEids)
            let repairCost = calculate_resupply_cost(shellInfo, *buildingCost, fortification_repair__costPercent)
            isHumanRepairBuilding &&= shellInfo.current < shellInfo.max && repairCost <= stockOfBuilderCapabilities

    var isHumanRotateBuilding = false
    query() <| $ [es(REQUIRE=builder_preview, REQUIRE_NOT=(builder_server_preview, builder_additive_preview))] (semi_transparent__visible : bool)
      isHumanRotateBuilding = semi_transparent__visible

    var isHumanCancelContextCommandEnabled = false
    query(squad_member__squad) <| $ [es] (squad__orderType : int = 0; squad__hasPersonalOrder : bool = false)
      isHumanCancelContextCommandEnabled = squad__orderType > 0 || squad__hasPersonalOrder

    var isActionsAvailablityChanged = false
    for actionHandle, isActionAvailable in input_priority__actionsHandles, input_priority__actionsAvailability
      let prevIsActionAvailable = isActionAvailable

      if actionHandle == human_input__use
        isActionAvailable = isHumanUseEnabled
      elif actionHandle == human_input__exitVehicleAlone
        isActionAvailable = isHumanExitVehicleAloneEnabled
      elif actionHandle == human_input__reload
        isActionAvailable = isHumanReloadEnabled
      elif actionHandle == human_input__vehicleMaintenance
        isActionAvailable = isHumanMaintenanceEnabled
      elif actionHandle == human_input__pushObject
        isActionAvailable = isHumanPushObjectEnabled
      elif actionHandle == human_input__melee
        isActionAvailable = isHumanMeleeEnabled
      elif actionHandle == human_input__buildingAction
        isActionAvailable = isHumanBuildingActionEnabled
      elif actionHandle == human_inventory_input__pickup
        isActionAvailable = isInventoryPickup
      elif actionHandle == human_inventory_input__forcedPickup
        isActionAvailable = isInventoryPickup
      elif actionHandle == human_input__bipodToggle
        isActionAvailable = isHumanBipodToggle
      elif actionHandle == human_context_command__aCancelContextCommand
        isActionAvailable = isHumanCancelContextCommandEnabled
      elif actionHandle == human_input__throwBack
        isActionAvailable = isHumanThrowBack
      elif actionHandle == mortar_input__switchShellType
        isActionAvailable = isMortarSwitchShellType
      elif actionHandle == human_input__fortificationMirrorPreview
        isActionAvailable = isHumanRotateBuilding
      elif actionHandle == human_input__repairBuilding
        isActionAvailable = isHumanRepairBuilding

      if isActionAvailable != prevIsActionAvailable
        isActionsAvailablityChanged = true

    if isActionsAvailablityChanged
      sendEvent(eid, [[EventInputPriorityActionsAvailabilityChanged]])
