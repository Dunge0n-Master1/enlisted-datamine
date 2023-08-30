require ecs
require app
require math.base
require DagorRandom
require DngWalkerai


def is_human_should_wait_human(agent_transform : float3x4; other_transform : float3x4; distance_range : float2)
  let dir1 = agent_transform[0]
  let dir2 = other_transform[0]
  if dir1.x * dir2.x + dir1.z * dir2.z < 0.0
    return false

  let pos1 = agent_transform[3]
  let pos2 = other_transform[3]
  if distance_sq(pos1, pos2) > square(distance_range.y)
    return false

  let dist = dir1.x * (pos2.x - pos1.x) + dir1.z * (pos2.z - pos1.z)
  if dist < distance_range.x || dist > distance_range.y
    return false

  return true


[es(tag=server, REQUIRE=human, after=human_phys_es)]
def server_ai_human_squad_member_keep_distance(info : UpdateStageInfoAct;
                                               eid aka agent_eid : EntityId;
                                               squad_member__squad aka agent_squad_member__squad : EntityId;
                                               beh_tree__enabled : bool;
                                               walker_agent__waitSquadMemberTime : float2 = float2(0.1, 0.5);
                                               walker_agent__waitSquadMemberDist : float2 = float2(0.2, 1.6))
  if !beh_tree__enabled
    return

  query(squad_member__squad) <| $ [es] (squad__allMembers : EidList; squad__leader : EntityId)
    if squad__leader == agent_eid
      return
    query(agent_eid) <| $ [es] (var walker_agent aka agent_walker_agent : EntityAgent&; transform aka agent_transform : float3x4)
      if agent_walker_agent.moveCheckIt < 0 || agent_walker_agent.moveCheckIt >= length(squad__allMembers)
        agent_walker_agent.moveCheckIt = 0
      else
        let MIN_PVEL_SQ = 1.5
        if length_sq(agent_walker_agent.velocity) > MIN_PVEL_SQ
          let memberEid = squad__allMembers[agent_walker_agent.moveCheckIt]
          agent_walker_agent.moveCheckIt += 1
          if memberEid != agent_eid
            query(memberEid) <| $ [es] (transform aka member_transform : float3x4)
              if is_human_should_wait_human(agent_transform, member_transform, walker_agent__waitSquadMemberDist)
                query(memberEid) <| $ [es] (walker_agent aka member_walker_agent : EntityAgent)
                  let MIN_CVEL_SQ = 2.5
                  if length_sq(member_walker_agent.velocity) > MIN_CVEL_SQ
                    assume waitTime = walker_agent__waitSquadMemberTime
                    agent_walker_agent.waitMoveTime = get_sync_time() + rnd_float(waitTime.x, waitTime.y)
