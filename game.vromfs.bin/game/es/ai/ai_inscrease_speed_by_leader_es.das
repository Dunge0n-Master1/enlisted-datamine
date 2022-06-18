require ecs
require HumanPhys
require DagorMath
require EnlistedHuman

[es(tag=server, before=human_phys_es, after=after_entity_mods_apply_sync_point)]
def ai_inscrease_speed_by_leader_dist_es(info : UpdateStageInfoAct; squad__leader : EntityId; squad__ownerPlayer : EntityId; squad__allMembers : EidList)
  query(squad__ownerPlayer) <| $ [es(REQUIRE_NOT=playerIsBot)] ()
    query(squad__leader) <| $ [es] (transform aka leader_transform : float3x4)
      for member in squad__allMembers
        query(member) <| $ [es] (beh_tree__enabled : bool;
                                 transform : float3x4;
                                 var human_net_phys : HumanActor&;
                                 bot__speedBoostSum : float = 0.2f;
                                 bot__speedBoostSqDistThreshold : float = 225f)
          if !beh_tree__enabled
            return
          // do plus because we want to save entity perks
          let dist = length_sq(leader_transform[3] - transform[3])
          human_net_phys.phys.currentState.moveSpeedMult += dist >= bot__speedBoostSqDistThreshold ? bot__speedBoostSum : 0f
          human_net_phys.phys.currentState.staminaDrainMult = 0f // Infinity stamina for bots
