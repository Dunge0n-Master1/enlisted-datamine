require ecs
require ecs.common

[es(tag=server, on_appear)]
def init_squad_unlocks(evt : Event;
                       squad__id : int;
                       squad__ownerPlayer : EntityId;
                       var squad__artilleryTimersMulUnlock : float&)
  query(squad__ownerPlayer) <| $ [es] (army : string; armies : Object)
    let armyData = armies[army]
    let squads = get_ecs_array(*get_ecs_object(armyData), "squads")
    if squads == null
      return

    let curSquad = get_ecs_object((*squads)[squad__id])
    squad__artilleryTimersMulUnlock = get_float(curSquad, "artilleryCooldownMul") ?? 1.0
