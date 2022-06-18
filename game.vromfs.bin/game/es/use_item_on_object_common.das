module use_item_on_object_common shared
require ecs
require ecs.common

def use_item_on_object(itemContainer : EidList;
                       var human_use_object__selectedObject : EntityId&;
                       var human_use_object__lookAtObject : EntityId&;
                       var human_use_object__lookAtSelected : bool&;
                       var customUsePrompt : das_string?;
                       item_predicate : block<(eid : EntityId const) : bool>;
                       entity_predicate : block<(e_eid, i_eid : EntityId const) : bool>)
  if human_use_object__selectedObject != INVALID_ENTITY_ID
    return
  find_query() <| $ [es] (client_usable_objects__riEids : EidList)
    var resultingItem = INVALID_ENTITY_ID
    var hasRequiredItem = false
    for itemEid in itemContainer
      hasRequiredItem ||= invoke(item_predicate, itemEid)
      if hasRequiredItem
        resultingItem = itemEid
        break

    for eid in client_usable_objects__riEids
      if invoke(entity_predicate, eid, resultingItem)
        if hasRequiredItem
          human_use_object__selectedObject = eid
          human_use_object__lookAtSelected = true
          if customUsePrompt != null
            *customUsePrompt := get_string(resultingItem, "item__setCustomUsePrompt", "")
        else
          human_use_object__lookAtObject = eid
        return true
    return true