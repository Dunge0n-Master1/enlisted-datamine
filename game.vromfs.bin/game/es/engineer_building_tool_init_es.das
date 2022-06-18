require ecs
require ecs.common
require DagorSystem

def private is_building_unlock(engineer_unlocks : Array; unlock_id : int)
  for unlock in engineer_unlocks
    if get_int(unlock) ?? 0 == unlock_id
      return true
  return false

def private unlock_bulding(index : int; template_name : string; engineer_unlocks : Array; var unlocks : IntList&)
  if find_index(unlocks, index) >= 0
    return

  let tmpl = getTemplateByName(template_name)
  if tmpl == null
    logerr("Engineer building template '{template_name}' not exist!")
    return

  let unlockId = get_int(getTemplateComponent(*tmpl, "building__requireUnlockId")) ?? -1
  if unlockId == -1 || is_building_unlock(engineer_unlocks, unlockId)
    push(unlocks, index)

[es(on_appear, tag=server)]
def engineer_get_building_tool(evt : Event; previewTemplate : StringList; gun__owner : EntityId)
  query(gun__owner) <| $ [es] (squad_member__squad : EntityId)
    query(squad_member__squad) <| $ [es] (squad__id : int;
                                          squad__ownerPlayer : EntityId;
                                          var buildings__unlockIds : IntList&)
      query(squad__ownerPlayer) <| $ [es] (army : string; armies : Object)
        let armyData = armies[army]
        let squads = get_ecs_array(*get_ecs_object(armyData), "squads")
        if squads == null
          return

        let curSquad = get_ecs_object((*squads)[squad__id])
        let engineerUnlocks = get_ecs_array(curSquad, "engineerUnlocks")
        if engineerUnlocks == null
          return

        for index in range(length(previewTemplate))
          unlock_bulding(index, string(previewTemplate[index]), *engineerUnlocks, buildings__unlockIds)
