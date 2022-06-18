require ecs
require app
require ecs.common
require strings

[es(tag=server, on_appear)]
def artillery_squad_unlocks_init(evt : Event; squad__ownerPlayer : EntityId; squad__id : int)
  query(squad__ownerPlayer) <| $ [es] (army : string;
                                       armies : Object;
                                       artillery__allTemplates : Array;
                                       var artillery__templates : StringList&)
    let armyData = armies[army]
    let squads = get_ecs_array(*get_ecs_object(armyData), "squads")
    if squads != null
      let curSquad = get_ecs_object((*squads)[squad__id])

      let artilleryUnlocks = get_ecs_array(curSquad, "artilleryTypeUnlocks")
      var unlocks : table<int; bool>
      if artilleryUnlocks != null
        for unlock in *artilleryUnlocks
          let unlockId = get_int(unlock) ?? -1
          if unlockId >= 0
            unlocks[unlockId] = true
      clear(artillery__templates)
      for artillery in artillery__allTemplates
        let artilleryInfo = get_ecs_object(artillery)
        let unlockId = get_int(artilleryInfo, "unlockId")
        let artilleryTemplate = get_string(artilleryInfo, "template", "")
        if !empty(artilleryTemplate) && (unlockId == null || key_exists(unlocks, *unlockId))
          artillery__templates |> push(artilleryTemplate)