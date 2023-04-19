require ecs
require DngWounds
require dm
require game.events_game

[es(tag=render, REQUIRE=human__breakable_bones)]
def tear_all_limbs_on_hit(evt : EventEntityDied;
                          transform : float3x4;
                          attaches_list : EidList;
                          human__tearAllLimbsDamage : float = 9000.;
                          human__tearAllLimbsEffect : string = "";
                          human__tearAllLimbsEffectOffset = float3(0.0, 1.2, 0.0))
  if evt.shellId < 0
    return
  damage_table_get_props(evt.shellId) <| $(damageProps : DamageTableProps)
    let shellDamage = damageProps.damage
    if shellDamage < human__tearAllLimbsDamage
      return
    for eid in attaches_list
      query(eid) <| $ [es] (var broken_bones_nodes : BrokenBonesNodes)
        for breakInst in broken_bones_nodes.breaks
          breakInst.accumulatedDamage = breakInst.damageThreshold
    if human__tearAllLimbsEffect != ""
      createEntity(human__tearAllLimbsEffect) <| $(var init : ComponentsInitializer)
        var tm = transform
        tm[3] += human__tearAllLimbsEffectOffset
        init |> set("transform", tm)
