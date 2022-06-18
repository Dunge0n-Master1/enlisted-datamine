require ecs
require ecs.common
require math
require math.base
require DagorConsole
require Dacoll
require DagorMath
require RendInst
require game.es.events
require common_shooter.es.use_query_params_common
require game.utils.hero

[es(tag=gameClient, before=hero_human_pre_use_object_es)]
def hero_human_use_ri(act : UpdateStageInfoAct;
                      client_usable_objects__extraQueryRiRadius : float = 0.0;
                      var client_usable_objects__riEids : EidList)
  clear(client_usable_objects__riEids)
  let params = get_use_query_params(get_controlled_hero())
  if !params.canUse
    return
  let queryRadius = params.dist + client_usable_objects__extraQueryRiRadius
  let viewBB = BBox3(params.pos + params.dir * queryRadius * .5, queryRadius)
  gather_ri_gen_extra_collidable(viewBB) <| $(handles : array<riex_handle_t>#)
    if length(handles) == 0
      return
    var usableEntityDots : array<float>
    for it in handles
      let entityEid = find_ri_extra_eid(it)
      if entityEid == INVALID_ENTITY_ID
        continue
      var riPos : float3
      var riExtraRadius = 0.0
      query(entityEid) <| $ [es] (transform : float3x4; ri_offset : float3?; ri_extra_radius : float = 0.0)
        riPos = ri_offset == null ? transform[3] : transform * (*ri_offset)
        riExtraRadius = ri_extra_radius
      let riDir = riPos - params.pos
      if length(riDir) > params.dist + riExtraRadius
        continue
      let riDot = dot(normalize(riDir), params.dir)
      if riDot < params.dot
        continue
      var insertionIndex = length(usableEntityDots)
      for i in iter_range(usableEntityDots)
        if usableEntityDots[i] < riDot
          insertionIndex = i
          break
      push(client_usable_objects__riEids, entityEid, insertionIndex)
      push(usableEntityDots, riDot, insertionIndex)
