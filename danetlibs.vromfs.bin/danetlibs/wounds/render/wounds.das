require app
require ecs
require DngWounds
require danetlibs.wounds.render.wounds_events


[es(tag=render, REQUIRE=human__breakable_bones)]
def reset_bones_damage_on_healing_es(evt : CmdRestoreEntityHp;
                                     attaches_list : ecs::EidList;
                                     isAlive : bool;
                                     isDowned : bool = false)
  if !isAlive || isDowned || evt.restoreHp <= 0.f
    return

  for eid in attaches_list
    ecs::query(eid) <| $ [es] (var broken_bones_nodes : BrokenBonesNodes)
      for breakInst in broken_bones_nodes.breaks
        breakInst.accumulatedDamage = 0.0


[es(tag=render, REQUIRE=human__breakable_bones)]
def reset_bones_damage_on_downed_death_es(evt : EventEntityDied;
                                          attaches_list : ecs::EidList;
                                          hitpoints__downedEndTime : float)
  if hitpoints__downedEndTime < 0.f || get_sync_time() < hitpoints__downedEndTime
    return

  for eid in attaches_list
    ecs::query(eid) <| $ [es] (var broken_bones_nodes : BrokenBonesNodes)
      for breakInst in broken_bones_nodes.breaks
        breakInst.accumulatedDamage = 0.0


[es(tag=render, on_disappear, REQUIRE=human__breakable_bones)]
def destroy_attached_gibs_es(evt : Event; eid : EntityId)
  let ownerBodyEid = eid
  ecs::query() <| $ [es(REQUIRE=attachable_gibs)] (eid, slot_attach__attachedTo : EntityId)
    if slot_attach__attachedTo == ownerBodyEid
      destroyEntity(eid)
