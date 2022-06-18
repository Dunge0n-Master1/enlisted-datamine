module enl_teleport_common shared
require ecs
require game.utils.hero
require game.es.teleport_common


def teleport_squad_to_pos(squad_eid : EntityId; position : float3)
  query(squad_eid) <| $ [es] (squad__allMembers : EidList)
    for memberEid in squad__allMembers
      teleport_or_request(memberEid, position)