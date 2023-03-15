require ecs
require ecs.safe
require ecs.common
require game.es.input.input_events
require game.es.input.input_common
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


def init(input_priority__actionsOrder : StringList;
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

    for conflictedActionDesc in conflictedActionDescs
      erase(actionsToProcess, conflictedActionDesc.handle)

    if !empty(conflictedActionDescs)
      sort(conflictedActionDescs) <| $(lhs, rhs : ActionDesc)
        let lhsPrior = input_priority__actionsPriorities[lhs.index]
        let rhsPrior = input_priority__actionsPriorities[rhs.index]
        return lhsPrior < rhsPrior

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


def reset(var input_priority__actionsHandles : IntList&;
          var input_priority__actionsPriorities : IntList&;
          var input_priority__actionsAvailability : BoolList&;
          var input_priority__conflictedActionsTable : IntList&)
  for action in input_priority__actionsHandles
    set_action_enabled(uint16(action), true)

  clear(input_priority__actionsHandles)
  clear(input_priority__actionsPriorities)
  clear(input_priority__actionsAvailability)
  clear(input_priority__conflictedActionsTable)


[es(tag=input, on_appear, track=glob_input__inputMode, on_event=EventControlsMenuToggle)]
def input_priority_on_appear(evt : Event;
                             glob_input__inputMode : int;
                             input_priority__actionsOrder : StringList;
                             var input_priority__actionsHandles : IntList&;
                             var input_priority__actionsPriorities : IntList&;
                             var input_priority__actionsAvailability : BoolList&;
                             var input_priority__conflictedActionsTable : IntList&)
  if glob_input__inputMode == int(InputMode MODE_GAMEPAD)
    init(input_priority__actionsOrder,
         input_priority__actionsHandles,
         input_priority__actionsPriorities,
         input_priority__actionsAvailability,
         input_priority__conflictedActionsTable)
  else
    reset(input_priority__actionsHandles,
          input_priority__actionsPriorities,
          input_priority__actionsAvailability,
          input_priority__conflictedActionsTable)


[es(tag=input)]
def input_priority_on_init(evt : EventDaInputInit;
                           input_priority__actionsOrder : StringList;
                           var input_priority__actionsHandles : IntList&;
                           var input_priority__actionsPriorities : IntList&;
                           var input_priority__actionsAvailability : BoolList&;
                           var input_priority__conflictedActionsTable : IntList&)
  if evt.init && is_gamepad_input()
    init(input_priority__actionsOrder,
         input_priority__actionsHandles,
         input_priority__actionsPriorities,
         input_priority__actionsAvailability,
         input_priority__conflictedActionsTable)
  else
    reset(input_priority__actionsHandles,
          input_priority__actionsPriorities,
          input_priority__actionsAvailability,
          input_priority__conflictedActionsTable)


[es(tag=input, track=(input_priority__conflictedActionsTable, input_priority__actionsAvailability))]
def input_priority_update_enabled_actions(evt : Event;
                                          input_priority__actionsHandles : IntList;
                                          input_priority__actionsPriorities : IntList;
                                          input_priority__actionsAvailability : BoolList;
                                          input_priority__conflictedActionsTable : IntList)
  if empty(input_priority__conflictedActionsTable)
    return

  let rows = input_priority__conflictedActionsTable[0]
  var i = 1
  for _row in range(0, rows)
    let cols = input_priority__conflictedActionsTable[i]
    i++

    var isEnabledActionFound = false
    var prevActionPriority = -1
    for _col in range(0, cols)
      let actionIndex = input_priority__conflictedActionsTable[i]
      i++

      let actionHandle = input_priority__actionsHandles[actionIndex]
      let actionPriority = input_priority__actionsPriorities[actionIndex]
      let isAvailable = input_priority__actionsAvailability[actionIndex]
      let isActionPairedWithPrevAction = prevActionPriority > -1 && actionPriority == prevActionPriority
      let isEnabled = isAvailable && (!isEnabledActionFound || isActionPairedWithPrevAction)
      set_action_enabled(uint16(actionHandle), isEnabled)
      if isAvailable
        isEnabledActionFound = true

      prevActionPriority = actionPriority


[es(tag=input)]
def input_priority_update(info : UpdateStageUpdateInput;
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
                                   human_input__buildingAction : int;
                                   human_inventory_input__pickup : int;
                                   human_inventory_input__forcedPickup : int;
                                   human_context_command__aCancelContextCommand : int;
                                   human_use_object__selectedObject : EntityId;
                                   human_use_object__selectedBuilding : EntityId;
                                   human_weap__currentGunEid : EntityId;
                                   human_vehicle__isHoldingGunPassenger : bool;
                                   useActionAvailable : int;
                                   push_object__canPush : bool;
                                   squad_member__squad : EntityId;
                                   maintenance__isExtinguishAvailable : bool;
                                   maintenance__isRepairAvailable : bool;
                                   isInVehicle : bool)
    let isHumanUseEnabled = !!human_use_object__selectedObject && !human_vehicle__isHoldingGunPassenger
    let isHumanExitVehicleAloneEnabled = isHumanUseEnabled && isInVehicle
    let isHumanMaintenanceEnabled = maintenance__isExtinguishAvailable || maintenance__isRepairAvailable || !!human_use_object__selectedBuilding
    let isHumanPushObjectEnabled = push_object__canPush
    let isHumanBuildingActionEnabled = !!human_use_object__selectedBuilding
    let isInventoryPickup = useActionAvailable == int(HumanAction ACTION_PICK_UP)
    let isInventoryForcedPickup = useActionAvailable == int(HumanAction ACTION_SWITCH_WEAPONS)

    var isHumanReloadEnabled = false
    var isHumanMeleeEnabled = false
    query(human_weap__currentGunEid) <| $ [es] (gun__ammo : int = 0;
                                                gun__maxAmmo : int = 0;
                                                gun__totalAmmo : int = 0;
                                                disableMelee : Tag const?;
                                                buildingTool : Tag const?)
      isHumanReloadEnabled = gun__ammo < gun__maxAmmo && gun__totalAmmo > 0 || buildingTool != null
      isHumanMeleeEnabled = (disableMelee == null)

    var isHumanCancelContextCommandEnabled = false
    query(squad_member__squad) <| $ [es] (squad__orderType : int = 0; squad__hasPersonalOrder : bool = false)
      isHumanCancelContextCommandEnabled = squad__orderType > 0 || squad__hasPersonalOrder

    for actionHandle, isActionAvailable in input_priority__actionsHandles, input_priority__actionsAvailability
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
        isActionAvailable = isInventoryForcedPickup
      elif actionHandle == human_context_command__aCancelContextCommand
        isActionAvailable = isHumanCancelContextCommandEnabled
